import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var app: AppModel

    @State private var month = Date()
    @State private var events: [EventoCalendario] = []
    @State private var loading = true
    @State private var error: String?
    @State private var selectedDay: Date?

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        cal.locale = Locale(identifier: "es_PE")
        return cal
    }

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
    }

    private var leadingBlanks: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                monthHeader
                weekdayHeader
                grid
                if loading {
                    LoadingState(text: "Cargando eventos…")
                } else if let error {
                    ErrorState(message: error) {
                        Task { await load() }
                    }
                } else {
                    dayEvents
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(VG.background)
        .navigationTitle("Calendario")
        .navigationBarTitleDisplayMode(.inline)
        .vgScreen()
        .task { await load() }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(VG.gold)
                    .frame(width: 34, height: 34)
                    .overlay(Rectangle().stroke(VG.goldLine, lineWidth: 1))
            }
            .buttonStyle(.plain)
            Spacer()
            Text(VGFormat.monthTitle(monthStart))
                .font(.vgSerif(22))
                .foregroundStyle(VG.text)
            Spacer()
            Button {
                changeMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(VG.gold)
                    .frame(width: 34, height: 34)
                    .overlay(Rectangle().stroke(VG.goldLine, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(["L", "M", "M", "J", "V", "S", "D"], id: \.self) { day in
                Text(day)
                    .font(.vgSans(10, weight: .semibold))
                    .foregroundStyle(VG.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
            ForEach(0..<leadingBlanks, id: \.self) { index in
                Color.clear.frame(height: 40).id("blank-\(index)")
            }
            ForEach(1...daysInMonth, id: \.self) { day in
                dayCell(day)
            }
        }
    }

    private func dayCell(_ day: Int) -> some View {
        let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
        let key = VGFormat.apiDate(date)
        let hasEvents = events.contains { $0.eventDate == key }
        let selected = selectedDay.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        return Button {
            selectedDay = selected ? nil : date
        } label: {
            VStack(spacing: 3) {
                Text("\(day)")
                    .font(.vgSans(12, weight: hasEvents ? .semibold : .regular))
                    .foregroundStyle(selected ? VG.background : VG.text)
                Circle()
                    .fill(hasEvents ? (selected ? VG.background : VG.gold) : .clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(selected ? VG.gold : (hasEvents ? VG.gold.opacity(0.08) : VG.card))
            .overlay(Rectangle().stroke(hasEvents && !selected ? VG.goldLine : VG.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var dayEvents: some View {
        if let selectedDay {
            let key = VGFormat.apiDate(selectedDay)
            let items = events.filter { $0.eventDate == key }
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: VGFormat.longDate(selectedDay), subtitle: "\(items.count) evento(s)")
                if items.isEmpty {
                    EmptyState(title: "Día libre", message: "No hay eventos agendados.")
                } else {
                    ForEach(items) { item in
                        NavigationLink {
                            RequestDetailView(requestId: item.id)
                        } label: {
                            eventRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "Agenda del mes", subtitle: "\(events.count) eventos en \(VGFormat.monthTitle(monthStart).lowercased())")
                if events.isEmpty {
                    EmptyState(title: "Sin eventos", message: "Selecciona otro mes o registra nuevas solicitudes.")
                } else {
                    ForEach(events) { item in
                        NavigationLink {
                            RequestDetailView(requestId: item.id)
                        } label: {
                            eventRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func eventRow(_ item: EventoCalendario) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(String(item.eventDate.suffix(2)))
                    .font(.vgSerif(18))
                    .foregroundStyle(VG.gold)
                Text(String(VGFormat.shortDate(item.eventDate).prefix(6)))
                    .font(.vgSans(9))
                    .foregroundStyle(VG.secondary)
            }
            .frame(width: 44)
            .padding(.vertical, 8)
            .overlay(Rectangle().stroke(VG.goldLine, lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.clientName)
                    .font(.vgSans(14, weight: .medium))
                    .foregroundStyle(VG.text)
                    .lineLimit(1)
                Text("\(item.eventTypeName) · \(item.folio)")
                    .font(.vgSans(11))
                    .foregroundStyle(VG.secondary)
                Text([item.eventTime.map { "\($0) hrs" }, item.location]
                        .compactMap { $0 }.joined(separator: " · "))
                    .font(.vgSans(11))
                    .foregroundStyle(VG.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                StatusBadge(status: item.status)
                Text(VGFormat.soles(item.totalAmount))
                    .font(.vgSans(11, weight: .semibold))
                    .foregroundStyle(VG.text)
            }
        }
        .padding(12)
        .background(VG.card)
        .overlay(Rectangle().stroke(VG.line, lineWidth: 1))
    }

    private func changeMonth(_ delta: Int) {
        if let next = calendar.date(byAdding: .month, value: delta, to: monthStart) {
            month = next
            selectedDay = nil
            Task { await load() }
        }
    }

    private func load() async {
        guard let token = app.token else {
            error = "Sesión no autorizada."
            loading = false
            return
        }
        loading = true
        let start = monthStart
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? start
        do {
            let value: [EventoCalendario] = try await app.api.get(
                "/api/requests/eventos",
                query: ["desde": VGFormat.apiDate(start), "hasta": VGFormat.apiDate(end)],
                token: token
            )
            events = value
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}
