import SwiftUI

enum AppTab: Int {
  case focus = 0
  case study = 1
  case settings = 2
}

struct MainTabView: View {
  @EnvironmentObject private var appState: AppState
  @State private var selectedTab = AppTab.focus.rawValue
  /// Blocks tab-bar tap-through right after onboarding dismisses.
  @State private var shieldTabBarHits = false

  var body: some View {
    Group {
      if appState.showOnboarding {
        OnboardingView(onFinished: finishOnboarding)
      } else {
        TabView(selection: $selectedTab) {
          FocusView(selectedTab: $selectedTab)
            .tabItem { Label("Focus", systemImage: "shield.checkered") }
            .tag(AppTab.focus.rawValue)

          StudyView(selectedTab: $selectedTab)
            .tabItem { Label("Study", systemImage: "book.fill") }
            .tag(AppTab.study.rawValue)

          SettingsView()
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(AppTab.settings.rawValue)
        }
        .tint(UnrotTheme.accent)
        .overlay(alignment: .bottom) {
          if shieldTabBarHits {
            Color.clear
              .frame(height: 88)
              .contentShape(Rectangle())
              .allowsHitTesting(true)
          }
        }
        .fullScreenCover(isPresented: $appState.showGateQuiz) {
          GateQuizView()
        }
        .onChange(of: appState.showOnboarding) { _, showing in
          if !showing {
            selectedTab = AppTab.focus.rawValue
          }
        }
        .onChange(of: appState.openStudyTabAfterQuiz) { _, open in
          if open {
            selectedTab = AppTab.study.rawValue
            appState.openStudyTabAfterQuiz = false
          }
        }
        .onChange(of: appState.isLocked) { _, locked in
          if locked && appState.activeDeck != nil { selectedTab = AppTab.study.rawValue }
        }
      }
    }
  }

  private func finishOnboarding() {
    selectedTab = AppTab.focus.rawValue
    appState.completeOnboarding()
    shieldTabBarHits = true
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(500))
      shieldTabBarHits = false
    }
  }
}
