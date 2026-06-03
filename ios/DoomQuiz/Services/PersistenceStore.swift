import Foundation

enum PersistenceStore {
  private static let key = "doomquiz.state.v2"
  private static let onboardingKey = "doomquiz.onboarding.completed"

  static var hasCompletedOnboarding: Bool {
    get { UserDefaults.standard.bool(forKey: onboardingKey) }
    set { UserDefaults.standard.set(newValue, forKey: onboardingKey) }
  }

  static func todayKey() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.timeZone = .current
    return f.string(from: Date())
  }

  static func defaultSnapshot() -> PersistedSnapshot {
    .init(
      dailyBudgetMinutes: 45,
      remainingMinutes: 45,
      usedTodayMinutes: 0,
      quizEarnedTodayMinutes: 0,
      studyReadingSecondsToday: 0,
      gateRewardClaimedMinutes: 0,
      gateRewardClaimedSectionIds: [],
      lastResetDate: todayKey(),
      decks: [],
      activeDeckId: nil
    )
  }

  static func load() -> PersistedSnapshot {
    guard let data = UserDefaults.standard.data(forKey: key),
      let decoded = try? JSONDecoder().decode(PersistedSnapshot.self, from: data)
    else { return defaultSnapshot() }
    return normalize(decoded)
  }

  static func save(_ snapshot: PersistedSnapshot) {
    if let data = try? JSONEncoder().encode(normalize(snapshot)) {
      UserDefaults.standard.set(data, forKey: key)
    }
  }

  static func clearAllHistory() {
    UserDefaults.standard.removeObject(forKey: key)
    UserDefaults.standard.removeObject(forKey: onboardingKey)
  }

  static func normalize(_ snapshot: PersistedSnapshot) -> PersistedSnapshot {
    var next = snapshot
    let today = todayKey()
    if next.lastResetDate != today {
      next.lastResetDate = today
      next.remainingMinutes = next.dailyBudgetMinutes
      next.usedTodayMinutes = 0
      next.quizEarnedTodayMinutes = 0
      next.studyReadingSecondsToday = 0
      next.gateRewardClaimedMinutes = 0
      next.gateRewardClaimedSectionIds = []
    }
    return next
  }
}
