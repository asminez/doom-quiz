import SwiftUI

struct LearningNowCard: View {
  let deck: StudyDeck?
  let locked: Bool
  var onOpenStudy: () -> Void
  var onTakeQuiz: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Button(action: onOpenStudy) {
        HStack(spacing: 12) {
          ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .fill(QuizletTheme.primarySoft)
              .frame(width: 48, height: 48)
            Image(systemName: deck == nil ? "plus" : "book.fill")
              .font(.title3.weight(.semibold))
              .foregroundStyle(QuizletTheme.primary)
          }

          VStack(alignment: .leading, spacing: 4) {
            Text(deck == nil ? "Start learning" : "Learning now")
              .font(.caption.weight(.bold))
              .foregroundStyle(UnrotTheme.textMuted)
              .textCase(.uppercase)
            Text(deck?.title ?? "Pick a topic")
              .font(.headline.weight(.bold))
              .foregroundStyle(UnrotTheme.text)
              .lineLimit(2)
            Text(subtitle)
              .font(.caption)
              .foregroundStyle(locked ? UnrotTheme.accent : UnrotTheme.textMuted)
              .lineLimit(2)
          }

          Spacer()
          Image(systemName: "chevron.right")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(UnrotTheme.textMuted)
        }
      }
      .buttonStyle(.plain)

      if locked, let onTakeQuiz, deck != nil {
        Button(action: onTakeQuiz) {
          HStack(spacing: 8) {
            Image(systemName: "lock.open.fill")
            Text("Take quiz")
              .font(.subheadline.weight(.heavy))
            Spacer()
          }
          .foregroundStyle(.white)
          .padding(.vertical, 12)
          .padding(.horizontal, 14)
          .background(
            LinearGradient(
              colors: [UnrotTheme.accent, UnrotTheme.accent.opacity(0.85)],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(14)
    .background(UnrotTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(deck == nil ? QuizletTheme.primary.opacity(0.5) : (locked ? UnrotTheme.accent : QuizletTheme.primary.opacity(0.35)), lineWidth: 1.5)
    )
    .themeCardShadow(elevated: true)
  }

  private var subtitle: String {
    guard let deck else { return "Tap to create your quiz" }
    if locked {
      return "\(deck.questions.count) questions · quiz to unlock"
    }
    return "\(deck.questions.count) gate questions · \(deck.points.count) cards"
  }
}
