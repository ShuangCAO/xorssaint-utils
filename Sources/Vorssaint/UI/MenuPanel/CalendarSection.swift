// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// The month calendar panel: a fixed six-row grid that follows the app
/// language and the chosen first day of the week. It keeps the current month
/// on open unless the user paged away from it, and it can select a day
/// without leaving the panel.
struct CalendarSection: View {
    @ObservedObject private var l10n = L10n.shared
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(DefaultsKey.calendarWeekStartsMonday) private var weekStartsMonday = true
    @State private var displayedMonth: CalendarMonth
    @State private var today = Date()
    @State private var hasManuallyNavigated = false
    @State private var selectedDate: Date?
    @State private var hasExplicitSelection = false

    init() {
        let calendar = CalendarGrid.calendar(
            locale: Locale(identifier: L10n.shared.language.rawValue),
            weekStartsMonday: UserDefaults.standard.bool(forKey: DefaultsKey.calendarWeekStartsMonday))
        _displayedMonth = State(initialValue: CalendarMonth.containing(Date(), calendar: calendar))
    }

    private var strings: CalendarPanelStrings {
        FeatureStrings.calendarPanel(l10n.language)
    }

    private var calendar: Calendar {
        CalendarGrid.calendar(locale: Locale(identifier: l10n.language.rawValue),
                              weekStartsMonday: weekStartsMonday)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            weekdayRow
            grid
        }
        .panelCard()
        .onAppear(perform: refreshForAppearance)
        .onChange(of: weekStartsMonday) { _, _ in
            // Only the first column moves; keep the month the user is on.
            if !hasManuallyNavigated {
                displayedMonth = CalendarMonth.containing(Date(), calendar: calendar)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            let now = Date()
            today = now
            if !hasManuallyNavigated {
                displayedMonth = CalendarMonth.containing(now, calendar: calendar)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text(CalendarGrid.monthTitle(for: displayedMonth, calendar: calendar))
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 6)
            iconButton("chevron.left", help: strings.previousMonth) {
                step(-1)
            }
            Button(action: goToToday) {
                Text(strings.today)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(minWidth: 24, minHeight: 22)
                    .padding(.horizontal, 4)
                    .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .background(controlFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .help(strings.today)
            .accessibilityLabel(strings.today)
            iconButton("chevron.right", help: strings.nextMonth) {
                step(1)
            }
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(CalendarGrid.weekdayLabels(calendar: calendar).enumerated()),
                    id: \.offset) { _, label in
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        let weeks = CalendarGrid.weeks(month: displayedMonth, calendar: calendar, today: today,
                                       holidayStore: isChineseLanguage ? HolidayStore.shared : nil)
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7),
            spacing: 2
        ) {
            ForEach(weeks, id: \.self) { week in
                ForEach(week) { day in
                    dayButton(day)
                }
            }
        }
        // A new month rebuilds every cell, so an adjacent-month slot can
        // never keep the previous month's styling.
        .id(displayedMonth)
    }

    private func dayButton(_ day: CalendarDay) -> some View {
        let isSelected = selectedDate.map {
            calendar.isDate(day.date, inSameDayAs: $0)
        } ?? false
        return Button {
            selectedDate = day.date
            hasExplicitSelection = true
        } label: {
            VStack(spacing: 0) {
                Text("\(day.dayNumber)")
                    .font(.system(size: day.isCurrentMonth ? 12.5 : 11,
                                  weight: isSelected ? .semibold
                                        : day.isCurrentMonth ? .medium : .regular))
                    .foregroundStyle(dayColor(day, isSelected: isSelected))
                if let marker = holidayMarker(for: day, isSelected: isSelected) {
                    Text(marker.text)
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundStyle(marker.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.accentColor)
                } else if day.isToday {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 1.4)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel(for: day)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The holiday name sits under the date; an adjusted workday only needs
    /// the standard 班 marker, since its name is the holiday it belongs to.
    private func holidayMarker(for day: CalendarDay,
                               isSelected: Bool) -> (text: String, color: Color)? {
        guard let holiday = day.holiday else { return nil }
        switch holiday {
        case .offDay(let name):
            return (name, isSelected ? .white.opacity(0.9) : Color.red.opacity(0.9))
        case .workday:
            return ("班", isSelected ? .white.opacity(0.9) : Color.orange)
        }
    }

    private func accessibilityLabel(for day: CalendarDay) -> String {
        var label = day.date.formatted(.dateTime.year().month().day()
            .locale(Locale(identifier: l10n.language.rawValue)))
        guard let holiday = day.holiday else { return label }
        switch holiday {
        case .offDay(let name):
            label += "，\(name)"
        case .workday(let name):
            label += "，\(name)，调休上班"
        }
        return label
    }

    private var isChineseLanguage: Bool {
        switch l10n.language {
        case .zhHans, .zhTW, .zhHK: return true
        default: return false
        }
    }

    private func dayColor(_ day: CalendarDay, isSelected: Bool) -> Color {
        if isSelected { return .white }
        if day.isWeekend {
            return Color.red.opacity(day.isCurrentMonth ? 0.85 : 0.35)
        }
        return day.isCurrentMonth ? .primary : Color.secondary.opacity(0.45)
    }

    private var controlFill: Color {
        PanelSurface.controlFill(for: colorScheme)
    }

    private func iconButton(_ name: String,
                            help: String,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 10.5, weight: .semibold))
                .frame(width: 22, height: 22)
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .background(controlFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .help(help)
        .accessibilityLabel(help)
    }

    private func step(_ delta: Int) {
        displayedMonth = delta < 0 ? displayedMonth.previous() : displayedMonth.next()
        hasManuallyNavigated = true
        refreshTodayIfViewingCurrentMonth()
    }

    private func goToToday() {
        let now = Date()
        today = now
        selectedDate = now
        hasExplicitSelection = false
        displayedMonth = CalendarMonth.containing(now, calendar: calendar)
        hasManuallyNavigated = false
    }

    private func refreshForAppearance() {
        let now = Date()
        today = now
        if !hasManuallyNavigated {
            displayedMonth = CalendarMonth.containing(now, calendar: calendar)
        }
        if !hasExplicitSelection {
            selectedDate = nil
        }
    }

    private func refreshTodayIfViewingCurrentMonth() {
        let now = Date()
        guard CalendarMonth.containing(now, calendar: calendar) == displayedMonth else { return }
        today = now
    }
}