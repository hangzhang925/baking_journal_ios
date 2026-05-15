import Foundation

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
        if grams >= 1000 {
            return "\(number(grams / 1000, precision: 3)) kg"
        }
        return "\(number(grams, precision: gramPrecision)) g"
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
}
