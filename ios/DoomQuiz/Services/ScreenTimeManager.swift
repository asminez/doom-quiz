import Foundation
import FamilyControls
import ManagedSettings

@MainActor
final class ScreenTimeManager: ObservableObject {
  static let useMockScreenTime = true

  @Published var selection = FamilyActivitySelection()
  @Published var isAuthorized = false
  @Published var authorizationError: String?
  @Published private(set) var mockBlockedAppCount = 0

  private let store = ManagedSettingsStore()

  var isMockMode: Bool { Self.useMockScreenTime }

  var shieldedAppCount: Int {
    if isMockMode { return mockBlockedAppCount }
    return selection.applicationTokens.count + selection.categoryTokens.count
  }

  func refreshAuthorization() {
    if isMockMode {
      isAuthorized = true
      return
    }
    isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
  }

  func requestAuthorization() async {
    if isMockMode {
      isAuthorized = true
      authorizationError = nil
      return
    }
    do {
      try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
      isAuthorized = true
      authorizationError = nil
    } catch {
      isAuthorized = false
      authorizationError = error.localizedDescription
    }
  }

  func applyShields() {
    if isMockMode { return }
    store.shield.applications = selection.applicationTokens.isEmpty
      ? nil : selection.applicationTokens
    if !selection.categoryTokens.isEmpty {
      store.shield.applicationCategories = .specific(selection.categoryTokens)
    }
  }

  func clearShields() {
    if isMockMode { return }
    store.clearAllSettings()
  }

  func cycleMockBlockedApps() {
    guard isMockMode else { return }
    mockBlockedAppCount = switch mockBlockedAppCount {
    case 0: 3
    case 3: 5
    default: 0
    }
  }
}
