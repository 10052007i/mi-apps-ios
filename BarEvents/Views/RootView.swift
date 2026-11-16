import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppModel
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView(onQuote: { tab = 2 }, onCatalog: { tab = 1 })
                .tabItem { Label("Inicio", systemImage: "house") }
                .tag(0)

            CatalogView()
                .tabItem { Label("Carta", systemImage: "wineglass") }
                .tag(1)

            QuoteView()
                .tabItem { Label("Cotizar", systemImage: "sparkles") }
                .tag(2)

            ContactView()
                .tabItem { Label("Contacto", systemImage: "phone") }
                .tag(3)

            AccountView()
                .tabItem { Label("Cuenta", systemImage: "person.crop.circle") }
                .tag(4)
        }
        .tint(VG.gold)
        .toolbarBackground(VG.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
