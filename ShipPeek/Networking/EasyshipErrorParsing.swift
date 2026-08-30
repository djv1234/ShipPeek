import Foundation

/// Easyship's error payloads vary by endpoint — `{"error": {"message": …, "details": […]}}`,
/// `{"errors": […]}`, and a bare `{"message": …}` have all been seen — so rather than binding to one
/// shape, walk whatever came back and pull out the first human-readable text. When nothing matches,
/// fall back to the raw body: "unknown field `category`" is worth far more than "status 422" when
/// you're getting a request shape right for the first time.
enum EasyshipErrorParsing {
    static func message(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }

        if let object = try? JSONSerialization.jsonObject(with: data), let text = extract(object) {
            return text
        }

        let raw = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        return String(raw.prefix(300))
    }

    private static func extract(_ object: Any) -> String? {
        switch object {
        case let string as String:
            return string.isEmpty ? nil : string
        case let array as [Any]:
            let parts = array.compactMap(extract)
            return parts.isEmpty ? nil : parts.joined(separator: "\n")
        case let dictionary as [String: Any]:
            for key in ["message", "error", "errors", "details", "description"] {
                if let value = dictionary[key], let text = extract(value) { return text }
            }
            return nil
        default:
            return nil
        }
    }
}
