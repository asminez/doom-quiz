import SwiftUI

struct ManualDeckBuilderView: View {
  @EnvironmentObject private var appState: AppState
  @Environment(\.dismiss) private var dismiss

  @State private var title = ""
  @State private var cards: [DraftCard] = [DraftCard(), DraftCard(), DraftCard()]
  @State private var questions: [DraftQuestion] = (0..<6).map { _ in DraftQuestion() }
  @State private var error: String?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          StudyInputField(placeholder: "Quiz title (e.g. Bio Chapter 3)", text: $title)

          Text("Flashcards (optional review)")
            .font(.subheadline.weight(.heavy))
            .foregroundStyle(QuizletTheme.text)
          ForEach($cards) { $card in
            cardRow($card)
          }
          Button {
            if cards.count < 8 { cards.append(DraftCard()) }
          } label: {
            Label("Add flashcard", systemImage: "plus.circle.fill")
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(QuizletTheme.primary)
          }
          .buttonStyle(.plain)

          Text("Unlock quiz · 6 questions")
            .font(.subheadline.weight(.heavy))
            .foregroundStyle(QuizletTheme.text)
            .padding(.top, 4)
          ForEach(Array(questions.enumerated()), id: \.element.id) { index, _ in
            questionBlock(index: index)
          }

          if let error {
            Text(error).font(.footnote).foregroundStyle(QuizletTheme.wrong)
          }

          Button(action: saveDeck) {
            Text("Save quiz")
              .fontWeight(.heavy)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
          }
          .buttonStyle(.borderedProminent)
          .tint(QuizletTheme.primary)
        }
        .padding(20)
      }
      .background(QuizletTheme.bg)
      .navigationTitle("Create quiz")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
    }
  }

  private func cardRow(_ card: Binding<DraftCard>) -> some View {
    VStack(spacing: 8) {
      StudyInputField(placeholder: "Term", text: card.term)
      StudyInputField(placeholder: "Definition", text: card.definition, axis: .vertical, lineLimit: 2...4)
    }
    .padding(12)
    .background(QuizletTheme.bg)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  private func questionBlock(index: Int) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Question \(index + 1)")
        .font(.caption.weight(.bold))
        .foregroundStyle(QuizletTheme.textMuted)
      StudyInputField(
        placeholder: "Question prompt",
        text: $questions[index].prompt,
        axis: .vertical,
        lineLimit: 2...4
      )
      ForEach(0..<4, id: \.self) { ci in
        HStack(spacing: 10) {
          Button {
            questions[index].correctIndex = ci
          } label: {
            Image(systemName: questions[index].correctIndex == ci ? "checkmark.circle.fill" : "circle")
              .foregroundStyle(questions[index].correctIndex == ci ? QuizletTheme.correct : QuizletTheme.textMuted)
          }
          .buttonStyle(.plain)
          StudyInputField(placeholder: "Choice \(ci + 1)", text: $questions[index].choices[ci])
        }
      }
    }
    .padding(12)
    .background(QuizletTheme.bg)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  private func saveDeck() {
    error = nil
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmedTitle.count >= 2 else {
      error = "Add a quiz title."
      return
    }

    let builtQuestions: [QuizQuestion] = questions.enumerated().compactMap { index, q in
      let prompt = q.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
      let choices = q.choices.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      guard !prompt.isEmpty, choices.allSatisfy({ !$0.isEmpty }) else { return nil }
      return QuizQuestion(
        id: "manual-q\(index)-\(Int(Date().timeIntervalSince1970))",
        prompt: prompt,
        choices: choices,
        correctIndex: min(3, max(0, q.correctIndex))
      )
    }

    guard builtQuestions.count >= 6 else {
      error = "Fill in all 6 questions with 4 choices each."
      return
    }

    let id = "deck-manual-\(Int(Date().timeIntervalSince1970))"
    let points = cards.enumerated().compactMap { index, c -> MemorizePoint? in
      let term = c.term.trimmingCharacters(in: .whitespacesAndNewlines)
      let def = c.definition.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !term.isEmpty, !def.isEmpty else { return nil }
      return MemorizePoint(id: "\(id)-p\(index)", term: term, definition: def)
    }

    let deck = StudyDeck(
      id: id,
      title: trimmedTitle,
      source: "manual",
      points: points,
      questions: Array(builtQuestions.prefix(6)),
      createdAt: Date()
    )
    appState.upsertDeck(deck)
    dismiss()
  }
}

private struct DraftCard: Identifiable {
  let id = UUID()
  var term = ""
  var definition = ""
}

private struct DraftQuestion: Identifiable {
  let id = UUID()
  var prompt = ""
  var choices = ["", "", "", ""]
  var correctIndex = 0
}
