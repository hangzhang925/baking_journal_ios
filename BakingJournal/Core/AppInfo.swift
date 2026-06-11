import Foundation

struct AppInfo {
    static let current = AppInfo(bundle: .main)

    let bundleIdentifier: String?
    let version: String?
    let buildNumber: String?

    init(bundle: Bundle) {
        bundleIdentifier = bundle.bundleIdentifier
        version = Self.nonEmptyInfoValue("CFBundleShortVersionString", in: bundle)
        buildNumber = Self.nonEmptyInfoValue("CFBundleVersion", in: bundle)
    }

    func displayVersion(fallback: String) -> String {
        switch (version, buildNumber) {
        case let (.some(version), .some(buildNumber)) where version != buildNumber:
            return "\(version) (\(buildNumber))"
        case let (.some(version), _):
            return version
        case let (_, .some(buildNumber)):
            return buildNumber
        default:
            return fallback
        }
    }

    private static func nonEmptyInfoValue(_ key: String, in bundle: Bundle) -> String? {
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
