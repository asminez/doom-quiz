import SwiftUI
import FamilyControls

struct FocusView: View {
  @EnvironmentObject private var appState: AppState
  @Binding var selectedTab: Int
  @State private var showPicker = false
  @State private var showScreenTimeError = false

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
            .padding(.top, 20)

          activitySummary
            .padding(.top, 18)

          earnMoreTimeSection
            .padding(.top, 30)

          blockedAppsSection
            .padding(.top, 30)

          Button { selectedTab = AppTab.settings.rawValue } label: {
            Label("Change daily limit in Settings", systemImage: "gearshape")
              .font(.system(size: 14, weight: .semibold, design: .rounded))
              .foregroundStyle(UnrotTheme.textMuted)
              .frame(maxWidth: .infinity)
              .padding(.top, 14)
          }
          .buttonStyle(.plain)
          .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 28)
      }
      .background(UnrotTheme.bg)
      .navigationBarHidden(true)
    }
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
          ?? "Allow Screen Time in Settings to pick apps to block. The app picker only works on a real iPhone with Screen Time enabled."
      )
    }
  }

  private var metricsSection: some View {
    HStack(spacing: 14) {
      metricTile(
        value: "\(appState.snapshot.remainingMinutes)m",
        label: "Minutes left",
        icon: "hourglass",
        ringColor: UnrotTheme.accent
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
    .themeCardShadow()
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

  private var earnMoreTimeSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Earn more time")
        .font(.system(size: 18, weight: .heavy, design: .rounded))
        .foregroundStyle(UnrotTheme.text)

      learningNowCards
    }
  }

  private var learningNowCards: some View {
    VStack(spacing: 12) {
      ForEach(learningNowDecks) { deck in
        focusLearningCard(deck: deck)
      }

      if learningNowDecks.isEmpty {
        focusLearningCard(deck: nil)
      }
    }
  }

  private var blockedAppsSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text("Blocked apps")
          .font(.system(size: 18, weight: .heavy, design: .rounded))
          .foregroundStyle(UnrotTheme.text)
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

      blockedAppsCard
    }
  }

  private var blockedAppsCard: some View {
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
        Text(
          appState.screenTime.isAuthorized
            ? "Pick apps to lock when your scroll bank hits zero."
            : "Allow Screen Time to search and pick apps to block."
        )
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
    .themeCardShadow()
    .onTapGesture {
      Task { await openBlockedAppsPicker() }
    }
  }

  private func openBlockedAppsPicker() async {
    let ready = await appState.screenTime.prepareForPicker()
    if ready {
      showPicker = true
    } else {
      showScreenTimeError = true
    }
  }

  private func focusLearningCard(deck: StudyDeck?) -> some View {
    Button {
      if let deck {
        appState.setActiveDeck(deck.id)
      }
      withAnimation(.easeInOut(duration: 0.2)) {
        selectedTab = AppTab.study.rawValue
      }
    } label: {
      HStack(spacing: 12) {
        ZStack {
          RoundedRectangle(cornerRadius: 13, style: .continuous)
            .fill(QuizletTheme.primarySoft)
            .frame(width: 39, height: 39)
          Image(systemName: deck == nil ? "plus" : "book.fill")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(QuizletTheme.primary)
        }

        VStack(alignment: .leading, spacing: 4) {
          Text(deck == nil ? "START LEARNING" : "CONTINUE STUDYING")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(UnrotTheme.textMuted)
          Text(deck?.title ?? "Pick a topic")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(UnrotTheme.text)
            .lineLimit(1)
          Text(deck == nil ? "Tap to start studying" : "\(deck?.masteredParagraphIds.count ?? 0)/\(LessonContentAmount.sectionCount) sections mastered")
            .font(.system(size: 12))
            .foregroundStyle(UnrotTheme.textMuted)
        }

        Spacer(minLength: 7)

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(UnrotTheme.textMuted)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 17)
      .background(UnrotTheme.card)
      .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 17, style: .continuous)
          .stroke(QuizletTheme.primary.opacity(0.6), lineWidth: 1.5)
      )
      .themeCardShadow(elevated: true)
    }
    .buttonStyle(.plain)
  }
}
