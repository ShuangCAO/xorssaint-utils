// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// The menu bar clock: a date/time string drawn in place of the idle glyph.
///
/// Pure Foundation, so the test harness can pin the formatting and the tick
/// schedule without a status item. The caller drives it from the main thread.
enum MenuBarClockSupport {
    /// The tinyCal default: a Chinese date with a seconds readout. A custom
    /// pattern is stored in defaults; this is only the fallback.
    static let defaultFormat = "y年M月dd日 E HH:mm:ss"

    /// tinyCal formats in Simplified Chinese regardless of the app language,
    /// so its weekday and month names read the same on every Mac. A custom
    /// pattern still gets the same locale; only the pattern is user-editable.
    static let locale = Locale(identifier: "zh_Hans_CN")

    /// Longer patterns have no room in the menu bar and are more likely to be
    /// a paste accident than an intended format.
    static let maximumFormatLength = 60

    /// A single-line pattern, or the default when nothing usable was typed.
    static func sanitizedFormat(_ rawValue: String?) -> String {
        let trimmed = (rawValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return defaultFormat }
        let singleLine = trimmed
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        return String(singleLine.prefix(maximumFormatLength))
    }

    /// Whether the pattern renders seconds, so the status item has to tick
    /// once a second instead of once a minute. Text inside single quotes is a
    /// literal: `'s'` is the letter, not a seconds field. `S` (fractional
    /// seconds) is a different unit and does not count.
    static func includesSeconds(_ format: String) -> Bool {
        var isQuoted = false
        var index = format.startIndex
        while index < format.endIndex {
            let character = format[index]
            if character == "'" {
                let next = format.index(after: index)
                if next < format.endIndex, format[next] == "'" {
                    // '' is a literal apostrophe, not a quote boundary.
                    index = format.index(after: next)
                    continue
                }
                isQuoted.toggle()
            } else if character == "s", !isQuoted {
                return true
            }
            index = format.index(after: index)
        }
        return false
    }

    /// How often the title has to be rebuilt: seconds make a one-second
    /// clock, everything else a minute clock.
    static func refreshInterval(for format: String) -> TimeInterval {
        includesSeconds(sanitizedFormat(format)) ? 1 : 60
    }

    /// The first tick, aligned to the next whole second or minute so the
    /// clock never drifts and a minute clock changes exactly on the minute.
    static func nextFireDate(after date: Date,
                             interval: TimeInterval,
                             calendar: Calendar = .current) -> Date {
        guard interval >= 1 else { return date.addingTimeInterval(1) }
        let components = calendar.dateComponents([.second, .nanosecond], from: date)
        let second = Double(components.second ?? 0)
        let fraction = Double(components.nanosecond ?? 0) / 1_000_000_000
        if interval < 60 {
            return date.addingTimeInterval(1 - fraction)
        }
        let elapsed = second.truncatingRemainder(dividingBy: interval) + fraction
        return date.addingTimeInterval(interval - elapsed)
    }

    /// The formatted clock. One formatter is kept per pattern/locale/zone,
    /// because rebuilding a DateFormatter on every tick is needlessly costly.
    static func text(for date: Date,
                     format: String,
                     locale: Locale = MenuBarClockSupport.locale,
                     timeZone: TimeZone = .current) -> String {
        let resolved = sanitizedFormat(format)
        let key = "\(resolved)|\(locale.identifier)|\(timeZone.identifier)"
        if key != cachedFormatterKey {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.timeZone = timeZone
            formatter.dateFormat = resolved
            cachedFormatter = formatter
            cachedFormatterKey = key
        }
        let rendered = cachedFormatter?.string(from: date) ?? ""
        // A malformed pattern can render nothing. The status item would then
        // have neither text nor icon, so fall back to the known-good default.
        guard rendered.isEmpty, resolved != defaultFormat else { return rendered }
        return text(for: date, format: defaultFormat, locale: locale, timeZone: timeZone)
    }

    private static var cachedFormatter: DateFormatter?
    private static var cachedFormatterKey = ""
}