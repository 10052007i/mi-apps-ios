import Foundation

enum VGFormat {
    private static let locale = Locale(identifier: "es_PE")

    private static let money: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()

    private static let apiFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let monthDay: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_PE")
        f.dateFormat = "d 'de' MMMM, yyyy"
        return f
    }()

    private static let monthName = DateFormatter()

    static var exchangeRate: Double = 3.4

    static func number(_ value: Double) -> String {
        money.string(from: NSNumber(value: value)) ?? "0"
    }

    static func soles(_ value: Double) -> String {
        "S/ \(number(value))"
    }

    static func dollars(_ soles: Double) -> String {
        "US$ \(number(soles / max(exchangeRate, 0.01)))"
    }

    static func doubleMoney(_ soles: Double) -> String {
        "\(Self.soles(soles)) (~ \(dollars(soles)))"
    }

    static func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        return apiFormatter.date(from: value)
    }

    static func apiDate(_ date: Date) -> String {
        apiFormatter.string(from: date)
    }

    static func longDate(_ value: String?) -> String {
        guard let date = parseDate(value) else { return "Por definir" }
        return monthDay.string(from: date)
    }

    static func longDate(_ date: Date) -> String {
        monthDay.string(from: date)
    }

    static func monthTitle(_ date: Date) -> String {
        monthName.locale = Locale(identifier: "es_PE")
        monthName.dateFormat = "LLLL yyyy"
        return monthName.string(from: date).capitalized
    }

    static func shortDate(_ value: String?) -> String {
        guard let date = parseDate(value) else { return "-" }
        monthName.locale = Locale(identifier: "es_PE")
        monthName.dateFormat = "dd MMM, yyyy"
        return monthName.string(from: date)
    }

    static func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    static func cleanedPhone(_ phone: String?) -> String {
        (phone ?? "").filter(\.isNumber)
    }

    static func whatsappLink(phone: String?, message: String) -> URL? {
        let clean = cleanedPhone(phone)
        let text = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let raw = clean.isEmpty ? "https://wa.me/?text=\(text)" : "https://wa.me/\(clean)?text=\(text)"
        return URL(string: raw)
    }
}
