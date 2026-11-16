import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var app: AppModel
    let onQuote: () -> Void
    let onCatalog: () -> Void

    @State private var cocktails: [Cocktail] = []
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    hero
                    stats
                    experience
                    featured
                    cta
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(VG.background)
            .toolbar(.hidden, for: .navigationBar)
            .vgScreen()
            .task { await load() }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Rectangle().fill(VG.gold).frame(width: 26, height: 1)
                Text("VELVET & GILT")
                    .font(.vgSans(11, weight: .semibold))
                    .tracking(4)
                    .foregroundStyle(VG.gold)
            }
            .padding(.top, 24)

            Text("Mixología de autor para noches memorables")
                .font(.vgSerif(38))
                .foregroundStyle(VG.text)
                .lineSpacing(2)

            Text("Bartenders de autor, carta personalizada y montaje completo para bodas, corporativos y celebraciones privadas en Lima.")
                .font(.vgSans(15))
                .foregroundStyle(VG.secondary)
                .lineSpacing(4)

            VStack(spacing: 12) {
                Button("Cotizar mi evento", action: onQuote)
                    .buttonStyle(PrimaryButtonStyle())
                Button("Ver la carta", action: onCatalog)
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.top, 6)
        }
    }

    private var stats: some View {
        HStack(spacing: 1) {
            stat(value: "\(max(cocktails.count, 16))", label: "Cócteles de autor")
            stat(value: "3", label: "Pasos para cotizar")
            stat(value: "24/7", label: "Atención WhatsApp")
        }
        .background(VG.line)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.vgSerif(22))
                .foregroundStyle(VG.gold)
            Text(label)
                .font(.vgSans(10, weight: .medium))
                .foregroundStyle(VG.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(VG.card)
    }

    private var experience: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "La experiencia")
            SectionTitle(text: "Una barra completa en tu evento", subtitle: "Nos encargamos de la coctelería de principio a fin: insumos, equipo, cristalería y servicio.")
            VStack(spacing: 12) {
                experienceRow(icon: "wineglass", title: "Carta personalizada", text: "Diseñamos la carta según tu tipo de evento, invitados y temporada.")
                experienceRow(icon: "person.2", title: "Equipo profesional", text: "Bartenders y ayudantes asignados automáticamente según el aforo.")
                experienceRow(icon: "sparkles", title: "Montaje completo", text: "Llegamos con barra, cristalería, insumos y desmontaje incluido.")
            }
            NavigationLink {
                ServicesView()
            } label: {
                Text("Conocer los servicios")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    private func experienceRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(VG.gold)
                .frame(width: 34, height: 34)
                .overlay(Rectangle().stroke(VG.goldLine, lineWidth: 1))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.vgSans(15, weight: .semibold))
                    .foregroundStyle(VG.text)
                Text(text)
                    .font(.vgSans(13))
                    .foregroundStyle(VG.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(VG.card)
        .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
    }

    private var featured: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "Carta signature")
            HStack {
                SectionTitle(text: "Cócteles destacados")
                Spacer()
                Button("Ver todos", action: onCatalog)
                    .buttonStyle(GhostButtonStyle())
            }
            if let error {
                Text(error)
                    .font(.vgSans(12))
                    .foregroundStyle(VG.secondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(cocktails.filter(\.active).prefix(5)) { cocktail in
                        VStack(alignment: .leading, spacing: 0) {
                            RemoteImage(urlString: cocktail.imageUrl, height: 170)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(cocktail.name)
                                    .font(.vgSerif(17))
                                    .foregroundStyle(VG.text)
                                    .lineLimit(1)
                                Text(cocktail.spirit ?? cocktail.category)
                                    .font(.vgSans(10, weight: .semibold))
                                    .tracking(1)
                                    .foregroundStyle(VG.gold)
                                    .textCase(.uppercase)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(VG.card)
                        }
                        .frame(width: 190)
                        .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, -20)
            .contentMargins(.horizontal, 20, for: .scrollContent)
        }
    }

    private var cta: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("¿Listo para brindar?")
                .font(.vgSerif(24))
                .foregroundStyle(VG.text)
            Text("Genera tu paquete en minutos y recibe el PDF con la propuesta completa.")
                .font(.vgSans(14))
                .foregroundStyle(VG.secondary)
            Button("Comenzar cotización", action: onQuote)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 4)
        }
        .padding(20)
        .background(VG.surface)
        .overlay(Rectangle().stroke(VG.goldLine, lineWidth: 1))
    }

    private func load() async {
        do {
            let list: [Cocktail] = try await API.shared.get("/api/public/cocktails")
            cocktails = list
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
