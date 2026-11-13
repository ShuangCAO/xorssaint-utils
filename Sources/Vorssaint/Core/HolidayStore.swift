// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Chinese statutory holidays and adjusted workdays, from the State Council
/// notices collected by the holiday-cn project. The bundled JSON is updated
/// once a year when the next notice is published; until then, years outside
/// its range report as uncovered instead of silently showing no holidays.
final class HolidayStore {
    enum HolidayInfo: Hashable {
        case offDay(name: String)
        case workday(name: String)
    }

    private struct Payload: Decodable {
        let years: [YearEntry]
    }

    private struct YearEntry: Decodable {
        let year: Int
        let days: [Day]
    }

    private struct Day: Decodable {
        let name: String
        let date: String
        let isOffDay: Bool
    }

    private let offDayNames: [String: String]
    private let workdayNames: [String: String]
    /// The years the bundled data covers; a month outside it is the signal
    /// that the file needs updating.
    let minYear: Int?
    let maxYear: Int?

    init(jsonData: Data) throws {
        let payload = try JSONDecoder().decode(Payload.self, from: jsonData)
        var off: [String: String] = [:]
        var work: [String: String] = [:]
        for entry in payload.years {
            for day in entry.days {
                if day.isOffDay {
                    off[day.date] = day.name
                } else {
                    work[day.date] = day.name
                }
            }
        }
        offDayNames = off
        workdayNames = work
        minYear = payload.years.map(\.year).min()
        maxYear = payload.years.map(\.year).max()
    }

    /// Built from the bundled resource. A missing or malformed file leaves
    /// the calendar without holiday data rather than failing to open.
    static let shared: HolidayStore? = {
        guard let url = Bundle.main.url(forResource: "holidays-cn", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? HolidayStore(jsonData: data)
    }()

    func info(forDayKey key: String) -> HolidayInfo? {
        if let name = offDayNames[key] { return .offDay(name: name) }
        if let name = workdayNames[key] { return .workday(name: name) }
        return nil
    }

    func isYearOutOfCoverage(_ year: Int) -> Bool {
        guard let minYear, let maxYear else { return false }
        return year < minYear || year > maxYear
    }

    /// The local calendar-day key the bundled data uses, `yyyy-MM-dd`.
    static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d",
                      components.year ?? 0,
                      components.month ?? 0,
                      components.day ?? 0)
    }
}