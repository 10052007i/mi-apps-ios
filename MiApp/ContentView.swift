import SwiftUI
import UIKit

struct ContentView: View {
    // MARK: - Persistencia con AppStorage (los datos se guardan al cerrar la app)
    @AppStorage("contador_toques") private var contador: Int = 0
    @AppStorage("total_historico") private var totalHistorico: Int = 0
    @AppStorage("meta_objetivo") private var metaObjetivo: Int = 50

    // MARK: - Estados de UI y animaciones
    @State private var scaleEffect: CGFloat = 1.0
    @State private var mostrarAlertaReinicio = false
    @State private var mostrarAjustes = false

    // Progreso hacia la meta (0.0 a 1.0)
    private var progresoMeta: Double {
        guard metaObjetivo > 0 else { return 0 }
        return min(Double(contador) / Double(metaObjetivo), 1.0)
    }

    // Nivel según los toques acumulados
    private var rangoUsuario: (titulo: String, color: Color, icono: String) {
        switch contador {
        case 0..<10:
            return ("Principiante", .gray, "leaf.fill")
        case 10..<30:
            return ("Entusiasta", .blue, "flame.fill")
        case 30..<50:
            return ("Avanzado", .purple, "bolt.fill")
        default:
            return ("Maestro iOS", .orange, "crown.fill")
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo con gradiente sutil dinámico
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.12),
                        Color.pink.opacity(0.06),
                        Color(uiColor: .systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Tarjeta de Bienvenida / Logo
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 84, height: 84)
                                    .shadow(color: .orange.opacity(0.4), radius: 10, x: 0, y: 5)

                                Image(systemName: "swift")
                                    .font(.system(size: 44, weight: .bold))
                                    .foregroundColor(.white)
                                    .scaleEffect(scaleEffect)
                            }
                            .onTapGesture {
                                animarLogo()
                                darToqueHaptico(.light)
                            }

                            Text("MiApp Swift")
                                .font(.title.bold())
                                .foregroundColor(.primary)

                            Text("Desarrollado en Aplicativos iOS II")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 10)

                        // MARK: - Tarjeta de Progreso y Nivel
                        VStack(spacing: 16) {
                            HStack {
                                Label(rangoUsuario.titulo, systemImage: rangoUsuario.icono)
                                    .font(.subheadline.bold())
                                    .foregroundColor(rangoUsuario.color)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(rangoUsuario.color.opacity(0.15))
                                    .clipShape(Capsule())

                                Spacer()

                                Text("\(contador)/\(metaObjetivo) toques")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }

                            // Barra de progreso interactiva
                            ProgressView(value: progresoMeta)
                                .tint(.orange)
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            if contador >= metaObjetivo {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                    Text("¡Meta alcanzada! Felicitaciones 🎉")
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(18)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)

                        // MARK: - Contador Principal
                        VStack(spacing: 8) {
                            Text("Total de toques")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Text("\(contador)")
                                .font(.system(size: 72, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: contador)
                        }
                        .padding(.vertical, 8)

                        // MARK: - Botón Principal con Efecto
                        Button {
                            incrementar(cantidad: 1)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.title2)
                                Text("¡Tócame!")
                                    .font(.title3.bold())
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .orange.opacity(0.4), radius: 10, x: 0, y: 6)
                        }
                        .padding(.horizontal)
                        .scaleEffect(scaleEffect)

                        // MARK: - Controles secundarios (+5, -1, Reiniciar)
                        HStack(spacing: 12) {
                            Button {
                                decrementar()
                            } label: {
                                Label("-1", systemImage: "minus")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.bordered)
                            .tint(.secondary)
                            .disabled(contador == 0)

                            Button {
                                incrementar(cantidad: 5)
                            } label: {
                                Label("+5", systemImage: "plus.circle.fill")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)

                            Button(role: .destructive) {
                                mostrarAlertaReinicio = true
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.subheadline.bold())
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .disabled(contador == 0)
                        }
                        .padding(.horizontal)

                        // MARK: - Estadísticas Rápidas
                        HStack(spacing: 16) {
                            StatCard(
                                titulo: "Histórico",
                                valor: "\(totalHistorico)",
                                icono: "chart.line.uptrend.xyaxis",
                                color: .blue
                            )
                            StatCard(
                                titulo: "Meta",
                                valor: "\(metaObjetivo)",
                                icono: "target",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Inicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mostrarAjustes = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $mostrarAjustes) {
                AjustesSheet(
                    metaObjetivo: $metaObjetivo,
                    contador: $contador,
                    totalHistorico: $totalHistorico
                )
            }
            .alert("¿Reiniciar contador?", isPresented: $mostrarAlertaReinicio) {
                Button("Cancelar", role: .cancel) { }
                Button("Reiniciar", role: .destructive) {
                    withAnimation(.spring()) {
                        contador = 0
                    }
                    darToqueHaptico(.medium)
                }
            } message: {
                Text("El contador actual volverá a 0. El total histórico se mantendrá intacto.")
            }
        }
    }

    // MARK: - Métodos de interacción
    private func incrementar(cantidad: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            contador += cantidad
            totalHistorico += cantidad
            scaleEffect = 1.08
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring()) {
                scaleEffect = 1.0
            }
        }

        if contador >= metaObjetivo && (contador - cantidad) < metaObjetivo {
            darNotificacionHaptica(.success)
        } else {
            darToqueHaptico(.light)
        }
    }

    private func decrementar() {
        guard contador > 0 else { return }
        withAnimation(.spring()) {
            contador -= 1
        }
        darToqueHaptico(.light)
    }

    private func animarLogo() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
            scaleEffect = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring()) {
                scaleEffect = 1.0
            }
        }
    }

    private func darToqueHaptico(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    private func darNotificacionHaptica(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

// MARK: - Componente reutilizable: Tarjeta de estadística
struct StatCard: View {
    let titulo: String
    let valor: String
    let icono: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icono)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(valor)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Vista Modal de Ajustes
struct AjustesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var metaObjetivo: Int
    @Binding var contador: Int
    @Binding var totalHistorico: Int

    var body: some View {
        NavigationStack {
            Form {
                Section("Objetivo de toques") {
                    Stepper("Meta: \(metaObjetivo) toques", value: $metaObjetivo, in: 10...500, step: 10)
                }

                Section("Acerca del Proyecto") {
                    HStack {
                        Text("Institución")
                        Spacer()
                        Text("CIBERTEC")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Curso")
                        Spacer()
                        Text("Aplicativos iOS II")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Framework")
                        Spacer()
                        Text("SwiftUI (iOS 16+)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Versión")
                        Spacer()
                        Text("1.1.0")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        contador = 0
                        totalHistorico = 0
                    } label: {
                        HStack {
                            Spacer()
                            Text("Restablecer todos los datos")
                            Spacer()
                        }
                    }
                } footer: {
                    Text("Borra el contador actual y el récord histórico.")
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
