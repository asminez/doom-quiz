import SwiftUI
import FamilyControls

struct SettingsView: View {
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var themeStore: ThemeStore
  @State private var showPicker = false
  @State private var showClearHistoryConfirm = false

  private let budgets = [15, 30, 45, 60]

  var body: some View {
    NavigationStack {
      List {
        Section {
          Picker("Daily scroll limit", selection: budgetBinding) {
            ForEach(budgets, id: \.self) { m in
              Text("\(m) minutes").tag(m)
            }
          }
        } footer: {
          Text("Changing this resets today's scroll bank.")
        }

        Section("Appearance") {
          Picker("Theme", selection: $themeStore.mode) {
            ForEach(AppearanceMode.allCases) { option in
              Text(option.label).tag(option)
            }
          }
        }

        Section {
          if appState.screenTime.isMockMode {
            Button {
              appState.screenTime.cycleMockBlockedApps()
            } label: {
              HStack {
                Text("Simulate blocked apps")
                Spacer()
                if appState.screenTime.shieldedAppCount > 0 {
                  Text("\(appState.screenTime.shieldedAppCount)")
                    .foregroundStyle(UnrotTheme.textMuted)
                }
              }
            }
          } else {
            if !appState.screenTime.isAuthorized {
              Button {
                Task { await appState.screenTime.requestAuthorization() }
              } label: {
                HStack {
                  Text("Authorize Screen Time")
                  Spacer()
                  Image(systemName: "hourglass")
                }
              }
            }

            Button {
              showPicker = true
            } label: {
              HStack {
                Text("Choose apps to block")
                Spacer()
                if appState.screenTime.shieldedAppCount > 0 {
                  Text("\(appState.screenTime.shieldedAppCount) selected")
                    .foregroundStyle(UnrotTheme.textMuted)
                } else {
                  Image(systemName: "apps.iphone")
                }
              }
            }
          }
        } header: {
          Text("Screen Time")
        } footer: {
          Text(appState.screenTime.isMockMode
            ? "Demo mode: blocking is simulated so you can test DoomQuiz without Screen Time entitlements."
            : "When minutes hit 0, selected apps are blocked until you pass a quiz.")
        }

        Section("Testing") {
          Button(role: .destructive) {
            showClearHistoryConfirm = true
          } label: {
            Text("Clear history")
          }
        }
      }
      .listStyle(.insetGrouped)
      .listRowBackground(UnrotTheme.card)
      .scrollContentBackground(.hidden)
      .background(UnrotTheme.bg)
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
    }
    .background(UnrotTheme.bg)
    .familyActivityPicker(
      isPresented: $showPicker,
      selection: Binding(
        get: { appState.screenTime.selection },
        set: { appState.screenTime.selection = $0 }
      )
    )
    .alert("Clear all history?", isPresented: $showClearHistoryConfirm) {
      Button("Cancel", role: .cancel) {}
      Button("Clear & restart", role: .destructive) {
        appState.clearAllHistory()
      }
    } message: {
      Text("Removes quizzes, scroll bank progress, and shows onboarding again — like a new install.")
    }
  }
}

private extension SettingsView {
  var budgetBinding: Binding<Int> {
    Binding(
      get: { appState.snapshot.dailyBudgetMinutes },
      set: { appState.setDailyBudget($0) }
    )
  }
}
