import Foundation

struct Usuario: Codable, Identifiable, Equatable {
    let id: Int
    let email: String
    let fullName: String
    let role: String
    let active: Bool

    var isAdmin: Bool { role == "ADMIN" }
}

struct LoginResponse: Decodable {
    let token: String
    let type: String
    let user: Usuario
}

struct EventType: Decodable, Identifiable, Hashable {
    let id: Int
    let code: String
    let name: String
    let description: String?
    let active: Bool
    let sortOrder: Int?
}

struct EventTypeRef: Decodable, Identifiable, Hashable {
    let id: Int
    let code: String
    let name: String
}

struct Cocktail: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let category: String
    let spirit: String?
    let ingredients: String
    let imageUrl: String?
    let active: Bool
    let eventTypes: [EventTypeRef]
    let createdAt: String?
}

struct ServiceTier: Decodable, Identifiable, Hashable {
    let id: Int
    let code: String
    let name: String
    let description: String
    let tierType: String?
    let price: Double
    let active: Bool
}

struct Client: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let email: String?
    let whatsapp: String?
    let location: String?
    let tier: String
    let totalSpent: Double
    let reservations: Int
    let lastEvent: String?
    let active: Bool
    let createdAt: String?
}

struct Desglose: Decodable, Hashable {
    let base: Double
    let premium: Double
    let personal: Double
    let total: Double
}

struct CocktailRef: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let ingredients: String
    let imageUrl: String?
    let category: String
}

struct ClienteRef: Decodable, Hashable {
    let id: Int?
    let name: String
    let email: String?
    let whatsapp: String?
}

struct Solicitud: Decodable, Identifiable, Hashable {
    let id: Int
    let folio: String
    let publicToken: String
    let status: String
    let eventTypeId: Int
    let eventTypeName: String
    let eventDate: String
    let eventTime: String?
    let guests: Int
    let durationHours: Int
    let location: String?
    let notes: String?
    let level: String
    let extraBartenders: Int
    let bartenders: Int
    let assistants: Int
    let breakdown: Desglose
    let cocktails: [CocktailRef]
    let client: ClienteRef
    let createdAt: String?
}

struct SolicitudPage: Decodable {
    let items: [Solicitud]
    let total: Int
    let page: Int
    let size: Int
    let totalPages: Int
}

struct ResumenSolicitudes: Decodable {
    let solicitudes: Int
    let ingresosEstimados: Double
    let proximosEventos: Int
    let pendientes: Int
    let confirmadas: Int
    let canceladas: Int
}

struct EventoCalendario: Decodable, Identifiable, Hashable {
    let id: Int
    let folio: String
    let eventDate: String
    let eventTime: String?
    let status: String
    let eventTypeName: String
    let clientName: String
    let location: String?
    let totalAmount: Double
}

struct Settings: Decodable, Equatable {
    let whatsappOwner: String
    let contactEmail: String
    let businessName: String
    let exchangeRate: Double
    let baseHours: Int
    let extraHourPen: Double

    static let fallback = Settings(
        whatsappOwner: "51937336603",
        contactEmail: "hola@velvetgilt.com",
        businessName: "Velvet & Gilt",
        exchangeRate: 3.4,
        baseHours: 5,
        extraHourPen: 40
    )
}

struct LoginBody: Encodable {
    let email: String
    let password: String
}

struct SolicitudPayload: Encodable {
    let eventTypeId: Int
    let eventDate: String
    let eventTime: String?
    let guests: Int
    let durationHours: Int
    let location: String?
    let notes: String?
    let level: String
    let extraBartenders: Int
    let cocktailIds: [Int]
    let clientName: String
    let clientWhatsapp: String
    let clientEmail: String
}

struct StatusBody: Encodable {
    let status: String
}

struct CocktailPayload: Encodable {
    let name: String
    let category: String
    let spirit: String?
    let ingredients: String
    let imageUrl: String?
    let active: Bool
    let eventTypeIds: [Int]
}

struct ClientPayload: Encodable {
    let name: String
    let email: String?
    let whatsapp: String?
    let location: String?
    let tier: String
    let totalSpent: Double?
    let active: Bool
}

struct SettingsPayload: Encodable {
    let whatsappOwner: String
    let contactEmail: String
    let businessName: String
    let exchangeRate: Double
}

struct APIErrorBody: Decodable {
    let message: String?
    let fields: [String: String]?
}

enum SolicitudStatus: String, CaseIterable {
    case pendiente = "PENDIENTE"
    case confirmado = "CONFIRMADO"
    case cancelado = "CANCELADO"

    var label: String {
        String(rawValue.prefix(1)) + rawValue.dropFirst().lowercased()
    }
}

enum CategoriaCoctel: String, CaseIterable {
    case signature = "SIGNATURE"
    case clasicos = "CLASICOS"
    case citricos = "CITRICOS"
    case sinAlcohol = "SIN_ALCOHOL"

    var label: String {
        switch self {
        case .signature: return "Signature"
        case .clasicos: return "Clásicos"
        case .citricos: return "Cítricos"
        case .sinAlcohol: return "Sin alcohol"
        }
    }
}

enum Destilado: String, CaseIterable {
    case tequila = "TEQUILA"
    case ron = "RON"
    case vodka = "VODKA"
    case ginebra = "GINEBRA"
    case whisky = "WHISKY"
    case brandy = "BRANDY"
    case aperitivo = "APERITIVO"
    case sinAlcohol = "SIN_ALCOHOL"
    case otro = "OTRO"

    var label: String {
        switch self {
        case .tequila: return "Tequila"
        case .ron: return "Ron"
        case .vodka: return "Vodka"
        case .ginebra: return "Ginebra"
        case .whisky: return "Whisky"
        case .brandy: return "Brandy"
        case .aperitivo: return "Aperitivo"
        case .sinAlcohol: return "Sin alcohol"
        case .otro: return "Otro"
        }
    }
}
