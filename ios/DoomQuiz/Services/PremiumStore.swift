import Foundation

/// Premium gating — wire to StoreKit later.
enum PremiumStore {
  private static let key = "doomquiz.premium"

  static var isPremium: Bool {
    get { UserDefaults.standard.bool(forKey: key) }
    set { UserDefaults.standard.set(newValue, forKey: key) }
  }
}
