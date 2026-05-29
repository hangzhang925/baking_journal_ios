import Combine
import UIKit

func dismissActiveKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

final class BakingKeyboardState: ObservableObject {
    @Published private(set) var height: CGFloat = 0
    @Published private(set) var animationDuration: Double = 0.25

    private var cancellables: Set<AnyCancellable> = []

    init() {
        let center = NotificationCenter.default

        center.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .merge(with: center.publisher(for: UIResponder.keyboardWillShowNotification))
            .sink { [weak self] notification in
                self?.update(from: notification)
            }
            .store(in: &cancellables)

        center.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] notification in
                self?.animationDuration = notification.keyboardAnimationDuration
                self?.height = 0
            }
            .store(in: &cancellables)
    }

    private func update(from notification: Notification) {
        animationDuration = notification.keyboardAnimationDuration

        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let screenHeight = UIScreen.main.bounds.height
        height = max(0, screenHeight - frame.minY)
    }
}

private extension Notification {
    var keyboardAnimationDuration: Double {
        userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
    }
}
