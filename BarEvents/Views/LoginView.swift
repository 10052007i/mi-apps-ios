import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var loading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "Equipo Velvet & Gilt")
                    Text("Iniciar sesión")
                        .font(.vgSerif(32))
                        .foregroundStyle(VG.text)
                    Text("Accede al panel para gestionar solicitudes, clientes y la carta.")
                        .font(.vgSans(14))
                        .foregroundStyle(VG.secondary)
                }
                .padding(.top, 8)

                VStack(spacing: 14) {
                    LabeledField(label: "Correo", placeholder: "admin@velvetgilt.com", text: $email, keyboard: .emailAddress, capitalization: .never)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("CONTRASEÑA")
                            .font(.vgSans(10, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(VG.secondary)
                        SecureField("••••••••", text: $password)
                            .font(.vgSans(15))
                            .foregroundStyle(VG.text)
                            .textFieldStyle(VGTextFieldStyle())
                            .textContentType(.password)
                    }
                }

                if let error {
                    AlertBanner(message: error)
                }

                Button {
                    Task { await submit() }
                } label: {
                    Text(loading ? "Ingresando…" : "Ingresar")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(loading || email.isEmpty || password.isEmpty)

                Text("Demo: admin@velvetgilt.com / admin123")
                    .font(.vgSans(11))
                    .foregroundStyle(VG.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(VG.background)
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
        .vgScreen()
    }

    private func submit() async {
        loading = true
        error = nil
        do {
            try await app.login(email: email, password: password)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
