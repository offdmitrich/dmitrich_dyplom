import Foundation
import Security

enum KeychainPINStoreError: Error {
    case encodingFailed
    case unhandledStatus(OSStatus)
}

struct KeychainPINStore {
    private let service = "dmitrich.payroller-portfolio.security.pin"
    private let account = "app_pin"

    nonisolated init() {}

    func savePINHash(_ hash: String) throws {
        guard let data = hash.data(using: .utf8) else {
            throw KeychainPINStoreError.encodingFailed
        }

        let query = baseQuery()
        SecItemDelete(query as CFDictionary)

        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainPINStoreError.unhandledStatus(status)
        }
    }

    func loadPINHash() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let hash = String(data: data, encoding: .utf8) else {
            return nil
        }

        return hash
    }

    func deletePINHash() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
