// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// The menu bar clock's pure formatting and timer contract, pinned to a
/// fixed date and time zone. No status item or preferences are opened.
enum MenuBarClockTests {
    private static let utc = TimeZone(secondsFromGMT: 0)
        ?? TimeZone(identifier: "UTC")
        ?? .current

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar
    }

    private static func date(hour: Int, minute: Int, second: Int,
                             fraction: Double = 0) -> Date {
        let components = DateComponents(year: 2026, month: 11, day: 13,
                                        hour: hour, minute: minute, second: second)
        let base = calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
        return base.addingTimeInterval(fraction)
    }

    private static func seconds(_ date: Date, since expected: Date) -> Double {
        date.timeIntervalSince(expected)
    }

    static func run(_ suite: TestSuite) {
        let defaultText = MenuBarClockSupport.text(
            for: date(hour: 10, minute: 30, second: 45),
            format: MenuBarClockSupport.defaultFormat,
            locale: MenuBarClockSupport.locale,
            timeZone: utc)
        suite.expect(defaultText == "2026年11月13日 周五 10:30:45",
                     "the default pattern renders the tinyCal date and a seconds readout")

        let minuteText = MenuBarClockSupport.text(
            for: date(hour: 10, minute: 30, second: 45),
            format: "HH:mm",
            locale: MenuBarClockSupport.locale,
            timeZone: utc)
        suite.expect(minuteText == "10:30",
                     "a minute-only pattern drops the date and seconds")

        let posixText = MenuBarClockSupport.text(
            for: date(hour: 10, minute: 30, second: 45),
            format: "yyyy-MM-dd HH:mm:ss",
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: utc)
        suite.expect(posixText == "2026-11-13 10:30:45",
                     "a custom locale formats the same instant independently")

        suite.expect(MenuBarClockSupport.sanitizedFormat(nil) == MenuBarClockSupport.defaultFormat,
                     "a missing pattern falls back to the default")
        suite.expect(MenuBarClockSupport.sanitizedFormat("   ") == MenuBarClockSupport.defaultFormat,
                     "a blank pattern falls back to the default")
        suite.expect(MenuBarClockSupport.sanitizedFormat("  HH:mm\n") == "HH:mm",
                     "a pattern loses surrounding whitespace and newlines")
        suite.expect(MenuBarClockSupport.sanitizedFormat("HH:mm\r\n") == "HH:mm",
                     "a trailing carriage return is removed too")
        let longPattern = String(repeating: "y", count: MenuBarClockSupport.maximumFormatLength + 20)
        suite.expect(MenuBarClockSupport.sanitizedFormat(longPattern).count
                     == MenuBarClockSupport.maximumFormatLength,
                     "an overlong pattern is cut at the menu bar's limit")

        suite.expect(MenuBarClockSupport.includesSeconds("HH:mm:ss"),
                     "a seconds field asks for a one-second clock")
        suite.expect(!MenuBarClockSupport.includesSeconds("HH:mm"),
                     "a minute-only pattern asks for a minute clock")
        suite.expect(!MenuBarClockSupport.includesSeconds("'s' HH:mm"),
                     "an s inside quotes is text, not a seconds field")
        suite.expect(MenuBarClockSupport.includesSeconds("yyyy年M月d日 E HH:mm:ss"),
                     "a mixed date and seconds pattern still counts as seconds")
        suite.expect(!MenuBarClockSupport.includesSeconds("yyyy年M月d日 E HH:mm"),
                     "a date pattern without s does not ask for seconds")

        suite.expect(MenuBarClockSupport.refreshInterval(for: "HH:mm:ss") == 1,
                     "seconds refresh every second")
        suite.expect(MenuBarClockSupport.refreshInterval(for: "HH:mm") == 60,
                     "minutes refresh every minute")
        suite.expect(MenuBarClockSupport.refreshInterval(for: "'s' HH:mm") == 60,
                     "a quoted s does not switch to a one-second timer")

        let nextSecond = MenuBarClockSupport.nextFireDate(
            after: date(hour: 10, minute: 30, second: 45, fraction: 0.25),
            interval: 1,
            calendar: calendar)
        suite.expect(abs(seconds(nextSecond, since: date(hour: 10, minute: 30, second: 46))) < 0.001,
                     "a second clock fires on the next whole second")

        let nextMinute = MenuBarClockSupport.nextFireDate(
            after: date(hour: 10, minute: 30, second: 45, fraction: 0.25),
            interval: 60,
            calendar: calendar)
        suite.expect(abs(seconds(nextMinute, since: date(hour: 10, minute: 31, second: 0))) < 0.001,
                     "a minute clock fires on the next minute boundary")

        let exactMinute = MenuBarClockSupport.nextFireDate(
            after: date(hour: 10, minute: 30, second: 0),
            interval: 60,
            calendar: calendar)
        suite.expect(abs(seconds(exactMinute, since: date(hour: 10, minute: 31, second: 0))) < 0.001,
                     "an exact minute waits for the next one instead of firing immediately")

        suite.expect(MenuBarClockSupport.sanitizedFontSize(12) == 12
                     && MenuBarClockSupport.sanitizedFontSize(16) == 16,
                     "the clock font size accepts both ends of its range")
        suite.expect(MenuBarClockSupport.sanitizedFontSize(11) == MenuBarClockSupport.defaultFontSize
                     && MenuBarClockSupport.sanitizedFontSize(17) == MenuBarClockSupport.defaultFontSize
                     && MenuBarClockSupport.sanitizedFontSize(0) == MenuBarClockSupport.defaultFontSize,
                     "a size outside the range, including a missing key, falls back to the system size")

        // One cached formatter must not leak a previous pattern into the next
        // call: the settings field changes the pattern while the app runs.
        _ = MenuBarClockSupport.text(for: date(hour: 10, minute: 30, second: 45),
                                     format: "yyyy-MM-dd",
                                     locale: Locale(identifier: "en_US_POSIX"),
                                     timeZone: utc)
        let afterSwitch = MenuBarClockSupport.text(for: date(hour: 10, minute: 30, second: 45),
                                                   format: "HH:mm",
                                                   locale: Locale(identifier: "en_US_POSIX"),
                                                   timeZone: utc)
        suite.expect(afterSwitch == "10:30",
                     "changing the pattern replaces the cached formatter")
    }
}