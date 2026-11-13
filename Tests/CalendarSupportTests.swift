// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// The panel calendar's grid and the bundled holiday data, pinned to a
/// fixed time zone. No views or preferences are opened.
enum CalendarSupportTests {
    private static let utc = TimeZone(secondsFromGMT: 0)
        ?? TimeZone(identifier: "UTC")
        ?? .current

    private static func calendar(locale: String = "en_US", monday: Bool) -> Calendar {
        var calendar = CalendarGrid.calendar(locale: Locale(identifier: locale),
                                             weekStartsMonday: monday)
        calendar.timeZone = utc
        return calendar
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int,
                             calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
            ?? Date(timeIntervalSince1970: 0)
    }

    static func run(_ suite: TestSuite) {
        let monday = calendar(monday: true)
        let sunday = calendar(monday: false)
        suite.expect(monday.firstWeekday == 2 && sunday.firstWeekday == 1,
                     "the week starts on Monday or Sunday as chosen")

        let november = CalendarMonth(year: 2026, month: 11)
        suite.expect(CalendarMonth.containing(date(2026, 11, 13, calendar: monday),
                                              calendar: monday) == november,
                     "a date reports its own month")
        suite.expect(CalendarMonth(year: 2026, month: 1).previous()
                     == CalendarMonth(year: 2025, month: 12),
                     "January pages back into the previous December")
        suite.expect(CalendarMonth(year: 2026, month: 12).next()
                     == CalendarMonth(year: 2027, month: 1),
                     "December pages forward into the next January")

        let today = date(2026, 11, 13, calendar: monday)
        let weeks = CalendarGrid.weeks(month: november, calendar: monday, today: today)
        suite.expect(weeks.count == CalendarGrid.rowCount && weeks.allSatisfy { $0.count == 7 },
                     "the grid always carries six full rows")
        suite.expect(weeks[0][0].dayNumber == 26 && !weeks[0][0].isCurrentMonth,
                     "a Monday-first November 2026 starts on October 26")

        let sundayWeeks = CalendarGrid.weeks(month: november, calendar: sunday, today: today)
        suite.expect(sundayWeeks[0][0].dayNumber == 1 && sundayWeeks[0][0].isCurrentMonth,
                     "a Sunday-first November 2026 starts on November 1")

        let cells = weeks.flatMap { $0 }
        let thirteenth = cells.first { $0.isCurrentMonth && $0.dayNumber == 13 }
        suite.expect(thirteenth?.isToday == true,
                     "today is marked inside the current month")
        suite.expect(cells.filter { $0.isCurrentMonth }.count == 30,
                     "November 2026 contributes its thirty days")
        suite.expect(cells.first { $0.dayNumber == 14 && $0.isCurrentMonth }?.isWeekend == true
                     && cells.first { $0.dayNumber == 15 && $0.isCurrentMonth }?.isWeekend == true
                     && thirteenth?.isWeekend == false,
                     "weekend days are flagged and Friday is not")

        let february = CalendarGrid.weeks(month: CalendarMonth(year: 2026, month: 2),
                                          calendar: monday,
                                          today: today)
        suite.expect(february.flatMap { $0 }.filter(\.isCurrentMonth).count == 28,
                     "a common February contributes twenty-eight days")
        let leapFebruary = CalendarGrid.weeks(month: CalendarMonth(year: 2024, month: 2),
                                              calendar: monday,
                                              today: today)
        suite.expect(leapFebruary.flatMap { $0 }.filter(\.isCurrentMonth).count == 29,
                     "a leap February contributes twenty-nine days")

        let weekdayLabels = CalendarGrid.weekdayLabels(calendar: monday)
        suite.expect(weekdayLabels.count == 7
                     && weekdayLabels.first == monday.veryShortWeekdaySymbols[monday.firstWeekday - 1],
                     "weekday labels start at the calendar's first day")

        let zhTitle = CalendarGrid.monthTitle(for: november, calendar: calendar(locale: "zh_Hans", monday: true))
        suite.expect(zhTitle.contains("2026") && zhTitle.contains("11"),
                     "the month title follows the app language and keeps year and month")
        let enTitle = CalendarGrid.monthTitle(for: november, calendar: monday)
        suite.expect(enTitle.contains("2026") && enTitle.contains("November"),
                     "an English month title names the month and year")

        let holidayJSON = """
            {"years":[{"year":2026,"days":[
              {"name":"元旦","date":"2026-01-01","isOffDay":true},
              {"name":"春节","date":"2026-02-15","isOffDay":false}
            ]}]}
            """
        guard let holidays = try? HolidayStore(jsonData: Data(holidayJSON.utf8)) else {
            suite.expect(false, "the bundled holiday shape decodes")
            return
        }
        suite.expect(holidays.info(forDayKey: "2026-01-01") == .offDay(name: "元旦"),
                     "an off day keeps its name")
        suite.expect(holidays.info(forDayKey: "2026-02-15") == .workday(name: "春节"),
                     "an adjusted workday is distinguished from an off day")
        suite.expect(holidays.info(forDayKey: "2026-02-16") == nil,
                     "a day outside the notice has no holiday entry")
        suite.expect(holidays.minYear == 2026 && holidays.maxYear == 2026,
                     "the store reports the years it covers")
        suite.expect(holidays.isYearOutOfCoverage(2025)
                     && holidays.isYearOutOfCoverage(2027)
                     && !holidays.isYearOutOfCoverage(2026),
                     "a year outside the data is reported as uncovered")
        suite.expect(HolidayStore.dayKey(for: date(2026, 1, 5, calendar: monday),
                                         calendar: monday) == "2026-01-05",
                     "the holiday key is a zero-padded local calendar day")
    }
}