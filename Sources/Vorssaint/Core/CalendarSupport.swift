// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// One month in the panel's calendar. Pure value type so the grid can be
/// rebuilt from a saved month without touching the view.
struct CalendarMonth: Hashable {
    var year: Int
    var month: Int

    static func containing(_ date: Date, calendar: Calendar) -> CalendarMonth {
        let components = calendar.dateComponents([.year, .month], from: date)
        return CalendarMonth(year: components.year ?? 0, month: components.month ?? 1)
    }

    func previous() -> CalendarMonth {
        month == 1 ? CalendarMonth(year: year - 1, month: 12)
                   : CalendarMonth(year: year, month: month - 1)
    }

    func next() -> CalendarMonth {
        month == 12 ? CalendarMonth(year: year + 1, month: 1)
                    : CalendarMonth(year: year, month: month + 1)
    }
}

/// One date in the month grid. Adjacent-month days are included so every
/// month keeps the same six rows and the panel never changes height.
struct CalendarDay: Hashable, Identifiable {
    let date: Date
    let dayNumber: Int
    let isToday: Bool
    let isCurrentMonth: Bool
    let isWeekend: Bool

    var id: Date { date }
}

enum CalendarGrid {
    /// Six rows, always: a month can need four to six, and a fixed count
    /// keeps the panel from resizing as the user pages through the year.
    static let rowCount = 6

    /// The calendar the panel draws with: Gregorian, the app language's
    /// month and weekday names, and the chosen first day of the week.
    static func calendar(locale: Locale, weekStartsMonday: Bool) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        calendar.firstWeekday = weekStartsMonday ? 2 : 1
        return calendar
    }

    static func weeks(month: CalendarMonth,
                      calendar: Calendar,
                      today: Date) -> [[CalendarDay]] {
        guard let firstOfMonth = calendar.date(from: DateComponents(year: month.year,
                                                                    month: month.month,
                                                                    day: 1))
        else { return [] }

        let leading = (calendar.component(.weekday, from: firstOfMonth)
                       - calendar.firstWeekday + 7) % 7
        guard let gridStart = calendar.date(byAdding: .day,
                                            value: -leading,
                                            to: calendar.startOfDay(for: firstOfMonth))
        else { return [] }

        var rows: [[CalendarDay]] = []
        for week in 0..<rowCount {
            var row: [CalendarDay] = []
            for slot in 0..<7 {
                let offset = week * 7 + slot
                guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart)
                else { continue }
                let components = calendar.dateComponents([.day, .month, .year], from: date)
                row.append(CalendarDay(
                    date: date,
                    dayNumber: components.day ?? 0,
                    isToday: calendar.isDate(date, inSameDayAs: today),
                    isCurrentMonth: components.month == month.month
                        && components.year == month.year,
                    isWeekend: calendar.isDateInWeekend(date)))
            }
            rows.append(row)
        }
        return rows
    }

    /// "November 2026", "2026年11月", and whatever the app language asks a
    /// year-and-month template to produce.
    static func monthTitle(for month: CalendarMonth, calendar: Calendar) -> String {
        guard let date = calendar.date(from: DateComponents(year: month.year,
                                                            month: month.month,
                                                            day: 1))
        else { return "" }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? .current
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return formatter.string(from: date)
    }

    /// Seven very short weekday names, starting at the calendar's first day.
    static func weekdayLabels(calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        return (0..<7).map { slot in
            let weekday = (calendar.firstWeekday + slot - 1) % 7 + 1
            return symbols[weekday - 1]
        }
    }
}