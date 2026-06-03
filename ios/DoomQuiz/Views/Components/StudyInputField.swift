import SwiftUI

struct StudyInputField: View {
  let placeholder: String
  @Binding var text: String
  var axis: Axis = .horizontal
  var lineLimit: ClosedRange<Int>? = nil

  var body: some View {
  Group {
    if let lineLimit {
      TextField(placeholder, text: $text, axis: axis)
        .lineLimit(lineLimit)
    } else {
      TextField(placeholder, text: $text, axis: axis)
    }
  }
  .font(.body)
  .foregroundStyle(QuizletTheme.text)
  .tint(QuizletTheme.primary)
  .padding(14)
  .background(QuizletTheme.inputBg)
  .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  .overlay(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
      .stroke(QuizletTheme.border, lineWidth: 1)
  )
  }
}

struct StudySectionCard<Content: View>: View {
  let icon: String
  let title: String
  let subtitle: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .font(.title3.weight(.semibold))
          .foregroundStyle(QuizletTheme.primary)
          .frame(width: 36, height: 36)
          .background(QuizletTheme.primarySoft)
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.headline.weight(.heavy))
            .foregroundStyle(QuizletTheme.text)
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(QuizletTheme.textMuted)
        }
      }
      content
    }
    .padding(16)
    .background(QuizletTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(QuizletTheme.border, lineWidth: 1)
    )
    .themeCardShadow()
  }
}
