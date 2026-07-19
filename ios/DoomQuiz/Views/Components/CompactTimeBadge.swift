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

/// Topic emoji from the AI lesson, or a fallback SF Symbol.
struct DeckTopicIcon: View {
  let deck: StudyDeck?
  var symbolSize: CGFloat = 17
  var emojiSize: CGFloat = 22

  var body: some View {
    Group {
      if deck == nil {
        Image(systemName: "plus")
          .font(.system(size: symbolSize, weight: .semibold))
          .foregroundStyle(QuizletTheme.primary)
      } else if let emoji = deck?.topicEmoji, !emoji.isEmpty {
        Text(emoji)
          .font(.system(size: emojiSize))
      } else if deck?.isAIGenerated == true {
        Image(systemName: "book.fill")
          .font(.system(size: symbolSize, weight: .semibold))
          .foregroundStyle(QuizletTheme.primary)
      } else {
        Image(systemName: "square.stack.fill")
          .font(.system(size: symbolSize, weight: .semibold))
          .foregroundStyle(QuizletTheme.primary)
      }
    }
  }
}
