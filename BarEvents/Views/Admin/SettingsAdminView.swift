import SwiftUI

struct SettingsAdminView: View {
    @EnvironmentObject private var app: AppModel

    @State private var businessName = ""
    @State private var contactEmail = ""
    @State private var whatsappOwner = ""
    @State private var exchangeRate = ""
    @State private var baseHours = 5
    @State private var extraHour = 40.0
    @State private var loading = true
    @State private var saving = false
    @State private var error: String?
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if loading {
                    LoadingState(text: "Cargando configuración…")
                } else {
                    VGCard {
                        VStack(spacing: 14) {
                            LabeledField(label: "Nombre del negocio", text: $businessName, capitalization: .words)
                            LabeledField(label: "Correo de contacto", text: $contactEmail, keyboard: .emailAddress, capitalization: .never)
                            LabeledField(label: "WhatsApp del dueño", text: $whatsappOwner, keyboard: .phonePad)
                            LabeledField(label: "Tipo de cambio (S/ por US$)", text: $exchangeRate, keyboard: .decimalPad)
                        }
                    }

                    VGCard {
                        VStack(spacing: 10) {
                            InfoRow(label: "Horas base incluidas", value: "\(baseHours) h")
                            Divider().overlay(VG.line)
                            InfoRow(label: "Hora extra por bartender", value: VGFormat.soles(extraHour))
                            Text("Estos parámetros se definen en el backend y son de solo lectura.")
                                .font(.vgSans(11))
                                .foregroundStyle(VG.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    if let error {
                        AlertBanner(message: error)
                    }
                    if saved {
                        Text("Cambios guardados.")
                            .font(.vgSans(12))
                            .foregroundStyle(VG.success)
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        Text(saving ? "Guardando…" : "Guardar configuración")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(saving)

                    Button {
                        Task { await load() }
                    } label: {
                        Text("Restablecer cambios")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(VG.background)
        .navigationTitle("Configuración")
        .navigationBarTitleDisplayMode(.inline)
        .vgScreen()
        .task { await load() }
    }

    private func load() async {
        loading = true
        do {
            let value: Settings = try await app.api.get("/api/public/settings")
            businessName = value.businessName
            contactEmail = value.contactEmail
            whatsappOwner = value.whatsappOwner
            exchangeRate = VGFormat.number(value.exchangeRate)
            baseHours = value.baseHours
            extraHour = value.extraHourPen
            app.apply(settings: value)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    private func save() async {
        guard let token = app.token else {
            error = "Sesión no autorizada."
            return
        }
        saving = true
        saved = false
        error = nil
        let rate = Double(exchangeRate.replacingOccurrences(of: ",", with: ".")) ?? app.settings.exchangeRate
        do {
            let updated: Settings = try await app.api.send(
                "/api/settings",
                method: "PUT",
                body: SettingsPayload(
                    whatsappOwner: whatsappOwner.trimmingCharacters(in: .whitespaces),
                    contactEmail: contactEmail.trimmingCharacters(in: .whitespaces),
                    businessName: businessName.trimmingCharacters(in: .whitespaces),
                    exchangeRate: rate
                ),
                token: token
            )
            app.apply(settings: updated)
            baseHours = updated.baseHours
            extraHour = updated.extraHourPen
            exchangeRate = VGFormat.number(updated.exchangeRate)
            saved = true
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }
}
