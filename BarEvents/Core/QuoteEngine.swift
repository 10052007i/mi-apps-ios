import Foundation

enum QuoteEngine {
    static let bartenderSteps = [55, 120, 180, 231, 271, 331, 371, 431, 481]
    static let bartenderTail = 50
    static let assistantSteps = [100, 150, 271, 371, 481]
    static let assistantTail = 100

    static func contar(guests: Int, steps: [Int], tail: Int, base: Int) -> Int {
        var total = base
        var last = 0
        for step in steps {
            if guests >= step {
                total += 1
                last = step
            } else {
                break
            }
        }
        if let final = steps.last, last == final {
            total += (guests - last) / tail
        }
        return total
    }

    static func team(guests: Int, eventTypeCode: String?) -> (bartenders: Int, assistants: Int) {
        if eventTypeCode == "MASTERCLASS" {
            return (1, guests >= 60 ? 1 : 0)
        }
        return (
            contar(guests: guests, steps: bartenderSteps, tail: bartenderTail, base: 1),
            contar(guests: guests, steps: assistantSteps, tail: assistantTail, base: 0)
        )
    }

    static func billedHours(durationHours: Int, baseHours: Int) -> Int {
        max(durationHours, baseHours)
    }

    static func breakdown(
        guests: Int,
        durationHours: Int,
        eventTypeCode: String?,
        basePrice: Double,
        personalPrice: Double,
        baseHours: Int,
        extraHourPen: Double
    ) -> Desglose {
        let extraHours = Double(billedHours(durationHours: durationHours, baseHours: baseHours) - baseHours)
        let team = team(guests: guests, eventTypeCode: eventTypeCode)
        let perBartender = basePrice + extraHourPen * extraHours
        let perAssistant = personalPrice + extraHourPen * extraHours
        let base = (perBartender * Double(team.bartenders) * 100).rounded() / 100
        let personal = (perAssistant * Double(team.assistants) * 100).rounded() / 100
        return Desglose(base: base, premium: 0, personal: personal, total: base + personal)
    }
}
