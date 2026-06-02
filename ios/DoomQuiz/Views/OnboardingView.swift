import SwiftUI
import UIKit

struct OnboardingView: View {
  @EnvironmentObject private var appState: AppState
  @State private var step = 0
  @State private var name = ""
  @State private var selectedBudget = 45
  @State private var revealedChatCount = 0
  @State private var selectedHours = "2 to 4 hours"
  @State private var isShowingChoices = false
  @State private var selectedReply: String?
  @State private var animationFinished = false

  private let replyChoices = ["ok wow", "show me how"]

  private let hourChoices = [
    "Less than 2 hours",
    "2 to 4 hours",
    "4 to 6 hours",
    "6 to 8 hours",
  ]

  private var chatScript: [ChatLine] {
    [
      .bot("hey \(displayName)"),
      .bot("quick one. does this loop sound familiar?"),
      .bot("scroll"),
      .bot("feel bad"),
      .bot("say 'last reel'"),
      .bot("scroll again"),
      .user("yea am i cooked?"),
      .bot("you are not broken."),
      .bot("you are up against teams engineered to keep you hooked."),
      .bot("you. can't. stop.", warning: true),
      .bot("not a fair fight."),
      .bot("but thousands here flipped it by learning before scrolling.", emphasized: true),
      .bot("wanna see how they do it?"),
    ]
  }

  var body: some View {
    ZStack {
      backgroundColor.ignoresSafeArea()

      if step == 5 {
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
            else if step == 3 { hoursStep }
            else { budgetStep }
          }
          .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))

          Spacer()
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
    VStack(alignment: .leading, spacing: 18) {
      Spacer(minLength: 26)
      Text("Welcome to QuizScroll")
        .font(.system(size: 44, weight: .black, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
      Text("Study first. Then scroll.")
        .font(.title2.weight(.medium))
        .foregroundStyle(UnrotTheme.textMuted)
      Image("brain_character")
        .resizable()
        .scaledToFit()
        .frame(height: 160)
        .frame(maxWidth: .infinity)
      Text("Less doomscrolling. More learning.")
        .font(.headline.weight(.semibold))
        .foregroundStyle(UnrotTheme.textMuted)
        .frame(maxWidth: .infinity, alignment: .center)
      Spacer()
      continueButton("Continue") {
        Haptics.medium()
        withAnimation { step = 1 }
      }
    }
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
      }
      .padding(.bottom, 6)

      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(chatScript.prefix(revealedChatCount).enumerated()), id: \.offset) { _, line in
              chatBubble(line)
            }

            if let selectedReply {
              chatBubble(.user(selectedReply))
                .id("selected-reply")
            } else if isShowingChoices {
              VStack(alignment: .leading, spacing: 8) {
                ForEach(replyChoices, id: \.self) { choice in
                  inlineChoice(choice)
                }
              }
              .id("reply-choices")
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onChange(of: isShowingChoices) { _, showing in
          if showing {
            withAnimation { proxy.scrollTo("reply-choices", anchor: .bottom) }
          }
        }
        .onChange(of: selectedReply) { _, reply in
          if reply != nil {
            withAnimation { proxy.scrollTo("selected-reply", anchor: .bottom) }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .task(id: step) {
      guard step == 2 else { return }
      await revealChat()
    }
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
          }
          .buttonStyle(.plain)
        }
      }
      continueButton("Continue") {
        Haptics.medium()
        withAnimation { step = 4 }
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
        withAnimation { step = 5 }
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
          appState.setDailyBudget(selectedBudget)
          appState.completeOnboarding()
          Haptics.success()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 26)
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .onAppear { animationFinished = false }
  }

  private func chatBubble(_ line: ChatLine) -> some View {
    HStack(alignment: .top) {
      if line.sender == .user { Spacer(minLength: 56) }
      Text(line.text)
        .font(.system(size: 18, weight: .semibold, design: .rounded))
        .foregroundStyle(line.warning ? UnrotTheme.danger : (line.emphasized ? UnrotTheme.accent : UnrotTheme.text))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(line.sender == .bot ? UnrotTheme.card : UnrotTheme.accent.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      if line.sender == .bot { Spacer(minLength: 56) }
    }
    .frame(maxWidth: .infinity, alignment: line.sender == .bot ? .leading : .trailing)
  }

  private func inlineChoice(_ text: String) -> some View {
    Button {
      selectReply(text)
    } label: {
      Text(text)
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundStyle(UnrotTheme.accent)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(UnrotTheme.accent.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  private func selectReply(_ text: String) {
    Haptics.selection()
    withAnimation(.easeInOut(duration: 0.22)) {
      selectedReply = text
      isShowingChoices = false
    }
    Task {
      try? await Task.sleep(for: .milliseconds(650))
      await MainActor.run {
        withAnimation { step = 3 }
      }
    }
  }

  private func revealChat() async {
    revealedChatCount = 0
    isShowingChoices = false
    selectedReply = nil

    for idx in 0..<chatScript.count {
      let delay = chatScript[idx].sender == .user ? 520 : 760
      try? await Task.sleep(for: .milliseconds(delay))
      await MainActor.run {
        revealedChatCount = idx + 1
        if chatScript[idx].warning {
          Haptics.warning()
        } else {
          Haptics.light()
        }
      }
    }
    await MainActor.run {
      isShowingChoices = true
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
