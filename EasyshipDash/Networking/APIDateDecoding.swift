import Foundation

/// Easyship's timestamps aren't all the same shape: list endpoints return ISO-8601 with fractional
/// seconds, `eta_date` comes back as a plain `yyyy-MM-dd`, and some fields omit the timezone.
/// `JSONDecoder.DateDecodingStrategy.iso8601` accepts exactly one of those, and because a single
/// unparseable date fails the *entire* response, one stray format takes down a whole screen.
/// Everything therefore goes through this multi-format parser instead.
enum APIDateDecoding {
    static let strategy: JSONDecoder.DateDecodingStrategy = .custom { decoder -> Date in
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            guard let date = parse(string) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unrecognized date format: \"\(string)\""
                )
            }
            return date
        }

        if let seconds = try? container.decode(Double.self) {
            return Date(timeIntervalSince1970: seconds)
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Date was neither a string nor a number.")
    }

    static func parse(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        for formatter in isoFormatters {
            if let date = formatter.date(from: trimmed) { return date }
        }
        for formatter in fallbackFormatters {
            if let date = formatter.date(from: trimmed) { return date }
        }
        return nil
    }

    private static let isoFormatters: [ISO8601DateFormatter] = {
        let withFractionalSeconds = ISO8601DateFormatter()
        withFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let withoutFractionalSeconds = ISO8601DateFormatter()
        withoutFractionalSeconds.formatOptions = [.withInternetDateTime]

        return [withFractionalSeconds, withoutFractionalSeconds]
    }()

    private static let fallbackFormatters: [DateFormatter] = {
        [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ].map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            return formatter
        }
    }()
}
