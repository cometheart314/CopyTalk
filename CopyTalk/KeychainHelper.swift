import Foundation
import Security

struct KeychainHelper {

    private static let service = "jp.co.artman21.copytalk"
    private static let account = "GoogleCloudTTSAPIKey"
    private static let userDefaultsKey = "googleCloudTTSAPIKey"

    /// API キーを保存する
    @discardableResult
    static func saveAPIKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.set("", forKey: userDefaultsKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: userDefaultsKey)
        }
        return true
    }

    /// API キーを取得する
    /// UserDefaults を優先し、未設定の場合のみ Keychain からマイグレーションする
    static func getAPIKey() -> String? {
        // UserDefaults に値がセット済み（空文字含む）なら Keychain は参照しない
        if UserDefaults.standard.object(forKey: userDefaultsKey) != nil {
            guard let key = UserDefaults.standard.string(forKey: userDefaultsKey),
                  !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            return key
        }

        // UserDefaults 未設定 → Keychain からマイグレーション（初回のみ）
        if let key = getAPIKeyFromKeychain(),
           !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            UserDefaults.standard.set(key, forKey: userDefaultsKey)
            return key
        }

        return nil
    }

    /// API キーを削除する
    @discardableResult
    static func deleteAPIKey() -> Bool {
        UserDefaults.standard.set("", forKey: userDefaultsKey)
        // Keychain にも残っていれば削除を試みる（失敗しても問題ない）
        deleteAPIKeyFromKeychain()
        return true
    }

    // MARK: - Keychain (マイグレーション用)

    private static func getAPIKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    private static func deleteAPIKeyFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
