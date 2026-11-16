import SwiftUI

struct ClientsAdminView: View {
    @EnvironmentObject private var app: AppModel

    @State private var clients: [Client] = []
    @State private var loading = true
    @State private var error: String?
    @State private var search = ""
    @State private var tier = ""
    @State private var editing: Client?

    private let tiers = ["", "PARTICULAR", "CORPORATIVO", "VIP"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                searchField
                filterRow
                if loading {
                    LoadingState(text: "Cargando clientes…")
                } else if let error {
                    ErrorState(message: error) {
                        Task { await load() }
                    }
                } else if clients.isEmpty {
                    EmptyState(title: "Sin clientes", message: "Los clientes se crean al recibir solicitudes.")
                } else {
                    VStack(spacing: 10) {
                        ForEach(clients) { client in
                            Button {
                                editing = client
                            } label: {
                                row(client)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(VG.background)
        .navigationTitle("Clientes")
        .navigationBarTitleDisplayMode(.inline)
        .vgScreen()
        .task { await load() }
        .refreshable { await load() }
        .sheet(item: $editing) { client in
            ClientEditor(client: client) {
                Task { await load() }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(VG.secondary)
            TextField("Buscar nombre, correo o WhatsApp", text: $search)
                .font(.vgSans(14))
                .foregroundStyle(VG.text)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { Task { await load() } }
            if !search.isEmpty {
                Button {
                    search = ""
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

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tiers, id: \.self) { item in
                    SelectableChip(label: item.isEmpty ? "Todos" : item.capitalized, selected: tier == item) {
                        tier = item
                        Task { await load() }
                    }
                }
            }
        }
        .contentMargins(.horizontal, 0, for: .scrollContent)
    }

    private func row(_ client: Client) -> some View {
        HStack(spacing: 12) {
            Text(VGFormat.initials(client.name))
                .font(.vgSerif(15))
                .foregroundStyle(VG.gold)
                .frame(width: 42, height: 42)
                .overlay(Rectangle().stroke(VG.goldLine, lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(client.name)
                        .font(.vgSans(14, weight: .medium))
                        .foregroundStyle(VG.text)
                        .lineLimit(1)
                    StatusBadge(status: client.tier)
                }
                Text(client.email ?? client.whatsapp ?? "Sin contacto")
                    .font(.vgSans(11))
                    .foregroundStyle(VG.secondary)
                    .lineLimit(1)
                Text("\(client.reservations) eventos · \(VGFormat.soles(client.totalSpent))")
                    .font(.vgSans(11))
                    .foregroundStyle(VG.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(VG.secondary)
        }
        .padding(14)
        .background(VG.card)
        .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
    }

    private func load() async {
        guard let token = app.token else {
            error = "Sesión no autorizada."
            loading = false
            return
        }
        loading = true
        var query: [String: String] = [:]
        if !search.trimmingCharacters(in: .whitespaces).isEmpty {
            query["search"] = search.trimmingCharacters(in: .whitespaces)
        }
        if !tier.isEmpty { query["tier"] = tier }
        do {
            let value: [Client] = try await app.api.get("/api/clients", query: query, token: token)
            clients = value
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

struct ClientEditor: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    let client: Client
    let onSaved: () -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var whatsapp = ""
    @State private var location = ""
    @State private var tier = "PARTICULAR"
    @State private var totalSpent = ""
    @State private var active = true
    @State private var saving = false
    @State private var error: String?

    private let tiers = ["PARTICULAR", "CORPORATIVO", "VIP"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    LabeledField(label: "Nombre", text: $name, capitalization: .words)
                    LabeledField(label: "Correo", text: $email, keyboard: .emailAddress, capitalization: .never)
                    LabeledField(label: "WhatsApp", text: $whatsapp, keyboard: .phonePad)
                    LabeledField(label: "Ubicación", text: $location, capitalization: .words)
                    LabeledField(label: "Total gastado (S/)", text: $totalSpent, keyboard: .decimalPad)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("TIER")
                            .font(.vgSans(10, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(VG.secondary)
                        HStack(spacing: 8) {
                            ForEach(tiers, id: \.self) { item in
                                SelectableChip(label: item.capitalized, selected: tier == item) {
                                    tier = item
                                }
                            }
                        }
                    }

                    Toggle("Cliente activo", isOn: $active)
                        .font(.vgSans(13))
                        .foregroundStyle(VG.text)
                        .tint(VG.gold)

                    if let error {
                        AlertBanner(message: error)
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        Text(saving ? "Guardando…" : "Guardar cambios")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(saving || name.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button {
                        Task { await deactivate() }
                    } label: {
                        Text("Desactivar cliente")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(20)
            }
            .background(VG.background)
            .navigationTitle("Cliente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(VG.gold)
                }
            }
            .onAppear {
                name = client.name
                email = client.email ?? ""
                whatsapp = client.whatsapp ?? ""
                location = client.location ?? ""
                tier = client.tier
                totalSpent = VGFormat.number(client.totalSpent)
                active = client.active
            }
        }
    }

    private func save() async {
        guard let token = app.token else { return }
        saving = true
        error = nil
        do {
            let payload = ClientPayload(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.isEmpty ? nil : email,
                whatsapp: whatsapp.isEmpty ? nil : whatsapp,
                location: location.isEmpty ? nil : location,
                tier: tier,
                totalSpent: Double(totalSpent.replacingOccurrences(of: ",", with: ".")),
                active: active
            )
            let _: Client = try await app.api.send("/api/clients/\(client.id)", method: "PUT", body: payload, token: token)
            onSaved()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }

    private func deactivate() async {
        guard let token = app.token else { return }
        saving = true
        do {
            try await app.api.sendNoBody("/api/clients/\(client.id)", method: "DELETE", token: token)
            onSaved()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }
}
