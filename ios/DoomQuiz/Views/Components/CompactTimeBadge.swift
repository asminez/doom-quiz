import SwiftUI

struct CompactTimeBadge: View {
  let remaining: Int
  let locked: Bool

  var body: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(locked ? UnrotTheme.danger : QuizletTheme.correct)
        .frame(width: 8, height: 8)
      Text(locked ? "Locked · 0m" : "\(remaining)m left")
        .font(.subheadline.weight(.bold))
        .foregroundStyle(locked ? UnrotTheme.danger : QuizletTheme.text)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(QuizletTheme.primarySoft)
    .clipShape(Capsule())
  }
}
