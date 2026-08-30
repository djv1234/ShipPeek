import Foundation

/// Debug-only dump of what actually went over the wire.
///
/// A 422 from Easyship names a problem with the request body, and the fastest way to find it is to
/// read the body next to the complaint. Compiled out of release builds entirely, and never prints
/// the `Authorization` header.
enum APIDebugLog {
    static func request(method: String, url: URL, body: Data?) {
        #if DEBUG
        print("\n➡️ \(method) \(url.absoluteString)")
        if let body {
            print(prettyPrinted(body))
        }
        #endif
    }

    static func response(status: Int, body: Data) {
        #if DEBUG
        print("⬅️ \(status)")
        print(prettyPrinted(body))
        print("")
        #endif
    }

    #if DEBUG
    private static func prettyPrinted(_ data: Data) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys]
              )
        else {
            return String(decoding: data, as: UTF8.self)
        }
        return String(decoding: pretty, as: UTF8.self)
    }
    #endif
}
