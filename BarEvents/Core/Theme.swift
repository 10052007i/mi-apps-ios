import SwiftUI

enum VG {
    static let background = Color(hex: 0x0F0F0F)
    static let surface = Color(hex: 0x151C25)
    static let card = Color(hex: 0x1A1A1A)
    static let cardAlt = Color(hex: 0x192029)
    static let gold = Color(hex: 0xD4AF37)
    static let goldHover = Color(hex: 0xB5952F)
    static let goldLight = Color(hex: 0xE9C349)
    static let text = Color(hex: 0xDCE3F0)
    static let secondary = Color(hex: 0xC4C7C7)
    static let success = Color(hex: 0x30A46C)
    static let danger = Color(hex: 0xE5484D)
    static let warning = Color(hex: 0xE2A03F)
    static let line = Color.white.opacity(0.10)
    static let goldLine = Color(hex: 0xD4AF37).opacity(0.4)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

extension Font {
    static func vgSerif(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func vgSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.vgSans(14, weight: .semibold))
            .textCase(.uppercase)
            .tracking(0.7)
            .foregroundStyle(VG.background)
            .padding(.vertical, 15)
            .padding(.horizontal, 24)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(configuration.isPressed ? VG.goldHover : VG.gold)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.vgSans(14, weight: .semibold))
            .textCase(.uppercase)
            .tracking(0.7)
            .foregroundStyle(VG.text)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(configuration.isPressed ? VG.gold.opacity(0.15) : Color.clear)
            .overlay(Rectangle().stroke(VG.gold, lineWidth: 1))
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.vgSans(14, weight: .semibold))
            .foregroundStyle(configuration.isPressed ? VG.gold : VG.text)
    }
}

struct VGTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.vgSans(15))
            .foregroundStyle(VG.text)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(VG.cardAlt)
            .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
    }
}

extension View {
    func vgScreen() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(VG.background.ignoresSafeArea())
            .foregroundStyle(VG.text)
            .tint(VG.gold)
            .preferredColorScheme(.dark)
    }
}
