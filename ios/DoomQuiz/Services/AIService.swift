import Foundation

private enum WorkerConfig {
  static let endpoint = "https://habitmap.asminrijal289-f9b.workers.dev"
  static let clientSecret = "abcdefghijklmnopqrstuvwxyzabcdef"
  static let model = "deepseek/deepseek-v4-flash"
  static let maxTokens = 3200
}

enum AIService {
  /// 8 reading sections × 150 words (~1200 words total).
  private static let lessonSectionCount = 8
  private static let wordsPerSection = 150
  private static var lessonTotalWords: Int { lessonSectionCount * wordsPerSection }

  private static func paragraphsPrompt(wordsPerSection: Int) -> String {
    let totalWords = lessonSectionCount * wordsPerSection
    return paragraphsPromptBase
      .replacingOccurrences(of: "WORDS_TOTAL", with: "\(totalWords)")
      .replacingOccurrences(of: "WORDS_EACH", with: "\(wordsPerSection)")
  }

  private static let paragraphsPromptBase = """
    Output ONLY one JSON object. No markdown, no commentary.
    {"title":"short title","paragraphs":[{"label":"Topic (Intro)","body":"string"}]}
    Rules:
    - Exactly 8 paragraphs — one mini-lesson path, NOT a textbook or Wikipedia dump.
    - Total reading length across all 8 bodies: about WORDS_TOTAL words (~WORDS_EACH words per section).
    - EXPLANATION over information: ~80% should explain why and how (walk the reader through ideas). ~20% facts, syntax, or names — no trivia lists or stat walls.
    - STRICT: each paragraph may include at most 5–6 numbers, dates, or statistics total.
    - Label sections with the topic name, e.g. "Python loops (Intro)", "Python loops (for loop syntax)", "World War 2 (Causes)".

    PROGRAMMING / SYNTAX / TOOLS topics (Python, JavaScript, SQL, Excel formulas, etc.):
    - EVERY section MUST include at least one short concrete example inline (1–6 lines of code, a command, or a formula).
    - Explain what each line does — not just show syntax without teaching.
    - Spread the lesson across 8 steps: intro → core syntax → examples → patterns → edge cases → practice mindset → recap.

    HISTORY / CONCEPTS / SCIENCE topics:
    - Explain cause-effect and meaning in plain language — spread the narrative across all 8 sections.
  """

  private static var bundledQuizRules: String {
    """
    - Each section MUST include exactly 6 questions in its "questions" array.
    - Each question: {"prompt":"string","choices":["A","B","C","D"],"correctIndex":0} with correctIndex 0-3.
    - Questions test ONLY that section's body — practical, not trivia.
    - Programming topics: at least 4 of 6 questions use short code snippets or code in choices.
    """
  }

  private static func firstSectionPrompt(wordsPerSection: Int) -> String {
    """
    Output ONLY one JSON object. No markdown, no commentary.
    {
      "sectionPlans": ["topic 1","topic 2","topic 3","topic 4","topic 5","topic 6","topic 7","topic 8"],
      "firstSection": {
        "label":"string",
        "body":"string",
        "questions":[{"prompt":"string","choices":["A","B","C","D"],"correctIndex":0}]
      }
    }
    Rules:
    - sectionPlans must contain exactly 8 concise section topics in learning order.
    - firstSection must match sectionPlans[0].
    - firstSection body should be around \(wordsPerSection) words.
    \(bundledQuizRules)
    - Keep explanations beginner-friendly and practical.
    """
  }

  private static func remainingSectionsPrompt(wordsPerSection: Int) -> String {
    """
    Output ONLY one JSON object. No markdown, no commentary.
    {
      "topicEmoji":"single emoji that fits the lesson topic",
      "paragraphs":[
        {"label":"string","body":"string","questions":[{"prompt":"string","choices":["A","B","C","D"],"correctIndex":0}]}
      ]
    }
    Rules:
    - topicEmoji must be exactly one emoji character (e.g. ⚔️ for Vikings, 🐍 for Python, 🇪🇸 for Spanish).
    - Return exactly 7 sections (sections 2 through 8 only).
    - Follow the provided section plan exactly in order.
    - Do not regenerate section 1.
    - Each body should be around \(wordsPerSection) words.
    \(bundledQuizRules)
    - Keep tone and difficulty consistent with section 1.
    """
  }

  private static let sectionQuestionsPrompt = """
    Output ONLY one JSON object. No markdown, no commentary.
    {"questions":[{"prompt":"string","choices":["A","B","C","D"],"correctIndex":0}]}
    Rules:
    - Exactly 6 questions, each with 4 choices, correctIndex 0-3.
    - Questions must test ONLY the single reading section provided — not other sections.
    - Practical mini-quiz: one clear idea from the section — not trivia or extra facts that were not taught.

    If the topic is programming, code, syntax, or a tool (loops, functions, SQL, APIs, etc.):
    - At least 4 of 6 questions MUST involve code: show a short snippet in the prompt OR put code lines in the choices.
    - Question types: correct syntax, predict output, spot the bug, pick the right keyword/indentation, what happens if you run this.
    - Wrong answers must be plausible code mistakes — not unrelated facts.
    - Keep snippets short (1–5 lines). No markdown fences in JSON strings.

    Otherwise:
    - Ask apply-the-concept questions; avoid pure definition or date memorization.
  """

  /// ~1200 words of lesson JSON — one request, not per-section.
  private static let quizMaxTokens = 2000

  private static func lessonMaxTokens(for wordsPerSection: Int) -> Int {
    min(5200, max(2800, lessonSectionCount * wordsPerSection * 3))
  }

  private static func lessonWithQuizzesMaxTokens(for wordsPerSection: Int, sectionCount: Int) -> Int {
    min(12_000, max(6000, sectionCount * (wordsPerSection * 3 + 900)))
  }

  static func generateDeck(
    title: String,
    content: String,
    source: String
  ) async throws -> StudyDeck {
    let material = studyMaterial(title: title, content: content, source: source)
    let id = "deck-\(Int(Date().timeIntervalSince1970))"
    var allQuestions: [QuizQuestion] = []
    let paragraphs = try await generateLessonParagraphsProgressive(
      deckId: id,
      title: title,
      material: material,
      source: source,
      wordsPerSection: LessonContentAmount.default.wordsPerSection
    ) { _, _, questions, _ in
      allQuestions.append(contentsOf: questions)
    }
    return StudyDeck(
      id: id,
      title: title,
      source: source,
      paragraphs: paragraphs,
      points: [],
      questions: allQuestions,
      createdAt: Date()
    )
  }

  /// Two API calls, each section bundled with its quiz:
  /// - Call 1: 8 topic outline + section 1 reading + section 1 quiz
  /// - Call 2: topic emoji + sections 2–8, each with its own quiz
  static func generateLessonParagraphsProgressive(
    deckId: String,
    title: String,
    material: String,
    source: String = "topic",
    wordsPerSection: Int = LessonContentAmount.default.wordsPerSection,
    onSection: @MainActor @escaping (Int, StudyParagraph, [QuizQuestion], String?) -> Void
  ) async throws -> [StudyParagraph] {
    let first = try await fetchLessonPlanAndFirstSection(
      title: title,
      material: material,
      source: source,
      wordsPerSection: wordsPerSection
    )
    let firstParagraph = StudyParagraph(
      id: "\(deckId)-para0",
      label: first.first.label,
      body: first.first.body
    )
    let firstQuestions = try await resolveSectionQuestions(
      parsed: first.first.questions,
      deckId: deckId,
      paragraph: firstParagraph,
      material: material,
      deckTitle: title
    )
    var paragraphs: [StudyParagraph] = [firstParagraph]
    await onSection(0, firstParagraph, firstQuestions, nil)

    let tail = try await fetchRemainingSections(
      material: material,
      source: source,
      sectionPlans: first.sectionPlans,
      firstSection: (label: first.first.label, body: first.first.body),
      wordsPerSection: wordsPerSection
    )

    if let topicEmoji = tail.topicEmoji {
      await onSection(0, firstParagraph, [], topicEmoji)
    }

    for (offset, section) in tail.sections.enumerated() {
      let index = offset + 1
      let paragraph = StudyParagraph(
        id: "\(deckId)-para\(index)",
        label: section.label,
        body: section.body
      )
      let questions = try await resolveSectionQuestions(
        parsed: section.questions,
        deckId: deckId,
        paragraph: paragraph,
        material: material,
        deckTitle: title
      )
      paragraphs.append(paragraph)
      await onSection(index, paragraph, questions, nil)
    }

    guard paragraphs.count >= 6 else {
      throw AIServiceError.server("AI returned too few reading sections.")
    }
    return paragraphs
  }

  /// Phase 1 (batch): all sections at once — used only for legacy/backfill paths.
  static func generateLessonDeck(
    title: String,
    content: String,
    source: String,
    wordsPerSection: Int = LessonContentAmount.default.wordsPerSection
  ) async throws -> StudyDeck {
    let material = studyMaterial(title: title, content: content, source: source)
    let id = "deck-\(Int(Date().timeIntervalSince1970))"
    let paragraphs = try await generateLessonParagraphsProgressive(
      deckId: id,
      title: title,
      material: material,
      source: source,
      wordsPerSection: wordsPerSection,
      onSection: { _, _, _, _ in }
    )

    return StudyDeck(
      id: id,
      title: title,
      source: source,
      paragraphs: paragraphs,
      reviewSummary: source == "syllabus" ? PDFTextExtractor.clipForModel(content) : nil,
      points: [],
      questions: [],
      createdAt: Date()
    )
  }

  /// Phase 2: all section quizzes (run in background while user reads).
  static func generateAllSectionQuestions(
    deckId: String,
    paragraphs: [StudyParagraph],
    material: String,
    deckTitle: String
  ) async throws -> [QuizQuestion] {
    try await generateSectionQuestions(
      deckId: deckId,
      paragraphs: paragraphs,
      material: material,
      deckTitle: deckTitle
    )
  }

  private static func studyMaterial(title: String, content: String, source: String) -> String {
    if source == "topic" { return "Topic: \(title)" }
    let clipped = PDFTextExtractor.clipForModel(content)
    return "Study material (\(title)):\n\n\(clipped)"
  }

  private static func syllabusLessonInstructions(wordsPerSection: Int, totalWords: Int) -> String {
    """
    The user uploaded PDF study material above. Base all 8 sections on that document.
    Do not add major topics that are not in the material. Spread ideas across sections 1–8 in a logical order.
    Total lesson target: \(totalWords) words (~\(wordsPerSection) words per section).
    """
  }

  /// Generate 6 questions for one section (used for backfill).
  static func generateQuestions(
    for paragraph: StudyParagraph,
    deckId: String,
    title: String,
    material: String
  ) async throws -> [QuizQuestion] {
    try await fetchSectionQuestions(
      deckId: deckId,
      paragraph: paragraph,
      material: material,
      topicTitle: title
    )
  }

  /// Backfill reading paragraphs for an existing AI deck.
  static func generateParagraphs(
    deckId: String,
    title: String,
    source: String,
    wordsPerSection: Int = LessonContentAmount.default.wordsPerSection
  ) async throws -> [StudyParagraph] {
    let material = studyMaterial(title: title, content: title, source: source)
    return try await generateLessonParagraphsProgressive(
      deckId: deckId,
      title: title,
      material: material,
      source: source,
      wordsPerSection: wordsPerSection,
      onSection: { _, _, _, _ in }
    )
  }

  // MARK: - Section questions

  private static func generateSectionQuestions(
    deckId: String,
    paragraphs: [StudyParagraph],
    material: String,
    deckTitle: String
  ) async throws -> [QuizQuestion] {
  try await withThrowingTaskGroup(of: [QuizQuestion].self) { group in
      for paragraph in paragraphs {
        group.addTask {
          try await fetchSectionQuestions(
            deckId: deckId,
            paragraph: paragraph,
            material: material,
            topicTitle: deckTitle
          )
        }
      }

      var all: [QuizQuestion] = []
      for try await sectionQuestions in group {
        all.append(contentsOf: sectionQuestions)
      }
      return all
    }
  }

  private static func fetchSectionQuestions(
    deckId: String,
    paragraph: StudyParagraph,
    material: String,
    topicTitle: String?
  ) async throws -> [QuizQuestion] {
    var lastError: Error?
    for _ in 0..<2 {
      do {
        let raw = try await callWorker(
          system: sectionQuestionsPrompt,
          user: """
          \(material)
          Lesson title: \(topicTitle ?? "lesson")

          Section to test:
          【\(paragraph.label)】
          \(paragraph.body)

          Create 6 multiple-choice questions for this section only. Quiz what was actually taught above.
          """,
          maxTokens: quizMaxTokens
        )
        let parsed = try parseQuestionsPayload(from: raw)
        guard parsed.count >= 4 else {
          throw AIServiceError.server("AI returned too few section questions.")
        }

        return mapQuestions(
          Array(parsed.prefix(RewardCalculator.sectionQuestionCount)),
          deckId: deckId,
          paragraphId: paragraph.id
        )
      } catch {
        lastError = error
      }
    }
    let label = topicTitle ?? paragraph.label
    throw lastError ?? AIServiceError.server("Could not generate questions for \(label).")
  }

  // MARK: - Fetch helpers

  private static func resolveSectionQuestions(
    parsed: [(prompt: String, choices: [String], correctIndex: Int)],
    deckId: String,
    paragraph: StudyParagraph,
    material: String,
    deckTitle: String
  ) async throws -> [QuizQuestion] {
    if parsed.count >= 4 {
      return mapQuestions(parsed, deckId: deckId, paragraphId: paragraph.id)
    }
    return try await fetchSectionQuestions(
      deckId: deckId,
      paragraph: paragraph,
      material: material,
      topicTitle: deckTitle
    )
  }

  private static func mapQuestions(
    _ parsed: [(prompt: String, choices: [String], correctIndex: Int)],
    deckId: String,
    paragraphId: String
  ) -> [QuizQuestion] {
    parsed.prefix(RewardCalculator.sectionQuestionCount).enumerated().map { index, q in
      var choices = q.choices.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      while choices.count < 4 { choices.append("Option \(choices.count + 1)") }
      return QuizQuestion(
        id: "\(deckId)-\(paragraphId)-q\(index)",
        prompt: q.prompt,
        choices: Array(choices.prefix(4)),
        correctIndex: min(3, max(0, q.correctIndex)),
        paragraphId: paragraphId
      )
    }
  }

  private static func fetchLessonPlanAndFirstSection(
    title: String,
    material: String,
    source: String,
    wordsPerSection: Int
  ) async throws -> (
    sectionPlans: [String],
    first: (label: String, body: String, questions: [(prompt: String, choices: [String], correctIndex: Int)])
  ) {
    let totalWords = lessonSectionCount * wordsPerSection
    let lessonBrief =
      source == "syllabus"
      ? syllabusLessonInstructions(wordsPerSection: wordsPerSection, totalWords: totalWords)
      : """
        What the user wants to learn: "\(title)"
        Create 8 section topics + section 1 full content + 6 quiz questions for section 1.
        Total lesson target: \(totalWords) words, with each section around \(wordsPerSection) words.
        Assume the user has never studied this topic before, so teach from beginner level and build up step by step.
        Do NOT write a guide on how to learn it.
        """
    var lastError: Error?
    for _ in 0..<2 {
      do {
        let raw = try await callWorker(
          system: firstSectionPrompt(wordsPerSection: wordsPerSection),
          user: """
          \(material)

          \(lessonBrief)
          """,
          maxTokens: lessonWithQuizzesMaxTokens(for: wordsPerSection, sectionCount: 1)
        )
        let parsed = try parsePlanAndFirstSection(from: raw)
        guard parsed.sectionPlans.count == lessonSectionCount else {
          throw AIServiceError.server("AI returned an invalid section plan.")
        }
        return parsed
      } catch {
        lastError = error
      }
    }
    throw lastError ?? AIServiceError.server("Could not generate section plan.")
  }

  private static func fetchRemainingSections(
    material: String,
    source: String,
    sectionPlans: [String],
    firstSection: (label: String, body: String),
    wordsPerSection: Int
  ) async throws -> (
    topicEmoji: String?,
    sections: [(
      label: String,
      body: String,
      questions: [(prompt: String, choices: [String], correctIndex: Int)]
    )]
  ) {
    var lastError: Error?
    for _ in 0..<2 {
      do {
        let raw = try await callWorker(
          system: remainingSectionsPrompt(wordsPerSection: wordsPerSection),
          user: """
          \(material)

          Section plan (use EXACTLY this order):
          \(sectionPlans.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))

          Section 1 already written:
          label: \(firstSection.label)
          body: \(firstSection.body)

          Generate sections 2 through 8 only. Each section must include 6 quiz questions.
          \(source == "syllabus" ? "Stay faithful to the uploaded study material; do not invent unrelated topics." : "")
          """,
          maxTokens: lessonWithQuizzesMaxTokens(for: wordsPerSection, sectionCount: 7)
        )
        let parsed = try parseRemainingSections(from: raw)
        if parsed.sections.count >= 5 {
          return parsed
        }
      } catch {
        lastError = error
      }
    }
    throw lastError ?? AIServiceError.server("Could not generate remaining sections.")
  }

  private static func parsePlanAndFirstSection(from raw: String) throws -> (
    sectionPlans: [String],
    first: (label: String, body: String, questions: [(prompt: String, choices: [String], correctIndex: Int)])
  ) {
    let jsonText = sanitizeJSON(extractJSONString(from: raw))
    guard let data = jsonText.data(using: .utf8),
      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      throw AIServiceError.server("Could not parse section plan.")
    }

    let sectionPlans = parseSectionPlanList(from: root)
    guard sectionPlans.count == lessonSectionCount else {
      throw AIServiceError.server("Missing section topics in AI response.")
    }

    let firstObj = root["firstSection"] as? [String: Any] ?? [:]
    let firstLabel = ((firstObj["label"] ?? firstObj["title"]) as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let firstBody = ((firstObj["body"] ?? firstObj["content"] ?? firstObj["text"]) as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !firstLabel.isEmpty, !firstBody.isEmpty else {
      throw AIServiceError.server("Missing first section content in AI response.")
    }
    let firstQuestions = parseQuestionsFromObject(firstObj)
    return (sectionPlans, (firstLabel, firstBody, firstQuestions))
  }

  /// Keep a single emoji grapheme; strip anything else the model might add.
  private static func sanitizeTopicEmoji(_ raw: String?) -> String? {
    guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
          let first = raw.first else { return nil }
    let emoji = String(first)
    let isEmoji = emoji.unicodeScalars.contains {
      $0.properties.isEmojiPresentation || $0.properties.isEmoji
    }
    return isEmoji ? emoji : nil
  }

  private static func parseRemainingSections(from raw: String) throws -> (
    topicEmoji: String?,
    sections: [(
      label: String,
      body: String,
      questions: [(prompt: String, choices: [String], correctIndex: Int)]
    )]
  ) {
    let jsonText = sanitizeJSON(extractJSONString(from: raw))
    guard let data = jsonText.data(using: .utf8),
      let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      throw AIServiceError.server("Could not parse remaining sections.")
    }
    let rawParagraphs = root["paragraphs"] as? [[String: Any]] ?? []
    let paragraphs = rawParagraphs.compactMap { item -> (String, String, [(prompt: String, choices: [String], correctIndex: Int)])? in
      let label = ((item["label"] ?? item["title"] ?? item["topic"]) as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let body = ((item["body"] ?? item["text"] ?? item["content"]) as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      guard !label.isEmpty, !body.isEmpty else { return nil }
      return (label, body, parseQuestionsFromObject(item))
    }
    guard !paragraphs.isEmpty else { throw AIServiceError.server("No remaining sections in AI response.") }
    let topicEmoji = sanitizeTopicEmoji(root["topicEmoji"] as? String)
    return (topicEmoji, paragraphs)
  }

  private static func parseQuestionsFromObject(_ object: [String: Any]) -> [(prompt: String, choices: [String], correctIndex: Int)] {
    let rawQuestions = (object["questions"] ?? object["quiz"]) as? [[String: Any]] ?? []
    return rawQuestions.compactMap { parseQuestionItem($0) }
  }

  private static func parseSectionPlanList(from root: [String: Any]) -> [String] {
    if let plans = root["sectionPlans"] as? [String] {
      return plans.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    if let sections = root["sectionPlans"] as? [[String: Any]] {
      return sections.compactMap {
        (($0["title"] ?? $0["label"] ?? $0["topic"]) as? String)?
          .trimmingCharacters(in: .whitespacesAndNewlines)
      }.filter { !$0.isEmpty }
    }
    return []
  }

  private static func parseQuestionsPayload(from raw: String) throws -> [(prompt: String, choices: [String], correctIndex: Int)] {
    let jsonText = sanitizeJSON(extractJSONString(from: raw))
    guard let data = jsonText.data(using: .utf8) else {
      throw AIServiceError.server("Could not parse quiz questions.")
    }

    if let response = try? JSONDecoder().decode(AIDeckResponse.self, from: data), !response.questions.isEmpty {
      return response.questions.map { ($0.prompt, $0.choices, $0.correctIndex) }
    }

    guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw AIServiceError.server("Could not parse quiz questions.")
    }

    let rawQuestions = (root["questions"] ?? root["quiz"]) as? [[String: Any]] ?? []
    let questions = rawQuestions.compactMap { parseQuestionItem($0) }
    guard !questions.isEmpty else {
      throw AIServiceError.server("No questions in AI response.")
    }
    return questions
  }

  private static func parseQuestionItem(_ item: [String: Any]) -> (String, [String], Int)? {
    let prompt =
      (item["prompt"] ?? item["question"] ?? item["text"] ?? item["stem"]) as? String ?? ""
    guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

    var choices: [String] = []
    if let arr = item["choices"] as? [String] { choices = arr }
    else if let arr = item["options"] as? [String] { choices = arr }
    else if let arr = item["answers"] as? [String] { choices = arr }
    else if let arr = item["choices"] as? [[String: Any]] {
      choices = arr.compactMap { $0["text"] as? String ?? $0["label"] as? String }
    }

    choices = choices.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    while choices.count < 4 { choices.append("None of the above") }

    var correctIndex = 0
    if let idx = item["correctIndex"] as? Int { correctIndex = idx }
    else if let idx = item["correct_index"] as? Int { correctIndex = idx }
    else if let letter = item["answer"] as? String { correctIndex = letterIndex(letter) }
    else if let idx = item["correct"] as? Int { correctIndex = idx }

    return (prompt, Array(choices.prefix(4)), min(3, max(0, correctIndex)))
  }

  private static func letterIndex(_ letter: String) -> Int {
    switch letter.uppercased().trimmingCharacters(in: .whitespacesAndNewlines) {
    case "A", "0": return 0
    case "B", "1": return 1
    case "C", "2": return 2
    case "D", "3": return 3
    default: return 0
    }
  }

  private static func sanitizeJSON(_ text: String) -> String {
    var s = text
      .replacingOccurrences(of: "\u{201C}", with: "\"")
      .replacingOccurrences(of: "\u{201D}", with: "\"")
      .replacingOccurrences(of: "\u{2018}", with: "'")
      .replacingOccurrences(of: "\u{2019}", with: "'")
    s = s.replacingOccurrences(
      of: ",\\s*([}\\]])",
      with: "$1",
      options: .regularExpression
    )
    return s.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static func extractJSONString(from text: String) -> String {
    var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

    if let fenceStart = cleaned.range(of: "```") {
      let afterFence = cleaned[fenceStart.upperBound...]
      if let fenceEnd = afterFence.range(of: "```") {
        var inner = String(afterFence[..<fenceEnd.lowerBound])
        if inner.hasPrefix("json") { inner = String(inner.dropFirst(4)) }
        cleaned = inner.trimmingCharacters(in: .whitespacesAndNewlines)
      }
    }

    guard let start = cleaned.firstIndex(of: "{") else { return cleaned }

    var depth = 0
    var inString = false
    var escaped = false
    var end = start

    for idx in cleaned.indices[start...] {
      let ch = cleaned[idx]
      if inString {
        if escaped { escaped = false }
        else if ch == "\\" { escaped = true }
        else if ch == "\"" { inString = false }
        continue
      }
      if ch == "\"" { inString = true; continue }
      if ch == "{" { depth += 1 }
      if ch == "}" {
        depth -= 1
        end = idx
        if depth == 0 { break }
      }
    }

    return depth == 0 ? String(cleaned[start...end]) : String(cleaned[start...])
  }

  // MARK: - Worker

  private static func callWorker(
    system: String,
    user: String,
    maxTokens: Int = WorkerConfig.maxTokens
  ) async throws -> String {
    guard WorkerConfig.endpoint.contains("workers.dev"),
      !WorkerConfig.endpoint.contains("YOUR_SUBDOMAIN")
    else {
      throw AIServiceError.server("Deploy the DoomQuiz worker and set endpoint in WorkerConfig.swift")
    }

    guard let url = URL(string: WorkerConfig.endpoint) else {
      throw AIServiceError.server("Invalid worker URL in WorkerConfig.swift")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 90
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(WorkerConfig.clientSecret, forHTTPHeaderField: "X-Dailyflow-Key")

    let body: [String: Any] = [
      "model": WorkerConfig.model,
      "messages": [
        ["role": "system", "content": system],
        ["role": "user", "content": user],
      ],
      "temperature": 0.2,
      "max_tokens": maxTokens,
      "reasoning": ["effort": "none"],
      "provider": [
        "order": ["parasail", "deepinfra"],
        "allow_fallbacks": true,
      ] as [String: Any],
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw AIServiceError.invalidResponse
    }
    if http.statusCode >= 400 {
      throw AIServiceError.server(String(data: data, encoding: .utf8) ?? "Worker error")
    }

    guard let text = extractAssistantText(from: data), !text.isEmpty else {
      throw AIServiceError.server("Empty AI response. Check WorkerConfig and try again.")
    }
    return text
  }

  private static func extractAssistantText(from data: Data) -> String? {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let choices = json["choices"] as? [[String: Any]],
      let first = choices.first,
      let message = first["message"] as? [String: Any]
    else { return nil }

    if let content = contentString(from: message["content"]), !content.isEmpty {
      return content
    }
    if let reasoning = message["reasoning"] as? String, reasoning.contains("{") {
      return reasoning
    }
    return nil
  }

  private static func contentString(from value: Any?) -> String? {
    guard let value else { return nil }
    if let s = value as? String { return s.isEmpty ? nil : s }
    if let arr = value as? [[String: Any]] {
      let parts = arr.compactMap { item -> String? in
        if let t = item["text"] as? String, !t.isEmpty { return t }
        if let t = item["content"] as? String, !t.isEmpty { return t }
        return nil
      }
      let joined = parts.joined(separator: "\n")
      return joined.isEmpty ? nil : joined
    }
    return nil
  }
}

enum AIServiceError: LocalizedError {
  case invalidResponse
  case server(String)

  var errorDescription: String? {
    switch self {
    case .invalidResponse: return "Invalid server response"
    case .server(let message): return message
    }
  }
}
