import Foundation
import Security

enum Keychain {
    private static let service = "com.cibertec.velvetgilt"

    static func save(_ value: String, key: String) {
        delete(key: key)
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        _ = SecItemAdd(query as CFDictionary, nil)
    }

    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        _ = SecItemDelete(query as CFDictionary)
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var token: String?
    @Published private(set) var user: Usuario?
    @Published private(set) var settings: Settings = .fallback
    @Published var baseURLString: String

    private let userKey = "vg_user"
    private let tokenKey = "vg_token"

    init() {
        token = Keychain.read(key: tokenKey)
        baseURLString = API.shared.baseURLString
        if let data = UserDefaults.standard.data(forKey: userKey),
           let stored = try? JSONDecoder().decode(Usuario.self, from: data) {
            user = stored
        }
        if token == nil { user = nil }
    }

    var api: API { API.shared }
    var isLoggedIn: Bool { token != nil && user != nil }
    var isAdmin: Bool { user?.isAdmin ?? false }
    var exchangeRate: Double { settings.exchangeRate }

    func login(email: String, password: String) async throws {
        let response: LoginResponse = try await api.send(
            "/api/auth/login",
            method: "POST",
            body: LoginBody(email: email.trimmingCharacters(in: .whitespaces), password: password)
        )
        token = response.token
        user = response.user
        Keychain.save(response.token, key: tokenKey)
        if let data = try? JSONEncoder().encode(response.user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
        await loadSettings()
    }

    func logout() {
        token = nil
        user = nil
        Keychain.delete(key: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    func loadSettings() async {
        do {
            let loaded: Settings = try await api.get("/api/public/settings")
            settings = loaded
            VGFormat.exchangeRate = loaded.exchangeRate
        } catch {
            VGFormat.exchangeRate = settings.exchangeRate
        }
    }

    func saveBaseURL(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        baseURLString = trimmed
        API.shared.baseURLString = trimmed
    }

    func apply(settings newValue: Settings) {
        settings = newValue
        VGFormat.exchangeRate = newValue.exchangeRate
    }
}
