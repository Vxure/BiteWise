import Foundation
import Security

enum KeychainError: Error {
    case unexpectedStatus(OSStatus)
}

/// Minimal Keychain wrapper for storing sensitive local data.
final class KeychainService {
    static let shared = KeychainService()

    private let service: String

    private init(service: String = Bundle.main.bundleIdentifier ?? "BiteWise") {
        self.service = service
    }

    func saveCodable<T: Encodable>(_ value: T, for key: String) throws {
        let data = try JSONEncoder().encode(value)
        try saveData(data, for: key)
    }

    func loadCodable<T: Decodable>(_ type: T.Type, for key: String) throws -> T? {
        guard let data = try loadData(for: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func saveData(_ data: Data, for key: String) throws {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        // Remove any existing value before adding the new one.
        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private func loadData(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        return item as? Data
    }
}
