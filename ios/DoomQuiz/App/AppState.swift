import Foundation
import SwiftUI
import FamilyControls

@MainActor
final class AppState: ObservableObject {
  @Published private(set) var snapshot: PersistedSnapshot
  @Published var showGateQuiz = false
  @Published var openStudyTabAfterQuiz = false
  @Published var activeSectionParagraphId: String?
  @Published var isGenerating = false
  @Published var isLoadingLessonSections = false
  @Published var isGeneratingQuizzes = false
  @Published var lastError: String?
  @Published var lastDepositMinutes: Int?
  @Published var showOnboarding: Bool

  let screenTime = ScreenTimeManager()

  init() {
    snapshot = PersistenceStore.load()
    showOnboarding = !PersistenceStore.hasCompletedOnboarding
    screenTime.refreshAuthorization()
    syncShields()
  }

  var activeDeck: StudyDeck? {
    guard let id = snapshot.activeDeckId else { return nil }
    return snapshot.decks.first { $0.id == id }
  }

  var isLocked: Bool { snapshot.remainingMinutes <= 0 }
  var studyMinutesReadToday: Int { snapshot.studyReadingSecondsToday / 120 }

  func completeOnboarding() {
    PersistenceStore.hasCompletedOnboarding = true
    showOnboarding = false
  }

  func clearAllHistory() {
    PersistenceStore.clearAllHistory()
    snapshot = PersistenceStore.defaultSnapshot()
    showOnboarding = true
    showGateQuiz = false
    activeSectionParagraphId = nil
    lastError = nil
    isGenerating = false
    isLoadingLessonSections = false
    isGeneratingQuizzes = false
    screenTime.refreshAuthorization()
    persist()
    syncShields()
  }

  func setActiveDeck(_ deckId: String) {
    guard snapshot.decks.contains(where: { $0.id == deckId }) else { return }
    snapshot.activeDeckId = deckId
    persist()
  }

  func deleteDeck(_ deckId: String) {
    snapshot.decks.removeAll { $0.id == deckId }
    if snapshot.activeDeckId == deckId {
      snapshot.activeDeckId = snapshot.decks.sorted { $0.createdAt > $1.createdAt }.first?.id
    }
    persist()
  }

  func addStudyReadingSeconds(_ seconds: Int) {
    guard seconds > 0 else { return }
    snapshot.studyReadingSecondsToday += seconds
    persist()
  }

  func setDailyBudget(_ minutes: Int) {
    snapshot.dailyBudgetMinutes = minutes
    snapshot.remainingMinutes = minutes
    snapshot.usedTodayMinutes = 0
    snapshot.studyReadingSecondsToday = 0
    snapshot.gateRewardClaimedMinutes = 0
    snapshot.gateRewardClaimedSectionIds = []
    persist()
  }

  func setInterestedTopics(_ topics: [String]) {
    snapshot.interestedTopics = topics
    persist()
  }

  func upsertDeck(_ deck: StudyDeck) {
    snapshot.decks.removeAll { $0.id == deck.id }
    snapshot.decks.append(deck)
    trimDecks(limit: 3, preferredActiveId: deck.id)
    snapshot.activeDeckId = deck.id
    persist()
  }

  func updateActiveDeckParagraphs(_ paragraphs: [StudyParagraph]) {
    guard let id = snapshot.activeDeckId, let index = snapshot.decks.firstIndex(where: { $0.id == id }) else { return }
    snapshot.decks[index].paragraphs = paragraphs
    snapshot.decks[index].masteredParagraphIds = []
    persist()
  }

  func setLessonParagraph(deckId: String, paragraph: StudyParagraph) {
    guard let index = snapshot.decks.firstIndex(where: { $0.id == deckId }) else { return }
    var paragraphs = snapshot.decks[index].paragraphs
    paragraphs.removeAll { $0.id == paragraph.id }
    paragraphs.append(paragraph)
    paragraphs.sort { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
    snapshot.decks[index].paragraphs = paragraphs
    persist()
  }

  func markParagraphMastered(_ paragraphId: String) {
    guard let id = snapshot.activeDeckId, let index = snapshot.decks.firstIndex(where: { $0.id == id }) else { return }
    if !snapshot.decks[index].masteredParagraphIds.contains(paragraphId) {
      snapshot.decks[index].masteredParagraphIds.append(paragraphId)
      persist()
    }
  }

  func appendSectionQuestions(_ newQuestions: [QuizQuestion], for paragraphId: String, deckId: String? = nil) {
    let targetId = deckId ?? snapshot.activeDeckId
    guard let id = targetId, let index = snapshot.decks.firstIndex(where: { $0.id == id }) else { return }
    snapshot.decks[index].questions.removeAll { $0.paragraphId == paragraphId }
    snapshot.decks[index].questions.append(contentsOf: newQuestions)
    persist()
  }

  func setQuestionsForDeck(deckId: String, questions: [QuizQuestion]) {
    guard let index = snapshot.decks.firstIndex(where: { $0.id == deckId }) else { return }
    snapshot.decks[index].questions = questions
    persist()
  }

  /// Fills quizzes only for sections the bundled AI response did not include.
  private func backfillMissingSectionQuizzes(deckId: String, material: String) async {
    guard let deck = snapshot.decks.first(where: { $0.id == deckId }) else { return }
    let missing = deck.paragraphs.filter { !deck.hasSectionQuestions(for: $0.id) }
    guard !missing.isEmpty else { return }

    isGeneratingQuizzes = true
    defer { isGeneratingQuizzes = false }

    for paragraph in missing {
      guard snapshot.decks.contains(where: { $0.id == deckId }) else { return }
      do {
        let questions = try await AIService.generateQuestions(
          for: paragraph,
          deckId: deckId,
          title: deck.title,
          material: material
        )
        appendSectionQuestions(questions, for: paragraph.id, deckId: deckId)
      } catch {
        lastError = error.localizedDescription
      }
    }
  }

  func ensureSectionQuestions(for paragraphId: String) async {
    guard let deck = activeDeck, deck.isAIGenerated, !deck.hasSectionQuestions(for: paragraphId),
      let paragraph = deck.paragraphs.first(where: { $0.id == paragraphId }) else { return }
    if isGeneratingQuizzes { return }
    isGenerating = true
    defer { isGenerating = false }
    do {
      let material = deck.source == "topic" ? "Topic: \(deck.title)" : "Study material: \(deck.title)"
      let questions = try await AIService.generateQuestions(for: paragraph, deckId: deck.id, title: deck.title, material: material)
      appendSectionQuestions(questions, for: paragraphId)
    } catch { lastError = error.localizedDescription }
  }

  func ensureReadingMaterial(wordsPerSection: Int = LessonContentAmount.default.wordsPerSection) async {
    guard let deck = activeDeck, deck.isAIGenerated, deck.paragraphs.isEmpty, !isGenerating, !isLoadingLessonSections else { return }
    isGenerating = true
    isLoadingLessonSections = true
    let material = lessonMaterial(title: deck.title, content: deck.reviewSummary ?? "", source: deck.source)
    do {
      let paragraphs = try await AIService.generateLessonParagraphsProgressive(
        deckId: deck.id,
        title: deck.title,
        material: material,
        source: deck.source,
        wordsPerSection: wordsPerSection
      ) { [weak self] index, paragraph, questions in
        guard let self else { return }
        self.setLessonParagraph(deckId: deck.id, paragraph: paragraph)
        if !questions.isEmpty {
          self.appendSectionQuestions(questions, for: paragraph.id, deckId: deck.id)
        }
        if index == 0 { self.isGenerating = false }
      }
      updateActiveDeckParagraphs(paragraphs)
      isGenerating = false
      isLoadingLessonSections = false
      await backfillMissingSectionQuizzes(deckId: deck.id, material: material)
    } catch {
      isGenerating = false
      isLoadingLessonSections = false
      lastError = error.localizedDescription
    }
  }

  /// Call before `generateDeck` so Study can show the loading screen on the next frame.
  func prepareLessonUI() {
    isGeneratingQuizzes = false
    isGenerating = true
    isLoadingLessonSections = true
    lastError = nil
  }

  func generateDeck(title: String, content: String, source: String, wordsPerSection: Int = LessonContentAmount.default.wordsPerSection) async {
    prepareLessonUI()
    let deckId = "deck-\(Int(Date().timeIntervalSince1970))"
    let storedExcerpt = source == "syllabus" ? PDFTextExtractor.clipForModel(content) : nil
    upsertDeck(
      StudyDeck(
        id: deckId,
        title: title,
        source: source,
        paragraphs: [],
        reviewSummary: storedExcerpt,
        points: [],
        questions: [],
        createdAt: Date()
      )
    )
    let material = lessonMaterial(title: title, content: content, source: source)
    do {
      let paragraphs = try await AIService.generateLessonParagraphsProgressive(
        deckId: deckId,
        title: title,
        material: material,
        source: source,
        wordsPerSection: wordsPerSection
      ) { [weak self] index, paragraph, questions in
        guard let self else { return }
        self.setLessonParagraph(deckId: deckId, paragraph: paragraph)
        if !questions.isEmpty {
          self.appendSectionQuestions(questions, for: paragraph.id, deckId: deckId)
        }
        if index == 0 { self.isGenerating = false }
      }
      updateActiveDeckParagraphs(paragraphs)
      isGenerating = false
      isLoadingLessonSections = false
      await backfillMissingSectionQuizzes(deckId: deckId, material: material)
    } catch {
      isGenerating = false
      isLoadingLessonSections = false
      lastError = error.localizedDescription
    }
  }

  func openGateQuiz() {
    guard let deck = activeDeck else { return }
    if deck.isAIGenerated, let target = deck.currentParagraph ?? deck.paragraphs.first {
      openSectionQuiz(paragraphId: target.id)
      return
    }
    activeSectionParagraphId = nil
    showGateQuiz = true
  }

  func openSectionQuiz(paragraphId: String) {
    guard activeDeck != nil else { return }
    activeSectionParagraphId = paragraphId
    showGateQuiz = true
  }

  func closeQuiz(openStudyTab: Bool = false) {
    showGateQuiz = false
    activeSectionParagraphId = nil
    openStudyTabAfterQuiz = openStudyTab
  }

  func applyQuizReward(correct: Int, total: Int) -> Int {
    let tierMinutes = RewardCalculator.minutes(forCorrect: correct, total: total)
    let delta = max(0, tierMinutes - snapshot.gateRewardClaimedMinutes)
    if tierMinutes > snapshot.gateRewardClaimedMinutes { snapshot.gateRewardClaimedMinutes = tierMinutes }
    if delta > 0 {
      snapshot.remainingMinutes += delta
      snapshot.quizEarnedTodayMinutes += delta
      persist()
      syncShields()
    }
    return delta
  }

  func applySectionQuizResult(correct: Int, total: Int, paragraphId: String) -> SectionQuizResult {
    guard let deck = activeDeck else {
      return SectionQuizResult(advanced: false, rewardMinutes: 0, claimedTotal: 0, wasAlreadyMastered: false)
    }
    let perfect = correct == total && total >= RewardCalculator.sectionQuestionCount
    let wasMastered = deck.masteredParagraphIds.contains(paragraphId)
    if perfect { markParagraphMastered(paragraphId) }
    var delta = 0
    if perfect, !snapshot.gateRewardClaimedSectionIds.contains(paragraphId) {
      delta = RewardCalculator.sectionPerfectMinutes
      snapshot.gateRewardClaimedSectionIds.append(paragraphId)
      snapshot.gateRewardClaimedMinutes += delta
      snapshot.remainingMinutes += delta
      snapshot.quizEarnedTodayMinutes += delta
      persist()
      syncShields()
    }
    return SectionQuizResult(advanced: perfect, rewardMinutes: delta, claimedTotal: snapshot.gateRewardClaimedMinutes, wasAlreadyMastered: wasMastered)
  }

  struct SectionQuizResult { var advanced: Bool; var rewardMinutes: Int; var claimedTotal: Int; var wasAlreadyMastered: Bool }

  private func trimDecks(limit: Int, preferredActiveId: String) {
    guard snapshot.decks.count > limit else { return }
    var removable = snapshot.decks.filter { $0.id != preferredActiveId && ($0.isAIGenerated && $0.allSectionsMastered) }
    while snapshot.decks.count > limit, let deck = removable.first {
      snapshot.decks.removeAll { $0.id == deck.id }
      removable.removeFirst()
    }
    while snapshot.decks.count > limit {
      guard let first = snapshot.decks.first(where: { $0.id != preferredActiveId }) else { break }
      snapshot.decks.removeAll { $0.id == first.id }
    }
  }

  private func lessonMaterial(title: String, content: String, source: String) -> String {
    if source == "topic" { return "Topic: \(title)" }
    return "Study material (\(title)):\n\n\(PDFTextExtractor.clipForModel(content))"
  }

  private func persist() { PersistenceStore.save(snapshot) }

  func updateScreenTimeSelection(_ selection: FamilyActivitySelection) {
    screenTime.updateSelection(selection)
    syncShields()
  }

  private func syncShields() {
    guard screenTime.isAuthorized else { return }
    if snapshot.remainingMinutes <= 0 { screenTime.applyShields() } else { screenTime.clearShields() }
  }
}
