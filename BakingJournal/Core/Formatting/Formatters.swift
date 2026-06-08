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
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func weight(_ grams: Double, gramPrecision: Int = 0) -> String {
        let parts = weightParts(grams, gramPrecision: gramPrecision)
        return "\(parts.value) \(parts.unit)"
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
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    static func starterTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd h:mma"
        return formatter.string(from: date)
    }

    static func starterDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
