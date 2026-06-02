import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
  @Published private(set) var snapshot: PersistedSnapshot
  @Published var showGateQuiz = false
  @Published var isGenerating = false
  @Published var lastError: String?
  @Published var showOnboarding: Bool

  let screenTime = ScreenTimeManager()

  init() {
    snapshot = PersistenceStore.load()
    showOnboarding = !PersistenceStore.hasCompletedOnboarding
    screenTime.refreshAuthorization()
    syncShields()
  }

  func completeOnboarding() {
    PersistenceStore.hasCompletedOnboarding = true
    showOnboarding = false
  }

  func clearAllHistory() {
    PersistenceStore.clearAllHistory()
    snapshot = PersistenceStore.defaultSnapshot()
    showOnboarding = true
    showGateQuiz = false
    lastError = nil
    isGenerating = false
    screenTime.refreshAuthorization()
  }

  var activeDeck: StudyDeck? {
    guard let id = snapshot.activeDeckId else { return nil }
    return snapshot.decks.first { $0.id == id }
  }

  var isLocked: Bool { snapshot.remainingMinutes <= 0 }

  var studyMinutesReadToday: Int {
    snapshot.studyReadingSecondsToday / 90
  }

  func setDailyBudget(_ minutes: Int) {
    snapshot.dailyBudgetMinutes = minutes
    snapshot.remainingMinutes = minutes
    snapshot.usedTodayMinutes = 0
    snapshot.studyReadingSecondsToday = 0
    persist()
  }

  func upsertDeck(_ deck: StudyDeck) {
    snapshot.decks.removeAll { $0.id == deck.id }
    snapshot.decks.append(deck)
    trimDecks(limit: 3, preferredActiveId: deck.id)
    snapshot.activeDeckId = deck.id
    persist()
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

  func generateDeck(title: String, content: String, source: String) async {
    isGenerating = true
    lastError = nil
    defer { isGenerating = false }
    do {
      let deck = try await AIService.generateDeck(title: title, content: content, source: source)
      upsertDeck(deck)
    } catch {
      lastError = error.localizedDescription
    }
  }

  func openGateQuiz() {
    guard activeDeck != nil else { return }
    showGateQuiz = true
  }

  func applyQuizReward(correct: Int) -> Int {
    let mins = RewardCalculator.minutes(forCorrect: correct)
    if mins > 0 {
      snapshot.remainingMinutes += mins
      persist()
      syncShields()
    }
    return mins
  }

  private func persist() { PersistenceStore.save(snapshot) }

  private func syncShields() {
    guard screenTime.isAuthorized else { return }
    if snapshot.remainingMinutes <= 0 {
      screenTime.applyShields()
    } else {
      screenTime.clearShields()
    }
  }

  private func trimDecks(limit: Int, preferredActiveId: String) {
    guard snapshot.decks.count > limit else { return }
    while snapshot.decks.count > limit {
      guard let removable = snapshot.decks.first(where: { $0.id != preferredActiveId }) else { break }
      snapshot.decks.removeAll { $0.id == removable.id }
    }
  }
}
