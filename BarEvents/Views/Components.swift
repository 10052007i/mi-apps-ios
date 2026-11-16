import SwiftUI
import UIKit

struct Eyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.vgSans(11, weight: .semibold))
            .tracking(2)
            .foregroundStyle(VG.gold)
    }
}

struct SectionTitle: View {
    let text: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.vgSerif(26))
                .foregroundStyle(VG.text)
            if let subtitle {
                Text(subtitle)
                    .font(.vgSans(14))
                    .foregroundStyle(VG.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct VGCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(VG.card)
            .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
    }
}

struct GoldDivider: View {
    var body: some View {
        Rectangle()
            .fill(VG.gold.opacity(0.55))
            .frame(width: 44, height: 1)
    }
}

struct StatusBadge: View {
    let status: String

    private var color: Color {
        switch status.uppercased() {
        case "CONFIRMADO", "CONFIRMADA", "ACTIVO", "ACTIVE":
            return VG.success
        case "CANCELADO", "CANCELADA", "INACTIVO":
            return VG.danger
        case "VIP", "SIGNATURE":
            return VG.gold
        default:
            return VG.warning
        }
    }

    private var label: String {
        switch status.uppercased() {
        case "CONFIRMADO", "CONFIRMADA": return "Confirmado"
        case "CANCELADO", "CANCELADA": return "Cancelado"
        case "PENDIENTE": return "Pendiente"
        case "VIP": return "VIP"
        case "FRECUENTE": return "Frecuente"
        case "NUEVO": return "Nuevo"
        default: return status.capitalized
        }
    }

    var body: some View {
        Text(label)
            .font(.vgSans(11, weight: .semibold))
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .overlay(Rectangle().stroke(color.opacity(0.5), lineWidth: 1))
    }
}

struct SelectableChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.vgSans(12, weight: .medium))
                .foregroundStyle(selected ? VG.background : VG.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(selected ? VG.gold : VG.cardAlt)
                .overlay(Rectangle().stroke(selected ? VG.gold : VG.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct LabeledField: View {
    let label: String
    var placeholder: String = ""
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var capitalization: TextInputAutocapitalization = .sentences
    var multiline = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label.uppercased())
                .font(.vgSans(10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(VG.secondary)
            if multiline {
                TextField(placeholder, text: $text, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(VGTextFieldStyle())
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(capitalization)
                    .autocorrectionDisabled(keyboard == .emailAddress)
                    .textFieldStyle(VGTextFieldStyle())
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var accent = false

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.vgSans(12))
                .foregroundStyle(VG.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.vgSans(13, weight: accent ? .semibold : .regular))
                .foregroundStyle(accent ? VG.gold : VG.text)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct RemoteImage: View {
    let urlString: String?
    var height: CGFloat = 150

    var body: some View {
        Group {
            if let url = API.shared.imageURL(urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }

    private var placeholder: some View {
        ZStack {
            VG.cardAlt
            Image(systemName: "wineglass")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(VG.gold.opacity(0.6))
        }
    }
}

struct LoadingState: View {
    var text = "Cargando…"

    var body: some View {
        VStack(spacing: 14) {
            ProgressView().tint(VG.gold)
            Text(text)
                .font(.vgSans(13))
                .foregroundStyle(VG.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct ErrorState: View {
    let message: String
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Text(message)
                .font(.vgSans(13))
                .foregroundStyle(VG.secondary)
                .multilineTextAlignment(.center)
            if let retry {
                Button("Reintentar", action: retry)
                    .buttonStyle(PrimaryButtonStyle(fullWidth: false))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(VG.card)
        .overlay(Rectangle().stroke(VG.danger.opacity(0.4), lineWidth: 1))
    }
}

struct EmptyState: View {
    let title: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.vgSerif(18))
                .foregroundStyle(VG.text)
            if let message {
                Text(message)
                    .font(.vgSans(13))
                    .foregroundStyle(VG.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct KeyValuePill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.vgSans(9, weight: .semibold))
                .tracking(1)
                .foregroundStyle(VG.secondary)
            Text(value)
                .font(.vgSans(14, weight: .semibold))
                .foregroundStyle(VG.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AlertBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.vgSans(13))
            .foregroundStyle(VG.danger)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(VG.danger.opacity(0.1))
            .overlay(Rectangle().stroke(VG.danger.opacity(0.45), lineWidth: 1))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
