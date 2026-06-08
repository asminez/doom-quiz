import SwiftUI

// MARK: - Topic / PDF

struct OnboardingTopicAnimation: View {
  var onAnimationComplete: (() -> Void)?

  @State private var pdfVisible = false
  @State private var pdfOffset: CGFloat = -80
  @State private var lessonVisible = false
  @State private var linesRevealed = 0

  var body: some View {
    VStack(spacing: 28) {
      header(
        title: "Pick a topic or PDF",
        subtitle: "QuizScroll builds your lesson from it."
      )

      ZStack {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .fill(UnrotTheme.surface)
          .frame(width: 280, height: 200)
          .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
              .stroke(UnrotTheme.cardBorder.opacity(0.6), lineWidth: 1)
          )

        if !lessonVisible {
          VStack(spacing: 10) {
            Image(systemName: "doc.fill")
              .font(.system(size: 52, weight: .semibold))
              .foregroundStyle(UnrotTheme.accent)
            Text("Syllabus.pdf")
              .font(.system(size: 15, weight: .bold, design: .rounded))
              .foregroundStyle(UnrotTheme.textMuted)
          }
          .offset(y: pdfOffset)
          .opacity(pdfVisible ? 1 : 0)
        } else {
          VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
              Image(systemName: "book.fill")
                .foregroundStyle(QuizletTheme.primary)
              Text("Your lesson")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(UnrotTheme.text)
            }

            ForEach(0..<4, id: \.self) { i in
              RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(i < linesRevealed ? QuizletTheme.primary.opacity(0.25) : UnrotTheme.cardBorder.opacity(0.35))
                .frame(height: 10)
                .frame(maxWidth: i == 3 ? 140 : .infinity)
                .opacity(i < linesRevealed ? 1 : 0.35)
            }
          }
          .padding(22)
          .frame(width: 240, alignment: .leading)
          .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
      }
      .frame(height: 220)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 24)
    .padding(.top, 36)
    .onAppear { runSequence() }
  }

  private func runSequence() {
    pdfVisible = false
    pdfOffset = -80
    lessonVisible = false
    linesRevealed = 0

    withAnimation(.easeOut(duration: 0.55)) {
      pdfVisible = true
      pdfOffset = 0
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
      withAnimation(.easeInOut(duration: 0.45)) {
        lessonVisible = true
      }
      for i in 0..<4 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(i) * 0.18) {
          withAnimation(.easeOut(duration: 0.25)) { linesRevealed = i + 1 }
        }
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
        onAnimationComplete?()
      }
    }
  }
}

// MARK: - Jail

struct OnboardingJailAnimation: View {
  var onAnimationComplete: (() -> Void)?

  private struct JailApp: Identifiable {
    let id: String
    let asset: String
    let start: CGSize
    let cell: CGSize
    let size: CGFloat
  }

  private let apps: [JailApp] = [
    .init(id: "ig", asset: "instagram_logo_clean", start: CGSize(width: -130, height: -110), cell: CGSize(width: -42, height: -28), size: 44),
    .init(id: "tt", asset: "tiktok_logo_clean", start: CGSize(width: 125, height: -100), cell: CGSize(width: 42, height: -28), size: 40),
    .init(id: "yt", asset: "youtube_logo_clean", start: CGSize(width: -120, height: 95), cell: CGSize(width: -42, height: 32), size: 48),
    .init(id: "x", asset: "x_logo_clean", start: CGSize(width: 115, height: 105), cell: CGSize(width: 42, height: 32), size: 38),
    .init(id: "sc", asset: "snapchat_logo_clean", start: CGSize(width: 0, height: -125), cell: CGSize(width: 0, height: 2), size: 46),
  ]

  @State private var imprisoned = false
  @State private var barsVisible = false
  @State private var locked = false

  var body: some View {
    VStack(spacing: 28) {
      header(
        title: "Your apps go to jail",
        subtitle: "They stay locked until you read and pass the quiz."
      )

      ZStack {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(UnrotTheme.cardBorder.opacity(0.18))
          .frame(width: 200, height: 150)
          .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .stroke(UnrotTheme.cardBorder.opacity(0.5), lineWidth: 1.5)
          )

        ForEach(apps) { app in
          Image(app.asset)
            .resizable()
            .scaledToFit()
            .frame(width: app.size, height: app.size)
            .offset(imprisoned ? app.cell : app.start)
            .scaleEffect(imprisoned ? 0.72 : 1)
            .rotationEffect(.degrees(imprisoned ? 0 : app.start.width > 0 ? 12 : -10))
        }

        JailBarsOverlay()
          .frame(width: 210, height: 160)
          .opacity(barsVisible ? 1 : 0)
          .scaleEffect(barsVisible ? 1 : 1.04)

        VStack {
          Spacer()
          ZStack {
            Circle()
              .fill(UnrotTheme.danger.opacity(0.15))
              .frame(width: 52, height: 52)
            Image(systemName: "lock.fill")
              .font(.system(size: 24, weight: .bold))
              .foregroundStyle(UnrotTheme.danger)
          }
          .offset(y: locked ? 78 : 58)
          .opacity(locked ? 1 : 0)
        }
        .frame(height: 160)
      }
      .frame(height: 240)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 24)
    .padding(.top, 36)
    .onAppear { runSequence() }
  }

  private func runSequence() {
    imprisoned = false
    barsVisible = false
    locked = false

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
      withAnimation(.spring(response: 0.85, dampingFraction: 0.78)) {
        imprisoned = true
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      withAnimation(.easeOut(duration: 0.35)) {
        barsVisible = true
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
        locked = true
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
      onAnimationComplete?()
    }
  }
}

private struct JailBarsOverlay: View {
  private let barCount = 8

  var body: some View {
    GeometryReader { geo in
      let spacing = geo.size.width / CGFloat(barCount)
      ZStack {
        ForEach(0..<barCount, id: \.self) { i in
          RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(UnrotTheme.text.opacity(0.72))
            .frame(width: 5, height: geo.size.height)
            .position(x: spacing * (CGFloat(i) + 0.5), y: geo.size.height / 2)
        }
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(UnrotTheme.text.opacity(0.85), lineWidth: 4)
      }
    }
  }
}

// MARK: - Quiz

struct OnboardingQuizAnimation: View {
  var onAnimationComplete: (() -> Void)?

  @State private var showQuestion = false
  @State private var selectedOption: Int?
  @State private var showPass = false

  private let options = [
    "Mitochondria power the cell",
    "Photosynthesis uses sunlight",
    "DNA stores genetic code",
    "Neurons send signals",
  ]

  var body: some View {
    VStack(spacing: 24) {
      header(
        title: "Pass the quiz to unlock",
        subtitle: "Answer from what you just read — then scroll."
      )

      VStack(alignment: .leading, spacing: 14) {
        Text("What did section 3 cover?")
          .font(.system(size: 18, weight: .heavy, design: .rounded))
          .foregroundStyle(UnrotTheme.text)
          .opacity(showQuestion ? 1 : 0)
          .offset(y: showQuestion ? 0 : 12)

        VStack(spacing: 8) {
          ForEach(Array(options.enumerated()), id: \.offset) { index, option in
            quizRow(option, index: index)
          }
        }
      }
      .padding(18)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(UnrotTheme.card)
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .stroke(UnrotTheme.cardBorder.opacity(0.55), lineWidth: 1)
      )
      .themeCardShadow()

      if showPass {
        HStack(spacing: 10) {
          Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 28))
            .foregroundStyle(UnrotTheme.success)
          Text("Apps unlocked!")
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .foregroundStyle(UnrotTheme.text)
        }
        .transition(.scale.combined(with: .opacity))
      }

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 24)
    .padding(.top, 36)
    .onAppear { runSequence() }
  }

  @ViewBuilder
  private func quizRow(_ text: String, index: Int) -> some View {
    let isSelected = selectedOption == index
    let isCorrect = index == 2

    HStack {
      Text(text)
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
      Spacer()
      if isSelected && isCorrect {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(UnrotTheme.success)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(isSelected && isCorrect ? UnrotTheme.success.opacity(0.14) : UnrotTheme.surface)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(isSelected && isCorrect ? UnrotTheme.success : UnrotTheme.cardBorder.opacity(0.5), lineWidth: isSelected && isCorrect ? 2 : 1)
    )
    .opacity(showQuestion ? 1 : 0)
    .offset(y: showQuestion ? 0 : 8)
    .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.08), value: showQuestion)
  }

  private func runSequence() {
    showQuestion = false
    selectedOption = nil
    showPass = false

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
      withAnimation(.easeOut(duration: 0.4)) { showQuestion = true }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
      withAnimation(.easeInOut(duration: 0.25)) { selectedOption = 2 }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
      withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { showPass = true }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
      onAnimationComplete?()
    }
  }
}

// MARK: - Win-win

struct OnboardingWinWinAnimation: View {
  var onAnimationComplete: (() -> Void)?

  @State private var topVisible = false
  @State private var bottomVisible = false
  @State private var centerVisible = false

  var body: some View {
    VStack(spacing: 22) {
      header(
        title: "Both paths win",
        subtitle: "Scroll less — or still scroll and learn. QuizScroll works either way."
      )

      VStack(spacing: 16) {
        winPathCard(
          icon: "hourglass.bottomhalf.fill",
          title: "Scroll less",
          detail: "Cut doomscrolling and reclaim your time.",
          color: UnrotTheme.accent,
          visible: topVisible
        )
        winPathCard(
          icon: "brain.head.profile",
          title: "Still scroll",
          detail: "Keep scrolling, but absorb hundreds of new facts.",
          color: QuizletTheme.primary,
          visible: bottomVisible
        )
      }

      Image("brain_character")
        .resizable()
        .scaledToFit()
        .frame(height: 88)
        .opacity(centerVisible ? 1 : 0)
        .scaleEffect(centerVisible ? 1 : 0.85)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 20)
    .padding(.top, 28)
    .onAppear { runSequence() }
  }

  private func winPathCard(icon: String, title: String, detail: String, color: Color, visible: Bool) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 32, weight: .semibold))
        .foregroundStyle(color)
      Text(title)
        .font(.system(size: 24, weight: .heavy, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
      Text(detail)
        .font(.system(size: 16, weight: .medium, design: .rounded))
        .foregroundStyle(UnrotTheme.textMuted)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 22)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(UnrotTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .stroke(color.opacity(0.45), lineWidth: 1.5)
    )
    .themeCardShadow()
    .opacity(visible ? 1 : 0)
    .offset(y: visible ? 0 : 20)
  }

  private func runSequence() {
    topVisible = false
    bottomVisible = false
    centerVisible = false

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      withAnimation(.easeOut(duration: 0.45)) { topVisible = true }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
      withAnimation(.easeOut(duration: 0.45)) { bottomVisible = true }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { centerVisible = true }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
      onAnimationComplete?()
    }
  }
}

// MARK: - Shared header

private func header(title: String, subtitle: String) -> some View {
  VStack(spacing: 8) {
    Text(title)
      .font(.system(size: 28, weight: .black, design: .rounded))
      .foregroundStyle(UnrotTheme.text)
      .multilineTextAlignment(.center)
    Text(subtitle)
      .font(.system(size: 16, weight: .medium, design: .rounded))
      .foregroundStyle(UnrotTheme.textMuted)
      .multilineTextAlignment(.center)
      .fixedSize(horizontal: false, vertical: true)
  }
  .frame(maxWidth: .infinity)
}
