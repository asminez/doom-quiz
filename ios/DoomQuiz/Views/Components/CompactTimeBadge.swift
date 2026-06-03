import SwiftUI

struct CompactTimeBadge: View {
  let minutesReadToday: Int

  var body: some View {
    HStack(spacing: 6) {
      Circle().fill(QuizletTheme.correct).frame(width: 8, height: 8)
      Text("\(minutesReadToday)m read today")
        .font(.subheadline.weight(.bold))
        .foregroundStyle(QuizletTheme.text)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(QuizletTheme.primarySoft)
    .clipShape(Capsule())
  }
}
