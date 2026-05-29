import Foundation
import UIKit
import UserNotifications

struct BakingNotificationID: Hashable, RawRepresentable {
    let rawValue: String
}

enum BakingNotificationScope {
    case cookTimer

    var identifierPrefix: String {
        switch self {
        case .cookTimer:
            return "cook.timer."
        }
    }
}

enum BakingNotificationScheduleResult {
    case scheduled(BakingNotificationID)
    case permissionDenied
    case failed
}

enum BakingNotificationEvent {
    case cookTimerFinished(
        recipeName: String,
        stepId: UUID,
        stepName: String,
        fireDate: Date
    )

    var id: BakingNotificationID {
        switch self {
        case .cookTimerFinished(_, let stepId, _, _):
            return BakingNotificationID(rawValue: "\(BakingNotificationScope.cookTimer.identifierPrefix)\(stepId.uuidString)")
        }
    }

    var scope: BakingNotificationScope {
        switch self {
        case .cookTimerFinished:
            return .cookTimer
        }
    }

    var title: String {
        switch self {
        case .cookTimerFinished:
            return BakingTerms.cookTimerFinishedNotificationTitle
        }
    }

    var body: String {
        switch self {
        case .cookTimerFinished(_, _, let stepName, _):
            return BakingTerms.cookTimerFinishedNotificationBody(stepName: stepName)
        }
    }

    var fireDate: Date {
        switch self {
        case .cookTimerFinished(_, _, _, let fireDate):
            return fireDate
        }
    }

    var userInfo: [AnyHashable: Any] {
        switch self {
        case .cookTimerFinished(let recipeName, let stepId, let stepName, _):
            return [
                "event": "cookTimerFinished",
                "recipeName": recipeName,
                "stepId": stepId.uuidString,
                "stepName": stepName
            ]
        }
    }
}

@MainActor
protocol BakingNotificationScheduling: AnyObject {
    func schedule(_ event: BakingNotificationEvent) async -> BakingNotificationScheduleResult
    func cancel(_ id: BakingNotificationID) async
    func cancel(scope: BakingNotificationScope) async
    func openNotificationSettings()
}

final class BakingNotificationService: NSObject, ObservableObject, BakingNotificationScheduling, UNUserNotificationCenterDelegate {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
        center.delegate = self
    }

    @MainActor
    func schedule(_ event: BakingNotificationEvent) async -> BakingNotificationScheduleResult {
        let status = await center.notificationSettings().authorizationStatus

        switch status {
        case .authorized, .provisional, .ephemeral:
            return await addNotificationRequest(for: event)
        case .notDetermined:
            do {
                let isGranted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                guard isGranted else { return .permissionDenied }
                return await addNotificationRequest(for: event)
            } catch {
                return .failed
            }
        case .denied:
            openNotificationSettings()
            return .permissionDenied
        @unknown default:
            return .permissionDenied
        }
    }

    @MainActor
    func cancel(_ id: BakingNotificationID) async {
        center.removePendingNotificationRequests(withIdentifiers: [id.rawValue])
        center.removeDeliveredNotifications(withIdentifiers: [id.rawValue])
    }

    @MainActor
    func cancel(scope: BakingNotificationScope) async {
        let prefix = scope.identifierPrefix
        let pendingIdentifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: pendingIdentifiers)

        let deliveredIdentifiers = await center.deliveredNotifications()
            .map(\.request.identifier)
            .filter { $0.hasPrefix(prefix) }
        center.removeDeliveredNotifications(withIdentifiers: deliveredIdentifiers)
    }

    @MainActor
    func openNotificationSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }

        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    @MainActor
    private func addNotificationRequest(for event: BakingNotificationEvent) async -> BakingNotificationScheduleResult {
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.body
        content.sound = .default
        content.userInfo = event.userInfo

        let interval = max(1, event.fireDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: event.id.rawValue, content: content, trigger: trigger)

        do {
            try await center.add(request)
            return .scheduled(event.id)
        } catch {
            return .failed
        }
    }
}
