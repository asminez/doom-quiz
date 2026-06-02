import SwiftUI

struct GateQuizView: View {
  @EnvironmentObject private var appState: AppState
  @Environment(\.dismiss) private var dismiss

  @State private var index = 0
  @State private var selected: Int?
  @State private var correctCount = 0
  @State private var finished = false
  @State private var rewardMinutes = 0

  private var questions: [QuizQuestion] { appState.activeDeck?.questions ?? [] }

  var body: some View {
    ZStack {
      QuizletTheme.bg.ignoresSafeArea()
      if questions.isEmpty { emptyState }
      else if finished { resultState }
      else { quizState }
    }
  }

  private var emptyState: some View {
    VStack(spacing: 16) {
      Text("No quiz loaded").font(.title2.weight(.heavy))
      Button("Close") { close() }.buttonStyle(.borderedProminent).tint(QuizletTheme.primary)
    }
  }

  private var quizState: some View {
    let q = questions[index]
    return VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("Gate quiz").font(.subheadline.weight(.bold)).foregroundStyle(QuizletTheme.textMuted)
        Spacer()
        Text("\(index + 1) / \(questions.count)").font(.subheadline.weight(.heavy)).foregroundStyle(QuizletTheme.primary)
      }.padding(.horizontal, 20).padding(.top, 20)

      Text(q.prompt).font(.title2.weight(.heavy)).foregroundStyle(QuizletTheme.text).padding(20)

      ScrollView {
        VStack(spacing: 10) {
          ForEach(Array(q.choices.enumerated()), id: \.offset) { i, choice in
            quizOption(choice: choice, index: i, question: q)
          }
        }.padding(.horizontal, 20)
      }

      if selected != nil {
        Button(index < questions.count - 1 ? "Next" : "See results") { advance() }
          .buttonStyle(.borderedProminent).tint(QuizletTheme.primary).padding(20)
      }

      Text("5/5 → +10 min · 4/5 → +5 · 3/5 → +2 · below 3 → none")
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
      selected = i
      if i == q.correctIndex { correctCount += 1 }
    } label: {
      Text(choice).font(.body.weight(.semibold)).foregroundStyle(QuizletTheme.text)
        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 16).padding(.horizontal, 18)
        .background(bg(for: result, selected: selected == i))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(border(for: result, selected: selected == i), lineWidth: 2))
    }.buttonStyle(.plain).disabled(selected != nil)
  }

  private var resultState: some View {
    VStack(spacing: 16) {
      Text("\(correctCount)/\(questions.count)").font(.system(size: 56, weight: .black, design: .rounded)).foregroundStyle(QuizletTheme.primary)
      Text(RewardCalculator.label(forCorrect: correctCount)).font(.body).multilineTextAlignment(.center).foregroundStyle(QuizletTheme.text).padding(.horizontal, 24)
      if rewardMinutes > 0 {
        Button("Done — apps unlocked") {
          close()
        }.buttonStyle(.borderedProminent).tint(QuizletTheme.primary)
      } else {
        Button("Back to Study") { close() }.buttonStyle(.bordered)
      }
    }.padding(24)
  }

  private func advance() {
    if index < questions.count - 1 {
      index += 1
      selected = nil
      return
    }
    rewardMinutes = appState.applyQuizReward(correct: correctCount)
    finished = true
  }

  private func close() {
    appState.showGateQuiz = false
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
