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
  static let bg = dynamic(light: UIColor(red: 0.97, green: 0.97, blue: 0.985, alpha: 1), dark: UIColor(red: 0.04, green: 0.04, blue: 0.043, alpha: 1))
  static let surface = dynamic(light: UIColor(red: 0.94, green: 0.95, blue: 0.98, alpha: 1), dark: UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1))
  static let card = dynamic(light: UIColor.white, dark: UIColor(red: 0.11, green: 0.11, blue: 0.125, alpha: 1))
  static let cardBorder = dynamic(light: UIColor(red: 0.86, green: 0.88, blue: 0.93, alpha: 1), dark: UIColor(red: 0.16, green: 0.16, blue: 0.19, alpha: 1))
  static let text = dynamic(light: UIColor(red: 0.12, green: 0.12, blue: 0.16, alpha: 1), dark: UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1))
  static let textMuted = dynamic(light: UIColor(red: 0.42, green: 0.45, blue: 0.53, alpha: 1), dark: UIColor(red: 0.61, green: 0.64, blue: 0.69, alpha: 1))
  static let accent = Color(red: 1, green: 0.42, blue: 0.29)
  static let accentSoft = Color(red: 1, green: 0.42, blue: 0.29, opacity: 0.15)
  static let danger = Color(red: 0.97, green: 0.44, blue: 0.44)
  static let ringTrack = dynamic(light: UIColor(red: 0.88, green: 0.89, blue: 0.93, alpha: 1), dark: UIColor(red: 0.16, green: 0.16, blue: 0.19, alpha: 1))
  static let success = Color(red: 0.14, green: 0.79, blue: 0.45)
}

enum QuizletTheme {
  static let bg = UnrotTheme.bg
  static let card = UnrotTheme.card
  static let primary = Color(red: 0.13, green: 0.53, blue: 0.98)
  static let primarySoft = Color(red: 0.13, green: 0.53, blue: 0.98, opacity: 0.12)
  static let text = UnrotTheme.text
  static let textMuted = UnrotTheme.textMuted
  static let correct = Color(red: 0.14, green: 0.7, blue: 0.43)
  static let wrong = Color(red: 1, green: 0.45, blue: 0.36)
  static let border = UnrotTheme.cardBorder
}

private func dynamic(light: UIColor, dark: UIColor) -> Color {
  Color(UIColor { trait in
    trait.userInterfaceStyle == .dark ? dark : light
  })
}
