import AppKit

/// Recognises simple arithmetic (e.g. "12 * (4 + 2) / 3") and evaluates it
/// with NSExpression — no query is sent anywhere, it's all local.
final class CalculatorProvider: SearchProvider {
    let id = "calculator"
    let displayName = "Calculator"

    private let allowedCharacters = CharacterSet(charactersIn: "0123456789.+-*/()% ")

    func results(for query: String) async -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil else { return [] }
        guard trimmed.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else { return [] }

        let expression = NSExpression(format: trimmed.replacingOccurrences(of: "x", with: "*"))
        guard let value = expression.expressionValue(with: nil, context: nil) as? NSNumber else { return [] }

        let formatted = formatNumber(value.doubleValue)
        return [
            SearchResult(
                title: formatted,
                subtitle: "\(trimmed) = \(formatted)  ·  ⏎ to copy",
                icon: NSImage(systemSymbolName: "equal.circle.fill", accessibilityDescription: nil),
                category: .calculator,
                score: 95,
                action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(formatted, forType: .string)
                }
            )
        ]
    }

    private func formatNumber(_ value: Double) -> String {
        if value == value.rounded() && abs(value) < 1e15 {
            return String(format: "%.0f", value)
        }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 6
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
