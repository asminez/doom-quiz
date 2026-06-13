import Foundation

struct StudyParagraph: Identifiable, Codable, Hashable {
  let id: String
  var label: String
  var body: String
}

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
  var paragraphId: String?

  init(
    id: String,
    prompt: String,
    choices: [String],
    correctIndex: Int,
    paragraphId: String? = nil
  ) {
    self.id = id
    self.prompt = prompt
    self.choices = choices
    self.correctIndex = correctIndex
    self.paragraphId = paragraphId
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    prompt = try c.decode(String.self, forKey: .prompt)
    choices = try c.decode([String].self, forKey: .choices)
    correctIndex = try c.decode(Int.self, forKey: .correctIndex)
    paragraphId = try c.decodeIfPresent(String.self, forKey: .paragraphId)
  }

  enum CodingKeys: String, CodingKey {
    case id, prompt, choices, correctIndex, paragraphId
  }
}

struct StudyDeck: Identifiable, Codable, Hashable {
  let id: String
  var title: String
  var source: String
  var paragraphs: [StudyParagraph]
  var reviewSummary: String?
  var points: [MemorizePoint]
  var questions: [QuizQuestion]
  var masteredParagraphIds: [String]
  var createdAt: Date

  var isAIGenerated: Bool { source == "topic" || source == "syllabus" }

  var studyProgress: Double {
    if isAIGenerated {
      return Double(masteredParagraphIds.count) / Double(LessonContentAmount.sectionCount)
    }
    guard !paragraphs.isEmpty else { return 0 }
    return Double(masteredParagraphIds.count) / Double(paragraphs.count)
  }

  var currentParagraph: StudyParagraph? {
    paragraphs.first { !masteredParagraphIds.contains($0.id) }
  }

  var allSectionsMastered: Bool {
    if isAIGenerated {
      return masteredParagraphIds.count >= LessonContentAmount.sectionCount
        && paragraphs.count >= LessonContentAmount.sectionCount
    }
    return !paragraphs.isEmpty && masteredParagraphIds.count >= paragraphs.count
  }

  func questions(for paragraphId: String) -> [QuizQuestion] {
    questions.filter { $0.paragraphId == paragraphId }
  }

  func hasSectionQuestions(for paragraphId: String) -> Bool {
    questions(for: paragraphId).count >= RewardCalculator.sectionQuestionCount
  }

  enum CodingKeys: String, CodingKey {
    case id, title, source, paragraphs, reviewSummary, points, questions
    case masteredParagraphIds, createdAt
  }

  init(
    id: String,
    title: String,
    source: String,
    paragraphs: [StudyParagraph] = [],
    reviewSummary: String? = nil,
    points: [MemorizePoint] = [],
    questions: [QuizQuestion],
    masteredParagraphIds: [String] = [],
    createdAt: Date
  ) {
    self.id = id
    self.title = title
    self.source = source
    self.paragraphs = paragraphs
    self.reviewSummary = reviewSummary
    self.points = points
    self.questions = questions
    self.masteredParagraphIds = masteredParagraphIds
    self.createdAt = createdAt
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    title = try c.decode(String.self, forKey: .title)
    source = try c.decode(String.self, forKey: .source)
    paragraphs = try c.decodeIfPresent([StudyParagraph].self, forKey: .paragraphs) ?? []
    reviewSummary = try c.decodeIfPresent(String.self, forKey: .reviewSummary)
    points = try c.decodeIfPresent([MemorizePoint].self, forKey: .points) ?? []
    questions = try c.decode([QuizQuestion].self, forKey: .questions)
    masteredParagraphIds = try c.decodeIfPresent([String].self, forKey: .masteredParagraphIds) ?? []
    createdAt = try c.decode(Date.self, forKey: .createdAt)

    if paragraphs.isEmpty, let reviewSummary, !reviewSummary.isEmpty {
      paragraphs = [
        StudyParagraph(id: "\(id)-legacy", label: "\(title) (Overview)", body: reviewSummary),
      ]
    }
  }
}

enum LessonContentAmount: String, CaseIterable, Identifiable {
  case low
  case medium
  case high
  case veryHigh

  var id: String { rawValue }

  static let sectionCount = 8
  static let `default`: LessonContentAmount = .medium

  var label: String {
    switch self {
    case .low: return "Low"
    case .medium: return "Medium"
    case .high: return "High"
    case .veryHigh: return "Very high"
    }
  }

  var wordsPerSection: Int {
    switch self {
    case .low: return 80
    case .medium: return 100
    case .high: return 120
    case .veryHigh: return 150
    }
  }

  var totalWords: Int { Self.sectionCount * wordsPerSection }
}

struct DailyActivityRecord: Codable, Hashable, Identifiable {
  var date: String
  var studyMinutes: Int
  var scrollMinutes: Int

  var id: String { date }
}

struct PersistedSnapshot: Codable {
  static let maxHistoryDays = 90
  static let studySecondsPerDisplayedMinute = 90

  var dailyBudgetMinutes: Int
  var remainingMinutes: Int
  var usedTodayMinutes: Int
  var quizEarnedTodayMinutes: Int
  var studyReadingSecondsToday: Int
  var gateRewardClaimedMinutes: Int
  var gateRewardClaimedSectionIds: [String]
  var lastResetDate: String
  var activityHistory: [DailyActivityRecord]
  var decks: [StudyDeck]
  var activeDeckId: String?
  var interestedTopics: [String]

  enum CodingKeys: String, CodingKey {
    case dailyBudgetMinutes, remainingMinutes, usedTodayMinutes
    case quizEarnedTodayMinutes, studyReadingSecondsToday, gateRewardClaimedMinutes, gateRewardClaimedSectionIds
    case lastResetDate, activityHistory, decks, activeDeckId, interestedTopics
  }

  init(
    dailyBudgetMinutes: Int,
    remainingMinutes: Int,
    usedTodayMinutes: Int,
    quizEarnedTodayMinutes: Int,
    studyReadingSecondsToday: Int = 0,
    gateRewardClaimedMinutes: Int = 0,
    gateRewardClaimedSectionIds: [String] = [],
    lastResetDate: String,
    activityHistory: [DailyActivityRecord] = [],
    decks: [StudyDeck],
    activeDeckId: String?,
    interestedTopics: [String] = []
  ) {
    self.dailyBudgetMinutes = dailyBudgetMinutes
    self.remainingMinutes = remainingMinutes
    self.usedTodayMinutes = usedTodayMinutes
    self.quizEarnedTodayMinutes = quizEarnedTodayMinutes
    self.studyReadingSecondsToday = studyReadingSecondsToday
    self.gateRewardClaimedMinutes = gateRewardClaimedMinutes
    self.gateRewardClaimedSectionIds = gateRewardClaimedSectionIds
    self.lastResetDate = lastResetDate
    self.activityHistory = activityHistory
    self.decks = decks
    self.activeDeckId = activeDeckId
    self.interestedTopics = interestedTopics
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    dailyBudgetMinutes = try c.decode(Int.self, forKey: .dailyBudgetMinutes)
    remainingMinutes = try c.decode(Int.self, forKey: .remainingMinutes)
    usedTodayMinutes = try c.decode(Int.self, forKey: .usedTodayMinutes)
    quizEarnedTodayMinutes = try c.decodeIfPresent(Int.self, forKey: .quizEarnedTodayMinutes) ?? 0
    studyReadingSecondsToday = try c.decodeIfPresent(Int.self, forKey: .studyReadingSecondsToday) ?? 0
    gateRewardClaimedMinutes = try c.decodeIfPresent(Int.self, forKey: .gateRewardClaimedMinutes) ?? 0
    gateRewardClaimedSectionIds = try c.decodeIfPresent([String].self, forKey: .gateRewardClaimedSectionIds) ?? []
    lastResetDate = try c.decode(String.self, forKey: .lastResetDate)
    activityHistory = try c.decodeIfPresent([DailyActivityRecord].self, forKey: .activityHistory) ?? []
    decks = try c.decode([StudyDeck].self, forKey: .decks)
    activeDeckId = try c.decodeIfPresent(String.self, forKey: .activeDeckId)
    interestedTopics = try c.decodeIfPresent([String].self, forKey: .interestedTopics) ?? []
  }

  var studyMinutesToday: Int {
    studyReadingSecondsToday / Self.studySecondsPerDisplayedMinute
  }

  var scrollMinutesToday: Int {
    max(0, dailyBudgetMinutes + quizEarnedTodayMinutes - remainingMinutes)
  }

  var totalSectionsMastered: Int {
    decks.reduce(0) { $0 + $1.masteredParagraphIds.count }
  }

  mutating func archiveDayIfNeeded(beforeResettingFrom previousDate: String) {
    guard !previousDate.isEmpty else { return }
    guard !activityHistory.contains(where: { $0.date == previousDate }) else { return }
    let study = studyReadingSecondsToday / Self.studySecondsPerDisplayedMinute
    let scroll = max(0, dailyBudgetMinutes + quizEarnedTodayMinutes - remainingMinutes)
    guard study > 0 || scroll > 0 else { return }
    activityHistory.append(DailyActivityRecord(date: previousDate, studyMinutes: study, scrollMinutes: scroll))
  }

  mutating func syncTodayActivityHistory(today: String) {
    usedTodayMinutes = scrollMinutesToday
    let record = DailyActivityRecord(
      date: today,
      studyMinutes: studyMinutesToday,
      scrollMinutes: scrollMinutesToday
    )
    if let index = activityHistory.firstIndex(where: { $0.date == today }) {
      activityHistory[index] = record
    } else {
      activityHistory.append(record)
    }
    activityHistory.sort { $0.date > $1.date }
    if activityHistory.count > Self.maxHistoryDays {
      activityHistory = Array(activityHistory.prefix(Self.maxHistoryDays))
    }
  }

  func record(for dateKey: String) -> DailyActivityRecord {
    activityHistory.first { $0.date == dateKey }
      ?? DailyActivityRecord(date: dateKey, studyMinutes: 0, scrollMinutes: 0)
  }

  func lastNDays(_ count: Int, endingOn end: Date = Date()) -> [DailyActivityRecord] {
    let calendar = Calendar.current
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = .current
    return (0..<count).reversed().compactMap { offset in
      guard let day = calendar.date(byAdding: .day, value: -offset, to: end) else { return nil }
      let key = formatter.string(from: day)
      return record(for: key)
    }
  }
}

struct AIDeckResponse: Codable {
  var title: String
  var summary: String?
  var paragraphs: [AIParagraph]?
  var points: [AIMemorizePoint]?
  var questions: [AIQuestion]

  struct AIParagraph: Codable {
    var label: String
    var body: String
  }

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
