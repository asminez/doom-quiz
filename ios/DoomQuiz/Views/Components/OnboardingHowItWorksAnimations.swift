import SwiftUI

// MARK: - Topic / PDF

struct OnboardingTopicAnimation: View {
  var onAnimationComplete: (() -> Void)?

  @State private var topicText = ""
  @State private var showLesson = false
  @State private var startButtonHighlighted = false
  @State private var revealedWordCount = 0

  private let demoTopic = "Spanish"
  private let quickTopics = ["Spanish", "French", "Python", "Calculus"]
  private let sampleSectionBody =
    "Spanish has over 500 million speakers worldwide. Start with everyday greetings: "
    + "hola means hello, buenos días is good morning, and gracias means thank you. "
    + "These phrases work in almost any conversation you'll have."

  var body: some View {
    VStack(spacing: 20) {
      header(
        title: "Pick a topic or PDF",
        subtitle: "QuizScroll builds your lesson from it, just like the Study tab."
      )

      Group {
        if showLesson {
          lessonPreviewCard
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
          topicPickerCard
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
      }
      .frame(maxWidth: .infinity)
      .frame(minHeight: 380)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 20)
    .padding(.top, 24)
    .onAppear { runSequence() }
  }

  private var topicPickerCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      Label("Learn or improve", systemImage: "sparkles")
        .font(.system(size: 14, weight: .heavy, design: .rounded))
        .foregroundStyle(QuizletTheme.primary)

      StudyInputField(
        placeholder: "Enter the topic you want to learn",
        text: $topicText,
        axis: .vertical,
        lineLimit: 2...3
      )
      .allowsHitTesting(false)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(quickTopics, id: \.self) { idea in
            Text(idea)
              .font(.system(size: 13, weight: .semibold, design: .rounded))
              .foregroundStyle(topicText == idea ? .white : QuizletTheme.primary)
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(topicText == idea ? QuizletTheme.primary : QuizletTheme.primarySoft)
              .clipShape(Capsule())
          }
        }
      }

      Text("Start lesson")
        .font(.system(size: 16, weight: .heavy, design: .rounded))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(QuizletTheme.primary.opacity(startButtonHighlighted ? 1 : 0.45))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .scaleEffect(startButtonHighlighted ? 1.02 : 1)
        .animation(.easeInOut(duration: 0.25), value: startButtonHighlighted)

      syllabusPreviewRow
    }
    .padding(20)
    .background(
      LinearGradient(
        colors: [QuizletTheme.primarySoft.opacity(0.65), QuizletTheme.card],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(QuizletTheme.primary.opacity(0.28), lineWidth: 1.5)
    )
    .themeCardShadow(elevated: true)
  }

  private var syllabusPreviewRow: some View {
    HStack(spacing: 12) {
      Image(systemName: "doc.fill")
        .font(.title3.weight(.semibold))
        .foregroundStyle(QuizletTheme.primary)
        .frame(width: 44, height: 44)
        .background(QuizletTheme.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

      VStack(alignment: .leading, spacing: 3) {
        HStack(spacing: 6) {
          Text("Syllabus")
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(QuizletTheme.text)
          Text("Premium")
            .font(.caption2.weight(.bold))
            .foregroundStyle(QuizletTheme.textMuted)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(QuizletTheme.inputBg)
            .clipShape(Capsule())
        }
        Text("Upload PDF (lecture notes or syllabus)")
          .font(.system(size: 12, weight: .medium, design: .rounded))
          .foregroundStyle(QuizletTheme.textMuted)
          .lineLimit(1)
      }

      Spacer(minLength: 4)

      Image(systemName: "chevron.right")
        .font(.caption.weight(.bold))
        .foregroundStyle(QuizletTheme.textMuted)
    }
    .padding(.top, 4)
  }

  private var sampleWords: [Substring] {
    sampleSectionBody.split(separator: " ")
  }

  private var displayedSectionBody: String {
    sampleWords.prefix(revealedWordCount).joined(separator: " ")
  }

  private var lessonPreviewCard: some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 5) {
          Text(demoTopic)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(QuizletTheme.text)
          Text("Section 1 of 8 · Greetings")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(QuizletTheme.textMuted)
        }
        Spacer(minLength: 8)
        VStack(spacing: 3) {
          Text("0/8")
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(QuizletTheme.primary)
          Text("sections")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(QuizletTheme.textMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(QuizletTheme.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }

      HStack(spacing: 5) {
        ForEach(0..<8, id: \.self) { index in
          Capsule()
            .fill(index == 0 ? QuizletTheme.primary : QuizletTheme.border)
            .frame(height: 8)
        }
      }

      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 8) {
          Image(systemName: "text.alignleft")
            .font(.caption.weight(.bold))
            .foregroundStyle(QuizletTheme.primary)
          Text("Greetings")
            .font(.system(size: 13, weight: .heavy, design: .rounded))
            .foregroundStyle(QuizletTheme.primary)
        }

        Text(displayedSectionBody)
          .font(.system(size: 16, weight: .regular, design: .rounded))
          .foregroundStyle(QuizletTheme.text)
          .lineSpacing(6)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(18)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        LinearGradient(
          colors: [QuizletTheme.card, QuizletTheme.primarySoft.opacity(0.25)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .stroke(QuizletTheme.primary.opacity(0.35), lineWidth: 1.5)
      )

      Label("Take section quiz", systemImage: "checkmark.circle.fill")
        .font(.system(size: 15, weight: .heavy, design: .rounded))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(QuizletTheme.primary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    .padding(20)
    .background(QuizletTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(QuizletTheme.border.opacity(0.55), lineWidth: 1)
    )
    .themeCardShadow(elevated: true)
  }

  private func runSequence() {
    topicText = ""
    showLesson = false
    startButtonHighlighted = false
    revealedWordCount = 0

    let chars = Array(demoTopic)
    for (index, char) in chars.enumerated() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.45 + Double(index) * 0.07) {
        topicText.append(char)
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45 + Double(chars.count) * 0.07 + 0.35) {
      startButtonHighlighted = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      withAnimation(.easeInOut(duration: 0.5)) {
        showLesson = true
      }
      let totalWords = sampleWords.count
      for i in 1...totalWords {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12 + Double(i) * 0.05) {
          revealedWordCount = i
        }
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.12 + Double(totalWords) * 0.05 + 0.5) {
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

  private static let cellSize = CGSize(width: 260, height: 200)
  private static let cellCorner: CGFloat = 20

  @State private var imprisoned = false
  @State private var barsDropped = false
  @State private var slamImpact = false

  var body: some View {
    VStack(spacing: 28) {
      header(
        title: "Your apps go to jail",
        subtitle: "They stay locked until you read and pass the quiz."
      )

      ZStack {
        RoundedRectangle(cornerRadius: Self.cellCorner, style: .continuous)
          .fill(UnrotTheme.cardBorder.opacity(0.18))
          .overlay(
            RoundedRectangle(cornerRadius: Self.cellCorner, style: .continuous)
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

        // The gate slides down into the opening, so it is clipped to the cell.
        JailBarsOverlay()
          .offset(y: barsDropped ? 0 : -(Self.cellSize.height + 30))
          .clipShape(RoundedRectangle(cornerRadius: Self.cellCorner, style: .continuous))
      }
      .frame(width: Self.cellSize.width, height: Self.cellSize.height)
      .scaleEffect(x: slamImpact ? 1.015 : 1, y: slamImpact ? 0.985 : 1, anchor: .bottom)

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 24)
    .padding(.top, 36)
    .onAppear { runSequence() }
  }

  private func runSequence() {
    imprisoned = false
    barsDropped = false
    slamImpact = false

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
      withAnimation(.spring(response: 0.85, dampingFraction: 0.78)) {
        imprisoned = true
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      withAnimation(.interpolatingSpring(stiffness: 220, damping: 16)) {
        barsDropped = true
      }
    }

    // Squash on the frame the moment the gate lands, then settle.
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.78) {
      withAnimation(.easeOut(duration: 0.07)) { slamImpact = true }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { slamImpact = false }
      }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
      onAnimationComplete?()
    }
  }
}

private struct JailBarsOverlay: View {
  private let barCount = 8
  private let barWidth: CGFloat = 8
  private let railHeight: CGFloat = 12
  private let inset: CGFloat = 16

  /// Stops that read as a rounded steel rod: dark at both edges with a bright
  /// specular stripe just off-centre.
  private var steelStops: [Gradient.Stop] {
    [
      .init(color: UnrotTheme.text.opacity(0.55), location: 0.0),
      .init(color: UnrotTheme.text.opacity(0.95), location: 0.2),
      .init(color: Color.white.opacity(0.75), location: 0.36),
      .init(color: UnrotTheme.text.opacity(0.95), location: 0.6),
      .init(color: UnrotTheme.text.opacity(0.5), location: 1.0),
    ]
  }

  private var steelAcross: LinearGradient {
    LinearGradient(stops: steelStops, startPoint: .leading, endPoint: .trailing)
  }

  private var steelDown: LinearGradient {
    LinearGradient(stops: steelStops, startPoint: .top, endPoint: .bottom)
  }

  var body: some View {
    GeometryReader { geo in
      let w = geo.size.width
      let h = geo.size.height
      let usableWidth = w - inset * 2
      let gap = usableWidth / CGFloat(barCount - 1)
      let topRailY = h * 0.15
      let bottomRailY = h * 0.85
      let barXs = (0..<barCount).map { inset + gap * CGFloat($0) }

      ZStack {
        ForEach(Array(barXs.enumerated()), id: \.offset) { _, x in
          RoundedRectangle(cornerRadius: barWidth / 3, style: .continuous)
            .fill(steelAcross)
            .frame(width: barWidth, height: h - inset)
            .shadow(color: .black.opacity(0.35), radius: 4, x: 2, y: 1)
            .position(x: x, y: h / 2)
        }

        ForEach([topRailY, bottomRailY], id: \.self) { y in
          RoundedRectangle(cornerRadius: railHeight / 3, style: .continuous)
            .fill(steelDown)
            .frame(width: usableWidth + barWidth, height: railHeight)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            .position(x: w / 2, y: y)
        }

        // Rivets where every bar meets a rail.
        ForEach(Array(barXs.enumerated()), id: \.offset) { _, x in
          ForEach([topRailY, bottomRailY], id: \.self) { y in
            Circle()
              .fill(UnrotTheme.bg.opacity(0.55))
              .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
              .frame(width: 3.5, height: 3.5)
              .position(x: x, y: y)
          }
        }

        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(steelAcross, lineWidth: 6)
          .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
          .padding(inset / 2)
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

  private let correctIndex = 0

  private let options = [
    "Buenos días",
    "Buenas noches",
    "Por favor",
    "Gracias",
  ]

  var body: some View {
    VStack(spacing: 24) {
      header(
        title: "Pass the quiz to unlock",
        subtitle: "Answer from what you just read, then scroll."
      )

      VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 8) {
          Image(systemName: "character.book.closed.fill")
            .font(.caption.weight(.bold))
            .foregroundStyle(QuizletTheme.primary)
          Text("Spanish · Section 1")
            .font(.system(size: 12, weight: .heavy, design: .rounded))
            .foregroundStyle(QuizletTheme.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(QuizletTheme.primarySoft)
            .clipShape(Capsule())
          Spacer()
          Text("1/6")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(UnrotTheme.textMuted)
        }
        .opacity(showQuestion ? 1 : 0)

        Text("How do you greet someone in the morning?")
          .font(.system(size: 20, weight: .heavy, design: .rounded))
          .foregroundStyle(UnrotTheme.text)
          .fixedSize(horizontal: false, vertical: true)
          .opacity(showQuestion ? 1 : 0)
          .offset(y: showQuestion ? 0 : 12)

        VStack(spacing: 10) {
          ForEach(Array(options.enumerated()), id: \.offset) { index, option in
            quizRow(option, index: index)
          }
        }
      }
      .padding(22)
      .frame(maxWidth: .infinity, minHeight: 320, alignment: .topLeading)
      .background(UnrotTheme.card)
      .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 22, style: .continuous)
          .stroke(QuizletTheme.primary.opacity(showPass ? 0.35 : 0.12), lineWidth: 1.5)
      )
      .themeCardShadow()

      if showPass {
        HStack(spacing: 10) {
          Image(systemName: "checkmark.seal.fill")
            .font(.system(size: 22))
            .foregroundStyle(UnrotTheme.success)
          Text("Apps unlocked. Scroll until time runs out.")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(UnrotTheme.text)
            .fixedSize(horizontal: false, vertical: true)
          Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
          LinearGradient(
            colors: [UnrotTheme.success.opacity(0.1), UnrotTheme.card],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(UnrotTheme.success.opacity(0.25), lineWidth: 1)
        )
        .themeCardShadow()
        .transition(.scale(scale: 0.96).combined(with: .opacity))
      }

      Spacer(minLength: 0)
    }
    .padding(.horizontal, 20)
    .padding(.top, 24)
    .onAppear { runSequence() }
  }

  @ViewBuilder
  private func quizRow(_ text: String, index: Int) -> some View {
    let isSelected = selectedOption == index
    let isCorrect = index == correctIndex

    HStack {
      Text(text)
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
        .fixedSize(horizontal: false, vertical: true)
      Spacer()
      if isSelected && isCorrect {
        Image(systemName: "checkmark.circle.fill")
          .font(.title3)
          .foregroundStyle(UnrotTheme.success)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 15)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(isSelected && isCorrect ? UnrotTheme.success.opacity(0.14) : UnrotTheme.surface)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
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

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      withAnimation(.easeInOut(duration: 0.25)) { selectedOption = correctIndex }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
      withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) { showPass = true }
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
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
        subtitle: "Scroll less, or still scroll and learn. QuizScroll works either way."
      )

      VStack(spacing: 18) {
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
      .frame(minHeight: 340)

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
    VStack(alignment: .leading, spacing: 14) {
      Image(systemName: icon)
        .font(.system(size: 36, weight: .semibold))
        .foregroundStyle(color)
      Text(title)
        .font(.system(size: 26, weight: .heavy, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
      Text(detail)
        .font(.system(size: 17, weight: .medium, design: .rounded))
        .foregroundStyle(UnrotTheme.textMuted)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, 22)
    .padding(.vertical, 28)
    .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
    .background(UnrotTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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
