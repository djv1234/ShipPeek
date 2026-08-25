import Foundation
import Security

/// Minimal wrapper around Keychain Services for storing the Easyship API token per environment.
enum KeychainStore {
    private static let service = "com.sergeyvolf.EasyshipDash.apiToken"

    static func token(for environment: EasyshipEnvironment) -> String? {
        var query = baseQuery(for: environment)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func setToken(_ token: String, for environment: EasyshipEnvironment) {
        let query = baseQuery(for: environment)
        let attributes: [String: Any] = [kSecValueData as String: Data(token.utf8)]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        } else {
            var newItem = query
            newItem[kSecValueData as String] = Data(token.utf8)
            SecItemAdd(newItem as CFDictionary, nil)
        }
    }

    static func deleteToken(for environment: EasyshipEnvironment) {
        let query = baseQuery(for: environment)
        SecItemDelete(query as CFDictionary)
    }

    private static func baseQuery(for environment: EasyshipEnvironment) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: environment.rawValue
        ]
    }
}
