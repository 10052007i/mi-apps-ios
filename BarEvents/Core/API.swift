import Foundation

struct APIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

final class API {
    static let shared = API()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 25
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }

    var baseURLString: String {
        get { UserDefaults.standard.string(forKey: "vg_api_base_url") ?? "https://particularly-discussed-jews-mambo.trycloudflare.com" }
        set { UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "vg_api_base_url") }
    }

    var baseURL: URL? {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func url(_ path: String) -> URL? {
        if path.hasPrefix("http") { return URL(string: path) }
        guard let base = baseURL else { return nil }
        let root = base.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: root + ensureSlash(path))
    }

    func imageURL(_ value: String?) -> URL? {
        guard let value, !value.isEmpty else { return nil }
        return url(value)
    }

    private func ensureSlash(_ value: String) -> String {
        value.hasPrefix("/") ? value : "/" + value
    }

    func get<T: Decodable>(_ path: String, query: [String: String] = [:], token: String? = nil) async throws -> T {
        let data = try await data(path, method: "GET", query: query, token: token)
        return try decode(data)
    }

    func send<T: Decodable, B: Encodable>(_ path: String, method: String, body: B, token: String? = nil) async throws -> T {
        let data = try await data(path, method: method, body: try encoder.encode(body), token: token)
        return try decode(data)
    }

    func send<B: Encodable>(_ path: String, method: String, body: B, token: String? = nil) async throws {
        _ = try await data(path, method: method, body: try encoder.encode(body), token: token)
    }

    func sendNoBody(_ path: String, method: String, token: String? = nil) async throws {
        _ = try await data(path, method: method, token: token)
    }

    func data(_ path: String, method: String = "GET", body: Data? = nil, query: [String: String] = [:], token: String? = nil) async throws -> Data {
        guard baseURL != nil, let target = url(path) else {
            throw APIError(message: "Configura la URL del API en Ajustes.")
        }
        var components = URLComponents(url: target, resolvingAgainstBaseURL: false)
        if !query.isEmpty {
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else { throw APIError(message: "URL del API inválida.") }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError(message: "Respuesta inválida del servidor.")
            }
            guard (200..<300).contains(http.statusCode) else {
                if let body = try? decoder.decode(APIErrorBody.self, from: data) {
                    if let first = body.fields?.values.first, !first.isEmpty {
                        throw APIError(message: first)
                    }
                    if let message = body.message, !message.isEmpty {
                        throw APIError(message: message)
                    }
                }
                if http.statusCode == 401 {
                    throw APIError(message: "Sesión no autorizada. Vuelve a iniciar sesión.")
                }
                if http.statusCode == 404 {
                    throw APIError(message: "No encontrado.")
                }
                throw APIError(message: "El servidor respondió \(http.statusCode).")
            }
            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError(message: "No se pudo conectar con \(baseURLString). Revisa la URL del API y el túnel.")
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError(message: "Respuesta inesperada del servidor.")
        }
    }
}
