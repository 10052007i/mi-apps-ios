import SwiftUI

struct AdminHomeView: View {
    @EnvironmentObject private var app: AppModel

    @State private var summary: ResumenSolicitudes?
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if loading {
                    LoadingState(text: "Cargando métricas…")
                } else if let error {
                    ErrorState(message: error) {
                        Task { await load() }
                    }
                } else if let summary {
                    metrics(summary)
                }
                menu
                Button {
                    app.logout()
                } label: {
                    Text("Cerrar sesión")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(VG.background)
        .navigationTitle("Panel")
        .navigationBarTitleDisplayMode(.inline)
        .vgScreen()
        .task { await load() }
        .refreshable { await load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Administración")
            Text("Resumen del negocio")
                .font(.vgSerif(30))
                .foregroundStyle(VG.text)
            Text(app.user?.email ?? "")
                .font(.vgSans(12))
                .foregroundStyle(VG.secondary)
        }
        .padding(.top, 8)
    }

    private func metrics(_ s: ResumenSolicitudes) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            metric("Solicitudes", "\(s.solicitudes)", "doc.text", VG.gold)
            metric("Ingresos est.", VGFormat.soles(s.ingresosEstimados), "chart.line.uptrend.xyaxis", VG.success)
            metric("Próximos eventos", "\(s.proximosEventos)", "calendar", VG.text)
            metric("Pendientes", "\(s.pendientes)", "clock", VG.warning)
        }
    }

    private func metric(_ title: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(tint)
            Text(value)
                .font(.vgSerif(24))
                .foregroundStyle(VG.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.vgSans(10, weight: .medium))
                .foregroundStyle(VG.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(VG.card)
        .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
    }

    private var menu: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GESTIÓN")
                .font(.vgSans(10, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(VG.secondary)
            VStack(spacing: 0) {
                adminLink("Solicitudes", "Listado, filtros y estados", "tray.full") { RequestsAdminView() }
                Divider().overlay(VG.line)
                adminLink("Calendario", "Eventos por mes", "calendar") { CalendarView() }
                Divider().overlay(VG.line)
                adminLink("Clientes", "Base de clientes y tiers", "person.2") { ClientsAdminView() }
                Divider().overlay(VG.line)
                adminLink("Carta", "Cócteles y disponibilidad", "wineglass") { CatalogAdminView() }
                Divider().overlay(VG.line)
                adminLink("Configuración", "Negocio y tipo de cambio", "slider.horizontal.3") { SettingsAdminView() }
            }
            .background(VG.card)
            .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
        }
    }

    private func adminLink<Destination: View>(_ title: String, _ subtitle: String, _ icon: String, @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(VG.gold)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.vgSans(14, weight: .medium))
                        .foregroundStyle(VG.text)
                    Text(subtitle)
                        .font(.vgSans(11))
                        .foregroundStyle(VG.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(VG.secondary)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }

    private func load() async {
        loading = true
        guard let token = app.token else {
            error = "Sesión no autorizada."
            loading = false
            return
        }
        do {
            let value: ResumenSolicitudes = try await app.api.get("/api/requests/resumen", token: token)
            summary = value
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
