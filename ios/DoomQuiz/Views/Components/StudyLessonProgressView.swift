import SwiftUI

struct StudyLessonProgressView: View {
  @EnvironmentObject private var appState: AppState
  let deckTitle: String
  let paragraphs: [StudyParagraph]
  let masteredIds: Set<String>
  let isGeneratingQuestions: Bool
  var expectedSectionCount: Int = LessonContentAmount.sectionCount
  var isReadingSessionActive: Bool = true
  var showQuizNotReadyHint: Bool = false
  let onTakeQuiz: (String) -> Void

  private var masteredCount: Int { masteredIds.count }
  private var displaySectionCount: Int { expectedSectionCount }

  private var allMastered: Bool {
    masteredCount >= expectedSectionCount && paragraphs.count >= expectedSectionCount
  }

  private var currentParagraph: StudyParagraph? {
    paragraphs.first { !masteredIds.contains($0.id) }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      segmentedProgressBar

      if allMastered {
        masteredCompleteCard
      } else if let current = currentParagraph {
        paragraphCard(current)
          .task(id: "\(current.id)-\(isReadingSessionActive)") {
            guard isReadingSessionActive else { return }
            await trackReadingTime()
          }
        sectionQuizButton(for: current)
        if showQuizNotReadyHint {
          quizNotReadyCard
        }
      }

      if masteredCount > 0, !allMastered {
        masteredList
      }
    }
  }

  private var segmentedProgressBar: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Progress")
          .font(.system(size: 11, weight: .heavy, design: .rounded))
          .foregroundStyle(QuizletTheme.textMuted)
          .textCase(.uppercase)
        Spacer()
        Text("\(masteredCount)/\(displaySectionCount)")
          .font(.system(size: 11, weight: .bold, design: .rounded))
          .foregroundStyle(QuizletTheme.primary)
      }

      HStack(spacing: 5) {
        ForEach(0..<expectedSectionCount, id: \.self) { index in
          Capsule()
            .fill(segmentColor(at: index))
            .frame(height: 8)
            .overlay {
              if let paragraph = paragraph(at: index), masteredIds.contains(paragraph.id) {
                Image(systemName: "checkmark")
                  .font(.system(size: 6, weight: .black))
                  .foregroundStyle(.white)
              }
            }
        }
      }
    }
    .animation(.spring(response: 0.35), value: masteredCount)
  }

  private func paragraph(at index: Int) -> StudyParagraph? {
    guard paragraphs.indices.contains(index) else { return nil }
    return paragraphs[index]
  }

  private func segmentColor(at index: Int) -> Color {
    guard let paragraph = paragraph(at: index) else { return QuizletTheme.border }
    if masteredIds.contains(paragraph.id) { return QuizletTheme.correct }
    if paragraph.id == currentParagraph?.id { return QuizletTheme.primary }
    return QuizletTheme.border
  }

  private func paragraphCard(_ paragraph: StudyParagraph) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(paragraph.body)
        .font(.system(size: 18, weight: .regular, design: .rounded))
        .foregroundStyle(QuizletTheme.text)
        .lineSpacing(7)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      LinearGradient(
        colors: [QuizletTheme.card, QuizletTheme.primarySoft.opacity(0.25)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(QuizletTheme.primary.opacity(0.35), lineWidth: 1.5)
    )
    .themeCardShadow(elevated: true)
  }

  private func sectionQuizButton(for paragraph: StudyParagraph) -> some View {
    Button {
      onTakeQuiz(paragraph.id)
    } label: {
      Label("Take section quiz", systemImage: "checkmark.circle.fill")
        .font(.system(size: 16, weight: .heavy, design: .rounded))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
    .buttonStyle(.borderedProminent)
    .tint(QuizletTheme.primary)
  }

  private var quizNotReadyCard: some View {
    HStack(spacing: 10) {
      Image(systemName: "battery.25")
        .font(.body.weight(.semibold))
        .foregroundStyle(QuizletTheme.primary)
      Text("Low battery mode: keep reading this section first. Quiz will appear soon.")
        .font(.footnote.weight(.semibold))
        .foregroundStyle(QuizletTheme.textMuted)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(QuizletTheme.primarySoft)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .themeCardShadow()
  }

  private var masteredCompleteCard: some View {
    HStack(spacing: 12) {
      Image(systemName: "star.circle.fill")
        .font(.title2)
        .foregroundStyle(QuizletTheme.correct)
      VStack(alignment: .leading, spacing: 4) {
        Text("All sections passed")
          .font(.headline.weight(.heavy))
          .foregroundStyle(QuizletTheme.text)
        Text("Pick a new topic below, or review any section when locked.")
          .font(.footnote)
          .foregroundStyle(QuizletTheme.textMuted)
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(QuizletTheme.correct.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
  }

  private var masteredList: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Done")
        .font(.caption2.weight(.bold))
        .foregroundStyle(QuizletTheme.textMuted)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          ForEach(paragraphs.filter { masteredIds.contains($0.id) }) { paragraph in
            HStack(spacing: 4) {
              Image(systemName: "checkmark")
                .font(.system(size: 8, weight: .bold))
              Text(shortLabel(paragraph.label))
                .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(QuizletTheme.correct)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(QuizletTheme.correct.opacity(0.1))
            .clipShape(Capsule())
          }
        }
      }
    }
  }

  /// "World War 2 (Causes)" → "Causes" when it repeats the deck title.
  private func shortLabel(_ label: String) -> String {
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

  /// Count time on the reading card; displayed minutes = seconds ÷ 90 (real minutes / 1.5).
  private func trackReadingTime() async {
    let tickSeconds = 15
    while !Task.isCancelled {
      try? await Task.sleep(for: .seconds(tickSeconds))
      guard !Task.isCancelled else { break }
      appState.addStudyReadingSeconds(tickSeconds)
    }
  }
}
