import Foundation

enum QuizSession {
  static func prepare(_ source: [QuizQuestion]) -> [QuizQuestion] {
    source.shuffled().map { shuffleChoices(in: $0) }
  }

  private static func shuffleChoices(in question: QuizQuestion) -> QuizQuestion {
    guard question.choices.indices.contains(question.correctIndex) else { return question }
    let correctAnswer = question.choices[question.correctIndex]
    let shuffledChoices = question.choices.shuffled()
    let newIndex = shuffledChoices.firstIndex(of: correctAnswer) ?? question.correctIndex
    return QuizQuestion(
      id: question.id,
      prompt: question.prompt,
      choices: shuffledChoices,
      correctIndex: newIndex,
      paragraphId: question.paragraphId
    )
  }
}
