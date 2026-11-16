import SwiftUI
import UIKit

struct QuoteView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.openURL) private var openURL

    @State private var step = 1
    @State private var confirmed: Solicitud?

    @State private var eventTypes: [EventType] = []
    @State private var cocktails: [Cocktail] = []
    @State private var tiers: [ServiceTier] = []
    @State private var loading = true
    @State private var loadError: String?

    @State private var eventTypeId: Int?
    @State private var guests = 50
    @State private var durationHours = 4
    @State private var eventDate = Date().addingTimeInterval(86_400)
    @State private var includeTime = false
    @State private var eventTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()

    @State private var search = ""
    @State private var categories: Set<String> = []
    @State private var spirits: Set<String> = []
    @State private var selection: Set<Int> = []

    @State private var clientName = ""
    @State private var clientWhatsapp = ""
    @State private var clientEmail = ""
    @State private var location = ""
    @State private var notes = ""

    @State private var validation = ""
    @State private var sending = false
    @State private var sendError: String?
    @State private var copied = false
    @State private var showTracking = false

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let confirmed {
                    ConfirmationView(
                        solicitud: confirmed,
                        onTracking: { showTracking = true },
                        onReset: reset
                    )
                } else if loading {
                    header
                    LoadingState(text: "Cargando cotizador…")
                } else if let loadError {
                    header
                    ErrorState(message: loadError) {
                        Task { await load() }
                    }
                } else {
                    header
                    stepIndicator
                    switch step {
                    case 1: stepOne
                    case 2: stepTwo
                    default: stepThree
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .background(VG.background)
        .vgScreen()
        .task { await load() }
        .sheet(isPresented: $showTracking) {
            NavigationStack { TrackingView() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Cotizador")
            Text(confirmed == nil ? "Diseña tu barra" : "Solicitud enviada")
                .font(.vgSerif(32))
                .foregroundStyle(VG.text)
            Text(confirmed == nil ? "Tres pasos para estimar tu evento y generar un folio de seguimiento." : "Guarda tu folio y revisa el estado cuando quieras.")
                .font(.vgSans(13))
                .foregroundStyle(VG.secondary)
        }
        .padding(.top, 12)
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { index in
                VStack(alignment: .leading, spacing: 6) {
                    Rectangle()
                        .fill(index <= step ? VG.gold : VG.line)
                        .frame(height: 2)
                    Text(["Evento", "Carta", "Datos"][index - 1].uppercased())
                        .font(.vgSans(9, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(index <= step ? VG.gold : VG.secondary)
                }
            }
        }
    }

    // MARK: Paso 1

    private var stepOne: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionTitle(text: "El evento", subtitle: "Cuéntanos el formato, el aforo y la fecha.")

            VStack(alignment: .leading, spacing: 10) {
                Text("TIPO DE EVENTO")
                    .font(.vgSans(10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(VG.secondary)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(eventTypes.filter(\.active)) { type in
                        Button {
                            eventTypeId = type.id
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(type.name)
                                    .font(.vgSans(14, weight: .semibold))
                                    .foregroundStyle(eventTypeId == type.id ? VG.background : VG.text)
                                Text(type.description ?? "")
                                    .font(.vgSans(10))
                                    .foregroundStyle(eventTypeId == type.id ? VG.background.opacity(0.75) : VG.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, minHeight: 62, alignment: .topLeading)
                            .padding(12)
                            .background(eventTypeId == type.id ? VG.gold : VG.card)
                            .overlay(Rectangle().stroke(eventTypeId == type.id ? VG.gold : VG.line, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VGCard {
                VStack(spacing: 16) {
                    stepperRow(title: "Invitados", value: "\(guests)", onMinus: { guests = max(1, guests - 10) }, onPlus: { guests += 10 })
                    Divider().overlay(VG.line)
                    stepperRow(title: "Duración", value: "\(durationHours) h", onMinus: { durationHours = max(1, durationHours - 1) }, onPlus: { durationHours = min(24, durationHours + 1) })
                    Divider().overlay(VG.line)
                    HStack {
                        Text("Fecha")
                            .font(.vgSans(13))
                            .foregroundStyle(VG.secondary)
                        Spacer()
                        DatePicker("", selection: $eventDate, in: Date()...Date().addingTimeInterval(60 * 60 * 24 * 730), displayedComponents: .date)
                            .labelsHidden()
                            .tint(VG.gold)
                    }
                    Divider().overlay(VG.line)
                    HStack {
                        Text("Hora")
                            .font(.vgSans(13))
                            .foregroundStyle(VG.secondary)
                        Spacer()
                        Toggle("", isOn: $includeTime)
                            .labelsHidden()
                            .tint(VG.gold)
                        if includeTime {
                            DatePicker("", selection: $eventTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                    }
                }
            }

            estimateCard

            if !validation.isEmpty {
                AlertBanner(message: validation)
            }

            Button("Continuar a la carta") {
                validateStepOne()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private func stepperRow(title: String, value: String, onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.vgSans(13))
                .foregroundStyle(VG.secondary)
            Spacer()
            Button(action: onMinus) {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(VG.gold)
                    .frame(width: 32, height: 32)
                    .overlay(Rectangle().stroke(VG.goldLine, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Text(value)
                .font(.vgSans(15, weight: .semibold))
                .foregroundStyle(VG.text)
                .frame(minWidth: 58)
            Button(action: onPlus) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(VG.gold)
                    .frame(width: 32, height: 32)
                    .overlay(Rectangle().stroke(VG.goldLine, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var estimateCard: some View {
        VGCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Eyebrow(text: "Estimación")
                    Spacer()
                    Text("\(billedHours) h")
                        .font(.vgSans(11, weight: .semibold))
                        .foregroundStyle(VG.secondary)
                }
                InfoRow(label: "Equipo", value: "\(team.bartenders) bartender(s) · \(team.assistants) ayudante(s)")
                InfoRow(label: "Bartenders", value: VGFormat.soles(desglose.base))
                InfoRow(label: "Ayudantes", value: VGFormat.soles(desglose.personal))
                Divider().overlay(VG.line)
                HStack(alignment: .firstTextBaseline) {
                    Text("TOTAL ESTIMADO")
                        .font(.vgSans(10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(VG.secondary)
                    Spacer()
                    Text(VGFormat.soles(desglose.total))
                        .font(.vgSerif(24))
                        .foregroundStyle(VG.gold)
                }
                Text(VGFormat.dollars(desglose.total) + " · tipo de cambio \(VGFormat.number(max(app.settings.exchangeRate, 0.01)))")
                    .font(.vgSans(11))
                    .foregroundStyle(VG.secondary)
                if durationHours < app.settings.baseHours {
                    Text("El paquete base incluye \(app.settings.baseHours) horas; se cobra ese mínimo.")
                        .font(.vgSans(11))
                        .foregroundStyle(VG.warning)
                }
            }
        }
    }

    // MARK: Paso 2

    private var stepTwo: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(text: "La carta", subtitle: "Elige al menos un cóctel. Los marcados como recomendados van con tu tipo de evento.")

            TextField("Buscar en la carta", text: $search)
                .autocorrectionDisabled()
                .textFieldStyle(VGTextFieldStyle())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categoriesDisponibles, id: \.self) { item in
                        SelectableChip(label: CategoriaCoctel(rawValue: item)?.label ?? item, selected: categories.contains(item)) {
                            categories = toggled(categories, item)
                        }
                    }
                    ForEach(spiritsDisponibles, id: \.self) { item in
                        SelectableChip(label: Destilado(rawValue: item)?.label ?? item, selected: spirits.contains(item)) {
                            spirits = toggled(spirits, item)
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 0, for: .scrollContent)

            let recommended = filtered.filter { c in
                guard let eventTypeId else { return true }
                return c.eventTypes.contains { $0.id == eventTypeId }
            }
            let rest = filtered.filter { c in
                guard let eventTypeId else { return false }
                return !c.eventTypes.contains { $0.id == eventTypeId }
            }

            if recommended.isEmpty && rest.isEmpty {
                EmptyState(title: "Sin cócteles", message: "Ajusta la búsqueda o los filtros.")
            } else {
                if !recommended.isEmpty {
                    Text("RECOMENDADOS")
                        .font(.vgSans(10, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(VG.gold)
                    ForEach(recommended) { cocktail in
                        cocktailRow(cocktail)
                    }
                }
                if !rest.isEmpty {
                    Text("RESTO DE LA CARTA")
                        .font(.vgSans(10, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(VG.secondary)
                        .padding(.top, 6)
                    ForEach(rest) { cocktail in
                        cocktailRow(cocktail)
                    }
                }
            }

            if !validation.isEmpty {
                AlertBanner(message: validation)
            }

            HStack(spacing: 10) {
                Button("Atrás") { step = 1 }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Continuar") { validateStepTwo() }
                    .buttonStyle(PrimaryButtonStyle())
            }
            Text("\(selection.count) cóctel(es) seleccionado(s)")
                .font(.vgSans(11))
                .foregroundStyle(VG.secondary)
        }
    }

    private func cocktailRow(_ cocktail: Cocktail) -> some View {
        Button {
            if selection.contains(cocktail.id) {
                selection.remove(cocktail.id)
            } else {
                selection.insert(cocktail.id)
            }
            validation = ""
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selection.contains(cocktail.id) ? "checkmark.square.fill" : "square")
                    .foregroundStyle(selection.contains(cocktail.id) ? VG.gold : VG.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(cocktail.name)
                        .font(.vgSans(14, weight: .medium))
                        .foregroundStyle(VG.text)
                    Text([CategoriaCoctel(rawValue: cocktail.category)?.label ?? cocktail.category,
                          cocktail.spirit.flatMap { Destilado(rawValue: $0)?.label }]
                            .compactMap { $0 }.joined(separator: " · "))
                        .font(.vgSans(11))
                        .foregroundStyle(VG.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(selection.contains(cocktail.id) ? VG.gold.opacity(0.08) : VG.card)
            .overlay(Rectangle().stroke(selection.contains(cocktail.id) ? VG.goldLine : VG.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Paso 3

    private var stepThree: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionTitle(text: "Tus datos", subtitle: "Con esto emitimos tu folio y el PDF de la propuesta.")

            VStack(spacing: 14) {
                LabeledField(label: "Nombre completo", placeholder: "Ana Pérez", text: $clientName, capitalization: .words)
                LabeledField(label: "WhatsApp", placeholder: "+51 999 999 999", text: $clientWhatsapp, keyboard: .phonePad)
                LabeledField(label: "Correo", placeholder: "ana@correo.com", text: $clientEmail, keyboard: .emailAddress, capitalization: .never)
                LabeledField(label: "Ubicación del evento", placeholder: "Distrito / dirección", text: $location, capitalization: .words)
                LabeledField(label: "Notas", placeholder: "Detalles, restricciones, horarios…", text: $notes, multiline: true)
            }

            estimateCard

            VGCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Carta seleccionada")
                        .font(.vgSerif(17))
                        .foregroundStyle(VG.text)
                    Text(selectedCocktails.map(\.name).joined(separator: ", "))
                        .font(.vgSans(12))
                        .foregroundStyle(VG.secondary)
                }
            }

            if !validation.isEmpty {
                AlertBanner(message: validation)
            }
            if let sendError {
                AlertBanner(message: sendError)
            }

            HStack(spacing: 10) {
                Button("Atrás") { step = 2 }
                    .buttonStyle(SecondaryButtonStyle())
                Button(sending ? "Enviando…" : "Confirmar") {
                    Task { await submit() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(sending)
            }
        }
    }

    // MARK: Lógica

    private var selectedType: EventType? {
        eventTypes.first { $0.id == eventTypeId }
    }

    private var basePrice: Double {
        tiers.first { $0.code == "BASE" }?.price ?? 272
    }

    private var personalPrice: Double {
        tiers.first { $0.code == "PERSONAL" }?.price ?? 150
    }

    private var billedHours: Int {
        QuoteEngine.billedHours(durationHours: durationHours, baseHours: app.settings.baseHours)
    }

    private var team: (bartenders: Int, assistants: Int) {
        QuoteEngine.team(guests: guests, eventTypeCode: selectedType?.code)
    }

    private var desglose: Desglose {
        QuoteEngine.breakdown(
            guests: guests,
            durationHours: durationHours,
            eventTypeCode: selectedType?.code,
            basePrice: basePrice,
            personalPrice: personalPrice,
            baseHours: app.settings.baseHours,
            extraHourPen: app.settings.extraHourPen
        )
    }

    private var selectedCocktails: [Cocktail] {
        cocktails.filter { selection.contains($0.id) }
    }

    private var filtered: [Cocktail] {
        let text = search.trimmingCharacters(in: .whitespaces).lowercased()
        return cocktails.filter { c in
            guard c.active else { return false }
            let matchesText = text.isEmpty
                || c.name.lowercased().contains(text)
                || c.ingredients.lowercased().contains(text)
            let matchesCategory = categories.isEmpty || categories.contains(c.category)
            let matchesSpirit = spirits.isEmpty || (c.spirit.map(spirits.contains) ?? false)
            return matchesText && matchesCategory && matchesSpirit
        }
    }

    private var categoriesDisponibles: [String] {
        Array(Set(cocktails.filter(\.active).map(\.category))).sorted()
    }

    private var spiritsDisponibles: [String] {
        Array(Set(cocktails.filter(\.active).compactMap(\.spirit))).sorted()
    }

    private func toggled(_ set: Set<String>, _ value: String) -> Set<String> {
        var copy = set
        if copy.contains(value) { copy.remove(value) } else { copy.insert(value) }
        return copy
    }

    private func validateStepOne() {
        guard eventTypeId != nil else {
            validation = "Selecciona el tipo de evento."
            return
        }
        guard guests >= 1, guests <= 100_000 else {
            validation = "Indica un número de invitados entre 1 y 100000."
            return
        }
        guard durationHours >= 1, durationHours <= 24 else {
            validation = "La duración debe estar entre 1 y 24 horas."
            return
        }
        validation = ""
        step = 2
    }

    private func validateStepTwo() {
        guard !selection.isEmpty else {
            validation = "Selecciona al menos un cóctel para la carta del evento."
            return
        }
        validation = ""
        step = 3
    }

    private func submit() async {
        let name = clientName.trimmingCharacters(in: .whitespaces)
        let whatsapp = clientWhatsapp.trimmingCharacters(in: .whitespaces)
        let email = clientEmail.trimmingCharacters(in: .whitespaces)
        let place = location.trimmingCharacters(in: .whitespaces)

        guard !name.isEmpty, !whatsapp.isEmpty, !email.isEmpty, !place.isEmpty else {
            validation = "Completa nombre, WhatsApp, correo y ubicación del evento."
            return
        }
        guard email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil else {
            validation = "El correo electrónico no es válido."
            return
        }
        guard let eventTypeId else { return }

        validation = ""
        sendError = nil
        sending = true
        do {
            let payload = SolicitudPayload(
                eventTypeId: eventTypeId,
                eventDate: VGFormat.apiDate(eventDate),
                eventTime: includeTime ? timeFormatter.string(from: eventTime) : nil,
                guests: guests,
                durationHours: durationHours,
                location: place,
                notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
                level: "BASE",
                extraBartenders: 0,
                cocktailIds: Array(selection),
                clientName: name,
                clientWhatsapp: whatsapp,
                clientEmail: email
            )
            let created: Solicitud = try await app.api.send("/api/public/solicitudes", method: "POST", body: payload)
            confirmed = created
            step = 1
        } catch {
            sendError = error.localizedDescription
        }
        sending = false
    }

    private func reset() {
        confirmed = nil
        step = 1
        selection = []
        categories = []
        spirits = []
        search = ""
        clientName = ""
        clientWhatsapp = ""
        clientEmail = ""
        location = ""
        notes = ""
        validation = ""
        sendError = nil
    }

    private func load() async {
        loading = true
        do {
            async let types: [EventType] = app.api.get("/api/public/event-types")
            async let drinks: [Cocktail] = app.api.get("/api/public/cocktails")
            async let loadedTiers: [ServiceTier] = app.api.get("/api/public/service-tiers")
            eventTypes = try await types
            cocktails = try await drinks
            tiers = try await loadedTiers
            if eventTypeId == nil {
                eventTypeId = eventTypes.first(where: \.active)?.id
            }
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        loading = false
    }
}

struct ConfirmationView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.openURL) private var openURL

    let solicitud: Solicitud
    let onTracking: () -> Void
    let onReset: () -> Void

    @State private var copied = false
    @State private var showShare = false
    @State private var shareURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VGCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(solicitud.folio)
                            .font(.vgSerif(26))
                            .foregroundStyle(VG.gold)
                        Spacer()
                        StatusBadge(status: solicitud.status)
                    }
                    Text("Recibimos tu solicitud. Te contactaremos por WhatsApp para confirmar los detalles.")
                        .font(.vgSans(13))
                        .foregroundStyle(VG.secondary)
                    Divider().overlay(VG.line)
                    InfoRow(label: "Evento", value: solicitud.eventTypeName)
                    InfoRow(label: "Fecha", value: VGFormat.longDate(solicitud.eventDate))
                    InfoRow(label: "Invitados", value: "\(solicitud.guests)")
                    InfoRow(label: "Equipo", value: "\(solicitud.bartenders) bartender(s) · \(solicitud.assistants) ayudante(s)")
                    Divider().overlay(VG.line)
                    InfoRow(label: "Total", value: VGFormat.doubleMoney(solicitud.breakdown.total), accent: true)
                }
            }

            VGCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Token de seguimiento")
                        .font(.vgSans(11, weight: .semibold))
                        .foregroundStyle(VG.secondary)
                    Text(solicitud.publicToken)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(VG.text)
                        .textSelection(.enabled)
                }
            }

            VStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = Messages.trackingLink(solicitud)
                    copied = true
                } label: {
                    Text(copied ? "Enlace copiado" : "Copiar enlace de seguimiento")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    if let url = app.api.url("/api/public/solicitudes/\(solicitud.publicToken)/pdf") {
                        shareURL = url
                        showShare = true
                    }
                } label: {
                    Label("Descargar PDF", systemImage: "doc.text")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    if let url = VGFormat.whatsappLink(phone: app.settings.whatsappOwner, message: Messages.owner(solicitud)) {
                        openURL(url)
                    }
                } label: {
                    Label("Enviar por WhatsApp", systemImage: "message")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button("Ver seguimiento", action: onTracking)
                    .buttonStyle(GhostButtonStyle())

                Button("Nueva solicitud", action: onReset)
                    .buttonStyle(GhostButtonStyle())
            }
        }
        .sheet(isPresented: $showShare) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }
}
