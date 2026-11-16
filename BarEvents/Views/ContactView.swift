import SwiftUI

struct ContactView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    actions
                    info
                    quoteCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(VG.background)
            .navigationTitle("Contacto")
            .navigationBarTitleDisplayMode(.inline)
            .vgScreen()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Estamos para servirte")
            Text("Hablemos de tu evento")
                .font(.vgSerif(32))
                .foregroundStyle(VG.text)
            Text("Escríbenos por WhatsApp o correo y te respondemos el mismo día para coordinar disponibilidad, carta y montaje.")
                .font(.vgSans(14))
                .foregroundStyle(VG.secondary)
                .lineSpacing(3)
        }
        .padding(.top, 8)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                if let url = VGFormat.whatsappLink(
                    phone: app.settings.whatsappOwner,
                    message: "Hola, escribo desde la app de Velvet & Gilt."
                ) {
                    openURL(url)
                }
            } label: {
                Label("Escribir por WhatsApp", systemImage: "message.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                let email = app.settings.contactEmail
                let subject = "Cotización de evento - Velvet & Gilt"
                let clean = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let subj = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: "mailto:\(clean)?subject=\(subj)") {
                    openURL(url)
                }
            } label: {
                Label(app.settings.contactEmail, systemImage: "envelope")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Información")
            VGCard {
                VStack(spacing: 12) {
                    InfoRow(label: "WhatsApp", value: app.settings.whatsappOwner, accent: true)
                    Divider().overlay(VG.line)
                    InfoRow(label: "Correo", value: app.settings.contactEmail)
                    Divider().overlay(VG.line)
                    InfoRow(label: "Cobertura", value: "Lima Metropolitana y balnearios")
                    Divider().overlay(VG.line)
                    InfoRow(label: "Horario", value: "Lun a Sáb · 9:00 a 21:00")
                    Divider().overlay(VG.line)
                    InfoRow(label: "Respuesta", value: "Menos de 24 horas")
                }
            }
        }
    }

    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("¿Prefieres ver precios primero?")
                .font(.vgSerif(22))
                .foregroundStyle(VG.text)
            Text("Usa el cotizador y obtén una estimación inmediata con folio de seguimiento.")
                .font(.vgSans(13))
                .foregroundStyle(VG.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VG.surface)
        .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
    }
}
