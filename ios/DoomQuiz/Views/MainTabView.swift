import SwiftUI

enum AppTab: Int {
  case focus = 0
  case study = 1
  case settings = 2
}

struct MainTabView: View {
  @EnvironmentObject private var appState: AppState
  @State private var selectedTab = AppTab.focus.rawValue

  var body: some View {
    Group {
      if appState.showOnboarding {
        OnboardingView()
      } else {
        TabView(selection: $selectedTab) {
          FocusView(selectedTab: $selectedTab)
            .tabItem { Label("Focus", systemImage: "shield.checkered") }
            .tag(AppTab.focus.rawValue)

          StudyView()
            .tabItem { Label("Study", systemImage: "book.fill") }
            .tag(AppTab.study.rawValue)

          SettingsView()
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(AppTab.settings.rawValue)
        }
        .tint(UnrotTheme.accent)
        .fullScreenCover(isPresented: $appState.showGateQuiz) {
          GateQuizView()
        }
        .onChange(of: appState.isLocked) { _, locked in
          if locked && appState.activeDeck != nil {
            selectedTab = AppTab.study.rawValue
          }
        }
      }
    }
  }
}
