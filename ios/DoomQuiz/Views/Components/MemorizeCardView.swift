import SwiftUI

struct MemorizeCardView: View {
  let point: MemorizePoint
  let index: Int
  @State private var flipped = false

  var body: some View {
    Button {
      withAnimation(.spring(response: 0.35)) { flipped.toggle() }
    } label: {
      VStack(alignment: .leading, spacing: 8) {
        Text("\(index + 1)").font(.caption.weight(.heavy)).foregroundStyle(QuizletTheme.primary)
        Text(flipped ? "Definition" : "Term").font(.caption.weight(.semibold)).foregroundStyle(QuizletTheme.textMuted).textCase(.uppercase)
        Text(flipped ? point.definition : point.term).font(.title3.weight(.bold)).foregroundStyle(QuizletTheme.text).multilineTextAlignment(.leading)
        Text("Tap to flip").font(.caption).foregroundStyle(QuizletTheme.textMuted).padding(.top, 8)
      }
      .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
      .padding(20)
      .background(QuizletTheme.card)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(QuizletTheme.border, lineWidth: 1))
    }
    .buttonStyle(.plain)
  }
}
