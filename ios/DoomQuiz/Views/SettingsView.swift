import SwiftUI
import FamilyControls

struct SettingsView: View {
  @EnvironmentObject private var appState: AppState
  @EnvironmentObject private var themeStore: ThemeStore
  @State private var showPicker = false
  @State private var showClearHistoryConfirm = false
  @State private var showScreenTimeError = false

  private let budgets = [0, 15, 30, 45, 60]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          Text("Settings")
            .font(.title.weight(.black))
            .foregroundStyle(UnrotTheme.text)

          scrollBankSummary
            .padding(.top, 20)

          scrollLimitSection
            .padding(.top, 28)

          appearanceSection
            .padding(.top, 28)

          screenTimeSection
            .padding(.top, 28)

          advancedSection
            .padding(.top, 28)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
      }
      .background(UnrotTheme.bg)
      .navigationBarHidden(true)
    }
    .background(UnrotTheme.bg)
    .familyActivityPicker(
      isPresented: $showPicker,
      selection: Binding(
        get: { appState.screenTime.selection },
        set: { appState.updateScreenTimeSelection($0) }
      )
    )
    .alert("Screen Time access needed", isPresented: $showScreenTimeError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(
        appState.screenTime.authorizationError
          ?? "Allow Screen Time to pick apps to block. This only works on a real iPhone with Screen Time enabled."
      )
    }
    .alert("Clear all history?", isPresented: $showClearHistoryConfirm) {
      Button("Cancel", role: .cancel) {}
      Button("Clear & restart", role: .destructive) {
        appState.clearAllHistory()
      }
    } message: {
      Text("Removes quizzes, scroll bank progress, and shows onboarding again — like a new install.")
    }
  }

  // MARK: - Summary

  private var scrollBankSummary: some View {
    HStack(spacing: 14) {
      ZStack {
        Circle()
          .strokeBorder(UnrotTheme.accent.opacity(0.85), lineWidth: 4)
          .frame(width: 52, height: 52)
        Image(systemName: "hourglass")
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(UnrotTheme.accent)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text("\(appState.snapshot.remainingMinutes)m left today")
          .font(.system(size: 17, weight: .bold, design: .rounded))
          .foregroundStyle(UnrotTheme.text)
        Text("Daily limit \(appState.snapshot.dailyBudgetMinutes)m · \(appState.snapshot.usedTodayMinutes)m scrolled")
          .font(.system(size: 14))
          .foregroundStyle(UnrotTheme.textMuted)
      }

      Spacer(minLength: 0)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(UnrotTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .stroke(UnrotTheme.cardBorder.opacity(0.6), lineWidth: 1)
    )
    .themeCardShadow()
  }

  // MARK: - Scroll limit

  private var scrollLimitSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      settingsSectionTitle("Daily scroll limit")

      VStack(alignment: .leading, spacing: 14) {
        HStack(spacing: 10) {
          ForEach(budgets, id: \.self) { minutes in
            budgetChip(minutes)
          }
        }

        Text("Changing your limit resets today's scroll bank to the new amount.")
          .font(.system(size: 13))
          .foregroundStyle(UnrotTheme.textMuted)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(UnrotTheme.card)
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(UnrotTheme.cardBorder.opacity(0.6), lineWidth: 1)
      )
      .themeCardShadow()
    }
  }

  private func budgetChip(_ minutes: Int) -> some View {
    let selected = appState.snapshot.dailyBudgetMinutes == minutes
    return Button {
      appState.setDailyBudget(minutes)
      HapticFeedback.selection()
    } label: {
      Text("\(minutes)m")
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .foregroundStyle(selected ? .white : UnrotTheme.text)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(selected ? UnrotTheme.accent : UnrotTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  // MARK: - Appearance

  private var appearanceSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      settingsSectionTitle("Appearance")

      VStack(spacing: 0) {
        ForEach(Array(AppearanceMode.allCases.enumerated()), id: \.element.id) { index, option in
          appearanceRow(option)
          if index < AppearanceMode.allCases.count - 1 {
            Divider()
              .overlay(UnrotTheme.cardBorder.opacity(0.5))
              .padding(.leading, 52)
          }
        }
      }
      .background(UnrotTheme.card)
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(UnrotTheme.cardBorder.opacity(0.6), lineWidth: 1)
      )
      .themeCardShadow()
    }
  }

  private func appearanceRow(_ option: AppearanceMode) -> some View {
    let selected = themeStore.mode == option
    return Button {
      themeStore.mode = option
      HapticFeedback.selection()
    } label: {
      HStack(spacing: 14) {
        Image(systemName: appearanceIcon(option))
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(selected ? UnrotTheme.accent : UnrotTheme.textMuted)
          .frame(width: 28)

        Text(option.label)
          .font(.system(size: 16, weight: .semibold, design: .rounded))
          .foregroundStyle(UnrotTheme.text)

        Spacer()

        if selected {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(UnrotTheme.accent)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private func appearanceIcon(_ mode: AppearanceMode) -> String {
    switch mode {
    case .system: return "circle.lefthalf.filled"
    case .light: return "sun.max.fill"
    case .dark: return "moon.fill"
    }
  }

  // MARK: - Screen Time

  private var screenTimeSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        settingsSectionTitle("Blocked apps")
        Spacer()
        Button {
          Task { await openBlockedAppsPicker() }
        } label: {
          Text(appState.screenTime.isAuthorized ? "+ Add" : "Allow")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(UnrotTheme.accent)
        }
        .buttonStyle(.plain)
      }

      VStack(alignment: .leading, spacing: 12) {
        Button {
          Task { await openBlockedAppsPicker() }
        } label: {
          HStack(spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
              .font(.system(size: 22, weight: .bold))
              .foregroundStyle(UnrotTheme.textMuted)
              .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
              Text(
                appState.screenTime.shieldedAppCount == 0
                  ? "No apps selected yet"
                  : "\(appState.screenTime.shieldedAppCount) apps selected"
              )
              .font(.system(size: 17, weight: .bold, design: .rounded))
              .foregroundStyle(UnrotTheme.text)

              Text(
                appState.screenTime.isAuthorized
                  ? "These lock when your scroll bank hits zero."
                  : "Allow Screen Time to pick apps to block."
              )
              .font(.system(size: 14))
              .foregroundStyle(UnrotTheme.textMuted)
              .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
              .font(.system(size: 14, weight: .bold))
              .foregroundStyle(UnrotTheme.textMuted)
          }
          .padding(16)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(UnrotTheme.surface)
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
          .themeCardShadow()
        }
        .buttonStyle(.plain)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(UnrotTheme.card)
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(UnrotTheme.cardBorder.opacity(0.6), lineWidth: 1)
      )
      .themeCardShadow()
    }
  }

  // MARK: - Advanced

  private var advancedSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      settingsSectionTitle("Advanced")

      Button {
        showClearHistoryConfirm = true
      } label: {
        HStack(spacing: 14) {
          Image(systemName: "trash")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(UnrotTheme.danger)
            .frame(width: 28)

          VStack(alignment: .leading, spacing: 3) {
            Text("Clear history")
              .font(.system(size: 16, weight: .bold, design: .rounded))
              .foregroundStyle(UnrotTheme.danger)
            Text("Reset quizzes, scroll bank, and onboarding")
              .font(.system(size: 13))
              .foregroundStyle(UnrotTheme.textMuted)
          }

          Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(UnrotTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(UnrotTheme.danger.opacity(0.35), lineWidth: 1)
        )
        .themeCardShadow()
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Helpers

  private func openBlockedAppsPicker() async {
    let ready = await appState.screenTime.prepareForPicker()
    if ready {
      showPicker = true
    } else {
      showScreenTimeError = true
    }
  }

  private func settingsSectionTitle(_ title: String) -> some View {
    Text(title)
      .font(.system(size: 18, weight: .heavy, design: .rounded))
      .foregroundStyle(UnrotTheme.text)
  }

  private func settingsInfoRow(icon: String, title: String, subtitle: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(UnrotTheme.textMuted)
        .frame(width: 28)
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 16, weight: .bold, design: .rounded))
          .foregroundStyle(UnrotTheme.text)
        Text(subtitle)
          .font(.system(size: 13))
          .foregroundStyle(UnrotTheme.textMuted)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  private func settingsActionLabel(title: String, trailing: String?) -> some View {
    HStack {
      Text(title)
        .font(.system(size: 16, weight: .semibold, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
      Spacer()
      if let trailing {
        Text(trailing)
          .font(.system(size: 14, weight: .bold, design: .rounded))
          .foregroundStyle(UnrotTheme.textMuted)
      }
      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(UnrotTheme.textMuted)
    }
    .padding(14)
    .frame(maxWidth: .infinity)
    .background(UnrotTheme.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .themeCardShadow()
  }
}
