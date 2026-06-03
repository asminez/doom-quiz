import SwiftUI

/// Small bottom bar — current lesson title + section progress; tap to resume.
struct CompressedLessonCard: View {
  let deck: StudyDeck
  let onResume: () -> Void

  private var mastered: Int { deck.masteredParagraphIds.count }
  private var total: Int { LessonContentAmount.sectionCount }
  private var progress: Double {
    guard deck.isAIGenerated else {
      guard !deck.paragraphs.isEmpty else { return 0 }
      return Double(mastered) / Double(deck.paragraphs.count)
    }
    return Double(mastered) / Double(total)
  }

  var body: some View {
    Button(action: onResume) {
      HStack(spacing: 12) {
        sectionProgressRing

        VStack(alignment: .leading, spacing: 3) {
          Text("Current lesson")
            .font(.caption2.weight(.bold))
            .foregroundStyle(QuizletTheme.textMuted)
            .textCase(.uppercase)

          Text(deck.title)
            .font(.subheadline.weight(.heavy))
            .foregroundStyle(QuizletTheme.text)
            .lineLimit(1)

          Text(progressCaption)
            .font(.caption.weight(.semibold))
            .foregroundStyle(
              deck.allSectionsMastered ? QuizletTheme.correct : QuizletTheme.textMuted
            )
        }

        Spacer(minLength: 4)

        VStack(spacing: 2) {
          Text("Resume")
            .font(.caption.weight(.bold))
            .foregroundStyle(QuizletTheme.primary)
          Image(systemName: "chevron.up")
            .font(.caption2.weight(.bold))
            .foregroundStyle(QuizletTheme.primary)
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
      .background(QuizletTheme.card)
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .stroke(QuizletTheme.primary.opacity(0.4), lineWidth: 1.5)
      )
      .themeCardShadow(elevated: true)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var sectionProgressRing: some View {
    if deck.isAIGenerated {
      ZStack {
        Circle()
          .stroke(QuizletTheme.border, lineWidth: 4)
        Circle()
          .trim(from: 0, to: progress)
          .stroke(
            deck.allSectionsMastered ? QuizletTheme.correct : QuizletTheme.primary,
            style: StrokeStyle(lineWidth: 4, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))
        Text("\(mastered)/\(total)")
          .font(.system(size: 10, weight: .heavy, design: .rounded))
          .foregroundStyle(QuizletTheme.text)
      }
      .frame(width: 44, height: 44)
    } else {
      ZStack {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(QuizletTheme.primarySoft)
          .frame(width: 44, height: 44)
        Image(systemName: deck.source == "manual" ? "square.stack.fill" : "book.fill")
          .font(.body.weight(.semibold))
          .foregroundStyle(QuizletTheme.primary)
      }
    }
  }

  private var progressCaption: String {
    if deck.isAIGenerated {
      if deck.allSectionsMastered { return "All sections passed" }
      return "\(mastered) of \(total) sections passed"
    }
    if deck.source == "manual" {
      return "\(deck.points.count) cards · \(deck.questions.count) questions"
    }
    return sourceLabel
  }

  private var sourceLabel: String {
    switch deck.source {
    case "syllabus": return "From syllabus"
    case "manual": return "Custom quiz"
    default: return "AI topic lesson"
    }
  }
}
