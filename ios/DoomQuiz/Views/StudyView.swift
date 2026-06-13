import SwiftUI
import UniformTypeIdentifiers

/// Study tab — manual decks + AI topic/syllabus quizzes.
struct StudyView: View {
  @EnvironmentObject private var appState: AppState
  @Binding var selectedTab: Int
  @State private var aiTopic = ""
  @State private var syllabusText = ""
  @State private var syllabusPDFName: String?
  @State private var syllabusPDFSummary: String?
  @State private var showSyllabusPDFPicker = false
  @State private var isImportingPDF = false
  @State private var showPremiumSheet = false
  @State private var showCreateSections = false
  @State private var reviewIndex = 0
  @State private var preparingSectionId: String?
  @State private var showQuizNotReadyHint = false
  @State private var loadingPhaseIndex = 0
  @State private var loadingProgress: Double = 0
  @State private var pendingLessonTitle: String?
  @AppStorage("doomquiz.studySectionLength") private var lessonContentAmountRaw = LessonContentAmount.default.rawValue

  private let quickTopics = [
    "World War 2",
    "Python",
    "Spanish",
    "French Revolution",
    "Organic chemistry",
    "Calculus",
    "US History",
    "Machine learning",
    "Human anatomy",
    "Shakespeare",
    "Music theory",
    "Ancient Rome",
    "JavaScript",
    "Cell biology",
    "Linear algebra",
    "Psychology",
    "Climate change",
    "Greek mythology",
    "Microeconomics",
    "Stoicism",
    "Photosynthesis",
    "SAT vocabulary",
    "Art history",
    "Statistics",
    "German basics",
    "Investing basics",
    "Nursing fundamentals",
    "Ethics",
    "Constitutional law",
    "Mediterranean geography",
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          headerRow

          if appState.isLocked {
            lockedHero
          }

          if let deck = appState.activeDeck {
            if isLoadingNewLesson(deck) {
              lessonLoadingScreen(deck: deck)
            } else {
              activeLessonCard(deck)
              if !studyingDecks.isEmpty {
                studyingSection
              }
              switchLessonCollapsibleCard
            }
          } else if appState.isGenerating, let pendingLessonTitle {
            lessonLoadingScreen(title: pendingLessonTitle)
          } else {
            newLessonSection
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 32)
      }
      .background(QuizletTheme.bg)
      .navigationBarHidden(true)
      .sheet(isPresented: $showPremiumSheet) {
        PremiumSheetView()
      }
      .fileImporter(
        isPresented: $showSyllabusPDFPicker,
        allowedContentTypes: [.pdf],
        allowsMultipleSelection: false
      ) { result in
        handleSyllabusPDFImport(result)
      }
    }
  }

  private var headerRow: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading, spacing: 2) {
        Text("Study")
          .font(.system(size: 29, weight: .black, design: .rounded))
          .foregroundStyle(QuizletTheme.text)
        Text("Read, quiz, earn scroll time")
          .font(.system(size: 14, weight: .medium, design: .rounded))
          .foregroundStyle(QuizletTheme.textMuted)
      }
      Spacer()
      CompactTimeBadge(
        minutesReadToday: appState.studyMinutesReadToday
      )
    }
    .padding(.bottom, 4)
  }

  private func activeLessonCard(_ deck: StudyDeck) -> some View {
    VStack(alignment: .leading, spacing: 18) {
      activeDeckHeader(deck)
      activeDeckBody(deck)
    }
    .padding(18)
    .background(QuizletTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(QuizletTheme.border.opacity(0.55), lineWidth: 1)
    )
    .themeCardShadow(elevated: true)
  }

  private var lockedHero: some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: "lock.fill")
        .font(.title3.weight(.bold))
        .foregroundStyle(UnrotTheme.accent)
        .frame(width: 44, height: 44)
        .background(UnrotTheme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

      VStack(alignment: .leading, spacing: 8) {
        Text("Time's up")
          .font(.system(size: 18, weight: .heavy, design: .rounded))
          .foregroundStyle(QuizletTheme.text)
        Text("Apps are locked. Pass the section quiz (6/6) to deposit minutes.")
          .font(.system(size: 14, weight: .medium, design: .rounded))
          .foregroundStyle(QuizletTheme.textMuted)
          .fixedSize(horizontal: false, vertical: true)

        if appState.activeDeck != nil {
          Button { appState.openGateQuiz() } label: {
            Text("Take section quiz")
              .font(.system(size: 15, weight: .heavy, design: .rounded))
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
          }
          .buttonStyle(.borderedProminent)
          .tint(UnrotTheme.accent)
          .padding(.top, 4)
        }
      }
    }
    .padding(16)
    .background(
      LinearGradient(
        colors: [UnrotTheme.accentSoft, QuizletTheme.card],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(UnrotTheme.accent.opacity(0.35), lineWidth: 1)
    )
    .themeCardShadow()
  }

  private func activeDeckHeader(_ deck: StudyDeck) -> some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text(deck.title)
          .font(.system(size: 22, weight: .heavy, design: .rounded))
          .foregroundStyle(QuizletTheme.text)
          .lineLimit(2)
        Text(activeLessonSubtitle(for: deck))
          .font(.system(size: 13, weight: .semibold, design: .rounded))
          .foregroundStyle(QuizletTheme.textMuted)
          .lineLimit(2)
      }
      Spacer(minLength: 8)
      if deck.isAIGenerated {
        VStack(spacing: 4) {
          Text("\(deck.masteredParagraphIds.count)/\(LessonContentAmount.sectionCount)")
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(deck.allSectionsMastered ? QuizletTheme.correct : QuizletTheme.primary)
          Text("sections")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(QuizletTheme.textMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
          deck.allSectionsMastered ? QuizletTheme.correct.opacity(0.12) : QuizletTheme.primarySoft
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
    }
  }

  /// Full block when no active lesson yet.
  private var newLessonSection: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Start learning")
        .font(.system(size: 20, weight: .heavy, design: .rounded))
        .foregroundStyle(QuizletTheme.text)
      lessonPickerContent
    }
  }

  /// Topic / syllabus / custom — new lesson or switch lesson form (no Studying list).
  private func switchLessonForm(embedded: Bool = false) -> some View {
    VStack(alignment: .leading, spacing: embedded ? 16 : 20) {
      topicHeroSection(embedded: embedded)

      if !embedded {
        Text("More ways")
          .font(.caption.weight(.bold))
          .foregroundStyle(QuizletTheme.textMuted)
          .padding(.leading, 4)
      }

      syllabusOptionSection(embedded: embedded)

      if let err = appState.lastError {
        Text(err)
          .font(.footnote)
          .foregroundStyle(QuizletTheme.wrong)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  /// Full picker when no active lesson yet — Studying above ways to start a lesson.
  private var lessonPickerContent: some View {
    VStack(alignment: .leading, spacing: 20) {
      if !studyingDecks.isEmpty {
        studyingSection
      }
      switchLessonForm()
    }
  }

  /// Primary path — always visible (Quizlet-style search hero).
  private func topicHeroSection(embedded: Bool = false) -> some View {
    let content = VStack(alignment: .leading, spacing: 12) {
      Label("Learn or improve", systemImage: "sparkles")
        .font(.system(size: 14, weight: .heavy, design: .rounded))
        .foregroundStyle(QuizletTheme.primary)

      StudyInputField(
        placeholder: "Enter the topic you want to learn",
        text: $aiTopic,
        axis: .vertical,
        lineLimit: 2...3
      )

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(quickTopics, id: \.self) { idea in
            Button { aiTopic = idea } label: {
              Text(idea)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(aiTopic == idea ? .white : QuizletTheme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(aiTopic == idea ? QuizletTheme.primary : QuizletTheme.primarySoft)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
          }
        }
      }

      if aiTopic.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 {
        aiContentAmountControl
      }

      generateButton(title: "Start lesson") {
        await generateTopicQuiz()
      }
      .disabled(appState.isGenerating || aiTopic.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
    }

    return Group {
      if embedded {
        content
      } else {
        content
          .padding(18)
          .background(
            LinearGradient(
              colors: [QuizletTheme.primarySoft.opacity(0.65), QuizletTheme.card],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
              .stroke(QuizletTheme.primary.opacity(0.28), lineWidth: 1.5)
          )
          .themeCardShadow(elevated: true)
      }
    }
  }

  private var aiContentAmountControl: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Length")
        .font(.caption.weight(.bold))
        .foregroundStyle(QuizletTheme.textMuted)

      Picker("", selection: contentAmountPickerBinding) {
        ForEach(LessonContentAmount.allCases) { level in
          Text(level.label).tag(level.rawValue)
        }
      }
      .pickerStyle(.segmented)
    }
  }

  private func syllabusOptionSection(embedded: Bool = false) -> some View {
    let content = VStack(alignment: .leading, spacing: 10) {
      Button { openSyllabusPDFPicker() } label: {
        lessonOptionRowContent(
          icon: "doc.fill",
          title: "Syllabus",
          subtitle: syllabusPDFSubtitle,
          trailing: isImportingPDF ? AnyView(ProgressView()) : AnyView(
            Image(systemName: "chevron.right")
              .font(.caption.weight(.bold))
              .foregroundStyle(QuizletTheme.textMuted)
          ),
          badge: "Premium"
        )
      }
      .buttonStyle(.plain)
      .disabled(isImportingPDF)

      if syllabusPDFName != nil {
        aiContentAmountControl

        generateButton(title: "Start lesson from PDF") {
          await generateSyllabusQuiz()
        }
        .disabled(appState.isGenerating || syllabusText.count < 20)
      }
    }

    return Group {
      if embedded {
        content
      } else {
        content
          .padding(14)
          .background(QuizletTheme.card)
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .stroke(QuizletTheme.border, lineWidth: 1)
          )
          .themeCardShadow()
      }
    }
  }

  private func lessonOptionRowContent(
    icon: String,
    title: String,
    subtitle: String,
    trailing: AnyView,
    badge: String? = nil
  ) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.title3.weight(.semibold))
        .foregroundStyle(QuizletTheme.primary)
        .frame(width: 44, height: 44)
        .background(QuizletTheme.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(title)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(QuizletTheme.text)
          if let badge {
            Text(badge)
              .font(.caption2.weight(.bold))
              .foregroundStyle(QuizletTheme.textMuted)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(QuizletTheme.inputBg)
              .clipShape(Capsule())
          }
        }
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(QuizletTheme.textMuted)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
      }

      Spacer(minLength: 4)
      trailing
    }
  }

  private func generateButton(title: String, action: @escaping () async -> Void) -> some View {
    Button {
      Task { await action() }
    } label: {
      Group {
        if appState.isGenerating {
          ProgressView().tint(.white)
        } else {
          Text(title).fontWeight(.heavy)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
    }
    .buttonStyle(.borderedProminent)
    .tint(QuizletTheme.primary)
    .disabled(appState.isGenerating || appState.isLoadingLessonSections)
  }

  private func openSyllabusPDFPicker() {
    if PremiumStore.isPremium {
      showSyllabusPDFPicker = true
    } else {
      showPremiumSheet = true
    }
  }

  private func handleSyllabusPDFImport(_ result: Result<[URL], Error>) {
    switch result {
    case .failure(let error):
      appState.lastError = error.localizedDescription
    case .success(let urls):
      guard let url = urls.first else { return }
      isImportingPDF = true
      Task {
        defer { isImportingPDF = false }
        do {
          let extracted = try PDFTextExtractor.extractText(from: url)
          syllabusText = extracted.text
          syllabusPDFName = url.deletingPathExtension().lastPathComponent
          syllabusPDFSummary = extracted.summaryLine
          appState.lastError = nil
        } catch {
          appState.lastError = error.localizedDescription
        }
      }
    }
  }

  private func generateSyllabusQuiz() async {
    guard PremiumStore.isPremium else {
      showPremiumSheet = true
      return
    }
    let body = syllabusText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard body.count >= 20 else {
      appState.lastError = "Import a PDF first."
      return
    }
    let title = syllabusPDFName ?? "Syllabus"
    beginLessonGeneration(displayTitle: title)
    await appState.generateDeck(
      title: title,
      content: body,
      source: "syllabus",
      wordsPerSection: lessonContentAmount.wordsPerSection
    )
    finishLessonGeneration()
    if appState.activeDeck != nil {
      syllabusText = ""
      syllabusPDFName = nil
      syllabusPDFSummary = nil
    }
  }

  private func beginLessonGeneration(displayTitle: String) {
    pendingLessonTitle = displayTitle
    showCreateSections = false
    appState.prepareLessonUI()
  }

  private func finishLessonGeneration() {
    pendingLessonTitle = nil
    if appState.activeDeck?.paragraphs.isEmpty == true,
      !appState.isGenerating, !appState.isLoadingLessonSections
    {
      loadingProgress = 0
      loadingPhaseIndex = 0
    }
  }

  private func isLoadingNewLesson(_ deck: StudyDeck) -> Bool {
    deck.paragraphs.isEmpty && (appState.isGenerating || appState.isLoadingLessonSections)
  }

  private func lessonLoadingScreen(deck: StudyDeck) -> some View {
    lessonLoadingScreen(title: deck.title)
  }

  private func lessonLoadingScreen(title: String) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(title)
        .font(.title2.weight(.heavy))
        .foregroundStyle(QuizletTheme.text)
        .lineLimit(2)

      lessonLoadingCard
    }
  }

  private var lessonLoadingCard: some View {
    lessonLoadingCardContent
  }

  private var syllabusPDFSubtitle: String {
    if let syllabusPDFSummary, !syllabusPDFSummary.isEmpty { return syllabusPDFSummary }
    if let syllabusPDFName { return syllabusPDFName }
    return "Upload PDF — lecture notes or syllabus"
  }

  @ViewBuilder
  private func activeDeckBody(_ deck: StudyDeck) -> some View {
    if deck.isAIGenerated {
      aiDeckBody(deck)
    } else {
      manualDeckBody(deck)
    }
  }

  private var switchLessonCollapsibleCard: some View {
    VStack(alignment: .leading, spacing: showCreateSections ? 16 : 0) {
      Button {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
          showCreateSections.toggle()
        }
      } label: {
        HStack(spacing: 12) {
          Image(systemName: "arrow.triangle.2.circlepath")
            .font(.body.weight(.semibold))
            .foregroundStyle(QuizletTheme.primary)
            .frame(width: 40, height: 40)
            .background(QuizletTheme.primarySoft)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

          VStack(alignment: .leading, spacing: 2) {
            Text("Switch lesson")
              .font(.system(size: 15, weight: .bold, design: .rounded))
              .foregroundStyle(QuizletTheme.text)
            Text(showCreateSections ? "Pick a new topic or syllabus" : "Topic · Syllabus")
              .font(.system(size: 12, weight: .medium, design: .rounded))
              .foregroundStyle(QuizletTheme.textMuted)
          }

          Spacer(minLength: 4)

          Image(systemName: showCreateSections ? "chevron.up" : "chevron.down")
            .font(.caption.weight(.bold))
            .foregroundStyle(QuizletTheme.textMuted)
        }
      }
      .buttonStyle(.plain)

      if showCreateSections {
        Divider()

        switchLessonForm(embedded: true)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .padding(16)
    .background(UnrotTheme.surface.opacity(0.45))
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(QuizletTheme.border.opacity(0.55), lineWidth: 1)
    )
    .themeCardShadow()
    .padding(.top, 8)
  }

  private func aiDeckBody(_ deck: StudyDeck) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      if !deck.paragraphs.isEmpty {
        StudyLessonProgressView(
          deckTitle: deck.title,
          paragraphs: deck.paragraphs,
          masteredIds: Set(deck.masteredParagraphIds),
          isGeneratingQuestions: appState.isGeneratingQuizzes || preparingSectionId != nil,
          isReadingSessionActive: selectedTab == AppTab.study.rawValue && !showCreateSections,
          showQuizNotReadyHint: showQuizNotReadyHint,
          onTakeQuiz: { paragraphId in
            Task { await startSectionQuiz(paragraphId: paragraphId, deck: deck) }
          }
        )
      } else {
        readingMaterialPlaceholder
      }

      if deck.allSectionsMastered, appState.isLocked {
        reviewSectionButton(deck: deck)
      }
    }
    .task(id: deck.id) {
      if deck.isAIGenerated && deck.paragraphs.isEmpty,
        !appState.isGenerating, !appState.isLoadingLessonSections
      {
        await appState.ensureReadingMaterial(wordsPerSection: lessonContentAmount.wordsPerSection)
      }
    }
  }

  private func startSectionQuiz(paragraphId: String, deck: StudyDeck) async {
    preparingSectionId = paragraphId
    defer { preparingSectionId = nil }

    if !deck.hasSectionQuestions(for: paragraphId) {
      withAnimation(.easeInOut(duration: 0.2)) {
        showQuizNotReadyHint = true
      }
      return
    }

    showQuizNotReadyHint = false
    guard appState.activeDeck?.hasSectionQuestions(for: paragraphId) == true else { return }
    appState.openSectionQuiz(paragraphId: paragraphId)
  }

  private func reviewSectionButton(deck: StudyDeck) -> some View {
    Button {
      if let first = deck.paragraphs.first {
        Task { await startSectionQuiz(paragraphId: first.id, deck: deck) }
      }
    } label: {
      Text("Review a section — earn up to \(RewardCalculator.sectionPerfectMinutes)m")
        .fontWeight(.heavy)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    .buttonStyle(.borderedProminent)
    .tint(QuizletTheme.primary)
  }

  private var readingMaterialPlaceholder: some View {
    VStack(alignment: .leading, spacing: 12) {
      if appState.isGenerating || appState.isLoadingLessonSections {
        if appState.isLoadingLessonSections && (appState.activeDeck?.paragraphs.isEmpty == false) {
          HStack(spacing: 12) {
            ProgressView()
            Text("Loading more sections…")
              .font(.subheadline)
              .foregroundStyle(QuizletTheme.textMuted)
          }
          .padding(16)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(QuizletTheme.card)
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
          lessonLoadingCardContent
        }
      } else {
        Text("Reading material didn't load. Tap below to load your lesson sections.")
          .font(.footnote)
          .foregroundStyle(QuizletTheme.textMuted)
        Button {
          Task { await appState.ensureReadingMaterial(wordsPerSection: lessonContentAmount.wordsPerSection) }
        } label: {
          Text("Load reading material")
            .fontWeight(.heavy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(QuizletTheme.primary)
      }
    }
  }

  private func manualDeckBody(_ deck: StudyDeck) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      if !deck.points.isEmpty {
        Text("Quick review")
          .font(.headline.weight(.heavy))
          .foregroundStyle(QuizletTheme.text)

        TabView(selection: $reviewIndex) {
          ForEach(Array(deck.points.enumerated()), id: \.element.id) { index, point in
            MemorizeCardView(point: point, index: index)
              .tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: 200)

        Text("Card \(reviewIndex + 1) of \(deck.points.count)")
          .font(.caption)
          .foregroundStyle(QuizletTheme.textMuted)
          .frame(maxWidth: .infinity)
      }

      if appState.isLocked {
        Text("Unlock quiz · \(deck.questions.count) questions")
          .font(.headline.weight(.heavy))
          .foregroundStyle(QuizletTheme.text)

        attemptQuizButton(
          title: "Attempt quiz — earn up to 15 min",
          prominent: true
        )
      }
    }
  }

  private func attemptQuizButton(title: String, prominent: Bool) -> some View {
    Button { appState.openGateQuiz() } label: {
      Text(title)
        .fontWeight(.heavy)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    .buttonStyle(.borderedProminent)
    .tint(QuizletTheme.primary)
    .opacity(prominent ? 1 : 0.92)
  }

  private func activeLessonSubtitle(for deck: StudyDeck) -> String {
    guard deck.isAIGenerated else { return sourceLabel(deck.source) }

    let total = LessonContentAmount.sectionCount
    let current = deck.currentParagraph ?? deck.paragraphs.first
    let sectionNumber: Int = {
      guard let current, let index = deck.paragraphs.firstIndex(where: { $0.id == current.id }) else {
        return min(deck.masteredParagraphIds.count + 1, total)
      }
      return min(index + 1, total)
    }()

    guard let current else {
      return "Section \(sectionNumber) of \(total)"
    }
    let title = sectionTitleSnippet(current.label, deckTitle: deck.title)
    return "Section \(sectionNumber) of \(total) \(title)"
  }

  private func sectionTitleSnippet(_ label: String, deckTitle: String) -> String {
    let topic = deckTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    var rest = label.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !topic.isEmpty else { return rest }

    if rest.lowercased().hasPrefix(topic.lowercased()) {
      rest = String(rest.dropFirst(topic.count)).trimmingCharacters(in: .whitespacesAndNewlines)
      if rest.hasPrefix("("), rest.hasSuffix(")") {
        rest = String(rest.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
      }
      rest = rest.trimmingCharacters(in: CharacterSet(charactersIn: ":-–—·"))
    }
    return rest.isEmpty ? label : rest
  }

  private func sourceLabel(_ source: String) -> String {
    switch source {
    case "manual": return "Your quiz · \(appState.snapshot.remainingMinutes)m ready today"
    case "syllabus": return "AI · from syllabus"
    default: return "AI · topic quiz"
    }
  }

  private var lessonLoadingCardContent: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(currentLoadingPhaseTitle)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(QuizletTheme.text)

      Text("Turning your topic into a lesson you can actually read.")
        .font(.footnote)
        .foregroundStyle(QuizletTheme.textMuted)

      GeometryReader { geo in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(QuizletTheme.card)
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(QuizletTheme.primary)
            .frame(width: max(0, geo.size.width * loadingProgress))
        }
        .frame(height: 8)
      }
      .frame(height: 8)

      HStack {
        Text("\(Int(loadingProgress * 100))%")
          .font(.caption.weight(.semibold))
          .foregroundStyle(QuizletTheme.primary)
        Spacer()
        Text("Finding · Summarizing · Clarifying · Simplifying")
          .font(.caption2)
          .foregroundStyle(QuizletTheme.textMuted)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(QuizletTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .themeCardShadow()
    .task(id: appState.isGenerating || appState.isLoadingLessonSections) {
      guard appState.isGenerating || appState.isLoadingLessonSections else {
        loadingProgress = 0
        loadingPhaseIndex = 0
        return
      }

      let phases = loadingPhases
      loadingProgress = 0
      loadingPhaseIndex = 0

      let lastIndex = phases.count - 1
      for index in 0..<lastIndex {
        if !(appState.isGenerating || appState.isLoadingLessonSections) { break }
        loadingPhaseIndex = index
        HapticFeedback.selection()
        try? await Task.sleep(for: .milliseconds(1400))
        let fraction = Double(index + 1) / Double(phases.count)
        loadingProgress = min(0.8, fraction)
      }

      if appState.isGenerating || appState.isLoadingLessonSections {
        loadingPhaseIndex = lastIndex
        loadingProgress = max(loadingProgress, 0.8)

        while appState.isGenerating || appState.isLoadingLessonSections {
          try? await Task.sleep(for: .milliseconds(200))
        }

        HapticFeedback.medium()
        loadingProgress = 1.0
      }
    }
  }

  private func generateTopicQuiz() async {
    let trimmed = aiTopic.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count >= 3 else {
      appState.lastError = "Enter a topic (e.g. \"French Revolution\")."
      return
    }
    beginLessonGeneration(displayTitle: trimmed)
    await appState.generateDeck(
      title: trimmed,
      content: "Topic to learn: \(trimmed)",
      source: "topic",
      wordsPerSection: lessonContentAmount.wordsPerSection
    )
    finishLessonGeneration()
    if appState.activeDeck != nil {
      aiTopic = ""
    }
  }

  private var studyingDecks: [StudyDeck] {
    appState.snapshot.decks
      .filter { $0.id != appState.activeDeck?.id }
      .filter { !($0.isAIGenerated && $0.allSectionsMastered) }
      .sorted { $0.createdAt > $1.createdAt }
  }

  private var studyingSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Other lessons")
        .font(.system(size: 13, weight: .heavy, design: .rounded))
        .foregroundStyle(QuizletTheme.textMuted)
        .textCase(.uppercase)
        .padding(.leading, 2)

      VStack(spacing: 8) {
        ForEach(studyingDecks) { deck in
          Button {
            appState.setActiveDeck(deck.id)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
              showCreateSections = false
            }
          } label: {
            HStack(spacing: 12) {
              Image(systemName: deck.isAIGenerated ? "book.fill" : "square.stack.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(QuizletTheme.primary)
                .frame(width: 36, height: 36)
                .background(QuizletTheme.primarySoft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

              VStack(alignment: .leading, spacing: 3) {
                Text(deck.title)
                  .font(.system(size: 15, weight: .semibold, design: .rounded))
                  .foregroundStyle(QuizletTheme.text)
                  .lineLimit(1)
                Text(studyingSubtitle(deck))
                  .font(.system(size: 12, weight: .medium, design: .rounded))
                  .foregroundStyle(QuizletTheme.textMuted)
                  .lineLimit(1)
              }
              Spacer()
              Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(QuizletTheme.textMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(QuizletTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(QuizletTheme.border.opacity(0.55), lineWidth: 1)
            )
            .themeCardShadow()
          }
          .buttonStyle(.plain)
          .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(role: .destructive) {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                appState.deleteDeck(deck.id)
              }
            } label: {
              Label("Delete", systemImage: "trash")
            }
          }
        }
      }

    }
  }

  private func studyingSubtitle(_ deck: StudyDeck) -> String {
    if deck.isAIGenerated {
      return "\(deck.masteredParagraphIds.count)/\(LessonContentAmount.sectionCount) sections mastered"
    }
    return "\(deck.points.count) cards · \(deck.questions.count) questions"
  }
}

private extension StudyView {
  var lessonContentAmount: LessonContentAmount {
    LessonContentAmount(rawValue: lessonContentAmountRaw) ?? .default
  }

  var loadingPhases: [String] {
    [
      "Finding good material…",
      "Summarizing the dense bits…",
      "Making it clearer…",
      "Simplifying into 8 sections…",
    ]
  }

  var currentLoadingPhaseTitle: String {
    let phases = loadingPhases
    let index = min(max(0, loadingPhaseIndex), phases.count - 1)
    return phases[index]
  }

  var contentAmountPickerBinding: Binding<String> {
    Binding(
      get: { lessonContentAmountRaw },
      set: { newValue in
        let fallback = LessonContentAmount.default.rawValue
        let value = LessonContentAmount(rawValue: newValue)?.rawValue ?? fallback
        lessonContentAmountRaw = value
      }
    )
  }
}
