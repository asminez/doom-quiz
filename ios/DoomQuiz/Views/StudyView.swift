import SwiftUI

/// Study tab — Quizlet-style review + gate quiz (page 2).
struct StudyView: View {
  @EnvironmentObject private var appState: AppState
  @State private var topic = ""
  @State private var showNewTopic = false
  @State private var showPremiumSheet = false
  @State private var reviewIndex = 0
  @State private var readingTask: Task<Void, Never>?
  @State private var selectedLength = "medium"

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
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          headerRow

          if appState.isLocked {
            lockedHero
          } else if let deck = appState.activeDeck {
            unlockedBanner(deck: deck)
          }

          if let deck = appState.activeDeck {
            activeDeckBody(deck)
          } else {
            newTopicSection
          }
        }
        .padding(20)
        .padding(.bottom, 32)
      }
      .background(QuizletTheme.bg)
      .navigationBarHidden(true)
      .sheet(isPresented: $showPremiumSheet) {
        PremiumSheetView()
      }
      .onDisappear {
        stopReadingTimer()
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
        remaining: appState.snapshot.remainingMinutes,
        locked: appState.isLocked
      )
    }
  }

  private var lockedHero: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Time's up")
        .font(.title.weight(.heavy))
        .foregroundStyle(QuizletTheme.text)
      Text("Skim the cards below, then pass the 5-question quiz to earn scroll time.")
        .font(.subheadline)
        .foregroundStyle(QuizletTheme.textMuted)
        .fixedSize(horizontal: false, vertical: true)

      if appState.activeDeck != nil {
        Button {
          appState.openGateQuiz()
        } label: {
          Text("Take gate quiz")
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

  private func unlockedBanner(deck: StudyDeck) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(deck.title)
          .font(.headline.weight(.bold))
          .foregroundStyle(QuizletTheme.text)
        Text("\(appState.snapshot.remainingMinutes)m until next gate quiz")
          .font(.caption)
          .foregroundStyle(QuizletTheme.textMuted)
      }
      Spacer()
    }
  }

  @ViewBuilder
  private func activeDeckBody(_ deck: StudyDeck) -> some View {
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
      .onAppear { startReadingTimer() }
      .onDisappear { stopReadingTimer() }

      Text("Card \(reviewIndex + 1) of \(deck.points.count)")
        .font(.caption)
        .foregroundStyle(QuizletTheme.textMuted)
        .frame(maxWidth: .infinity)
    }

    Text("Gate quiz · \(deck.questions.count) questions")
      .font(.headline.weight(.heavy))
      .foregroundStyle(QuizletTheme.text)
      .padding(.top, 8)

    ForEach(Array(deck.questions.enumerated()), id: \.element.id) { index, q in
      QuizPreviewRow(question: q, index: index)
    }

    if appState.isLocked {
      Button {
        appState.showGateQuiz = true
      } label: {
        Text("Start quiz — earn up to 10 min")
          .fontWeight(.heavy)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
      }
      .buttonStyle(.borderedProminent)
      .tint(QuizletTheme.primary)
    }

    Button {
      showNewTopic = true
    } label: {
      Text("Switch lesson")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(QuizletTheme.primary)
        .frame(maxWidth: .infinity)
    }
    .padding(.top, 8)

    if showNewTopic {
      newTopicSection
    }
  }

  private var newTopicSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Start learning")
        .font(.title3.weight(.heavy))
        .foregroundStyle(QuizletTheme.text)
      Text("Enter a topic and generate a lesson + quiz.")
        .font(.footnote)
        .foregroundStyle(QuizletTheme.textMuted)

      TextField("Enter the topic you want to learn", text: $topic, axis: .vertical)
        .lineLimit(2...4)
        .padding(14)
        .background(QuizletTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(QuizletTheme.border, lineWidth: 1)
        )

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(quickTopics, id: \.self) { idea in
            Button { topic = idea } label: {
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

      if topic.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 {
        Picker("Length", selection: $selectedLength) {
          Text("Low").tag("low")
          Text("Medium").tag("medium")
          Text("High").tag("high")
        }
        .pickerStyle(.segmented)
      }

      Button {
        Task { await generateTopicQuiz() }
      } label: {
        Group {
          if appState.isGenerating { ProgressView().tint(.white) }
          else { Text("Start lesson").fontWeight(.heavy) }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
      }
      .buttonStyle(.borderedProminent)
      .tint(QuizletTheme.primary)
      .disabled(appState.isGenerating)

      if let err = appState.lastError {
        Text(err).font(.footnote).foregroundStyle(QuizletTheme.wrong)
      }

      Text("More ways")
        .font(.caption.weight(.bold))
        .foregroundStyle(QuizletTheme.textMuted)

      VStack(spacing: 10) {
        Button { showPremiumSheet = true } label: {
          lessonOptionRow(
            icon: "doc.fill",
            title: "Syllabus",
            subtitle: "Upload PDF — lecture notes or syllabus",
            badge: "Premium"
          )
        }
        .buttonStyle(.plain)

        Button { showPremiumSheet = true } label: {
          lessonOptionRow(
            icon: "square.and.pencil",
            title: "My quiz",
            subtitle: "Build your own flashcards & questions"
          )
        }
        .buttonStyle(.plain)
      }

      if !studyingDecks.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Studying")
            .font(.caption.weight(.bold))
            .foregroundStyle(QuizletTheme.textMuted)

          ForEach(studyingDecks) { deck in
            Button {
              appState.setActiveDeck(deck.id)
              showNewTopic = false
            } label: {
              HStack {
                Text(deck.title)
                  .font(.subheadline.weight(.semibold))
                  .foregroundStyle(QuizletTheme.text)
                  .lineLimit(1)
                Spacer()
                Text("Study now")
                  .font(.caption.weight(.bold))
                  .foregroundStyle(QuizletTheme.primary)
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 10)
              .background(QuizletTheme.card)
              .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
              Button(role: .destructive) {
                appState.deleteDeck(deck.id)
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
        }
        .padding(.top, 8)
      }
    }
    .padding(.top, 8)
  }

  private func lessonOptionRow(
    icon: String,
    title: String,
    subtitle: String,
    badge: String? = nil
  ) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 23, weight: .semibold))
        .foregroundStyle(QuizletTheme.primary)
        .frame(width: 46, height: 46)
        .background(QuizletTheme.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 6) {
          Text(title)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(QuizletTheme.text)
          if let badge {
            Text(badge)
              .font(.system(size: 12, weight: .bold))
              .foregroundStyle(QuizletTheme.textMuted)
              .padding(.horizontal, 7)
              .padding(.vertical, 3)
              .background(QuizletTheme.primarySoft)
              .clipShape(Capsule())
          }
        }
        Text(subtitle)
          .font(.system(size: 14))
          .foregroundStyle(QuizletTheme.textMuted)
      }

      Spacer()
      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(QuizletTheme.textMuted)
    }
    .padding(14)
    .background(QuizletTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(QuizletTheme.border, lineWidth: 1)
    )
  }

  private var studyingDecks: [StudyDeck] {
    appState.snapshot.decks
      .filter { $0.id != appState.activeDeck?.id }
      .sorted { $0.createdAt > $1.createdAt }
  }

  private func generateTopicQuiz() async {
    let trimmed = topic.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.count >= 3 else {
      appState.lastError = "Enter a topic (e.g. \"French Revolution\")."
      return
    }
    await appState.generateDeck(
      title: trimmed,
      content: "Topic to learn: \(trimmed)\nPreferred lesson length: \(selectedLength)",
      source: "topic"
    )
    showNewTopic = false
  }

  private func startReadingTimer() {
    readingTask?.cancel()
    readingTask = Task {
      let tickSeconds = 15
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(tickSeconds))
        guard !Task.isCancelled else { break }
        await MainActor.run {
          appState.addStudyReadingSeconds(tickSeconds)
        }
      }
    }
  }

  private func stopReadingTimer() {
    readingTask?.cancel()
    readingTask = nil
  }
}
