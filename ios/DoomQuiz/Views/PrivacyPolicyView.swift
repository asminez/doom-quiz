import SwiftUI

struct PrivacyPolicyView: View {
  @Environment(\.dismiss) private var dismiss

  private let lastUpdated = "July 2026"
  private let contactEmail = "privacy@doomquiz.app"

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header

        section(
          title: "The short version",
          body:
            "DoomQuiz is built to be private. Your learning happens on your device. We don't require an account, we don't show ads, and we never sell your data. We collect anonymous usage data to improve the app, which you can turn off any time in Settings."
        )

        section(
          title: "Data stored on your device",
          body:
            "Your decks, lessons, quiz progress, scroll bank, daily limits, and preferences are stored locally on your iPhone. This information stays on your device and is removed when you clear your history or delete the app."
        )

        section(
          title: "Screen Time & blocked apps",
          body:
            "When you choose apps to block, DoomQuiz uses Apple's Screen Time (Family Controls) framework. Your app selections are handled by iOS on your device. DoomQuiz cannot see the names of the specific apps you pick, and this selection is never sent to our servers."
        )

        section(
          title: "Learning content & AI",
          body:
            "When you create a lesson, the topic you type or the text extracted from a syllabus or PDF you upload is sent securely to our backend, which forwards it to an AI provider to generate your lesson and quiz. This text is used only to create your study content. We don't attach your name or identity to it. Please avoid entering sensitive personal information into topics or uploads."
        )

        section(
          title: "Anonymous usage analytics",
          body:
            "To understand how people use DoomQuiz (for example, which features are used and where people get stuck), we collect anonymous, aggregated usage events such as screens viewed, lessons generated, and quizzes completed. This data is tied only to a random, per-install identifier. We do NOT collect your name, email, phone number, precise location, contacts, or any advertising identifier (IDFA), and we do not track you across other apps or websites. You can turn analytics off under Settings > Privacy."
        )

        section(
          title: "What we don't do",
          body:
            "No accounts or logins. No advertising or ad networks. No third-party ad tracking. No selling or renting of your data. No cross-app tracking."
        )

        section(
          title: "Children",
          body:
            "DoomQuiz is not directed to children under 13, and we do not knowingly collect personal information from children."
        )

        section(
          title: "Your choices",
          body:
            "You can turn off anonymous analytics in Settings, clear all your on-device data with \u{201C}Clear history\u{201D}, or delete the app to remove everything stored locally."
        )

        section(
          title: "Contact",
          body:
            "Questions about privacy? Email us at \(contactEmail)."
        )

        Text("Last updated: \(lastUpdated)")
          .font(.system(size: 13))
          .foregroundStyle(UnrotTheme.textMuted)
          .padding(.top, 4)
      }
      .padding(.horizontal, 20)
      .padding(.top, 8)
      .padding(.bottom, 40)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .background(UnrotTheme.bg)
    .navigationTitle("Privacy Policy")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Privacy Policy")
        .font(.system(size: 30, weight: .black, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
      Text("How DoomQuiz handles your data.")
        .font(.system(size: 16))
        .foregroundStyle(UnrotTheme.textMuted)
    }
  }

  private func section(title: String, body: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.system(size: 18, weight: .heavy, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
      Text(body)
        .font(.system(size: 15))
        .foregroundStyle(UnrotTheme.text.opacity(0.85))
        .lineSpacing(4)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
