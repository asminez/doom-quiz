import Foundation

/// Lightweight, dependency-free product analytics.
///
/// Sends anonymous behavioral events to PostHog's HTTP capture API so we can
/// understand what users do in the app (onboarding funnel, lesson generation,
/// quiz completion, paywall views, etc.). No IDFA, no advertising identifiers,
/// no personal data, and therefore no App Tracking Transparency prompt required.
///
/// Setup: paste your PostHog **project** API key into `apiKey` below. While it's
/// empty, analytics is a no-op, so the app ships safely without it.
enum Analytics {

  // MARK: - Configuration

  /// PostHog project API key (starts with `phc_`). Leave empty to disable.
  private static let apiKey = ""

  /// PostHog ingestion host. Use "https://eu.i.posthog.com" for EU projects.
  private static let host = "https://us.i.posthog.com"

  // MARK: - Storage keys

  private static let optOutKey = "doomquiz.analytics.optOut"
  private static let distinctIdKey = "doomquiz.analytics.distinctId"

  // MARK: - Opt out

  /// User-facing toggle. When true, no events are sent.
  static var isOptedOut: Bool {
    get { UserDefaults.standard.bool(forKey: optOutKey) }
    set { UserDefaults.standard.set(newValue, forKey: optOutKey) }
  }

  private static var isEnabled: Bool { !apiKey.isEmpty && !isOptedOut }

  /// Stable, anonymous, per-install identifier. Not linked to any personal data.
  static var distinctId: String {
    if let existing = UserDefaults.standard.string(forKey: distinctIdKey) {
      return existing
    }
    let id = UUID().uuidString
    UserDefaults.standard.set(id, forKey: distinctIdKey)
    return id
  }

  // MARK: - Public API

  /// Capture a named event with optional properties. Fire-and-forget.
  static func capture(_ event: String, _ properties: [String: Any] = [:]) {
    guard isEnabled else { return }

    var props = properties
    props["platform"] = "ios"
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
      props["app_version"] = version
    }

    let payload: [String: Any] = [
      "api_key": apiKey,
      "event": event,
      "distinct_id": distinctId,
      "timestamp": ISO8601DateFormatter().string(from: Date()),
      "properties": props,
    ]

    send(payload)
  }

  /// Forget the anonymous identifier (used when the user clears all history so a
  /// reset behaves like a fresh install).
  static func reset() {
    UserDefaults.standard.removeObject(forKey: distinctIdKey)
  }

  // MARK: - Transport

  private static func send(_ payload: [String: Any]) {
    guard
      let url = URL(string: "\(host)/capture/"),
      let body = try? JSONSerialization.data(withJSONObject: payload)
    else { return }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = body
    URLSession.shared.dataTask(with: request).resume()
  }
}
