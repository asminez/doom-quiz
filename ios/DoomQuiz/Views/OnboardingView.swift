import SwiftUI
import UIKit

struct OnboardingView: View {
  @EnvironmentObject private var appState: AppState
  var onFinished: (() -> Void)?
  @State private var step = 0
  @State private var name = ""
  @State private var selectedBudget = 45
  @State private var revealedIntroCount = 0
  @State private var revealedEarnCount = 0
  @State private var revealedAchievementCount = 0
  @State private var revealedTestimonialCount = 0
  @State private var selectedHours = "2 to 4 hours"
  @State private var isShowingIdentityChoices = false
  @State private var isShowingPossibilityChoices = false
  @State private var selectedIdentityReply: String?
  @State private var selectedPossibilityReply: String?
  @State private var showTestimonialsContinue = false
  @State private var animationFinished = false

  private let identityChoices = [
    "yes that's def me",
    "how do you know",
    "lol way too real",
  ]

  private let possibilityChoices = [
    "is that possible?",
    "that's possible?",
  ]

  private let hourChoices = [
    "Less than 2 hours",
    "2 to 4 hours",
    "4 to 6 hours",
    "6 to 8 hours",
  ]

  private let testimonials: [OnboardingTestimonial] = [
    .init(
      quote: "I learnt Roman history while minimizing brain rot.",
      author: "Maya, 22"
    ),
    .init(
      quote: "I learnt about dropshipping while minimizing scrolling.",
      author: "James, 19"
    ),
    .init(
      quote: "I studied 100s of new French words to gain a few hours of scrolling 😭",
      author: "Lena, 21"
    ),
  ]

  /// Pause between chat bubbles (ms) — calmer than default typing pace.
  private let chatMessageDelayMs = 1_250
  private let chatSectionPauseMs = 850
  private let testimonialDelayMs = 1_100

  private let researchPoints: [OnboardingResearchPoint] = [
    .init(
      icon: "brain.head.profile",
      text: "People often learn more when they're required to — not just when they \"feel like it.\""
    ),
    .init(
      icon: "hand.raised.fill",
      text: "Even a small barrier to a bad habit can noticeably reduce how often you do it."
    ),
    .init(
      icon: "heart.fill",
      text: "Studies suggest people find others with more knowledge more attractive."
    ),
  ]

  private var introScript: [ChatLine] {
    [
      .bot("Hey \(displayName), we try to quit scrolling,"),
      .bot("need to open social media for some necessary work,"),
      .bot("end up scrolling."),
      .bot("is this you?"),
    ]
  }

  private var earnScript: [ChatLine] {
    [
      .bot("what if you had to earn the time for your social media?"),
      .bot("what if you could replace the time you spend on social media by learning?"),
    ]
  }

  private var achievementScript: [ChatLine] {
    [.bot("that's what many people have achieved through QuizScroll.", emphasized: true)]
  }

  var body: some View {
    ZStack {
      backgroundColor.ignoresSafeArea()

      if step == 6 {
        fullScreenAnimationStep
          .transition(.opacity)
      } else {
        VStack(alignment: .leading, spacing: 16) {
          if step > 0 {
            Button {
              Haptics.light()
              withAnimation(.easeInOut(duration: 0.25)) {
                step = max(0, step - 1)
              }
            } label: {
              Image(systemName: "arrow.left")
                .font(.title3.weight(.bold))
                .foregroundStyle(UnrotTheme.accent)
            }
            .buttonStyle(.plain)
          }

          Group {
            if step == 0 { welcomeStep }
            else if step == 1 { nameStep }
            else if step == 2 { chatStep }
            else if step == 3 { researchStep }
            else if step == 4 { hoursStep }
            else { budgetStep }
          }
          .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))

          Spacer(minLength: 0)
        }
        .padding(20)
      }
    }
    .animation(.easeInOut(duration: 0.28), value: step)
  }

  private var displayName: String {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "friend" : trimmed
  }

  private var backgroundColor: Color { UnrotTheme.bg }

  private var welcomeStep: some View {
    VStack(alignment: .center, spacing: 20) {
      Spacer(minLength: 20)

      VStack(spacing: 6) {
        Text("Welcome to")
          .font(.system(size: 28, weight: .semibold, design: .rounded))
          .foregroundStyle(UnrotTheme.textMuted)
        Text("QuizScroll")
          .font(.system(size: 52, weight: .black, design: .rounded))
          .foregroundStyle(UnrotTheme.text)
          .minimumScaleFactor(0.85)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)

      Text("Study first. Then scroll.")
        .font(.title.weight(.semibold))
        .foregroundStyle(UnrotTheme.textMuted)
        .multilineTextAlignment(.center)

      Image("brain_character")
        .resizable()
        .scaledToFit()
        .frame(height: 150)
        .frame(maxWidth: .infinity)

      Text("Less doomscrolling. More learning.")
        .font(.headline.weight(.semibold))
        .foregroundStyle(UnrotTheme.textMuted)
        .multilineTextAlignment(.center)

      Spacer()

      continueButton("Continue") {
        Haptics.medium()
        withAnimation { step = 1 }
      }
    }
    .frame(maxWidth: .infinity)
  }

  private var nameStep: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("What should I call you?")
        .font(.system(size: 40, weight: .black, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
      TextField("Your name", text: $name)
        .textFieldStyle(.plain)
        .padding(.vertical, 12)
        .font(.system(size: 24, weight: .regular))
        .foregroundStyle(UnrotTheme.text)
        .overlay(alignment: .bottom) {
          Rectangle().fill(UnrotTheme.cardBorder).frame(height: 1)
        }
      continueButton("Continue") {
        Haptics.medium()
        withAnimation { step = 2 }
      }
      .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
  }

  private var chatStep: some View {
    VStack(alignment: .leading, spacing: 14) {
      chatHeader

      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(introScript.prefix(revealedIntroCount).enumerated()), id: \.offset) { _, line in
              chatBubble(line)
            }

            if let selectedIdentityReply {
              chatBubble(.user(selectedIdentityReply))
                .id("identity-reply")
            } else if isShowingIdentityChoices {
              identityChoiceStack
                .id("identity-choices")
            }

            ForEach(Array(earnScript.prefix(revealedEarnCount).enumerated()), id: \.offset) { idx, line in
              chatBubble(line)
                .id("earn-\(idx)")
            }

            if let selectedPossibilityReply {
              chatBubble(.user(selectedPossibilityReply))
                .id("possibility-reply")
            } else if isShowingPossibilityChoices {
              possibilityChoiceStack
                .id("possibility-choices")
            }

            ForEach(Array(achievementScript.prefix(revealedAchievementCount).enumerated()), id: \.offset) { idx, line in
              chatBubble(line)
                .id("achievement-\(idx)")
            }

            ForEach(Array(testimonials.prefix(revealedTestimonialCount).enumerated()), id: \.offset) { idx, item in
              testimonialCard(item)
                .id("testimonial-\(idx)")
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: isShowingIdentityChoices) { _, showing in
          if showing { scrollChat(proxy, to: "identity-choices") }
        }
        .onChange(of: selectedIdentityReply) { _, reply in
          if reply != nil { scrollChat(proxy, to: "identity-reply") }
        }
        .onChange(of: isShowingPossibilityChoices) { _, showing in
          if showing { scrollChat(proxy, to: "possibility-choices") }
        }
        .onChange(of: selectedPossibilityReply) { _, reply in
          if reply != nil { scrollChat(proxy, to: "possibility-reply") }
        }
        .onChange(of: revealedEarnCount) { _, count in
          if count > 0 { scrollChat(proxy, to: "earn-\(count - 1)") }
        }
        .onChange(of: revealedTestimonialCount) { _, count in
          if count > 0 { scrollChat(proxy, to: "testimonial-\(count - 1)") }
        }
      }

      if showTestimonialsContinue {
        continueButton("Continue") {
          Haptics.medium()
          withAnimation { step = 3 }
        }
        .padding(.top, 4)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .task(id: step) {
      guard step == 2 else { return }
      await revealIntroChat()
    }
  }

  private var chatHeader: some View {
    HStack(spacing: 10) {
      Image("brain_character")
        .resizable()
        .scaledToFit()
        .frame(width: 46, height: 46)
        .background(UnrotTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
      VStack(alignment: .leading, spacing: 0) {
        Text("Brain")
          .font(.headline.weight(.bold))
          .foregroundStyle(UnrotTheme.text)
        HStack(spacing: 6) {
          Circle().fill(UnrotTheme.success).frame(width: 7, height: 7)
          Text("Online")
            .font(.caption.weight(.medium))
            .foregroundStyle(UnrotTheme.textMuted)
        }
      }
      Spacer()
    }
    .padding(.bottom, 6)
  }

  private var researchStep: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Here's some of the research QuizScroll is built on")
        .font(.system(size: 30, weight: .black, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
        .fixedSize(horizontal: false, vertical: true)

      Text("Small ideas from psychology — baked into how the app works.")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(UnrotTheme.textMuted)

      VStack(spacing: 12) {
        ForEach(researchPoints) { point in
          researchCard(point)
        }
      }

      Spacer(minLength: 8)

      continueButton("Continue") {
        Haptics.medium()
        withAnimation { step = 4 }
      }
    }
  }

  private func researchCard(_ point: OnboardingResearchPoint) -> some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: point.icon)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(UnrotTheme.accent)
        .frame(width: 28)

      Text(point.text)
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(UnrotTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(UnrotTheme.cardBorder.opacity(0.6), lineWidth: 1)
    )
    .themeCardShadow()
  }

  private var hoursStep: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("How many hours do you scroll daily?")
        .font(.system(size: 34, weight: .black, design: .rounded))
        .multilineTextAlignment(.leading)
        .foregroundStyle(UnrotTheme.text)
      Text("Rough guess is enough.")
        .font(.body.weight(.medium))
        .foregroundStyle(UnrotTheme.textMuted)
      VStack(spacing: 10) {
        ForEach(hourChoices, id: \.self) { option in
          Button {
            selectedHours = option
            Haptics.selection()
          } label: {
            HStack {
              Text(option)
                .font(.headline.weight(.semibold))
                .foregroundStyle(UnrotTheme.text)
              Spacer()
            }
            .padding(16)
            .background(UnrotTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(option == selectedHours ? UnrotTheme.accent : UnrotTheme.cardBorder, lineWidth: option == selectedHours ? 2 : 1)
            )
            .themeCardShadow()
          }
          .buttonStyle(.plain)
        }
      }
      continueButton("Continue") {
        Haptics.medium()
        withAnimation { step = 5 }
      }
    }
  }

  private var budgetStep: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Choose your daily scroll budget")
        .font(.system(size: 36, weight: .black, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
      Text("You can always change this later in Settings.")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(UnrotTheme.textMuted)
      HStack(spacing: 10) {
        ForEach([15, 30, 45, 60], id: \.self) { m in
          Button {
            selectedBudget = m
            Haptics.selection()
          } label: {
            Text("\(m)m")
              .font(.subheadline.weight(.bold))
              .foregroundStyle(selectedBudget == m ? .white : UnrotTheme.text)
              .padding(.horizontal, 14)
              .padding(.vertical, 10)
              .background(selectedBudget == m ? UnrotTheme.accent : UnrotTheme.card)
              .clipShape(Capsule())
          }
          .buttonStyle(.plain)
        }
      }
      continueButton("See animation") {
        Haptics.medium()
        withAnimation { step = 6 }
      }
    }
  }

  private var fullScreenAnimationStep: some View {
    ZStack(alignment: .bottom) {
      UnrotSeesawOnboarding {
        withAnimation(.easeInOut(duration: 0.3)) {
          animationFinished = true
        }
      }
      .ignoresSafeArea()

      if animationFinished {
        continueButton("Continue") {
          Haptics.success()
          appState.setDailyBudget(selectedBudget)
          Task { @MainActor in
            // Let the finger lift before the tab bar appears (avoids opening Settings).
            try? await Task.sleep(for: .milliseconds(400))
            if let onFinished {
              onFinished()
            } else {
              appState.completeOnboarding()
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 26)
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .onAppear { animationFinished = false }
  }

  private func testimonialCard(_ item: OnboardingTestimonial) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 3) {
        ForEach(0..<5, id: \.self) { _ in
          Image(systemName: "star.fill")
            .font(.caption2)
            .foregroundStyle(Color(red: 1, green: 0.78, blue: 0.2))
        }
      }
      Text(item.quote)
        .font(.system(size: 17, weight: .semibold, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
        .fixedSize(horizontal: false, vertical: true)
      Text("— \(item.author)")
        .font(.caption.weight(.semibold))
        .foregroundStyle(UnrotTheme.textMuted)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(UnrotTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .themeCardShadow()
  }

  private func chatBubble(_ line: ChatLine) -> some View {
    HStack(alignment: .top) {
      if line.sender == .user { Spacer(minLength: 48) }
      Text(line.text)
        .font(.system(size: 17, weight: .semibold, design: .rounded))
        .foregroundStyle(line.warning ? UnrotTheme.danger : (line.emphasized ? UnrotTheme.accent : UnrotTheme.text))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(line.sender == .bot ? UnrotTheme.card : UnrotTheme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .themeCardShadow()
      if line.sender == .bot { Spacer(minLength: 48) }
    }
    .frame(maxWidth: .infinity, alignment: line.sender == .bot ? .leading : .trailing)
  }

  private var identityChoiceStack: some View {
    VStack(alignment: .trailing, spacing: 8) {
      Text("Tap to reply")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(UnrotTheme.textMuted)
      ForEach(identityChoices, id: \.self) { choice in
        inlineChoice(choice) { selectIdentityReply(choice) }
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
  }

  private var possibilityChoiceStack: some View {
    VStack(alignment: .trailing, spacing: 8) {
      Text("Tap to reply")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(UnrotTheme.textMuted)
      ForEach(possibilityChoices, id: \.self) { choice in
        inlineChoice(choice) { selectPossibilityReply(choice) }
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
  }

  private func inlineChoice(_ text: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(text)
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(UnrotTheme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .themeCardShadow()
    }
    .buttonStyle(.plain)
  }

  private func selectIdentityReply(_ text: String) {
    Haptics.selection()
    withAnimation(.easeInOut(duration: 0.22)) {
      selectedIdentityReply = text
      isShowingIdentityChoices = false
    }
    Task { await revealEarnChat() }
  }

  private func selectPossibilityReply(_ text: String) {
    Haptics.selection()
    withAnimation(.easeInOut(duration: 0.22)) {
      selectedPossibilityReply = text
      isShowingPossibilityChoices = false
    }
    Task { await revealAchievementAndTestimonials() }
  }

  private func resetChatState() {
    revealedIntroCount = 0
    revealedEarnCount = 0
    revealedAchievementCount = 0
    revealedTestimonialCount = 0
    isShowingIdentityChoices = false
    isShowingPossibilityChoices = false
    selectedIdentityReply = nil
    selectedPossibilityReply = nil
    showTestimonialsContinue = false
  }

  private func scrollChat(_ proxy: ScrollViewProxy, to id: String) {
    withAnimation { proxy.scrollTo(id, anchor: .bottom) }
  }

  private func revealIntroChat() async {
    resetChatState()

    for idx in 0..<introScript.count {
      try? await Task.sleep(for: .milliseconds(chatMessageDelayMs))
      await MainActor.run {
        revealedIntroCount = idx + 1
        Haptics.light()
      }
    }
    await MainActor.run {
      isShowingIdentityChoices = true
    }
  }

  private func revealEarnChat() async {
    try? await Task.sleep(for: .milliseconds(chatSectionPauseMs))
    for idx in 0..<earnScript.count {
      try? await Task.sleep(for: .milliseconds(chatMessageDelayMs))
      await MainActor.run {
        revealedEarnCount = idx + 1
        Haptics.light()
      }
    }
    await MainActor.run {
      isShowingPossibilityChoices = true
    }
  }

  private func revealAchievementAndTestimonials() async {
    try? await Task.sleep(for: .milliseconds(chatSectionPauseMs))
    for idx in 0..<achievementScript.count {
      try? await Task.sleep(for: .milliseconds(chatMessageDelayMs))
      await MainActor.run {
        revealedAchievementCount = idx + 1
        Haptics.medium()
      }
    }

    for idx in 0..<testimonials.count {
      try? await Task.sleep(for: .milliseconds(testimonialDelayMs))
      await MainActor.run {
        revealedTestimonialCount = idx + 1
        Haptics.light()
      }
    }

    await MainActor.run {
      showTestimonialsContinue = true
    }
  }

  private func continueButton(_ title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .font(.headline.weight(.heavy))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
    .buttonStyle(.borderedProminent)
    .tint(UnrotTheme.accent)
  }
}

private struct OnboardingTestimonial: Identifiable {
  let id = UUID()
  let quote: String
  let author: String
}

private struct OnboardingResearchPoint: Identifiable {
  let id = UUID()
  let icon: String
  let text: String
}

private struct ChatLine {
  enum Sender {
    case bot
    case user
  }
  let sender: Sender
  let text: String
  var emphasized: Bool = false
  var warning: Bool = false

  static func bot(_ text: String, emphasized: Bool = false, warning: Bool = false) -> ChatLine {
    .init(sender: .bot, text: text, emphasized: emphasized, warning: warning)
  }
  static func user(_ text: String) -> ChatLine {
    .init(sender: .user, text: text)
  }
}

private enum Haptics {
  static func light() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
  }
  static func medium() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
  }
  static func selection() {
    UISelectionFeedbackGenerator().selectionChanged()
  }
  static func warning() {
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
  }
  static func success() {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
  }
}
