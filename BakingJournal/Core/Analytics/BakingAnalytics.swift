import FirebaseAnalytics
import Foundation

enum BakingAnalytics {
    enum Event {
        static let navTabClick = "nav_tab_click"
    }

    enum Parameter {
        static let tabName = "tab_name"
    }

    static func logNavTabClick(tabName: String) {
        AppLogger.debug(
            "\(Event.navTabClick) \(Parameter.tabName)=\(tabName)",
            category: "Analytics"
        )
        Analytics.logEvent(Event.navTabClick, parameters: [
            Parameter.tabName: tabName
        ])
    }
}
