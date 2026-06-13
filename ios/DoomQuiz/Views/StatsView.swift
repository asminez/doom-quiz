import Charts
import SwiftUI

struct StatsView: View {
  @EnvironmentObject private var appState: AppState

  private var weeklyData: [DailyActivityRecord] { appState.weeklyActivity }
  private var weekStudyTotal: Int { weeklyData.reduce(0) { $0 + $1.studyMinutes } }
  private var weekScrollTotal: Int { weeklyData.reduce(0) { $0 + $1.scrollMinutes } }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          header
          masteredHeroCard
          weekChartCard
          masteredContentsSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 32)
      }
      .background(UnrotTheme.bg)
      .navigationBarHidden(true)
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Stats")
        .font(.system(size: 29, weight: .black, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
      Text("Learning vs scrolling, at a glance")
        .font(.system(size: 14, weight: .regular, design: .rounded))
        .foregroundStyle(UnrotTheme.textMuted)
    }
  }

  private var masteredHeroCard: some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 6) {
        Label("Contents mastered", systemImage: "checkmark.seal.fill")
          .font(.system(size: 13, weight: .bold, design: .rounded))
          .foregroundStyle(QuizletTheme.correct)

        Text("\(appState.totalSectionsMastered)")
          .font(.system(size: 48, weight: .heavy, design: .rounded))
          .foregroundStyle(UnrotTheme.text)
          .contentTransition(.numericText())

        Text(masteredHeroSubtitle)
          .font(.system(size: 14, weight: .medium, design: .rounded))
          .foregroundStyle(UnrotTheme.textMuted)
      }

      Spacer(minLength: 12)

      ZStack {
        Circle()
          .stroke(UnrotTheme.ringTrack, lineWidth: 10)
          .frame(width: 88, height: 88)
        Circle()
          .trim(from: 0, to: masteredProgress)
          .stroke(
            AngularGradient(
              colors: [QuizletTheme.primary, QuizletTheme.correct],
              center: .center
            ),
            style: StrokeStyle(lineWidth: 10, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))
          .frame(width: 88, height: 88)
        VStack(spacing: 0) {
          Text("\(Int(masteredProgress * 100))%")
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundStyle(UnrotTheme.text)
          Text("done")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(UnrotTheme.textMuted)
        }
      }
    }
    .padding(20)
    .background(
      LinearGradient(
        colors: [QuizletTheme.primarySoft.opacity(0.7), UnrotTheme.card],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(QuizletTheme.primary.opacity(0.2), lineWidth: 1)
    )
    .themeCardShadow(elevated: true)
  }

  private var masteredHeroSubtitle: String {
    let deckCount = appState.snapshot.decks.count
    if deckCount == 0 { return "Start a lesson to track progress" }
    if deckCount == 1 { return "Across 1 lesson" }
    return "Across \(deckCount) lessons"
  }

  private var masteredProgress: Double {
    let mastered = appState.totalSectionsMastered
    let total = appState.snapshot.decks.reduce(0) { partial, deck in
      let expected = deck.isAIGenerated ? LessonContentAmount.sectionCount : max(deck.paragraphs.count, 1)
      return partial + expected
    }
    guard total > 0 else { return 0 }
    return min(1, Double(mastered) / Double(total))
  }

  private var weekChartCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Text("This week")
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundStyle(UnrotTheme.text)
          Text("Minutes per day")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(UnrotTheme.textMuted)
        }
        Spacer()
        chartLegend
      }

      HStack(spacing: 10) {
        weekPill(
          value: weekStudyTotal,
          label: "Learning",
          color: QuizletTheme.primary,
          icon: "book.fill"
        )
        weekPill(
          value: weekScrollTotal,
          label: "Scrolling",
          color: UnrotTheme.accent,
          icon: "iphone"
        )
      }

      WeeklyActivityChart(records: weeklyData)
        .frame(height: 210)
        .padding(.top, 4)
    }
    .padding(18)
    .background(UnrotTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(UnrotTheme.cardBorder.opacity(0.5), lineWidth: 1)
    )
    .themeCardShadow()
  }

  private var chartLegend: some View {
    HStack(spacing: 12) {
      legendDot(color: QuizletTheme.primary, label: "Learning")
      legendDot(color: UnrotTheme.accent, label: "Scrolling")
    }
  }

  private func legendDot(color: Color, label: String) -> some View {
    HStack(spacing: 5) {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)
      Text(label)
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundStyle(UnrotTheme.textMuted)
    }
  }

  private func weekPill(value: Int, label: String, color: Color, icon: String) -> some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .font(.system(size: 13, weight: .bold))
        .foregroundStyle(color)
        .frame(width: 32, height: 32)
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

      VStack(alignment: .leading, spacing: 1) {
        Text("\(value)m")
          .font(.system(size: 17, weight: .heavy, design: .rounded))
          .foregroundStyle(UnrotTheme.text)
        Text(label)
          .font(.system(size: 11, weight: .semibold, design: .rounded))
          .foregroundStyle(UnrotTheme.textMuted)
      }
      Spacer(minLength: 0)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(UnrotTheme.surface.opacity(0.65))
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }

  @ViewBuilder
  private var masteredContentsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Mastered")
        .font(.system(size: 18, weight: .heavy, design: .rounded))
        .foregroundStyle(UnrotTheme.text)

      if appState.masteredContentItems.isEmpty {
        emptyMasteredCard
      } else {
        VStack(spacing: 8) {
          ForEach(appState.masteredContentItems) { item in
            masteredRow(item)
          }
        }
      }
    }
  }

  private var emptyMasteredCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: "text.book.closed")
        .font(.title2.weight(.semibold))
        .foregroundStyle(QuizletTheme.primary.opacity(0.8))
      Text("No sections mastered yet")
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
      Text("Pass a section quiz with a perfect score to master it.")
        .font(.system(size: 13, weight: .regular, design: .rounded))
        .foregroundStyle(UnrotTheme.textMuted)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(UnrotTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(UnrotTheme.cardBorder.opacity(0.5), lineWidth: 1)
    )
    .themeCardShadow()
  }

  private func masteredRow(_ item: AppState.MasteredContentItem) -> some View {
    HStack(spacing: 12) {
      Image(systemName: "checkmark.circle.fill")
        .font(.title3)
        .foregroundStyle(QuizletTheme.correct)

      VStack(alignment: .leading, spacing: 2) {
        Text(item.sectionLabel)
          .font(.system(size: 15, weight: .semibold, design: .rounded))
          .foregroundStyle(UnrotTheme.text)
          .lineLimit(1)
        Text(item.deckTitle)
          .font(.system(size: 12, weight: .medium, design: .rounded))
          .foregroundStyle(UnrotTheme.textMuted)
          .lineLimit(1)
      }

      Spacer(minLength: 0)
    }
    .padding(14)
    .background(UnrotTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(UnrotTheme.cardBorder.opacity(0.45), lineWidth: 1)
    )
    .themeCardShadow()
  }
}

// MARK: - Chart

private struct WeeklyActivityChart: View {
  let records: [DailyActivityRecord]

  private struct ChartPoint: Identifiable {
    let id: String
    let day: Date
    let series: String
    let minutes: Int
  }

  private var points: [ChartPoint] {
    records.flatMap { record -> [ChartPoint] in
      guard let day = Self.parseDate(record.date) else { return [] }
      return [
        ChartPoint(id: "\(record.date)-study", day: day, series: "Learning", minutes: record.studyMinutes),
        ChartPoint(id: "\(record.date)-scroll", day: day, series: "Scrolling", minutes: record.scrollMinutes),
      ]
    }
  }

  private var yMax: Int {
    max(points.map(\.minutes).max() ?? 0, 15)
  }

  var body: some View {
    Chart(points) { point in
      AreaMark(
        x: .value("Day", point.day, unit: .day),
        y: .value("Minutes", point.minutes)
      )
      .foregroundStyle(by: .value("Series", point.series))
      .interpolationMethod(.catmullRom)
      .opacity(0.18)

      LineMark(
        x: .value("Day", point.day, unit: .day),
        y: .value("Minutes", point.minutes)
      )
      .foregroundStyle(by: .value("Series", point.series))
      .interpolationMethod(.catmullRom)
      .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

      PointMark(
        x: .value("Day", point.day, unit: .day),
        y: .value("Minutes", point.minutes)
      )
      .foregroundStyle(by: .value("Series", point.series))
      .symbolSize(point.minutes > 0 ? 36 : 0)
    }
    .chartForegroundStyleScale([
      "Learning": QuizletTheme.primary,
      "Scrolling": UnrotTheme.accent,
    ])
    .chartLegend(.hidden)
    .chartYScale(domain: 0...Double(yMax))
    .chartYAxis {
      AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
          .foregroundStyle(UnrotTheme.cardBorder.opacity(0.6))
        AxisValueLabel {
          if let minutes = value.as(Int.self) {
            Text("\(minutes)m")
              .font(.system(size: 10, weight: .medium, design: .rounded))
              .foregroundStyle(UnrotTheme.textMuted)
          }
        }
      }
    }
    .chartXAxis {
      AxisMarks(values: .stride(by: .day)) { value in
        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
          .font(.system(size: 10, weight: .semibold, design: .rounded))
          .foregroundStyle(UnrotTheme.textMuted)
      }
    }
  }

  private static func parseDate(_ key: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = .current
    return formatter.date(from: key)
  }
}
