import Foundation
import FamilyControls
import ManagedSettings

@MainActor
final class ScreenTimeManager: ObservableObject {
  private static let selectionKey = "doomquiz.screentime.selection"

  @Published var selection = FamilyActivitySelection()
  @Published var isAuthorized = false
  @Published var authorizationError: String?

  private let store = ManagedSettingsStore()

  var shieldedAppCount: Int {
    selection.applicationTokens.count
      + selection.categoryTokens.count
      + selection.webDomainTokens.count
  }

  var hasBlockedTargets: Bool { shieldedAppCount > 0 }

  init() {
    loadSelection()
  }

  func refreshAuthorization() {
    isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
  }

  func requestAuthorization() async {
    do {
      try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
      isAuthorized = true
      authorizationError = nil
    } catch {
      isAuthorized = false
      authorizationError = error.localizedDescription
    }
  }

  func prepareForPicker() async -> Bool {
    if isAuthorized { return true }
    await requestAuthorization()
    return isAuthorized
  }

  func updateSelection(_ newValue: FamilyActivitySelection) {
    selection = newValue
    saveSelection()
  }

  func applyShields() {
    guard isAuthorized, hasBlockedTargets else {
      clearShields()
      return
    }

    store.shield.applications = selection.applicationTokens.isEmpty
      ? nil : selection.applicationTokens

    store.shield.applicationCategories = selection.categoryTokens.isEmpty
      ? nil
      : .specific(selection.categoryTokens)

    store.shield.webDomains = selection.webDomainTokens.isEmpty
      ? nil
      : selection.webDomainTokens
  }

  func clearShields() {
    store.clearAllSettings()
  }

  private func loadSelection() {
    guard
      let data = UserDefaults.standard.data(forKey: Self.selectionKey),
      let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    else { return }
    selection = decoded
  }

  private func saveSelection() {
    guard let data = try? JSONEncoder().encode(selection) else { return }
    UserDefaults.standard.set(data, forKey: Self.selectionKey)
  }
}
