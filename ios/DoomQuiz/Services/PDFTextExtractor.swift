import Foundation
import PDFKit

/// How much PDF text we send to the model (~12k tokens ≈ $0.0017 input per call at DeepSeek V4 Flash).
enum LessonMaterialLimits {
  /// ~48k chars ≈ 12k tokens — enough to sample a 40-page PDF across all pages.
  static let maxCharacters = 48_000
  /// Per-page cap when sampling long PDFs so one dense page does not dominate.
  static let maxCharactersPerPageWhenSampling = 1_200
}

struct PDFExtractionResult {
  let text: String
  let pageCount: Int
  /// True when the PDF had more text than we could fit — we sampled across pages.
  let wasSampled: Bool

  var summaryLine: String {
    if pageCount == 0 { return "" }
    if wasSampled {
      return "\(pageCount) pages · using highlights across the document"
    }
    return pageCount == 1 ? "1 page imported" : "\(pageCount) pages imported"
  }
}

enum PDFTextExtractor {
  static func extractText(from url: URL) throws -> PDFExtractionResult {
    let accessed = url.startAccessingSecurityScopedResource()
    defer {
      if accessed { url.stopAccessingSecurityScopedResource() }
    }

    guard let document = PDFDocument(url: url) else {
      throw PDFTextExtractorError.unreadable
    }

    let pageCount = document.pageCount
    guard pageCount > 0 else {
      throw PDFTextExtractorError.tooLittleText
    }

    var pageTexts: [String] = []
    for index in 0..<pageCount {
      guard let page = document.page(at: index), let pageText = page.string else { continue }
      let trimmed = pageText.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty { pageTexts.append(trimmed) }
    }

    let combined = pageTexts.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
    guard combined.count >= 20 else {
      throw PDFTextExtractorError.tooLittleText
    }

    let budget = LessonMaterialLimits.maxCharacters
    if combined.count <= budget {
      return PDFExtractionResult(text: combined, pageCount: pageCount, wasSampled: false)
    }

    let sampled = sampleAcrossPages(pageTexts, budget: budget)
    return PDFExtractionResult(text: sampled, pageCount: pageCount, wasSampled: true)
  }

  /// Evenly sample from each page so a 40-page PDF is represented, not just the first chapters.
  private static func sampleAcrossPages(_ pageTexts: [String], budget: Int) -> String {
    guard !pageTexts.isEmpty else { return "" }

    let perPageCap = LessonMaterialLimits.maxCharactersPerPageWhenSampling
    let perPageBudget = max(200, min(perPageCap, budget / pageTexts.count))

    var parts: [String] = []
    var used = 0

    for (index, pageText) in pageTexts.enumerated() {
      guard used < budget else { break }
      let remaining = budget - used
      let sliceBudget = min(perPageBudget, remaining)
      var slice = String(pageText.prefix(sliceBudget))
      if pageText.count > sliceBudget {
        slice += "…"
      }
      parts.append("[Page \(index + 1)]\n\(slice)")
      used += slice.count + 12
    }

    let joined = parts.joined(separator: "\n\n")
    if joined.count <= budget { return joined }
    return String(joined.prefix(budget))
  }

  /// Trim material to the same budget used for API calls (syllabus body already extracted).
  static func clipForModel(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.count <= LessonMaterialLimits.maxCharacters { return trimmed }
    return String(trimmed.prefix(LessonMaterialLimits.maxCharacters))
  }
}

enum PDFTextExtractorError: LocalizedError {
  case unreadable
  case tooLittleText

  var errorDescription: String? {
    switch self {
    case .unreadable: return "Couldn't read that PDF. Try a different file."
    case .tooLittleText: return "That PDF doesn't have enough readable text."
    }
  }
}
