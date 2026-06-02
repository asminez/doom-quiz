import Foundation

enum RewardCalculator {
  static func minutes(forCorrect correct: Int, total: Int = 5) -> Int {
    guard total > 0 else { return 0 }
    let ratio = Double(correct) / Double(total)
    if ratio >= 1 { return 10 }
    if ratio >= 0.8 { return 5 }
    if ratio >= 0.6 { return 2 }
    return 0
  }

  static func label(forCorrect correct: Int, total: Int = 5) -> String {
    switch minutes(forCorrect: correct, total: total) {
    case 10: return "Perfect! +10 minutes unlocked."
    case 5: return "Great! +5 minutes unlocked."
    case 2: return "+2 minutes unlocked."
    default: return "No extra time — try again later."
    }
  }
}
