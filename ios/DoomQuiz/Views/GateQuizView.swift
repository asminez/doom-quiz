import SwiftUI

struct GateQuizView: View {
  @EnvironmentObject private var appState: AppState
  @Environment(\.dismiss) private var dismiss

  @State private var sessionQuestions: [QuizQuestion] = []
  @State private var index = 0
  @State private var selected: Int?
  @State private var correctCount = 0
  @State private var finished = false
  @State private var rewardMinutes = 0
  @State private var claimedTotal = 0
  @State private var sectionAdvanced = false
  @State private var sectionLabel = ""

  private var isSectionQuiz: Bool { appState.activeSectionParagraphId != nil }

  private var sourceQuestions: [QuizQuestion] {
    if let paragraphId = appState.activeSectionParagraphId,
      let deck = appState.activeDeck
    {
      return deck.questions(for: paragraphId)
    }
    return appState.activeDeck?.questions.filter { $0.paragraphId == nil } ?? []
  }

  var body: some View {
    ZStack {
      QuizletTheme.bg.ignoresSafeArea()
        .prefersHiddenStatusBar()
      if sessionQuestions.isEmpty { emptyState }
      else if finished { resultState }
      else { quizState }
    }
    .onAppear { beginSession() }
    .onChange(of: finished) { _, isFinished in
      guard isFinished else { return }
      if sectionAdvanced || rewardMinutes > 0 {
        HapticFeedback.success()
      } else if correctCount < sessionQuestions.count {
        HapticFeedback.warning()
      }
    }
  }

  private var emptyState: some View {
    VStack(spacing: 16) {
      Text("No quiz loaded").font(.title2.weight(.heavy))
      Button("Close") { close() }.buttonStyle(.borderedProminent).tint(QuizletTheme.primary)
    }
  }

  private var quizState: some View {
    let q = sessionQuestions[index]
    return VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text(isSectionQuiz ? "Section quiz" : "Unlock quiz")
          .font(.subheadline.weight(.bold))
          .foregroundStyle(QuizletTheme.textMuted)
        Spacer()
        Text("\(index + 1) / \(sessionQuestions.count)")
          .font(.subheadline.weight(.heavy))
          .foregroundStyle(QuizletTheme.primary)
      }.padding(.horizontal, 20).padding(.top, 20)

      if isSectionQuiz, !sectionLabel.isEmpty {
        Text(sectionLabel)
          .font(.caption.weight(.bold))
          .foregroundStyle(QuizletTheme.primary)
          .padding(.horizontal, 20)
          .padding(.top, 8)
      }

      Text(q.prompt).font(.title2.weight(.heavy)).foregroundStyle(QuizletTheme.text).padding(20)

      ScrollView {
        VStack(spacing: 10) {
          ForEach(Array(q.choices.enumerated()), id: \.offset) { i, choice in
            quizOption(choice: choice, index: i, question: q)
          }
        }.padding(.horizontal, 20)
      }

      if selected != nil {
        Button(index < sessionQuestions.count - 1 ? "Next" : "See results") {
          HapticFeedback.medium()
          advance()
        }
          .buttonStyle(.borderedProminent).tint(QuizletTheme.primary).padding(20)
      }

      Text(isSectionQuiz ? RewardCalculator.sectionRewardHint() : RewardCalculator.rewardHint(total: sessionQuestions.count))
        .font(.caption).foregroundStyle(QuizletTheme.textMuted).frame(maxWidth: .infinity).padding(.bottom, 12)
    }
  }

  @ViewBuilder
  private func quizOption(choice: String, index i: Int, question q: QuizQuestion) -> some View {
    let result: OptionResult = {
      guard let selected else { return .neutral }
      if i == q.correctIndex { return .correct }
      if i == selected { return .wrong }
      return .neutral
    }()

    Button {
      guard selected == nil else { return }
      HapticFeedback.selection()
      selected = i
      if i == q.correctIndex {
        correctCount += 1
        HapticFeedback.light()
      } else {
        HapticFeedback.error()
      }
    } label: {
      Text(choice).font(.body.weight(.semibold)).foregroundStyle(QuizletTheme.text)
        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 16).padding(.horizontal, 18)
        .background(bg(for: result, selected: selected == i))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(border(for: result, selected: selected == i), lineWidth: 2))
    }.buttonStyle(.plain).disabled(selected != nil)
  }

  private var resultState: some View {
    VStack(spacing: 20) {
      if isSectionQuiz {
        sectionResultContent
      } else if rewardMinutes > 0 {
        gateRewardContent
      } else {
        gateRetryContent
      }

      resultButtons
    }
    .padding(24)
  }

  @ViewBuilder
  private var sectionResultContent: some View {
    if sectionAdvanced {
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 64))
        .foregroundStyle(QuizletTheme.correct)
      Text("Section mastered!")
        .font(.title.weight(.heavy))
        .foregroundStyle(QuizletTheme.text)
      if rewardMinutes > 0 {
        Text(RewardCalculator.depositLabel(delta: rewardMinutes, claimedTotal: claimedTotal))
          .font(.body.weight(.semibold))
          .foregroundStyle(QuizletTheme.primary)
      }
      Text("Next section unlocked. Keep going!")
        .font(.subheadline)
        .foregroundStyle(QuizletTheme.textMuted)
        .multilineTextAlignment(.center)
    } else {
      Text("\(correctCount)/\(sessionQuestions.count)")
        .font(.system(size: 56, weight: .black, design: .rounded))
        .foregroundStyle(QuizletTheme.primary)
      Text(RewardCalculator.sectionLabel(forCorrect: correctCount, total: sessionQuestions.count))
        .font(.body)
        .multilineTextAlignment(.center)
        .foregroundStyle(QuizletTheme.text)
        .padding(.horizontal, 24)
      Text("Review the section reading, then come back for another attempt.")
        .font(.footnote)
        .foregroundStyle(QuizletTheme.textMuted)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
    }
  }

  @ViewBuilder
  private var gateRewardContent: some View {
    Image(systemName: "checkmark.circle.fill")
      .font(.system(size: 64))
      .foregroundStyle(QuizletTheme.correct)
    Text(RewardCalculator.depositLabel(delta: rewardMinutes, claimedTotal: claimedTotal))
      .font(.title.weight(.heavy))
      .foregroundStyle(QuizletTheme.text)
    Text("Added to your scroll bank. Shields are off until time runs out.")
      .font(.subheadline)
      .foregroundStyle(QuizletTheme.textMuted)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 24)
  }

  @ViewBuilder
  private var gateRetryContent: some View {
    Text("\(correctCount)/\(sessionQuestions.count)")
      .font(.system(size: 56, weight: .black, design: .rounded))
      .foregroundStyle(QuizletTheme.primary)
    Text(
      rewardMinutes == 0 && appState.snapshot.gateRewardClaimedMinutes > 0
        ? "You already earned \(appState.snapshot.gateRewardClaimedMinutes)m this lock. Score higher to add more."
        : RewardCalculator.label(forCorrect: correctCount, total: sessionQuestions.count)
    )
      .font(.body)
      .multilineTextAlignment(.center)
      .foregroundStyle(QuizletTheme.text)
      .padding(.horizontal, 24)
  }

  @ViewBuilder
  private var resultButtons: some View {
    if isSectionQuiz {
      if sectionAdvanced {
        Button {
          HapticFeedback.light()
          close()
        } label: {
          Text("Continue studying")
        }
          .buttonStyle(.borderedProminent)
          .tint(QuizletTheme.primary)
      } else {
        VStack(spacing: 12) {
          Button {
            HapticFeedback.medium()
            close(openStudy: true)
          } label: {
            Text("Study section")
          }
          .buttonStyle(.borderedProminent)
          .tint(QuizletTheme.primary)
          Button {
            HapticFeedback.light()
            beginSession()
          } label: {
            Text("Try again")
          }
            .buttonStyle(.bordered)
            .tint(QuizletTheme.primary)
        }
        .frame(maxWidth: .infinity)
      }
    } else if rewardMinutes > 0 {
      Button {
        HapticFeedback.success()
        close()
      } label: {
        Text("Start scrolling")
      }
      .buttonStyle(.borderedProminent)
      .tint(QuizletTheme.primary)
    } else {
      VStack(spacing: 12) {
        if appState.activeDeck?.isAIGenerated == true {
          Button {
            HapticFeedback.medium()
            close(openStudy: true)
          } label: {
            Text("Study lesson")
          }
          .buttonStyle(.borderedProminent)
          .tint(QuizletTheme.primary)
          Button {
            HapticFeedback.light()
            beginSession()
          } label: {
            Text("Try again")
          }
          .buttonStyle(.bordered)
          .tint(QuizletTheme.primary)
        } else {
          Button {
            HapticFeedback.light()
            beginSession()
          } label: {
            Text("Try again")
          }
          .buttonStyle(.borderedProminent)
          .tint(QuizletTheme.primary)
        }
      }
      .frame(maxWidth: .infinity)
    }
  }

  private func beginSession() {
    HapticFeedback.light()
    if let paragraphId = appState.activeSectionParagraphId,
      let deck = appState.activeDeck,
      let paragraph = deck.paragraphs.first(where: { $0.id == paragraphId })
    {
      sectionLabel = paragraph.label
    } else {
      sectionLabel = ""
    }

    sessionQuestions = QuizSession.prepare(sourceQuestions)
    index = 0
    selected = nil
    correctCount = 0
    finished = false
    rewardMinutes = 0
    claimedTotal = 0
    sectionAdvanced = false
  }

  private func advance() {
    if index < sessionQuestions.count - 1 {
      HapticFeedback.light()
      index += 1
      selected = nil
      return
    }

    if let paragraphId = appState.activeSectionParagraphId {
      let result = appState.applySectionQuizResult(
        correct: correctCount,
        total: sessionQuestions.count,
        paragraphId: paragraphId
      )
      sectionAdvanced = result.advanced
      rewardMinutes = result.rewardMinutes
      claimedTotal = result.claimedTotal
    } else {
      rewardMinutes = appState.applyQuizReward(correct: correctCount, total: sessionQuestions.count)
      claimedTotal = appState.snapshot.gateRewardClaimedMinutes
    }
    finished = true
  }

  private func close(openStudy: Bool = false) {
    appState.closeQuiz(openStudyTab: openStudy)
    dismiss()
  }

  private enum OptionResult { case neutral, correct, wrong }

  private func border(for result: OptionResult, selected: Bool) -> Color {
    switch result {
    case .correct: return QuizletTheme.correct
    case .wrong: return QuizletTheme.wrong
    case .neutral: return selected ? QuizletTheme.primary : QuizletTheme.border
    }
  }

  private func bg(for result: OptionResult, selected: Bool) -> Color {
    switch result {
    case .correct: return QuizletTheme.correct.opacity(0.12)
    case .wrong: return QuizletTheme.wrong.opacity(0.12)
    case .neutral: return selected ? QuizletTheme.primarySoft : QuizletTheme.card
    }
  }
}
