import SwiftUI
import UIKit

struct GlobalHistoryPanLayer: UIViewRepresentable {
    let width: CGFloat
    let onChanged: (CGSize, CGPoint, CGFloat) -> Void
    let onEnded: (CGSize, CGPoint, CGFloat) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = InstallerView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let uiView = uiView as? InstallerView else { return }
        uiView.coordinator = context.coordinator
        uiView.installRecognizerIfNeeded()
        context.coordinator.width = width
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(width: width, onChanged: onChanged, onEnded: onEnded)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var width: CGFloat
        var onChanged: (CGSize, CGPoint, CGFloat) -> Void
        var onEnded: (CGSize, CGPoint, CGFloat) -> Void
        private let edgeActivationWidth: CGFloat = 28

        init(
            width: CGFloat,
            onChanged: @escaping (CGSize, CGPoint, CGFloat) -> Void,
            onEnded: @escaping (CGSize, CGPoint, CGFloat) -> Void
        ) {
            self.width = width
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let translation = recognizer.translation(in: view)
            let velocity = recognizer.velocity(in: view)
            let translationSize = CGSize(width: translation.x, height: translation.y)

            switch recognizer.state {
            case .changed:
                onChanged(translationSize, velocity, width)
            case .ended, .cancelled, .failed:
                onEnded(translationSize, velocity, width)
            default:
                break
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
                  let view = gestureRecognizer.view else { return true }

            let location = panGesture.location(in: view)
            let velocity = panGesture.velocity(in: view)
            let isHorizontal = abs(velocity.x) > abs(velocity.y) * 1.2
            guard isHorizontal else { return false }

            if velocity.x > 0 {
                return location.x <= edgeActivationWidth
            }

            return location.x >= max(width - edgeActivationWidth, edgeActivationWidth)
        }
    }

    final class InstallerView: UIView {
        weak var coordinator: Coordinator?
        private weak var installedView: UIView?
        private weak var recognizer: UIPanGestureRecognizer?

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            isUserInteractionEnabled = false
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            installRecognizerIfNeeded()
        }

        func installRecognizerIfNeeded() {
            guard let window, let coordinator else { return }
            if installedView === window { return }

            if let recognizer, let installedView {
                installedView.removeGestureRecognizer(recognizer)
            }

            let recognizer = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
            recognizer.cancelsTouchesInView = false
            recognizer.delaysTouchesBegan = false
            recognizer.delaysTouchesEnded = false
            recognizer.delegate = coordinator
            window.addGestureRecognizer(recognizer)
            self.recognizer = recognizer
            installedView = window
        }

        deinit {
            if let recognizer, let installedView {
                installedView.removeGestureRecognizer(recognizer)
            }
        }
    }
}
