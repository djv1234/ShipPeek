import Foundation

/// Easyship's error payloads vary by endpoint — `{"error": {"message": …, "details": […]}}`,
/// `{"errors": […]}`, and a bare `{"message": …}` have all been seen — so rather than binding to one
/// shape, walk whatever came back and collect every human-readable string.
///
/// Collecting *all* of them matters: on a 422 the `message` is a generic "The request body content
/// is not valid." while `details` carries the per-field complaint that actually tells you what to
/// fix. Returning only the first match hid the useful half.
enum EasyshipErrorParsing {
    private static let maxLength = 600

    static func message(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }

        if let object = try? JSONSerialization.jsonObject(with: data) {
            var seen = Set<String>()
            let parts = extractAll(object).filter { seen.insert($0).inserted }
            if !parts.isEmpty {
                return truncated(parts.joined(separator: "\n"))
            }
        }

        let raw = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        return truncated(raw)
    }

    private static func extractAll(_ object: Any) -> [String] {
        switch object {
        case let string as String:
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? [] : [trimmed]
        case let array as [Any]:
            return array.flatMap(extractAll)
        case let dictionary as [String: Any]:
            // Ordered so the summary reads first and the field-level detail follows.
            return ["message", "details", "errors", "error", "description"]
                .compactMap { dictionary[$0] }
                .flatMap(extractAll)
        default:
            return []
        }
    }

    private static func truncated(_ text: String) -> String {
        text.count <= maxLength ? text : String(text.prefix(maxLength)) + "…"
    }
}
