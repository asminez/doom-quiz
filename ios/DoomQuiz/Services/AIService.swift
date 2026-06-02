import Foundation

enum AIService {
  /// Same Cloudflare Worker as AIwidget `BridgeConfig`.
  private static let workerEndpoint = "https://habitmap.asminrijal289-f9b.workers.dev"
  private static let workerClientSecret = "abcdefghijklmnopqrstuvwxyzabcdef"

  private static let model = "deepseek/deepseek-v4-flash"
  private static let deckMaxTokens = 1200

  private static let topicSystemPrompt = """
    You are a quiz writer for DoomQuiz. The user wants to LEARN a topic (not dump a syllabus). Output ONLY valid JSON:
    {
      "title": "short topic title",
      "points": [
        { "term": "key idea", "definition": "1-2 sentence explanation" }
      ],
      "questions": [
        {
          "prompt": "multiple choice question",
          "choices": ["A", "B", "C", "D"],
          "correctIndex": 0
        }
      ]
    }
    Rules:
    - 5-8 points for quick review (secondary to the quiz).
    - Exactly 5 questions — these are the main product; make them clear, fair, and educational.
    - Questions should teach the topic, not trick the user.
    - Assume the user has never studied this topic before.
    - Keep language beginner-friendly, define terms simply, and build up step by step.
    """

  private static let syllabusSystemPrompt = """
    You are a study coach for DoomQuiz Premium. Given syllabus or class notes, output ONLY valid JSON with the same shape as topic decks.
    Rules:
    - 7-8 memorize points tied to the provided material.
    - Exactly 5 multiple-choice questions that test that material.
    """

  static func generateDeck(
    title: String,
    content: String,
    source: String
  ) async throws -> StudyDeck {
    let system = source == "topic" ? topicSystemPrompt : syllabusSystemPrompt
    let userLabel =
      source == "topic"
      ? "Learning topic: \(title)\n\nCreate a quiz that helps a beginner learn this."
      : "Study material (\(title)):\n\n\(String(content.prefix(12_000)))"

    let messages: [[String: String]] = [
      ["role": "system", "content": system],
      ["role": "user", "content": userLabel],
    ]

    let raw = try await callWorker(messages: messages)
    let jsonText = extractJSONString(from: raw)
    guard let jsonData = jsonText.data(using: .utf8) else {
      throw AIServiceError.server("Could not read model JSON")
    }

    let decoded = try JSONDecoder().decode(AIDeckResponse.self, from: jsonData)
    let id = "deck-\(Int(Date().timeIntervalSince1970))"

    let points = decoded.points.prefix(8).enumerated().map { index, p in
      MemorizePoint(id: "\(id)-p\(index)", term: p.term, definition: p.definition)
    }

    let questions = decoded.questions.prefix(5).enumerated().map { index, q in
      var choices = q.choices
      while choices.count < 4 { choices.append("—") }
      return QuizQuestion(
        id: "\(id)-q\(index)",
        prompt: q.prompt,
        choices: Array(choices.prefix(4)),
        correctIndex: min(3, max(0, q.correctIndex))
      )
    }

    return StudyDeck(
      id: id,
      title: decoded.title.isEmpty ? title : decoded.title,
      source: source,
      points: Array(points),
      questions: Array(questions),
      createdAt: Date()
    )
  }

  private static func callWorker(messages: [[String: String]]) async throws -> String {
    guard let url = URL(string: workerEndpoint) else {
      throw AIServiceError.server("Invalid worker URL")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 60
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if !workerClientSecret.isEmpty {
      request.setValue(workerClientSecret, forHTTPHeaderField: "X-Dailyflow-Key")
    }

    let body: [String: Any] = [
      "model": model,
      "messages": messages,
      "temperature": 0.3,
      "max_tokens": deckMaxTokens,
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
      let snippet = String(data: data, encoding: .utf8)?.prefix(280) ?? "non-utf8"
      throw AIServiceError.server("Empty model response. Raw: \(snippet)")
    }
    return text
  }

  private static func extractAssistantText(from data: Data) -> String? {
    guard let json = try? JSONSerialization.jsonObject(with: data) else { return nil }

    if let obj = json as? [String: Any] {
      if let t = extractFromChoicesObject(obj), !t.isEmpty { return t }
      if let err = obj["error"] as? [String: Any], let msg = err["message"] as? String {
        return nil
      }
    }

    if let arr = json as? [[String: Any]] {
      for element in arr {
        if let t = extractFromChoicesObject(element), !t.isEmpty { return t }
      }
    }

    return nil
  }

  private static func extractFromChoicesObject(_ obj: [String: Any]) -> String? {
    guard let choices = obj["choices"] as? [[String: Any]], let first = choices.first else {
      return nil
    }

    if let message = first["message"] as? [String: Any] {
      if let content = contentString(from: message["content"]), !content.isEmpty {
        return content
      }
      if let reasoning = message["reasoning"] as? String, !reasoning.isEmpty,
        reasoning.contains("{")
      {
        return reasoning
      }
    }

    if let text = first["text"] as? String, !text.isEmpty { return text }
    if let output = obj["output"] as? String, !output.isEmpty { return output }
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

  private static func extractJSONString(from text: String) -> String {
    if let fenceStart = text.range(of: "```"),
      let fenceEnd = text.range(of: "```", range: fenceStart.upperBound..<text.endIndex)
    {
      var inner = String(text[fenceStart.upperBound..<fenceEnd.lowerBound])
      if inner.hasPrefix("json") {
        inner = String(inner.dropFirst(4))
      }
      return inner.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if let first = text.firstIndex(of: "{"), let last = text.lastIndex(of: "}") {
      return String(text[first...last])
    }
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
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
