import Foundation

struct MemorizePoint: Identifiable, Codable, Hashable {
  let id: String
  var term: String
  var definition: String
}

struct QuizQuestion: Identifiable, Codable, Hashable {
  let id: String
  var prompt: String
  var choices: [String]
  var correctIndex: Int
}

struct StudyDeck: Identifiable, Codable, Hashable {
  let id: String
  var title: String
  var source: String
  var points: [MemorizePoint]
  var questions: [QuizQuestion]
  var createdAt: Date
}

struct PersistedSnapshot: Codable {
  var dailyBudgetMinutes: Int
  var remainingMinutes: Int
  var usedTodayMinutes: Int
  var studyReadingSecondsToday: Int
  var lastResetDate: String
  var decks: [StudyDeck]
  var activeDeckId: String?
}

struct AIDeckResponse: Codable {
  var title: String
  var points: [AIMemorizePoint]
  var questions: [AIQuestion]

  struct AIMemorizePoint: Codable {
    var term: String
    var definition: String
  }

  struct AIQuestion: Codable {
    var prompt: String
    var choices: [String]
    var correctIndex: Int
  }
}
