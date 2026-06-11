import Foundation

struct BakingFormattedUnitValue {
    let value: String
    let unit: String
}

enum BakingFormat {
    static func number(_ value: Double, precision: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = precision
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.locale = L10n.locale
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func weight(_ grams: Double, gramPrecision: Int = 0) -> String {
        let parts = weightParts(grams, gramPrecision: gramPrecision)
        return "\(parts.value) \(parts.unit)"
    }

    static func compactWeight(_ grams: Double, gramPrecision: Int = 0) -> String {
        let parts = weightParts(grams, gramPrecision: gramPrecision)
        return "\(parts.value)\(parts.unit)"
    }

    static func weightParts(_ grams: Double, gramPrecision: Int = 0) -> BakingFormattedUnitValue {
        if grams >= 1000 {
            return BakingFormattedUnitValue(value: number(grams / 1000, precision: 3), unit: "kg")
        }
        return BakingFormattedUnitValue(value: number(grams, precision: gramPrecision), unit: "g")
    }

    static func duration(minutes: Double) -> String {
        guard minutes > 0 else { return "0 min" }
        let rounded = Int(minutes.rounded())
        let hours = rounded / 60
        let rest = rounded % 60
        if hours == 0 { return "\(rest) min" }
        if rest == 0 { return "\(hours) hr" }
        return "\(hours) hr \(rest) min"
    }

    static func clockTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = L10n.locale
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    static func bakeRecordDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = L10n.locale
        formatter.dateFormat = "yyyy-MM-dd H:mm"
        return formatter.string(from: date)
    }

    static func bakeRecordClockTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = L10n.locale
        formatter.dateFormat = "H:mm"
        return formatter.string(from: date)
    }

    static func starterTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = L10n.locale
        formatter.dateFormat = "yyyy-MM-dd h:mma"
        return formatter.string(from: date)
    }

    static func starterDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = L10n.locale
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func daysSince(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> Int {
        let dateStart = calendar.startOfDay(for: date)
        let todayStart = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: dateStart, to: todayStart).day ?? 0
        return max(0, days)
    }

    static func relativeDaysAgo(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        let days = daysSince(date, now: now, calendar: calendar)

        if days <= 0 {
            return BakingTerms.relativeToday
        }
        if days == 1 {
            return BakingTerms.relativeYesterday
        }
        return BakingTerms.relativeDaysAgo(days)
    }
}
