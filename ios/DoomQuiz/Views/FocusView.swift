import SwiftUI
import FamilyControls

struct FocusView: View {
  @EnvironmentObject private var appState: AppState
  @Binding var selectedTab: Int
  @State private var showPicker = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          Text("Scroll bank")
            .font(.system(size: 29, weight: .black, design: .rounded))
            .foregroundStyle(UnrotTheme.text)
          Text("Minutes left before apps lock")
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .foregroundStyle(UnrotTheme.textMuted)
            .padding(.top, 2)

          metricsSection
            .padding(.top, 16)

          activitySummary
            .padding(.top, 18)

          blockedAppsSection
            .padding(.top, 30)

          learningNowSection
            .padding(.top, 20)

          Button { selectedTab = AppTab.settings.rawValue } label: {
            Label("Change daily limit in Settings", systemImage: "gearshape")
              .font(.system(size: 14, weight: .semibold, design: .rounded))
              .foregroundStyle(UnrotTheme.textMuted)
              .frame(maxWidth: .infinity)
              .padding(.top, 14)
          }
          .buttonStyle(.plain)
          .padding(.bottom, 22)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
      }
      .background(UnrotTheme.bg)
      .navigationBarHidden(true)
    }
    .familyActivityPicker(
      isPresented: $showPicker,
      selection: Binding(
        get: { appState.screenTime.selection },
        set: { appState.screenTime.selection = $0 }
      )
    )
  }

  private var metricsSection: some View {
    HStack(spacing: 14) {
      metricTile(
        value: "\(appState.snapshot.remainingMinutes)m",
        label: "Minutes left",
        icon: "hourglass",
        ringColor: Color(red: 1.0, green: 0.39, blue: 0.29)
      )
      metricTile(
        value: "\(appState.studyMinutesReadToday)m",
        label: "Minutes read",
        icon: "book.fill",
        ringColor: QuizletTheme.primary
      )
    }
  }

  private func metricTile(value: String, label: String, icon: String, ringColor: Color) -> some View {
    VStack(alignment: .center, spacing: 0) {
      ZStack {
        Circle()
          .strokeBorder(ringColor.opacity(0.9), lineWidth: 4.4)
          .frame(width: 58, height: 58)
        Image(systemName: icon)
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(ringColor)
      }
      .padding(.top, 14)
      Text(value)
        .font(.system(size: 25, weight: .heavy, design: .rounded))
        .foregroundStyle(UnrotTheme.text)
        .padding(.top, 16)
      Text(label)
        .font(.system(size: 13, weight: .medium, design: .rounded))
        .foregroundStyle(UnrotTheme.textMuted)
        .padding(.top, 5)

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .top)
    .frame(height: 162)
    .background(UnrotTheme.card)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .stroke(UnrotTheme.cardBorder.opacity(0.5), lineWidth: 1)
    )
  }

  private var learningNowDecks: [StudyDeck] {
    appState.snapshot.decks.sorted { $0.createdAt > $1.createdAt }
  }

  private var activitySummary: some View {
    HStack(spacing: 8) {
      Image(systemName: "iphone")
        .font(.system(size: 14, weight: .semibold))
      Text("\(appState.snapshot.usedTodayMinutes)m scrolled today")
        .font(.system(size: 16, weight: .bold, design: .rounded))
    }
    .foregroundStyle(UnrotTheme.text)
  }

  private var blockedAppsSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text("Blocked apps")
          .font(.system(size: 18, weight: .heavy, design: .rounded))
          .foregroundStyle(UnrotTheme.text)
        Spacer()
        Button {
          if appState.screenTime.isAuthorized {
            showPicker = true
          } else {
            Task { await appState.screenTime.requestAuthorization() }
          }
        } label: {
          Text("+ Add")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(UnrotTheme.accent)
        }
        .buttonStyle(.plain)
      }

      HStack(spacing: 12) {
        Image(systemName: "shield.lefthalf.filled")
          .font(.system(size: 23, weight: .bold))
          .foregroundStyle(UnrotTheme.textMuted)
          .frame(width: 28, height: 34)
          .offset(x: -1.4)
        VStack(alignment: .leading, spacing: 5) {
          Text(appState.screenTime.shieldedAppCount == 0 ? "No apps selected yet" : "\(appState.screenTime.shieldedAppCount) apps selected")
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(UnrotTheme.text)
          Text("Pick apps to lock when your scroll bank hits zero.")
            .font(.system(size: 14))
            .foregroundStyle(UnrotTheme.textMuted)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer()
        Image(systemName: "chevron.right")
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(UnrotTheme.textMuted)
          .offset(x: -5)
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 22)
      .background(UnrotTheme.card)
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      .onTapGesture {
        if appState.screenTime.isAuthorized {
          showPicker = true
        } else {
          Task { await appState.screenTime.requestAuthorization() }
        }
      }
    }
  }

  private var learningNowSection: some View {
    VStack(spacing: 12) {
      ForEach(learningNowDecks) { deck in
        focusLearningCard(deck: deck)
      }

      if learningNowDecks.isEmpty {
        focusLearningCard(deck: nil)
      }
    }
  }

  private func focusLearningCard(deck: StudyDeck?) -> some View {
    Button {
      if let deck {
        appState.setActiveDeck(deck.id)
      }
      selectedTab = AppTab.study.rawValue
    } label: {
      HStack(spacing: 14) {
        ZStack {
          RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(QuizletTheme.primarySoft)
            .frame(width: 46, height: 46)
          Image(systemName: deck == nil ? "plus" : "book.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(QuizletTheme.primary)
        }

        VStack(alignment: .leading, spacing: 5) {
          Text("START LEARNING")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(UnrotTheme.textMuted)
          Text(deck?.title ?? "Pick a topic")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(UnrotTheme.text)
            .lineLimit(1)
          Text(deck == nil ? "Tap to start studying" : "0/8 sections mastered")
            .font(.system(size: 14))
            .foregroundStyle(UnrotTheme.textMuted)
        }

        Spacer(minLength: 8)

        Image(systemName: "chevron.right")
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(UnrotTheme.textMuted)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 20)
      .background(UnrotTheme.card)
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(QuizletTheme.primary.opacity(0.6), lineWidth: 2)
      )
    }
    .buttonStyle(.plain)
  }
}
