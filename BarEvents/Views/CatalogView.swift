import SwiftUI

struct CatalogView: View {
    @State private var cocktails: [Cocktail] = []
    @State private var loading = true
    @State private var error: String?
    @State private var search = ""
    @State private var category: String?
    @State private var spirit: String?
    @State private var selected: Cocktail?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    searchField
                    filters
                    content
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
            .sheet(item: $selected) { cocktail in
                CocktailDetailView(cocktail: cocktail)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Coctelería de autor")
            Text("La carta")
                .font(.vgSerif(34))
                .foregroundStyle(VG.text)
            Text("Clásicos, signature y opciones sin alcohol. Todos disponibles para tu evento.")
                .font(.vgSans(14))
                .foregroundStyle(VG.secondary)
        }
        .padding(.top, 8)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(VG.secondary)
            TextField("Buscar por nombre o ingrediente", text: $search)
                .font(.vgSans(14))
                .foregroundStyle(VG.text)
                .autocorrectionDisabled()
            if !search.isEmpty {
                Button {
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(VG.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(VG.cardAlt)
        .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectableChip(label: "Todo", selected: category == nil) {
                    category = nil
                }
                ForEach(categories, id: \.self) { item in
                    SelectableChip(label: CategoriaCoctel(rawValue: item)?.label ?? item.capitalized, selected: category == item) {
                        category = category == item ? nil : item
                    }
                }
                Rectangle().fill(VG.line).frame(width: 1, height: 20)
                ForEach(spirits, id: \.self) { item in
                    SelectableChip(label: Destilado(rawValue: item)?.label ?? item.capitalized, selected: spirit == item) {
                        spirit = spirit == item ? nil : item
                    }
                }
            }
        }
        .padding(.horizontal, -20)
        .contentMargins(.horizontal, 20, for: .scrollContent)
    }

    @ViewBuilder
    private var content: some View {
        if loading {
            LoadingState(text: "Cargando la carta…")
        } else if let error {
            ErrorState(message: error) {
                Task { await load() }
            }
        } else if filtered.isEmpty {
            EmptyState(title: "Sin resultados", message: "Prueba con otro filtro o término de búsqueda.")
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filtered) { cocktail in
                    Button {
                        selected = cocktail
                    } label: {
                        CocktailCard(cocktail: cocktail)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var filtered: [Cocktail] {
        let text = search.trimmingCharacters(in: .whitespaces).lowercased()
        return cocktails.filter { c in
            guard c.active else { return false }
            let matchesText = text.isEmpty
                || c.name.lowercased().contains(text)
                || c.ingredients.lowercased().contains(text)
            let matchesCategory = category == nil || c.category == category
            let matchesSpirit = spirit == nil || c.spirit == spirit
            return matchesText && matchesCategory && matchesSpirit
        }
    }

    private var categories: [String] {
        Array(Set(cocktails.filter(\.active).map(\.category))).sorted()
    }

    private var spirits: [String] {
        Array(Set(cocktails.filter(\.active).compactMap(\.spirit))).sorted()
    }

    private func load() async {
        loading = true
        do {
            let list: [Cocktail] = try await API.shared.get("/api/public/cocktails")
            cocktails = list
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

struct CocktailCard: View {
    let cocktail: Cocktail

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RemoteImage(urlString: cocktail.imageUrl, height: 140)
            VStack(alignment: .leading, spacing: 5) {
                Text(cocktail.name)
                    .font(.vgSerif(16))
                    .foregroundStyle(VG.text)
                    .lineLimit(1)
                Text(cocktail.spirit ?? cocktail.category)
                    .font(.vgSans(9, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(VG.gold)
                    .textCase(.uppercase)
                    .lineLimit(1)
                Text(cocktail.ingredients)
                    .font(.vgSans(11))
                    .foregroundStyle(VG.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(11)
        }
        .background(VG.card)
        .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
    }
}

struct CocktailDetailView: View {
    let cocktail: Cocktail
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    RemoteImage(urlString: cocktail.imageUrl, height: 260)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(cocktail.name)
                            .font(.vgSerif(30))
                            .foregroundStyle(VG.text)
                        HStack(spacing: 8) {
                            if let category = CategoriaCoctel(rawValue: cocktail.category) {
                                StatusBadge(status: category.label)
                            }
                            if let spirit = cocktail.spirit, let d = Destilado(rawValue: spirit) {
                                StatusBadge(status: d.label)
                            }
                        }
                        GoldDivider()
                        Text(cocktail.ingredients)
                            .font(.vgSans(15))
                            .foregroundStyle(VG.secondary)
                        if !cocktail.eventTypes.isEmpty {
                            Text("RECOMENDADO PARA")
                                .font(.vgSans(10, weight: .semibold))
                                .tracking(1.2)
                                .foregroundStyle(VG.secondary)
                                .padding(.top, 6)
                            FlowTags(items: cocktail.eventTypes.map(\.name))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 30)
            }
            .background(VG.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundStyle(VG.gold)
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct FlowTags: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(stride(from: 0, to: items.count, by: 2)), id: \.self) { index in
                HStack(spacing: 8) {
                    ForEach(items[index..<min(index + 2, items.count)], id: \.self) { item in
                        Text(item)
                            .font(.vgSans(11, weight: .medium))
                            .foregroundStyle(VG.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(VG.card)
                            .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}
