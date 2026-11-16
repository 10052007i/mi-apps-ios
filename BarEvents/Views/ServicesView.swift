import SwiftUI

struct ServicesView: View {
    @State private var tiers: [ServiceTier] = []
    @State private var eventTypes: [EventType] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                if loading {
                    LoadingState(text: "Cargando servicios…")
                } else if let error {
                    ErrorState(message: error) {
                        Task { await load() }
                    }
                } else {
                    tiersList
                    eventTypesList
                    cta
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(VG.background)
        .navigationTitle("Servicios")
        .navigationBarTitleDisplayMode(.inline)
        .vgScreen()
        .task { await load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Lo que hacemos")
            Text("Experiencias a tu medida")
                .font(.vgSerif(32))
                .foregroundStyle(VG.text)
            Text("Elige el formato que mejor acompaña tu celebración. Ajustamos carta, equipo y montaje según tu evento.")
                .font(.vgSans(14))
                .foregroundStyle(VG.secondary)
                .lineSpacing(3)
        }
        .padding(.top, 8)
    }

    private var tiersList: some View {
        VStack(spacing: 14) {
            ForEach(tiers.filter(\.active)) { tier in
                VGCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(tier.name)
                                .font(.vgSerif(22))
                                .foregroundStyle(VG.text)
                            Spacer()
                            StatusBadge(status: tier.tierType ?? tier.code)
                        }
                        Text(tier.description)
                            .font(.vgSans(14))
                            .foregroundStyle(VG.secondary)
                            .lineSpacing(3)
                        HStack {
                            Text("Desde")
                                .font(.vgSans(11))
                                .foregroundStyle(VG.secondary)
                            Text(VGFormat.soles(tier.price))
                                .font(.vgSans(17, weight: .semibold))
                                .foregroundStyle(VG.gold)
                            Spacer()
                            NavigationLink {
                                QuoteView()
                            } label: {
                                Text("Cotizar")
                                    .font(.vgSans(11, weight: .semibold))
                                    .textCase(.uppercase)
                                    .tracking(1)
                                    .foregroundStyle(VG.background)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(VG.gold)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 2)
                    }
                }
            }
        }
    }

    private var eventTypesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Tipos de evento", subtitle: "Cada formato tiene su propia carta sugerida y equipo asignado.")
            ForEach(eventTypes.filter(\.active).sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }) { type in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(VG.gold)
                        .padding(.top, 6)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(type.name)
                            .font(.vgSans(15, weight: .semibold))
                            .foregroundStyle(VG.text)
                        Text(type.description ?? "")
                            .font(.vgSans(13))
                            .foregroundStyle(VG.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var cta: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Armemos tu barra")
                .font(.vgSerif(24))
                .foregroundStyle(VG.text)
            Text("En tres pasos obtienes una estimación clara y un folio de seguimiento.")
                .font(.vgSans(14))
                .foregroundStyle(VG.secondary)
            NavigationLink {
                QuoteView()
            } label: {
                Text("Cotizar mi evento")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(20)
        .background(VG.surface)
        .overlay(Rectangle().stroke(VG.goldLine, lineWidth: 1))
    }

    private func load() async {
        loading = true
        do {
            async let loadedTypes: [EventType] = API.shared.get("/api/public/event-types")
            async let loadedTiers: [ServiceTier] = API.shared.get("/api/public/service-tiers")
            eventTypes = try await loadedTypes
            tiers = try await loadedTiers
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
