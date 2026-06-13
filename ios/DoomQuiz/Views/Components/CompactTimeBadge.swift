import SwiftUI

struct CompactTimeBadge: View {
  let minutesReadToday: Int

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: "book.fill")
        .font(.caption2.weight(.bold))
        .foregroundStyle(QuizletTheme.primary)
      Text("\(minutesReadToday)m")
        .font(.system(size: 15, weight: .heavy, design: .rounded))
        .foregroundStyle(QuizletTheme.text)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 9)
    .background(QuizletTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(QuizletTheme.border.opacity(0.5), lineWidth: 1)
    )
    .themeCardShadow()
  }
}
