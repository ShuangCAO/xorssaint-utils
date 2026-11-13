// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Chinese lunar dates for the calendar's hover text. Pure Foundation, so
/// the test harness can pin the month and day names without a view.
enum LunarDateSupport {
    static func text(for date: Date,
                     locale: Locale,
                     timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .chinese)
        calendar.locale = locale
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.month, .day, .isLeapMonth], from: date)
        guard let month = components.month,
              let day = components.day,
              month >= 1, month <= calendar.monthSymbols.count,
              day >= 1, day <= 30
        else { return "" }
        let leap = components.isLeapMonth == true ? leapPrefix(for: locale) : ""
        return "\(leap)\(calendar.monthSymbols[month - 1])\(dayName(day))"
    }

    /// 初一 … 初十, 十一 … 十九, 二十, 廿一 … 廿九, 三十.
    static func dayName(_ day: Int) -> String {
        switch day {
        case 1...10: return "初" + numerals[day - 1]
        case 11...19: return "十" + numerals[day - 11]
        case 20: return "二十"
        case 21...29: return "廿" + numerals[day - 21]
        case 30: return "三十"
        default: return ""
        }
    }

    private static let numerals = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

    private static func leapPrefix(for locale: Locale) -> String {
        // Locale normalizes zh_Hant_TW to zh_TW, so the script cannot be
        // read from "Hant" alone; the region identifies it as well.
        let identifier = locale.identifier.lowercased()
        let traditional = identifier.contains("hant")
            || identifier.contains("tw")
            || identifier.contains("hk")
        return traditional ? "閏" : "闰"
    }
}