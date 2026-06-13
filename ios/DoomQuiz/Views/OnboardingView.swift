import SwiftUI
import UIKit

struct OnboardingView: View {
  @EnvironmentObject private var appState: AppState
  var onFinished: (() -> Void)?
  @State private var step = 0
  @State private var selectedBudget = 45
  @State private var selectedBudgetChoice = "45 minutes"
  @State private var selectedInterests: Set<String> = []
  @State private var selectedHours = "2 to 4 hours"
  @State private var animationFinished = false
  @State private var howItWorksReady = false
  @State private var yearCommittedBoxesRemoved = 0
  @State private var yearScrollBoxesRemoved = 0
  @State private var yearCaptionPhase = 0
  @State private var yearGridFocused = false
  @State private var scrollStatsRevealed = 0

  private let yearDayCount = 365
  private let lifeExpectancyYears = 80
  private let committedHoursPerDay = 16.0
  private let yearTitleReadPauseMs = 2_100
  private let yearIntroPauseMs = 3_375
  private let yearResultReadPauseMs = 3_750
  private let yearScrollResultReadPauseMs = 4_125
  private let yearFocusReadPauseMs = 3_000
  private let yearFinalMessageReadPauseMs = 5_500
  private let scrollBoxTickMs = 72

  private var yearRemovalTotalMs: Int {
    YearBoxRemovalTiming.totalMs
  }

  private var isYearGridStep: Bool { step == 3 }
  private var isHowItWorksAnimStep: Bool { (9...12).contains(step) }

  private let scrollBudgetChoices = [
    "No scrolling",
    "15 minutes",
    "30 minutes",
    "45 minutes",
    "1 hour",
  ]

  private let scrollBudgetMinutes: [String: Int] = [
    "No scrolling": 0,
    "15 minutes": 15,
    "30 minutes": 30,
    "45 minutes": 45,
    "1 hour": 60,
  ]

  private let interestCategories: [OnboardingInterestCategory] = [
    .init(name: "Languages", topics: ["Spanish", "French", "Japanese", "Mandarin", "German", "Korean", "Italian", "Portuguese"]),
    .init(name: "Science & tech", topics: ["Python", "Web dev", "AI & ML", "Math", "Physics", "Biology", "Chemistry", "Data science"]),
    .init(name: "Arts & humanities", topics: ["History", "Philosophy", "Literature", "Art history", "Geography", "Music theory", "Film", "Architecture"]),
    .init(name: "Life & skills", topics: ["Psychology", "Economics", "Finance", "Business", "Public speaking", "Health & fitness", "Cooking", "Entrepreneurship"]),
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

  private let researchPoints: [OnboardingResearchPoint] = [
    .init(
      title: "Reading rebuilds the brain",
      context: "Brain scans show sustained reading strengthens the attention and language networks that passive scrolling tends to weaken.",
      citation: "Huber et al. (2018), Nature Communications"
    ),
    .init(
      title: "Even small barriers cut bad habits significantly",
      context: "Adding a short pause or extra step before a temptation makes mindless scrolling far less automatic.",
      citation: "Gollwitzer & Sheeran (2006), Advances in Experimental Social Psychology"
    ),
    .init(
      title: "The more knowledgeable, the more attractive 😉",
      context: "People consistently rate others as more appealing when they show real knowledge — depth and curiosity stand out.",
      citation: "Prokosch et al. (2009), Evolution and Human Behavior"
    ),
  ]

  var body: some View {
    ZStack {
      backgroundColor.ignoresSafeArea()

      if step == 8 {
        fullScreenAnimationStep
          .transition(.opacity)
      } else if isHowItWorksAnimStep {
        howItWorksAnimationFlow
          .transition(.opacity)
      } else {
        VStack(alignment: .leading, spacing: isYearGridStep ? 8 : 16) {
          Group {
            switch step {
            case 0: welcomeStep
            case 1: hoursStep
            case 2: scrollStatsStep
            case 3: yearDaysStep
            case 4: changeAndTestimonialsStep
            case 5: researchStep
            case 6: scrollBudgetStep
            case 7: topicSelectionStep
            default: EmptyView()
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isYearGridStep ? .center : .topLeading)
          .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))

          if !isYearGridStep {
            Spacer(minLength: 0)
          }
        }
        .padding(.horizontal, isYearGridStep ? 4 : 20)
        .padding(.vertical, isYearGridStep ? 10 : 20)
      }
    }
    .animation(isYearGridStep ? .easeInOut(duration: 0.42) : .easeInOut(duration: 0.28), value: step)
    .task(id: step) {
      guard step == 3 else { return }

      yearCommittedBoxesRemoved = 0
      yearScrollBoxesRemoved = 0
      yearCaptionPhase = 0
      yearGridFocused = false

      try? await Task.sleep(for: .milliseconds(yearIntroPauseMs))
      guard !Task.isCancelled else { return }

      await MainActor.run {
        withAnimation(.easeInOut(duration: 0.35)) { yearCaptionPhase = 1 }
      }

      try? await Task.sleep(for: .milliseconds(yearTitleReadPauseMs))
      guard !Task.isCancelled else { return }

      await MainActor.run {
        withAnimation(.easeOut(duration: YearBoxRemovalTiming.stateChange)) {
          yearCommittedBoxesRemoved = committedBoxesRemoved
        }
        Haptics.light()
      }

      try? await Task.sleep(for: .milliseconds(yearRemovalTotalMs + yearResultReadPauseMs))
      guard !Task.isCancelled else { return }

      await MainActor.run {
        withAnimation(.easeInOut(duration: 0.35)) { yearCaptionPhase = 2 }
      }

      try? await Task.sleep(for: .milliseconds(yearTitleReadPauseMs))
      guard !Task.isCancelled else { return }

      let scrollTotal = scrollBoxesRemoved
      if scrollTotal > 0 {
        for tick in 1...scrollTotal {
          guard !Task.isCancelled else { return }
          try? await Task.sleep(for: .milliseconds(scrollBoxTickMs))
          await MainActor.run {
            yearScrollBoxesRemoved = tick
            Haptics.scrollBoxTick()
          }
        }
      }

      try? await Task.sleep(for: .milliseconds(yearScrollResultReadPauseMs))
      guard !Task.isCancelled else { return }

      await MainActor.run {
        withAnimation(.easeInOut(duration: 0.35)) { yearCaptionPhase = 3 }
      }

      try? await Task.sleep(for: .milliseconds(yearTitleReadPauseMs))
      guard !Task.isCancelled else { return }

      await MainActor.run {
        withAnimation(.easeInOut(duration: 0.65)) {
          yearGridFocused = true
        }
        Haptics.light()
      }

      try? await Task.sleep(for: .milliseconds(yearFocusReadPauseMs + yearFinalMessageReadPauseMs))
      guard !Task.isCancelled else { return }

      await MainActor.run {
        withAnimation(.easeInOut(duration: 0.42)) { step = 4 }
      }
    }
    .task(id: step) {
      guard step == 2 else { return }
      scrollStatsRevealed = 0
      for i in 1...3 {
        try? await Task.sleep(for: .milliseconds(i == 1 ? 400 : 520))
        guard !Task.isCancelled else { return }
        await MainActor.run {
          withAnimation(.easeOut(duration: 0.35)) { scrollStatsRevealed = i }
          Haptics.light()
        }
      }
    }
  }

  private var estimatedScrollHours: Double {
    switch selectedHours {
    case "Less than 2 hours": return 2
    case "2 to 4 hours": return 4
    case "4 to 6 hours": return 6
    case "6 to 8 hours": return 8
    default: return 4
    }
  }

  private var committedBoxesRemoved: Int {
    Int((committedHoursPerDay * Double(yearDayCount) / 24.0).rounded())
  }

  private var scrollBoxesRemoved: Int {
    let base = Int((estimatedScrollHours * Double(yearDayCount) / 24.0).rounded())
    let bonus = selectedHours == "2 to 4 hours" ? 4 : 0
    return base + bonus
  }

  private var scrollDaysPerYear: Int {
    Int((estimatedScrollHours * Double(yearDayCount) / 24.0).rounded())
  }

  private var scrollYearsInLifetime: Int {
    Int((estimatedScrollHours * Double(lifeExpectancyYears) / 24.0).rounded())
  }

  private var backgroundColor: Color { UnrotTheme.bg }

  private var yearCaption: String {
    switch yearCaptionPhase {
    case 0:
      return "This is how much you have in a year."
    case 1:
      return "This is how much remains after\nsleep, eating, and work."
    case 2:
      return "You scroll this much of\nyour time, right?"
    default:
      return "This is how much remains."
    }
  }

  private var yearCaptionFooter: String? {
    guard yearGridFocused else { return nil }
    return "This remains for self-betterment, achieving your goals, family, friends, and living life."
  }

  // MARK: - Steps

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
        Haptics.continueTap()
        withAnimation { step = 1 }
      }
    }
    .frame(maxWidth: .infinity)
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
            Haptics.hourSelect()
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
      Spacer(minLength: 0)
      continueButton("Continue") {
        Haptics.continueTap()
        scrollStatsRevealed = 0
        withAnimation { step = 2 }
      }
    }
  }

  private var scrollStatsStep: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("That's a lot of scrolling.")
        .font(.system(size: 34, weight: .black, design: .rounded))
        .foregroundStyle(UnrotTheme.text)

      VStack(alignment: .leading, spacing: 20) {
        if scrollStatsRevealed >= 1 {
          scrollStatLine(value: "\(Int(estimatedScrollHours)) hrs", label: "a day")
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        if scrollStatsRevealed >= 2 {
          scrollStatLine(value: "\(scrollDaysPerYear) days", label: "a year")
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        if scrollStatsRevealed >= 3 {
          scrollStatLine(value: "\(scrollYearsInLifetime) years", label: "in a lifetime")
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
      }
      .padding(.top, 8)
      .animation(.easeOut(duration: 0.35), value: scrollStatsRevealed)

      Spacer(minLength: 0)

      continueButton("Continue") {
        Haptics.continueTap()
        yearCommittedBoxesRemoved = 0
        yearScrollBoxesRemoved = 0
        yearCaptionPhase = 0
        yearGridFocused = false
        withAnimation { step = 3 }
      }
      .opacity(scrollStatsRevealed >= 3 ? 1 : 0.35)
      .disabled(scrollStatsRevealed < 3)
    }
  }

  private func scrollStatLine(value: String, label: String) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 8) {
      Text(value)
        .font(.system(size: 44, weight: .black, design: .rounded))
        .foregroundStyle(UnrotTheme.accent)
      Text(label)
        .font(.system(size: 22, weight: .semibold, design: .rounded))
        .foregroundStyle(UnrotTheme.textMuted)
    }
  }

  private var yearDaysStep: some View {
    Group {
      if yearGridFocused {
        VStack(spacing: 0) {
          Spacer(minLength: 0)

          VStack(spacing: 18) {
            Text(yearCaption)
              .font(.system(size: 20, weight: .heavy, design: .rounded))
              .foregroundStyle(UnrotTheme.text)
              .multilineTextAlignment(.center)
              .fixedSize(horizontal: false, vertical: true)
              .frame(maxWidth: .infinity)
              .transition(.opacity.combined(with: .move(edge: .top)))

            OnboardingYearBoxesGrid(
              boxCount: yearDayCount,
              committedBoxesRemoved: yearCommittedBoxesRemoved,
              scrollBoxesRemoved: yearScrollBoxesRemoved,
              focusedMode: true
            )

            if let yearCaptionFooter {
              Text(yearCaptionFooter)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(UnrotTheme.textMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
          }

          Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        yearDaysPhaseStep(
          title: yearCaption,
          footer: yearCaptionFooter,
          footerBelowContent: false
        ) {
          OnboardingYearBoxesGrid(
            boxCount: yearDayCount,
            committedBoxesRemoved: yearCommittedBoxesRemoved,
            scrollBoxesRemoved: yearScrollBoxesRemoved
          )
        }
      }
    }
    .animation(.easeInOut(duration: 0.35), value: yearCaptionPhase)
    .animation(.easeInOut(duration: 0.65), value: yearGridFocused)
  }

  private var changeAndTestimonialsStep: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        VStack(alignment: .leading, spacing: 12) {
          Text("What if I told you we can change this?")
            .font(.system(size: 30, weight: .black, design: .rounded))
            .foregroundStyle(UnrotTheme.text)
            .fixedSize(horizontal: false, vertical: true)

          Text("Many people here have done the same — they replaced scrolling with learning.")
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(UnrotTheme.textMuted)
            .fixedSize(horizontal: false, vertical: true)
        }

        Text("Real people. Real results.")
          .font(.system(size: 24, weight: .black, design: .rounded))
          .foregroundStyle(UnrotTheme.text)
          .padding(.top, 4)

        ForEach(testimonials) { item in
          testimonialCard(item)
        }
      }
      .padding(.bottom, 8)
    }
    .safeAreaInset(edge: .bottom) {
      continueButton("Continue") {
        Haptics.continueTap()
        withAnimation { step = 5 }
      }
      .padding(.top, 8)
    }
  }

  private var researchStep: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Why learning?")
            .font(.system(size: 32, weight: .black, design: .rounded))
            .foregroundStyle(UnrotTheme.text)

          Text("Three findings that explain why this works.")
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .foregroundStyle(UnrotTheme.textMuted)
        }

        VStack(spacing: 14) {
          ForEach(researchPoints) { point in
            researchCard(point)
          }
        }
      }
      .padding(.bottom, 12)
    }
    .safeAreaInset(edge: .bottom) {
      continueButton("Continue") {
        Haptics.continueTap()
        withAnimation { step = 6 }
      }
      .padding(.top, 8)
    }
  }

  private var scrollBudgetStep: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Select your daily default allowance")
        .font(.system(size: 34, weight: .black, design: .rounded))
        .multilineTextAlignment(.leading)
        .foregroundStyle(UnrotTheme.text)

      Text("How much scroll time you get before apps lock.")
        .font(.body.weight(.medium))
        .foregroundStyle(UnrotTheme.textMuted)

      VStack(spacing: 10) {
        ForEach(scrollBudgetChoices, id: \.self) { option in
          Button {
            selectedBudgetChoice = option
            selectedBudget = scrollBudgetMinutes[option] ?? 45
            Haptics.hourSelect()
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
                .stroke(option == selectedBudgetChoice ? UnrotTheme.accent : UnrotTheme.cardBorder, lineWidth: option == selectedBudgetChoice ? 2 : 1)
            )
            .themeCardShadow()
          }
          .buttonStyle(.plain)
        }
      }

      Spacer(minLength: 0)

      continueButton("Continue") {
        Haptics.continueTap()
        appState.setDailyBudget(selectedBudget)
        withAnimation { step = 7 }
      }
    }
  }

  private var topicSelectionStep: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 8) {
        Text("What are you into?")
          .font(.system(size: 34, weight: .black, design: .rounded))
          .foregroundStyle(UnrotTheme.text)

        Text("Select topics you're into.")
          .font(.body.weight(.medium))
          .foregroundStyle(UnrotTheme.textMuted)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(.bottom, 18)

      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 22) {
          ForEach(interestCategories) { category in
            VStack(alignment: .leading, spacing: 12) {
              Text(category.name)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(UnrotTheme.textMuted)
                .textCase(.uppercase)

              InterestFlowLayout(spacing: 10) {
                ForEach(category.topics, id: \.self) { topic in
                  interestPill(topic)
                }
              }
            }
          }
        }
        .padding(.bottom, 12)
      }

      Text("\(selectedInterests.count) selected · pick at least 3")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(selectedInterests.count >= 3 ? UnrotTheme.accent : UnrotTheme.textMuted)
        .frame(maxWidth: .infinity)
        .padding(.top, 10)

      continueButton("Continue") {
        Haptics.continueTap()
        appState.setInterestedTopics(Array(selectedInterests).sorted())
        withAnimation { step = 8 }
      }
      .padding(.top, 12)
      .opacity(selectedInterests.count >= 3 ? 1 : 0.4)
      .disabled(selectedInterests.count < 3)
    }
  }

  private func interestPill(_ title: String) -> some View {
    let selected = selectedInterests.contains(title)
    return Button {
      if selected {
        selectedInterests.remove(title)
      } else {
        selectedInterests.insert(title)
      }
      Haptics.hourSelect()
    } label: {
      Text(title)
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundStyle(selected ? .white : UnrotTheme.text)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(selected ? UnrotTheme.accent : UnrotTheme.card)
        .clipShape(Capsule())
        .overlay(
          Capsule()
            .stroke(selected ? UnrotTheme.accent : UnrotTheme.cardBorder, lineWidth: selected ? 0 : 1)
        )
    }
    .buttonStyle(.plain)
  }

  private var howItWorksAnimationFlow: some View {
    ZStack(alignment: .bottom) {
      UnrotTheme.bg.ignoresSafeArea()

      VStack(spacing: 0) {
        Group {
          switch step {
          case 9:
            OnboardingTopicAnimation {
              withAnimation(.easeInOut(duration: 0.25)) { howItWorksReady = true }
            }
          case 10:
            OnboardingJailAnimation {
              withAnimation(.easeInOut(duration: 0.25)) { howItWorksReady = true }
            }
          case 11:
            OnboardingQuizAnimation {
              withAnimation(.easeInOut(duration: 0.25)) { howItWorksReady = true }
            }
          case 12:
            OnboardingWinWinAnimation {
              withAnimation(.easeInOut(duration: 0.25)) { howItWorksReady = true }
            }
          default:
            EmptyView()
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 16)
        .id(step)
      }

      if howItWorksReady {
        continueButton(step == 12 ? "Get started" : "Continue") {
          Haptics.continueTap()
          if step == 12 {
            Haptics.success()
            Task { @MainActor in
              try? await Task.sleep(for: .milliseconds(400))
              if let onFinished {
                onFinished()
              } else {
                appState.completeOnboarding()
              }
            }
          } else {
            howItWorksReady = false
            withAnimation(.easeInOut(duration: 0.35)) { step += 1 }
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 26)
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(.easeInOut(duration: 0.28), value: howItWorksReady)
    .onChange(of: step) { _, newStep in
      if (9...12).contains(newStep) { howItWorksReady = false }
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
          Haptics.continueTap()
          withAnimation { step = 9 }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 26)
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .onAppear { animationFinished = false }
  }

  // MARK: - Components

  private func researchCard(_ point: OnboardingResearchPoint) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(point.title)
        .font(.system(size: 19, weight: .heavy, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
        .fixedSize(horizontal: false, vertical: true)

      Text(point.context)
        .font(.system(size: 15, weight: .medium, design: .rounded))
        .foregroundStyle(UnrotTheme.textMuted)
        .fixedSize(horizontal: false, vertical: true)

      Text(point.citation)
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundStyle(UnrotTheme.textMuted.opacity(0.85))
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(UnrotTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(alignment: .leading) {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(UnrotTheme.accent)
        .frame(width: 4)
        .padding(.vertical, 12)
    }
    .themeCardShadow()
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

  private func yearDaysPhaseStep<Content: View>(
    title: String,
    titleFont: Font = .system(size: 20, weight: .heavy, design: .rounded),
    footer: String?,
    footerBelowContent: Bool = false,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(spacing: 10) {
      Text(title)
        .font(titleFont)
        .foregroundStyle(UnrotTheme.text)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .transition(.opacity.combined(with: .move(edge: .top)))

      if footerBelowContent, let footer {
        VStack(spacing: 12) {
          content()

          Text(footer)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(UnrotTheme.textMuted)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      } else {
        content()
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
          .layoutPriority(1)

        if let footer {
          Text(footer)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(UnrotTheme.textMuted)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

private enum YearBoxRemovalTiming {
  static let spreadSeconds = 0.38
  static let animSeconds = 0.42
  static let stateChange = 0.95

  static var totalMs: Int {
    Int((spreadSeconds + animSeconds) * 1_000)
  }
}

private struct OnboardingInterestCategory: Identifiable {
  let id = UUID()
  let name: String
  let topics: [String]
}

private struct InterestFlowLayout: Layout {
  var spacing: CGFloat = 8

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let width = proposal.width ?? 0
    let result = arrangeSubviews(subviews: subviews, maxWidth: width)
    return CGSize(width: width, height: result.height)
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let result = arrangeSubviews(subviews: subviews, maxWidth: bounds.width)
    for (index, frame) in result.frames.enumerated() {
      subviews[index].place(
        at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
        proposal: ProposedViewSize(frame.size)
      )
    }
  }

  private func arrangeSubviews(subviews: Subviews, maxWidth: CGFloat) -> (frames: [CGRect], height: CGFloat) {
    var frames: [CGRect] = []
    var x: CGFloat = 0
    var y: CGFloat = 0
    var rowHeight: CGFloat = 0

    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)
      if x + size.width > maxWidth, x > 0 {
        x = 0
        y += rowHeight + spacing
        rowHeight = 0
      }
      frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
      rowHeight = max(rowHeight, size.height)
      x += size.width + spacing
    }

    return (frames, y + rowHeight)
  }
}

private struct OnboardingYearBoxesGrid: View {
  let boxCount: Int
  let committedBoxesRemoved: Int
  let scrollBoxesRemoved: Int
  var focusedMode: Bool = false

  private var totalRemoved: Int {
    committedBoxesRemoved + scrollBoxesRemoved
  }

  private static let removalSpreadSeconds = YearBoxRemovalTiming.spreadSeconds
  private static let removalAnimSeconds = YearBoxRemovalTiming.animSeconds

  private let columns = 15
  private let referenceGapRatio: CGFloat = 0.42
  private let boxSizeScale: CGFloat = 0.85
  private let gapScale: CGFloat = 0.75

  private var rows: Int {
    (boxCount + columns - 1) / columns
  }

  var body: some View {
    if focusedMode {
      GeometryReader { geo in
        let metrics = gridMetrics(width: geo.size.width)
        remainingClusterGrid(metrics: metrics)
          .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
      }
      .frame(height: clusterHeight(forWidth: UIScreen.main.bounds.width - 8))
    } else {
      GeometryReader { geo in
        let metrics = gridMetrics(width: geo.size.width)
        fullYearGrid(metrics: metrics)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private struct GridMetrics {
    let cell: CGFloat
    let spacing: CGFloat
    let corner: CGFloat
  }

  private struct CellPos: Identifiable {
    let index: Int
    let row: Int
    let col: Int
    var id: Int { index }
  }

  private var activeCells: [CellPos] {
    guard totalRemoved < boxCount else { return [] }
    return (totalRemoved..<boxCount).map { index in
      CellPos(index: index, row: index / columns, col: index % columns)
    }
  }

  private func gridMetrics(width: CGFloat) -> GridMetrics {
    let cellFit = width / (CGFloat(columns) + CGFloat(columns - 1) * referenceGapRatio)
    let cell = cellFit * boxSizeScale
    let spacing = cellFit * referenceGapRatio * gapScale
    let corner = max(1.2, cell * 0.14)
    return GridMetrics(cell: cell, spacing: spacing, corner: corner)
  }

  private func clusterHeight(forWidth width: CGFloat) -> CGFloat {
    let metrics = gridMetrics(width: width)
    let cells = activeCells
    guard !cells.isEmpty else { return 0 }
    let minRow = cells.map(\.row).min() ?? 0
    let maxRow = cells.map(\.row).max() ?? 0
    let clusterRows = maxRow - minRow + 1
    return CGFloat(clusterRows) * metrics.cell + metrics.spacing * CGFloat(max(clusterRows - 1, 0))
  }

  @ViewBuilder
  private func remainingClusterGrid(metrics: GridMetrics) -> some View {
    let cells = activeCells
    if cells.isEmpty {
      EmptyView()
    } else {
      let minRow = cells.map(\.row).min() ?? 0
      let maxRow = cells.map(\.row).max() ?? 0
      let minCol = cells.map(\.col).min() ?? 0
      let maxCol = cells.map(\.col).max() ?? 0
      let clusterCols = maxCol - minCol + 1
      let clusterRows = maxRow - minRow + 1
      let step = metrics.cell + metrics.spacing
      let gridWidth = CGFloat(clusterCols) * metrics.cell + metrics.spacing * CGFloat(max(clusterCols - 1, 0))
      let gridHeight = CGFloat(clusterRows) * metrics.cell + metrics.spacing * CGFloat(max(clusterRows - 1, 0))

      ZStack(alignment: .topLeading) {
        ForEach(cells) { cell in
          RoundedRectangle(cornerRadius: metrics.corner, style: .continuous)
            .fill(UnrotTheme.accent)
            .frame(width: metrics.cell, height: metrics.cell)
            .offset(
              x: CGFloat(cell.col - minCol) * step,
              y: CGFloat(cell.row - minRow) * step
            )
        }
      }
      .frame(width: gridWidth, height: gridHeight)
      .frame(maxWidth: .infinity, alignment: .center)
      .transition(.scale(scale: 0.92).combined(with: .opacity))
    }
  }

  @ViewBuilder
  private func fullYearGrid(metrics: GridMetrics) -> some View {
    let gridWidth = CGFloat(columns) * metrics.cell + metrics.spacing * CGFloat(columns - 1)
    let gridHeight = CGFloat(rows) * metrics.cell + metrics.spacing * CGFloat(rows - 1)

    LazyVGrid(
      columns: Array(repeating: GridItem(.fixed(metrics.cell), spacing: metrics.spacing), count: columns),
      alignment: .center,
      spacing: metrics.spacing
    ) {
      ForEach(0..<boxCount, id: \.self) { index in
        RoundedRectangle(cornerRadius: metrics.corner, style: .continuous)
          .fill(color(for: index))
          .frame(width: metrics.cell, height: metrics.cell)
          .opacity(opacity(for: index))
          .scaleEffect(scale(for: index))
          .animation(
            .easeOut(duration: Self.removalAnimSeconds).delay(staggerDelay(for: index)),
            value: committedBoxesRemoved
          )
          .animation(nil, value: scrollBoxesRemoved)
      }
    }
    .frame(width: gridWidth, height: gridHeight)
  }

  private func boxKind(for index: Int) -> BoxKind {
    if index < committedBoxesRemoved { return .committedRemoved }
    if index < totalRemoved { return .scrollRemoved }
    return .active
  }

  private func color(for index: Int) -> Color {
    switch boxKind(for: index) {
    case .active: return UnrotTheme.accent
    case .committedRemoved: return UnrotTheme.cardBorder.opacity(0.45)
    case .scrollRemoved: return UnrotTheme.cardBorder.opacity(0.45)
    }
  }

  private func opacity(for index: Int) -> Double {
    switch boxKind(for: index) {
    case .active: return 1
    case .committedRemoved: return 0.5
    case .scrollRemoved: return 0.42
    }
  }

  private func scale(for index: Int) -> CGFloat {
    switch boxKind(for: index) {
    case .active: return 1
    case .committedRemoved: return 0.9
    case .scrollRemoved: return 0.9
    }
  }

  private func staggerDelay(for index: Int) -> Double {
    if index < committedBoxesRemoved {
      return Double(index) / Double(max(committedBoxesRemoved, 1)) * Self.removalSpreadSeconds
    }
    return 0
  }

  private enum BoxKind {
    case active
    case committedRemoved
    case scrollRemoved
  }
}

private struct OnboardingTestimonial: Identifiable {
  let id = UUID()
  let quote: String
  let author: String
}

private struct OnboardingResearchPoint: Identifiable {
  let id = UUID()
  let title: String
  let context: String
  let citation: String
}

private enum Haptics {
  static func light() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
  }
  static func medium() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
  }
  static func continueTap() {
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    generator.prepare()
    generator.impactOccurred(intensity: 1.0)
  }
  static func hourSelect() {
    let generator = UIImpactFeedbackGenerator(style: .rigid)
    generator.prepare()
    generator.impactOccurred(intensity: 0.95)
  }
  static func scrollBoxTick() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.prepare()
    generator.impactOccurred(intensity: 0.72)
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
