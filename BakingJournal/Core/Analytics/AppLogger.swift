import FirebaseCrashlytics
import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = "com.openbakery.bready"

    static func configureCrashContext(appInfo: AppInfo = .current) {
        let crashlytics = Crashlytics.crashlytics()

        if let bundleIdentifier = appInfo.bundleIdentifier {
            crashlytics.setCustomValue(bundleIdentifier, forKey: "bundle_id")
        }

        if let version = appInfo.version {
            crashlytics.setCustomValue(version, forKey: "app_version")
        }

        if let buildNumber = appInfo.buildNumber {
            crashlytics.setCustomValue(buildNumber, forKey: "build_number")
        }
    }

    static func debug(_ message: @autoclosure () -> String, category: String = "App") {
#if DEBUG
        let text = message()
        localLogger(category: category).debug("\(text, privacy: .public)")
#endif
    }

    static func breadcrumb(
        _ message: String,
        category: String = "App",
        metadata: [String: String] = [:]
    ) {
#if DEBUG
        localLogger(category: category).info("\(formattedMessage(message, category: category, metadata: metadata), privacy: .public)")
#endif
        Crashlytics.crashlytics().log(formattedMessage(message, category: category, metadata: metadata))
    }

    static func error(
        _ error: Error,
        context: String,
        category: String = "App",
        metadata: [String: String] = [:]
    ) {
        let message = formattedMessage(context, category: category, metadata: metadata)
#if DEBUG
        localLogger(category: category).error("\(message, privacy: .public) error=\(String(describing: error), privacy: .public)")
#endif
        let crashlytics = Crashlytics.crashlytics()
        crashlytics.log(message)
        metadata.forEach { entry in
            crashlytics.setCustomValue(entry.value, forKey: entry.key)
        }
        crashlytics.record(error: error)
    }

    static func setCrashValue(_ value: String, forKey key: String) {
#if DEBUG
        localLogger(category: "Crashlytics").debug("custom_value \(key, privacy: .public)=\(value, privacy: .public)")
#endif
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }

    private static func localLogger(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }

    private static func formattedMessage(
        _ message: String,
        category: String,
        metadata: [String: String]
    ) -> String {
        guard !metadata.isEmpty else {
            return "[\(category)] \(message)"
        }

        let pairs = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")

        return "[\(category)] \(message) \(pairs)"
    }
}
