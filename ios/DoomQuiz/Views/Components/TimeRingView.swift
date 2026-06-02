import SwiftUI

struct TimeRingView: View {
  let remaining: Int
  let total: Int
  var size: CGFloat = 168

  private var progress: Double {
    guard total > 0 else { return 0 }
    return min(1, Double(remaining) / Double(total))
  }

  var body: some View {
    ZStack {
      Circle().stroke(UnrotTheme.ringTrack, lineWidth: 10).frame(width: size, height: size)
      Circle()
        .trim(from: 0, to: progress)
        .stroke(progress > 0.2 ? UnrotTheme.accent : UnrotTheme.danger, style: StrokeStyle(lineWidth: 10, lineCap: .round))
        .frame(width: size, height: size)
        .rotationEffect(.degrees(-90))
      VStack(spacing: 2) {
        Text("\(remaining)").font(.system(size: 44, weight: .heavy, design: .rounded)).foregroundStyle(UnrotTheme.text)
        Text("min left").font(.subheadline).foregroundStyle(UnrotTheme.textMuted)
      }
    }
  }
}
