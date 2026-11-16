import SwiftUI

struct TrackingView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.openURL) private var openURL

    @State private var token = ""
    @State private var solicitud: Solicitud?
    @State private var loading = false
    @State private var error: String?
    @State private var showShare = false
    @State private var shareURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if let solicitud {
                    result(solicitud)
                } else {
                    form
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(VG.background)
        .navigationTitle("Seguimiento")
        .navigationBarTitleDisplayMode(.inline)
        .vgScreen()
        .sheet(isPresented: $showShare) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Tu paquete")
            Text("Sigue tu solicitud")
                .font(.vgSerif(30))
                .foregroundStyle(VG.text)
            Text("Ingresa el token de seguimiento que aparece en tu PDF o en el mensaje de confirmación.")
                .font(.vgSans(13))
                .foregroundStyle(VG.secondary)
        }
        .padding(.top, 8)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Token o enlace de seguimiento", text: $token)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(VGTextFieldStyle())
            if let error {
                AlertBanner(message: error)
            }
            Button {
                Task { await search() }
            } label: {
                Text(loading ? "Consultando…" : "Consultar")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(loading || token.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func result(_ s: Solicitud) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VGCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(s.folio)
                            .font(.vgSerif(24))
                            .foregroundStyle(VG.gold)
                        Spacer()
                        StatusBadge(status: s.status)
                    }
                    Text(s.eventTypeName)
                        .font(.vgSans(15, weight: .semibold))
                        .foregroundStyle(VG.text)
                    Text(VGFormat.longDate(s.eventDate) + (s.eventTime.map { " · \($0) hrs" } ?? ""))
                        .font(.vgSans(13))
                        .foregroundStyle(VG.secondary)
                    timeline(s.status)
                }
            }

            VGCard {
                VStack(spacing: 10) {
                    InfoRow(label: "Invitados", value: "\(s.guests)")
                    Divider().overlay(VG.line)
                    InfoRow(label: "Duración", value: "\(s.durationHours) horas")
                    Divider().overlay(VG.line)
                    InfoRow(label: "Equipo", value: "\(s.bartenders) bartender(s) · \(s.assistants) ayudante(s)")
                    if let location = s.location {
                        Divider().overlay(VG.line)
                        InfoRow(label: "Ubicación", value: location)
                    }
                }
            }

            VGCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Carta del evento")
                        .font(.vgSerif(18))
                        .foregroundStyle(VG.text)
                    ForEach(s.cocktails) { cocktail in
                        HStack(alignment: .top, spacing: 8) {
                            Text("·").foregroundStyle(VG.gold)
                            Text(cocktail.name)
                                .font(.vgSans(13))
                                .foregroundStyle(VG.text)
                            Spacer()
                        }
                    }
                }
            }

            VGCard {
                VStack(spacing: 10) {
                    InfoRow(label: "Bartenders", value: VGFormat.soles(s.breakdown.base))
                    InfoRow(label: "Ayudantes", value: VGFormat.soles(s.breakdown.personal))
                    Divider().overlay(VG.line)
                    InfoRow(label: "Total estimado", value: VGFormat.doubleMoney(s.breakdown.total), accent: true)
                }
            }

            VStack(spacing: 12) {
                Button {
                    openPDF(s)
                } label: {
                    Label("Ver PDF", systemImage: "doc.text")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    if let url = VGFormat.whatsappLink(phone: app.settings.whatsappOwner, message: Messages.package(s)) {
                        openURL(url)
                    }
                } label: {
                    Label("Enviar por WhatsApp", systemImage: "message")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button("Consultar otra solicitud") {
                    self.solicitud = nil
                    token = ""
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
    }

    private func timeline(_ status: String) -> some View {
        let steps = ["PENDIENTE", "CONFIRMADO"]
        let activeIndex = status == "CONFIRMADO" ? 1 : 0
        return HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 0) {
                    Circle()
                        .fill(index <= activeIndex ? VG.gold : VG.line)
                        .frame(width: 9, height: 9)
                    Rectangle()
                        .fill(index < activeIndex ? VG.gold : VG.line)
                        .frame(height: 1)
                }
            }
        }
        .overlay(alignment: .bottom) {
            HStack {
                Text("Pendiente")
                Spacer()
                Text("Confirmado")
            }
            .font(.vgSans(10))
            .foregroundStyle(VG.secondary)
            .offset(y: 12)
        }
        .padding(.bottom, 16)
        .padding(.top, 4)
    }

    private func openPDF(_ s: Solicitud) {
        guard let url = API.shared.url("/api/public/solicitudes/\(s.publicToken)/pdf") else { return }
        shareURL = url
        showShare = true
    }

    private func search() async {
        loading = true
        error = nil
        do {
            let cleaned = token
                .split(separator: "/")
                .last
                .map(String.init)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !cleaned.isEmpty else {
                error = "Ingresa un token válido."
                loading = false
                return
            }
            let found: Solicitud = try await API.shared.get("/api/public/solicitudes/\(cleaned)")
            solicitud = found
            token = cleaned
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
