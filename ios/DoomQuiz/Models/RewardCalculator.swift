import Foundation

enum RewardCalculator {
  static let gateQuestionCount = 6
  static let sectionQuestionCount = 6
  static let sectionPerfectMinutes = 5

  static func minutes(forCorrect correct: Int, total: Int = gateQuestionCount) -> Int {
    guard total > 0 else { return 0 }
    if total >= 6 {
      switch correct {
      case 6: return 15
      case 5: return 10
      case 4: return 5
      default: return 0
      }
    }
    let ratio = Double(correct) / Double(total)
    if ratio >= 0.83 { return 10 }
    if ratio >= 0.67 { return 5 }
    return 0
  }

  static func label(forCorrect correct: Int, total: Int = gateQuestionCount) -> String {
    let mins = minutes(forCorrect: correct, total: total)
    switch mins {
    case 15: return "Perfect! +15 minutes unlocked."
    case 10: return "Great! +10 minutes unlocked."
    case 5: return "+5 minutes unlocked."
    default: return "Need at least 4/6 correct for scroll time."
    }
  }

  static func rewardHint(total: Int = gateQuestionCount) -> String {
    if total >= 6 {
      return "6/6 → 15m · 5/6 → 10m · 4/6 → 5m · retries only add the difference"
    }
    return "Score 4+ correct to earn scroll time."
  }

  static func sectionMinutes(forCorrect correct: Int, total: Int = sectionQuestionCount) -> Int {
    guard total > 0, correct == total, total >= sectionQuestionCount else { return 0 }
    return sectionPerfectMinutes
  }

  static func sectionLabel(forCorrect correct: Int, total: Int = sectionQuestionCount) -> String {
    if correct == total && total >= sectionQuestionCount {
      return "Perfect! Section mastered — +\(sectionPerfectMinutes)m unlocked."
    }
    return "Need \(sectionQuestionCount)/\(sectionQuestionCount) to unlock the next section."
  }

  static func sectionRewardHint() -> String {
    "\(sectionQuestionCount)/\(sectionQuestionCount) → +\(sectionPerfectMinutes)m per section"
  }

  static func depositLabel(delta: Int, claimedTotal: Int) -> String {
    if delta > 0 && claimedTotal > delta {
      return "+\(delta)m added (\(claimedTotal)m total this lock)"
    }
    if delta > 0 {
      return "+\(delta)m deposited"
    }
    return "No new time — beat your best score to earn more."
  }
}
