import SwiftUI

@main
struct DoomQuizApp: App {
  @StateObject private var appState = AppState()
  @StateObject private var themeStore = ThemeStore()

  var body: some Scene {
    WindowGroup {
      MainTabView()
        .environmentObject(appState)
        .environmentObject(themeStore)
        .preferredColorScheme(themeStore.preferredColorScheme)
        .prefersHiddenStatusBar()
    }
  }
}
