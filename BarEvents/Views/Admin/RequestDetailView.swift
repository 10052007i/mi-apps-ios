import SwiftUI
import UIKit

struct RequestDetailView: View {
    @EnvironmentObject private var app: AppModel
    let requestId: Int

    @State private var request: Solicitud?
    @State private var loading = true
    @State private var error: String?
    @State private var saving = false
    @State private var pdfLoading = false
    @State private var shareURL: URL?
    @State private var showShare = false

    private let statuses = ["PENDIENTE", "CONFIRMADO", "CANCELADO"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if loading {
                    LoadingState()
                } else if let error {
                    ErrorState(message: error) {
                        Task { await load() }
                    }
                } else if let request {
                    content(request)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(VG.background)
        .navigationTitle(request?.folio ?? "Solicitud")
        .navigationBarTitleDisplayMode(.inline)
        .vgScreen()
        .task { await load() }
        .sheet(isPresented: $showShare) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }

    private func content(_ r: Solicitud) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let error {
                AlertBanner(message: error)
            }
            VGCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(r.folio)
                            .font(.vgSerif(26))
                            .foregroundStyle(VG.gold)
                        Spacer()
                        StatusBadge(status: r.status)
                    }
                    Text(r.eventTypeName)
                        .font(.vgSans(15, weight: .semibold))
                        .foregroundStyle(VG.text)
                    Text(VGFormat.longDate(r.eventDate) + (r.eventTime.map { " · \($0) hrs" } ?? ""))
                        .font(.vgSans(13))
                        .foregroundStyle(VG.secondary)
                }
            }

            sectionTitle("Estado")
            HStack(spacing: 8) {
                ForEach(statuses, id: \.self) { item in
                    Button {
                        Task { await changeStatus(r, to: item) }
                    } label: {
                        Text(SolicitudStatus(rawValue: item)?.label ?? item)
                            .font(.vgSans(11, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(r.status == item ? VG.gold : VG.card)
                            .foregroundStyle(r.status == item ? VG.background : VG.secondary)
                            .overlay(Rectangle().stroke(r.status == item ? VG.gold : VG.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(saving)
                }
            }

            sectionTitle("Evento")
            VGCard {
                VStack(spacing: 10) {
                    InfoRow(label: "Invitados", value: "\(r.guests)")
                    Divider().overlay(VG.line)
                    InfoRow(label: "Duración", value: "\(r.durationHours) horas")
                    Divider().overlay(VG.line)
                    InfoRow(label: "Equipo", value: "\(r.bartenders) bartender(s) · \(r.assistants) ayudante(s)")
                    Divider().overlay(VG.line)
                    InfoRow(label: "Ubicación", value: r.location ?? "Por definir")
                    if let notes = r.notes, !notes.isEmpty {
                        Divider().overlay(VG.line)
                        InfoRow(label: "Notas", value: notes)
                    }
                }
            }

            sectionTitle("Cliente")
            VGCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text(r.client.name)
                        .font(.vgSerif(19))
                        .foregroundStyle(VG.text)
                    InfoRow(label: "Correo", value: r.client.email ?? "—")
                    InfoRow(label: "WhatsApp", value: r.client.whatsapp ?? "—")
                    if let url = VGFormat.whatsappLink(phone: r.client.whatsapp, message: Messages.package(r)) {
                        Button {
                            UIApplication.shared.open(url)
                        } label: {
                            Text("Escribir por WhatsApp")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.top, 4)
                    }
                }
            }

            sectionTitle("Carta")
            VGCard {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(r.cocktails) { cocktail in
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

            sectionTitle("Totales")
            VGCard {
                VStack(spacing: 10) {
                    InfoRow(label: "Bartenders", value: VGFormat.soles(r.breakdown.base))
                    InfoRow(label: "Premium", value: VGFormat.soles(r.breakdown.premium))
                    InfoRow(label: "Ayudantes", value: VGFormat.soles(r.breakdown.personal))
                    Divider().overlay(VG.line)
                    InfoRow(label: "Total", value: VGFormat.doubleMoney(r.breakdown.total), accent: true)
                }
            }

            Button {
                Task { await downloadPDF(r) }
            } label: {
                Label(pdfLoading ? "Generando PDF…" : "Compartir PDF", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(pdfLoading)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.vgSans(10, weight: .semibold))
            .tracking(1.4)
            .foregroundStyle(VG.secondary)
    }

    private func load() async {
        guard let token = app.token else {
            error = "Sesión no autorizada."
            loading = false
            return
        }
        loading = true
        do {
            let value: Solicitud = try await app.api.get("/api/requests/\(requestId)", token: token)
            request = value
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    private func changeStatus(_ r: Solicitud, to status: String) async {
        guard status != r.status, let token = app.token else { return }
        saving = true
        do {
            let updated: Solicitud = try await app.api.send(
                "/api/requests/\(r.id)/status",
                method: "PUT",
                body: StatusBody(status: status),
                token: token
            )
            request = updated
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }

    private func downloadPDF(_ r: Solicitud) async {
        guard let token = app.token else { return }
        pdfLoading = true
        do {
            let data = try await app.api.data("/api/requests/\(r.id)/pdf", token: token)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(r.folio).pdf")
            try data.write(to: url, options: .atomic)
            shareURL = url
            showShare = true
        } catch {
            self.error = error.localizedDescription
        }
        pdfLoading = false
    }
}
