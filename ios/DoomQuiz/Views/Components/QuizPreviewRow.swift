import SwiftUI

struct QuizPreviewRow: View {
  let question: QuizQuestion
  let index: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Q\(index + 1)")
        .font(.caption.weight(.heavy))
        .foregroundStyle(QuizletTheme.primary)
      Text(question.prompt)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(QuizletTheme.text)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(QuizletTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(QuizletTheme.border, lineWidth: 1)
    )
  }
}
