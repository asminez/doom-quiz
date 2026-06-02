import SwiftUI

struct PremiumSheetView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        Text("DoomQuiz Premium")
          .font(.title.weight(.heavy))
        Text("Free: learn any topic with AI gate quizzes.")
          .foregroundStyle(QuizletTheme.textMuted)
        Text("Premium: upload syllabus or PDFs and auto-build quizzes from your class material.")
          .foregroundStyle(QuizletTheme.text)
        Spacer()
        Text("StoreKit coming soon")
          .font(.footnote)
          .foregroundStyle(QuizletTheme.textMuted)
          .frame(maxWidth: .infinity)
      }
      .padding(24)
      .navigationTitle("Premium")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium])
  }
}
