import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
  case system
  case light
  case dark

  var id: String { rawValue }

  var label: String {
    switch self {
    case .system: return "System"
    case .light: return "Light"
    case .dark: return "Dark"
    }
  }
}

@MainActor
final class ThemeStore: ObservableObject {
  @AppStorage("doomquiz.appearance.mode") private var modeRaw = AppearanceMode.system.rawValue
  @Published var mode: AppearanceMode = .system {
    didSet { modeRaw = mode.rawValue }
  }

  init() {
    mode = AppearanceMode(rawValue: modeRaw) ?? .system
  }

  var preferredColorScheme: ColorScheme? {
    switch mode {
    case .system: return nil
    case .light: return .light
    case .dark: return .dark
    }
  }
}

enum UnrotTheme {
  static let bg = dynamic(
    light: UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1),
    dark: UIColor(red: 0.04, green: 0.04, blue: 0.043, alpha: 1)
  )
  static let surface = dynamic(
    light: UIColor(red: 0.92, green: 0.93, blue: 0.96, alpha: 1),
    dark: UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1)
  )
  static let card = dynamic(
    light: UIColor.white,
    dark: UIColor(red: 0.11, green: 0.11, blue: 0.125, alpha: 1)
  )
  static let cardBorder = dynamic(
    light: UIColor(red: 0.78, green: 0.81, blue: 0.88, alpha: 1),
    dark: UIColor(red: 0.16, green: 0.16, blue: 0.19, alpha: 1)
  )
  static let text = dynamic(
    light: UIColor(red: 0.09, green: 0.10, blue: 0.14, alpha: 1),
    dark: UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)
  )
  static let textMuted = dynamic(
    light: UIColor(red: 0.34, green: 0.37, blue: 0.44, alpha: 1),
    dark: UIColor(red: 0.61, green: 0.64, blue: 0.69, alpha: 1)
  )
  static let accent = dynamic(
    light: UIColor(red: 0.88, green: 0.34, blue: 0.20, alpha: 1),
    dark: UIColor(red: 1.0, green: 0.42, blue: 0.29, alpha: 1)
  )
  static let accentSoft = dynamic(
    light: UIColor(red: 0.88, green: 0.34, blue: 0.20, alpha: 0.14),
    dark: UIColor(red: 1.0, green: 0.42, blue: 0.29, alpha: 0.15)
  )
  static let danger = dynamic(
    light: UIColor(red: 0.82, green: 0.26, blue: 0.26, alpha: 1),
    dark: UIColor(red: 0.97, green: 0.44, blue: 0.44, alpha: 1)
  )
  static let ringTrack = dynamic(
    light: UIColor(red: 0.84, green: 0.86, blue: 0.90, alpha: 1),
    dark: UIColor(red: 0.16, green: 0.16, blue: 0.19, alpha: 1)
  )
  static let success = dynamic(
    light: UIColor(red: 0.06, green: 0.54, blue: 0.34, alpha: 1),
    dark: UIColor(red: 0.14, green: 0.79, blue: 0.45, alpha: 1)
  )
  static let shadow = dynamic(
    light: UIColor(white: 0, alpha: 0.10),
    dark: UIColor(white: 0, alpha: 0.28)
  )
  static let shadowStrong = dynamic(
    light: UIColor(white: 0, alpha: 0.14),
    dark: UIColor(white: 0, alpha: 0.42)
  )
}

enum QuizletTheme {
  static let bg = UnrotTheme.bg
  static let card = UnrotTheme.card
  static let inputBg = UnrotTheme.surface
  static let primary = dynamic(
    light: UIColor(red: 0.07, green: 0.44, blue: 0.84, alpha: 1),
    dark: UIColor(red: 0.13, green: 0.53, blue: 0.98, alpha: 1)
  )
  static let primarySoft = dynamic(
    light: UIColor(red: 0.07, green: 0.44, blue: 0.84, alpha: 0.14),
    dark: UIColor(red: 0.13, green: 0.53, blue: 0.98, alpha: 0.12)
  )
  static let text = UnrotTheme.text
  static let textMuted = UnrotTheme.textMuted
  static let correct = dynamic(
    light: UIColor(red: 0.05, green: 0.52, blue: 0.32, alpha: 1),
    dark: UIColor(red: 0.14, green: 0.7, blue: 0.43, alpha: 1)
  )
  static let wrong = dynamic(
    light: UIColor(red: 0.84, green: 0.30, blue: 0.22, alpha: 1),
    dark: UIColor(red: 1.0, green: 0.45, blue: 0.36, alpha: 1)
  )
  static let border = UnrotTheme.cardBorder
}

extension View {
  /// Soft elevation for cards — stronger in light mode so UI reads off the background.
  func themeCardShadow(elevated: Bool = false) -> some View {
    shadow(
      color: elevated ? UnrotTheme.shadowStrong : UnrotTheme.shadow,
      radius: elevated ? 14 : 10,
      x: 0,
      y: elevated ? 6 : 4
    )
  }
}

private func dynamic(light: UIColor, dark: UIColor) -> Color {
  Color(UIColor { trait in
    trait.userInterfaceStyle == .dark ? dark : light
  })
}
