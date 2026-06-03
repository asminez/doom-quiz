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
  @State private var showManualBuilder = false
  @State private var showPremiumSheet = false
  @State private var showCreateSections = false
  @State private var reviewIndex = 0
  @State private var preparingSectionId: String?
  @State private var showQuizNotReadyHint = false
  @State private var loadingPhaseIndex = 0
  @State private var loadingProgress: Double = 0
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
        VStack(alignment: .leading, spacing: 20) {
          headerRow

          if appState.isLocked {
            lockedHero
          }

          if let deck = appState.activeDeck {
            if showCreateSections {
              switchLessonPickerMode(deck)
            } else {
              activeDeckHeader(deck)
              activeDeckBody(deck)
              switchLessonLink
            }
          } else {
            newLessonSection
          }
        }
        .padding(20)
        .padding(.bottom, showCreateSections && appState.activeDeck != nil ? 12 : 32)
      }
      .background(QuizletTheme.bg)
      .safeAreaInset(edge: .bottom, spacing: 0) {
        if showCreateSections, let deck = appState.activeDeck {
          CompressedLessonCard(deck: deck) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
              showCreateSections = false
            }
          }
          .padding(.horizontal, 20)
          .padding(.top, 8)
          .padding(.bottom, 10)
          .background(
            QuizletTheme.bg
              .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
          )
        }
      }
      .navigationBarHidden(true)
      .sheet(isPresented: $showManualBuilder) {
        ManualDeckBuilderView()
      }
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
      Text("Study")
        .font(.title.weight(.black))
        .foregroundStyle(QuizletTheme.text)
      Spacer()
      CompactTimeBadge(
        minutesReadToday: appState.studyMinutesReadToday
      )
    }
  }

  private var lockedHero: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Time's up")
        .font(.title.weight(.heavy))
        .foregroundStyle(QuizletTheme.text)
      Text("Apps are locked. Read the section, then pass its quiz (6/6) to deposit minutes.")
        .font(.subheadline)
        .foregroundStyle(QuizletTheme.textMuted)
        .fixedSize(horizontal: false, vertical: true)

      if appState.activeDeck != nil {
        Button { appState.openGateQuiz() } label: {
          Text("Pass section quiz to unlock")
            .fontWeight(.heavy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(QuizletTheme.primary)
      }
    }
    .padding(16)
    .background(UnrotTheme.accentSoft)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(UnrotTheme.accent.opacity(0.4), lineWidth: 1)
    )
  }

  private func activeDeckHeader(_ deck: StudyDeck) -> some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(deck.title)
          .font(.title2.weight(.heavy))
          .foregroundStyle(QuizletTheme.text)
          .lineLimit(2)
        Text(activeLessonSubtitle(for: deck))
          .font(.caption.weight(.semibold))
          .foregroundStyle(QuizletTheme.textMuted)
          .lineLimit(2)
      }
      Spacer(minLength: 8)
      if deck.isAIGenerated {
        Text("\(deck.masteredParagraphIds.count)/\(LessonContentAmount.sectionCount)")
          .font(.subheadline.weight(.heavy))
          .foregroundStyle(deck.allSectionsMastered ? QuizletTheme.correct : QuizletTheme.primary)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(
            deck.allSectionsMastered ? QuizletTheme.correct.opacity(0.12) : QuizletTheme.primarySoft
          )
          .clipShape(Capsule())
      }
    }
  }

  /// Full block when no active lesson yet.
  private var newLessonSection: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Start learning")
        .font(.headline.weight(.heavy))
        .foregroundStyle(QuizletTheme.text)
      lessonPickerContent
    }
  }

  /// Topic / syllabus / custom — shown when bar is expanded or no deck yet.
  private var lessonPickerContent: some View {
    VStack(alignment: .leading, spacing: 20) {
      topicHeroCard

      Text("More ways")
        .font(.caption.weight(.bold))
        .foregroundStyle(QuizletTheme.textMuted)
        .padding(.leading, 4)

      VStack(spacing: 10) {
        syllabusOptionCard
        lessonOptionRow(
          icon: "square.and.pencil",
          title: "My quiz",
          subtitle: "Build your own flashcards & questions",
          action: { showManualBuilder = true }
        )
      }

      if !studyingDecks.isEmpty {
        studyingSection
      }

      if let err = appState.lastError {
        Text(err)
          .font(.footnote)
          .foregroundStyle(QuizletTheme.wrong)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  /// Primary path — always visible (Quizlet-style search hero).
  private var topicHeroCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Learn or improve", systemImage: "sparkles")
        .font(.subheadline.weight(.heavy))
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
                .font(.caption.weight(.semibold))
                .foregroundStyle(QuizletTheme.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(QuizletTheme.primarySoft)
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
    .padding(16)
    .background(QuizletTheme.primarySoft.opacity(0.55))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(QuizletTheme.primary.opacity(0.35), lineWidth: 1.5)
    )
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

  private var syllabusOptionCard: some View {
    VStack(alignment: .leading, spacing: 10) {
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
    .padding(14)
    .background(QuizletTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(QuizletTheme.border, lineWidth: 1)
    )
  }

  private func lessonOptionRow(
    icon: String,
    title: String,
    subtitle: String,
    badge: String? = nil,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      lessonOptionRowContent(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: AnyView(
          Image(systemName: "chevron.right")
            .font(.caption.weight(.bold))
            .foregroundStyle(QuizletTheme.textMuted)
        ),
        badge: badge
      )
    }
    .buttonStyle(.plain)
    .padding(14)
    .background(QuizletTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(QuizletTheme.border, lineWidth: 1)
    )
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
    await appState.generateDeck(
      title: title,
      content: body,
      source: "syllabus",
      wordsPerSection: lessonContentAmount.wordsPerSection
    )
    if appState.activeDeck != nil {
      showCreateSections = false
      syllabusText = ""
      syllabusPDFName = nil
      syllabusPDFSummary = nil
    }
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

  private func switchLessonPickerMode(_ deck: StudyDeck) -> some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Switch lesson")
        .font(.title2.weight(.heavy))
        .foregroundStyle(QuizletTheme.text)

      lessonPickerContent
    }
    .transition(.opacity.combined(with: .move(edge: .top)))
  }

  private var switchLessonLink: some View {
    Button {
      withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
        showCreateSections = true
      }
    } label: {
      Text("Switch lesson")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(QuizletTheme.primary)
        .frame(maxWidth: .infinity)
    }
    .padding(.top, 4)
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
          .task(id: appState.isGenerating || appState.isLoadingLessonSections) {
            guard appState.isGenerating || appState.isLoadingLessonSections else {
              loadingProgress = 0
              loadingPhaseIndex = 0
              return
            }

            let phases = loadingPhases
            loadingProgress = 0
            loadingPhaseIndex = 0

            // Walk through all but the last phase at a calmer pace up to ~80%.
            let lastIndex = phases.count - 1
            for index in 0..<lastIndex {
              if !(appState.isGenerating || appState.isLoadingLessonSections) { break }
              loadingPhaseIndex = index
              HapticFeedback.selection()
              try? await Task.sleep(for: .milliseconds(1400))
              let fraction = Double(index + 1) / Double(phases.count)
              loadingProgress = min(0.8, fraction)
            }

            // Sit on the last phase and only jump to 100% when generation is done.
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

  private func generateTopicQuiz() async {
    let trimmed = aiTopic.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count >= 3 else {
      appState.lastError = "Enter a topic (e.g. \"French Revolution\")."
      return
    }
    await appState.generateDeck(
      title: trimmed,
      content: "Topic to learn: \(trimmed)",
      source: "topic",
      wordsPerSection: lessonContentAmount.wordsPerSection
    )
    if appState.activeDeck != nil {
      showCreateSections = false
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
    VStack(alignment: .leading, spacing: 10) {
      Text("Studying")
        .font(.caption.weight(.bold))
        .foregroundStyle(QuizletTheme.textMuted)
        .padding(.leading, 4)

      VStack(spacing: 8) {
        ForEach(studyingDecks) { deck in
          Button {
            appState.setActiveDeck(deck.id)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
              showCreateSections = false
            }
          } label: {
            HStack(spacing: 10) {
              Image(systemName: deck.isAIGenerated ? "book.fill" : "square.stack.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(QuizletTheme.primary)
              VStack(alignment: .leading, spacing: 2) {
                Text(deck.title)
                  .font(.subheadline.weight(.semibold))
                  .foregroundStyle(QuizletTheme.text)
                  .lineLimit(1)
                Text(studyingSubtitle(deck))
                  .font(.caption)
                  .foregroundStyle(QuizletTheme.textMuted)
                  .lineLimit(1)
              }
              Spacer()
              Image(systemName: "arrow.up.left")
                .font(.caption.weight(.bold))
                .foregroundStyle(QuizletTheme.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(QuizletTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(QuizletTheme.border, lineWidth: 1)
            )
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
