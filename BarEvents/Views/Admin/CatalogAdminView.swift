import SwiftUI

struct CatalogAdminView: View {
    @EnvironmentObject private var app: AppModel

    @State private var cocktails: [Cocktail] = []
    @State private var eventTypes: [EventType] = []
    @State private var loading = true
    @State private var error: String?
    @State private var search = ""
    @State private var editing: Cocktail?
    @State private var creating = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                searchField
                Button {
                    creating = true
                } label: {
                    Label("Nuevo cóctel", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())

                if loading {
                    LoadingState(text: "Cargando carta…")
                } else if let error {
                    ErrorState(message: error) {
                        Task { await load() }
                    }
                } else {
                    VStack(spacing: 10) {
                        ForEach(filtered) { cocktail in
                            Button {
                                editing = cocktail
                            } label: {
                                row(cocktail)
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
        .navigationTitle("Carta")
        .navigationBarTitleDisplayMode(.inline)
        .vgScreen()
        .task { await load() }
        .refreshable { await load() }
        .sheet(item: $editing) { cocktail in
            CocktailEditor(cocktail: cocktail, eventTypes: eventTypes) {
                Task { await load() }
            }
        }
        .sheet(isPresented: $creating) {
            CocktailEditor(cocktail: nil, eventTypes: eventTypes) {
                Task { await load() }
            }
        }
    }

    private var filtered: [Cocktail] {
        let text = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !text.isEmpty else { return cocktails }
        return cocktails.filter {
            $0.name.lowercased().contains(text) || $0.ingredients.lowercased().contains(text)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(VG.secondary)
            TextField("Buscar cóctel", text: $search)
                .font(.vgSans(14))
                .foregroundStyle(VG.text)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(VG.cardAlt)
        .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
        .padding(.top, 8)
    }

    private func row(_ cocktail: Cocktail) -> some View {
        HStack(spacing: 12) {
            RemoteImage(urlString: cocktail.imageUrl, height: 58)
                .frame(width: 58)
                .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text(cocktail.name)
                    .font(.vgSans(14, weight: .medium))
                    .foregroundStyle(VG.text)
                    .lineLimit(1)
                Text([CategoriaCoctel(rawValue: cocktail.category)?.label ?? cocktail.category,
                      cocktail.spirit.flatMap { Destilado(rawValue: $0)?.label }]
                        .compactMap { $0 }.joined(separator: " · "))
                    .font(.vgSans(11))
                    .foregroundStyle(VG.secondary)
                StatusBadge(status: cocktail.active ? "ACTIVO" : "INACTIVO")
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(VG.secondary)
        }
        .padding(12)
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
        do {
            async let drinks: [Cocktail] = app.api.get("/api/cocktails", token: token)
            async let types: [EventType] = app.api.get("/api/event-types", token: token)
            cocktails = try await drinks
            eventTypes = try await types
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

struct CocktailEditor: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    let cocktail: Cocktail?
    let eventTypes: [EventType]
    let onSaved: () -> Void

    @State private var name = ""
    @State private var category = "SIGNATURE"
    @State private var spirit = "TEQUILA"
    @State private var ingredients = ""
    @State private var imageUrl = ""
    @State private var active = true
    @State private var selectedTypes: Set<Int> = []
    @State private var saving = false
    @State private var error: String?

    private let categories = CategoriaCoctel.allCases
    private let spirits = Destilado.allCases

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    LabeledField(label: "Nombre", text: $name, capitalization: .words)
                    LabeledField(label: "Ingredientes", text: $ingredients, multiline: true)
                    LabeledField(label: "URL de imagen", text: $imageUrl, keyboard: .URL, capitalization: .never)

                    Text("CATEGORÍA")
                        .font(.vgSans(10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(VG.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { item in
                                SelectableChip(label: item.label, selected: category == item.rawValue) {
                                    category = item.rawValue
                                }
                            }
                        }
                    }
                    .contentMargins(.horizontal, 0, for: .scrollContent)

                    Text("DESTILADO")
                        .font(.vgSans(10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(VG.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(spirits, id: \.self) { item in
                                SelectableChip(label: item.label, selected: spirit == item.rawValue) {
                                    spirit = item.rawValue
                                }
                            }
                        }
                    }
                    .contentMargins(.horizontal, 0, for: .scrollContent)

                    Text("RECOMENDADO PARA")
                        .font(.vgSans(10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(VG.secondary)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(eventTypes.filter(\.active)) { type in
                            Button {
                                if selectedTypes.contains(type.id) {
                                    selectedTypes.remove(type.id)
                                } else {
                                    selectedTypes.insert(type.id)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: selectedTypes.contains(type.id) ? "checkmark.square.fill" : "square")
                                        .foregroundStyle(selectedTypes.contains(type.id) ? VG.gold : VG.secondary)
                                    Text(type.name)
                                        .font(.vgSans(13))
                                        .foregroundStyle(VG.text)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Toggle("Disponible en la carta", isOn: $active)
                        .font(.vgSans(13))
                        .foregroundStyle(VG.text)
                        .tint(VG.gold)

                    if let error {
                        AlertBanner(message: error)
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        Text(saving ? "Guardando…" : "Guardar")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(saving || name.trimmingCharacters(in: .whitespaces).isEmpty)

                    if cocktail != nil {
                        Button {
                            Task { await deactivate() }
                        } label: {
                            Text("Desactivar cóctel")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(20)
            }
            .background(VG.background)
            .navigationTitle(cocktail == nil ? "Nuevo cóctel" : "Editar cóctel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(VG.gold)
                }
            }
            .onAppear(perform: prefill)
        }
    }

    private func prefill() {
        guard let cocktail else { return }
        name = cocktail.name
        category = cocktail.category
        spirit = cocktail.spirit ?? "TEQUILA"
        ingredients = cocktail.ingredients
        imageUrl = cocktail.imageUrl ?? ""
        active = cocktail.active
        selectedTypes = Set(cocktail.eventTypes.map(\.id))
    }

    private func save() async {
        guard let token = app.token else { return }
        saving = true
        error = nil
        let payload = CocktailPayload(
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            spirit: spirit,
            ingredients: ingredients.trimmingCharacters(in: .whitespaces),
            imageUrl: imageUrl.trimmingCharacters(in: .whitespaces).isEmpty ? nil : imageUrl.trimmingCharacters(in: .whitespaces),
            active: active,
            eventTypeIds: Array(selectedTypes)
        )
        do {
            if let cocktail {
                let _: Cocktail = try await app.api.send("/api/cocktails/\(cocktail.id)", method: "PUT", body: payload, token: token)
            } else {
                let _: Cocktail = try await app.api.send("/api/cocktails", method: "POST", body: payload, token: token)
            }
            onSaved()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }

    private func deactivate() async {
        guard let cocktail, let token = app.token else { return }
        saving = true
        do {
            try await app.api.sendNoBody("/api/cocktails/\(cocktail.id)", method: "DELETE", token: token)
            onSaved()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        saving = false
    }
}
