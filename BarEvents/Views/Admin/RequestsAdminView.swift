import SwiftUI

struct RequestsAdminView: View {
    @EnvironmentObject private var app: AppModel

    @State private var page = 0
    @State private var size = 12
    @State private var status: String?
    @State private var search = ""
    @State private var result: SolicitudPage?
    @State private var loading = true
    @State private var error: String?

    private let statuses = ["PENDIENTE", "CONFIRMADO", "CANCELADO"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                searchField
                filters
                if loading {
                    LoadingState(text: "Cargando solicitudes…")
                } else if let error {
                    ErrorState(message: error) {
                        Task { await load() }
                    }
                } else if let result {
                    list(result)
                    pager(result)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(VG.background)
        .navigationTitle("Solicitudes")
        .navigationBarTitleDisplayMode(.inline)
        .vgScreen()
        .task { await load() }
        .refreshable { await load() }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(VG.secondary)
            TextField("Buscar folio, cliente, evento…", text: $search)
                .font(.vgSans(14))
                .foregroundStyle(VG.text)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    page = 0
                    Task { await load() }
                }
            if !search.isEmpty {
                Button {
                    search = ""
                    page = 0
                    Task { await load() }
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(VG.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(VG.cardAlt)
        .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
        .padding(.top, 8)
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectableChip(label: "Todas", selected: status == nil) {
                    status = nil
                    page = 0
                    Task { await load() }
                }
                ForEach(statuses, id: \.self) { item in
                    SelectableChip(label: SolicitudStatus(rawValue: item)?.label ?? item, selected: status == item) {
                        status = item
                        page = 0
                        Task { await load() }
                    }
                }
            }
        }
        .contentMargins(.horizontal, 0, for: .scrollContent)
    }

    private func list(_ result: SolicitudPage) -> some View {
        VStack(spacing: 10) {
            if result.items.isEmpty {
                EmptyState(title: "Sin solicitudes", message: "No hay resultados para este filtro.")
            }
            ForEach(result.items) { item in
                NavigationLink {
                    RequestDetailView(requestId: item.id)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(item.folio)
                                .font(.vgSans(12, weight: .semibold))
                                .foregroundStyle(VG.gold)
                            Spacer()
                            StatusBadge(status: item.status)
                        }
                        Text(item.client.name)
                            .font(.vgSerif(18))
                            .foregroundStyle(VG.text)
                        HStack(spacing: 6) {
                            Text(item.eventTypeName)
                            Text("·")
                            Text(VGFormat.shortDate(item.eventDate))
                        }
                        .font(.vgSans(12))
                        .foregroundStyle(VG.secondary)
                        HStack {
                            Text("\(item.guests) invitados · \(item.durationHours) h")
                                .font(.vgSans(11))
                                .foregroundStyle(VG.secondary)
                            Spacer()
                            Text(VGFormat.soles(item.breakdown.total))
                                .font(.vgSans(14, weight: .semibold))
                                .foregroundStyle(VG.text)
                        }
                    }
                    .padding(14)
                    .background(VG.card)
                    .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func pager(_ result: SolicitudPage) -> some View {
        HStack {
            Button("Anterior") {
                page = max(0, page - 1)
                Task { await load() }
            }
            .disabled(page == 0)
            Spacer()
            Text("Página \(result.page + 1) de \(max(result.totalPages, 1)) · \(result.total) registros")
                .font(.vgSans(11))
                .foregroundStyle(VG.secondary)
            Spacer()
            Button("Siguiente") {
                page = min(max(result.totalPages - 1, 0), page + 1)
                Task { await load() }
            }
            .disabled(page + 1 >= result.totalPages)
        }
        .font(.vgSans(12, weight: .semibold))
        .foregroundStyle(VG.gold)
        .padding(.top, 6)
    }

    private func load() async {
        guard let token = app.token else {
            error = "Sesión no autorizada."
            loading = false
            return
        }
        loading = true
        var query = ["page": String(page), "size": String(size)]
        if let status { query["status"] = status }
        if !search.trimmingCharacters(in: .whitespaces).isEmpty {
            query["search"] = search.trimmingCharacters(in: .whitespaces)
        }
        do {
            let value: SolicitudPage = try await app.api.get("/api/requests", query: query, token: token)
            result = value
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
