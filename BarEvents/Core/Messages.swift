import Foundation

enum Messages {
    static func trackingLink(_ solicitud: Solicitud) -> String {
        let root = API.shared.baseURLString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "\(root)/solicitud/\(solicitud.publicToken)"
    }

    static func package(_ s: Solicitud) -> String {
        let carta = s.cocktails.map(\.name).joined(separator: ", ")
        let hora = s.eventTime.map { ", \($0) hrs" } ?? ""
        return [
            "Hola \(s.client.name), aqui esta tu paquete para \(s.eventTypeName) (\(s.folio)):",
            "",
            "Fecha: \(VGFormat.longDate(s.eventDate))\(hora)",
            "Lugar: \(s.location ?? "Por definir")",
            "Invitados: \(s.guests) | Duracion: \(s.durationHours) h",
            "Equipo: \(s.bartenders) bartender(s), \(s.assistants) ayudante(s)",
            "Carta: \(carta)",
            "",
            "Bartenders: \(VGFormat.soles(s.breakdown.base))",
            "Premium: \(VGFormat.soles(s.breakdown.premium))",
            "Ayudantes: \(VGFormat.soles(s.breakdown.personal))",
            "Total: \(VGFormat.doubleMoney(s.breakdown.total))",
            "",
            "Estado: \(s.status.capitalized)",
            "Seguimiento: \(trackingLink(s))",
        ].joined(separator: "\n")
    }

    static func owner(_ s: Solicitud) -> String {
        let carta = s.cocktails.map(\.name).joined(separator: ", ")
        let hora = s.eventTime.map { ", \($0) hrs" } ?? ""
        return [
            "Hola, soy \(s.client.name) y acabo de generar mi paquete (\(s.folio)) desde la app.",
            "",
            "Evento: \(s.eventTypeName)",
            "Fecha: \(VGFormat.longDate(s.eventDate))\(hora)",
            "Lugar: \(s.location ?? "Por definir")",
            "Invitados: \(s.guests) | Duracion: \(s.durationHours) h",
            "Equipo: \(s.bartenders) bartender(s), \(s.assistants) ayudante(s)",
            "Carta: \(carta)",
            "",
            "Total: \(VGFormat.doubleMoney(s.breakdown.total))",
            "Seguimiento: \(trackingLink(s))",
        ].joined(separator: "\n")
    }
}
