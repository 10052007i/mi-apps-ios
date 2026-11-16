import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var app: AppModel
    @State private var showConfig = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if app.isLoggedIn {
                        profile
                    } else {
                        guest
                    }
                    links
                    if app.isLoggedIn {
                        logoutButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(VG.background)
            .navigationTitle("Cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .vgScreen()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showConfig = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(VG.gold)
                    }
                }
            }
            .sheet(isPresented: $showConfig) {
                ConfigSheet()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Tu espacio")
            Text(app.isLoggedIn ? "Hola, \(app.user?.fullName.components(separatedBy: " ").first ?? "")" : "Cuenta")
                .font(.vgSerif(32))
                .foregroundStyle(VG.text)
            Text(app.isLoggedIn ? "Gestiona tu panel y consulta tus solicitudes." : "Inicia sesión para administrar el negocio o consulta el estado de tu solicitud.")
                .font(.vgSans(14))
                .foregroundStyle(VG.secondary)
        }
        .padding(.top, 8)
    }

    private var profile: some View {
        VGCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Text(VGFormat.initials(app.user?.fullName ?? "VG"))
                        .font(.vgSerif(20))
                        .foregroundStyle(VG.gold)
                        .frame(width: 52, height: 52)
                        .overlay(Rectangle().stroke(VG.goldLine, lineWidth: 1))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(app.user?.fullName ?? "")
                            .font(.vgSans(16, weight: .semibold))
                            .foregroundStyle(VG.text)
                        Text(app.user?.email ?? "")
                            .font(.vgSans(12))
                            .foregroundStyle(VG.secondary)
                    }
                    Spacer()
                    StatusBadge(status: app.user?.role ?? "")
                }
                if app.isAdmin {
                    NavigationLink {
                        AdminHomeView()
                    } label: {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                            Text("Panel de administración")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.vgSans(14, weight: .semibold))
                        .foregroundStyle(VG.background)
                        .padding(14)
                        .background(VG.gold)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var guest: some View {
        VGCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Acceso al panel")
                    .font(.vgSerif(20))
                    .foregroundStyle(VG.text)
                Text("El panel de administración requiere credenciales del equipo Velvet & Gilt.")
                    .font(.vgSans(13))
                    .foregroundStyle(VG.secondary)
                NavigationLink {
                    LoginView()
                } label: {
                    Text("Iniciar sesión")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private var links: some View {
        VStack(spacing: 0) {
            NavigationLink {
                TrackingView()
            } label: {
                linkRow(icon: "magnifyingglass", title: "Consultar mi solicitud", subtitle: "Sigue tu paquete con el token o folio")
            }
            .buttonStyle(.plain)
            Divider().overlay(VG.line)
            Button {
                showConfig = true
            } label: {
                linkRow(icon: "server.rack", title: "Conexión al API", subtitle: app.baseURLString)
            }
            .buttonStyle(.plain)
        }
        .background(VG.card)
        .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
    }

    private func linkRow(icon: String, title: String, subtitle: String) -> some View {
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
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(VG.secondary)
        }
        .padding(16)
    }

    private var logoutButton: some View {
        Button {
            app.logout()
        } label: {
            Text("Cerrar sesión")
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}

struct ConfigSheet: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var value = ""
    @State private var status: String?
    @State private var testing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Dirección del API Gateway")
                        .font(.vgSerif(24))
                        .foregroundStyle(VG.text)
                    Text("Pega aquí la URL HTTPS del túnel de Cloudflare (sin barra final). Por defecto apunta al túnel actual del proyecto.")
                        .font(.vgSans(13))
                        .foregroundStyle(VG.secondary)
                    TextField("https://tu-tunel.trycloudflare.com", text: $value)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .textFieldStyle(VGTextFieldStyle())

                    HStack(spacing: 10) {
                        Button(testing ? "Probando…" : "Probar") {
                            Task { await test() }
                        }
                        .buttonStyle(SecondaryButtonStyle(fullWidth: false))
                        .disabled(testing)

                        Button("Guardar") {
                            app.saveBaseURL(value)
                            Task { await app.loadSettings() }
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle(fullWidth: false))
                    }

                    if let status {
                        Text(status)
                            .font(.vgSans(12))
                            .foregroundStyle(status.hasPrefix("OK") ? VG.success : VG.danger)
                    }

                    Divider().overlay(VG.line)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notas")
                            .font(.vgSans(12, weight: .semibold))
                            .foregroundStyle(VG.text)
                        Text("• El túnel cambia cada vez que se reinicia cloudflared.\n• Ejecuta tunnel.ps1 en el proyecto web y copia la nueva URL.\n• Esta app no necesita credenciales para ver la carta.")
                            .font(.vgSans(12))
                            .foregroundStyle(VG.secondary)
                            .lineSpacing(3)
                    }

                    Divider().overlay(VG.line)
                    InfoRow(label: "Versión", value: "1.0 (iOS 17+)")
                    InfoRow(label: "Proyecto", value: "Velvet & Gilt")
                }
                .padding(20)
            }
            .background(VG.background)
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Listo") { dismiss() }
                        .foregroundStyle(VG.gold)
                }
            }
            .onAppear { value = app.baseURLString }
        }
    }

    private func test() async {
        testing = true
        status = nil
        app.saveBaseURL(value)
        do {
            let list: [Cocktail] = try await API.shared.get("/api/public/cocktails")
            let settings: Settings = try await API.shared.get("/api/public/settings")
            status = "OK · \(list.count) cócteles · \(settings.businessName)"
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
        testing = false
    }
}
