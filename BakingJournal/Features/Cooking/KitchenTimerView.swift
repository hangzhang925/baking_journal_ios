import AlarmKit
import Foundation
import SwiftUI
import UIKit

struct KitchenTimerView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @StateObject private var viewModel = KitchenTimerViewModel()
    @State private var hours = 0
    @State private var minutes = 10
    @State private var seconds = 0

    var body: some View {
        VStack(spacing: 0) {
            BakingTopActionRow(leading: {
                if navigationController.canGoBack {
                    BakingIconButton(
                        icon: .back,
                        accessibilityLabel: BakingTerms.back
                    ) {
                        navigationController.goBack()
                    }
                }
            })

            Form {
                Section {
                    VStack(spacing: BakingSpace.lg) {
                        Text(viewModel.displayText)
                            .font(.system(size: 58, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.brandText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                            .frame(maxWidth: .infinity)
                            .contentTransition(.numericText())

                        Text(viewModel.statusText)
                            .font(BakingTypography.appPrimaryText)
                            .foregroundStyle(viewModel.statusColor)
                            .multilineTextAlignment(.center)

                        if viewModel.isIdle {
                            durationPicker
                        }

                        controls
                    }
                    .padding(.vertical, BakingSpace.md)
                }
                .listRowBackground(BakingSurface.rowBackground)
            }
            .scrollContentBackground(.hidden)
        }
        .background(Color.brandBackground)
        .navigationBarBackButtonHidden(true)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            viewModel.tick(date)
        }
        .task {
            viewModel.observeAlarmUpdates()
        }
    }

    private var duration: TimeInterval {
        TimeInterval((hours * 60 * 60) + (minutes * 60) + seconds)
    }

    private var canStart: Bool {
        duration > 0 && !viewModel.isScheduling
    }

    private var durationPicker: some View {
        HStack(spacing: 0) {
            wheelPicker(value: $hours, range: 0...23, label: BakingTerms.kitchenTimerHours)
            wheelPicker(value: $minutes, range: 0...59, label: BakingTerms.kitchenTimerMinutes)
            wheelPicker(value: $seconds, range: 0...59, label: BakingTerms.kitchenTimerSeconds)
        }
        .frame(height: 156)
    }

    private func wheelPicker(value: Binding<Int>, range: ClosedRange<Int>, label: String) -> some View {
        Picker(label, selection: value) {
            ForEach(Array(range), id: \.self) { option in
                Text(option.formatted(.number.precision(.integerLength(2))))
                    .tag(option)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
        .accessibilityLabel(label)
    }

    private var controls: some View {
        HStack(spacing: BakingSpace.lg) {
            if viewModel.isIdle || viewModel.isFinished || viewModel.isPermissionDenied || viewModel.isError {
                Button {
                    viewModel.start(duration: duration)
                } label: {
                    BakingSystemIconButtonLabel(
                        systemImage: "play.fill",
                        tint: canStart ? .brandPrimary : .brandSecondaryText
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canStart)
                .accessibilityLabel(BakingTerms.kitchenTimerStartAccessibility)
            }

            if viewModel.isRunning {
                Button {
                    viewModel.pause()
                } label: {
                    BakingSystemIconButtonLabel(systemImage: "pause.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.kitchenTimerPauseAccessibility)
            }

            if viewModel.isPaused {
                Button {
                    viewModel.resume()
                } label: {
                    BakingSystemIconButtonLabel(systemImage: "play.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.kitchenTimerResumeAccessibility)
            }

            if viewModel.canStop {
                Button {
                    viewModel.stop()
                } label: {
                    BakingSystemIconButtonLabel(systemImage: "stop.fill", tint: .brandText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.kitchenTimerStopAccessibility)
            }
        }
        .frame(minHeight: BakingTouchTarget.iconButton)
    }
}

private struct KitchenTimerAlarmMetadata: AlarmMetadata {
    let createdAt: Date
}

@MainActor
private final class KitchenTimerViewModel: ObservableObject {
    enum State {
        case idle
        case scheduling
        case running
        case paused
        case finished
        case permissionDenied
        case error
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var remaining: TimeInterval = 10 * 60

    private let manager = AlarmManager.shared
    private var activeAlarmID: Alarm.ID?
    private var endsAt: Date?
    private var totalDuration: TimeInterval = 10 * 60
    private var pausedRemaining: TimeInterval?
    private var updatesTask: Task<Void, Never>?

    var isIdle: Bool { state == .idle }
    var isScheduling: Bool { state == .scheduling }
    var isRunning: Bool { state == .running }
    var isPaused: Bool { state == .paused }
    var isFinished: Bool { state == .finished }
    var isPermissionDenied: Bool { state == .permissionDenied }
    var isError: Bool { state == .error }
    var canStop: Bool { isRunning || isPaused || isFinished }

    var displayText: String {
        Self.format(remaining)
    }

    var statusText: String {
        switch state {
        case .idle:
            BakingTerms.kitchenTimerIdleStatus
        case .scheduling:
            BakingTerms.kitchenTimerRunningStatus
        case .running:
            BakingTerms.kitchenTimerRunningStatus
        case .paused:
            BakingTerms.kitchenTimerPausedStatus
        case .finished:
            BakingTerms.kitchenTimerFinishedStatus
        case .permissionDenied:
            BakingTerms.kitchenTimerPermissionDeniedStatus
        case .error:
            BakingTerms.kitchenTimerErrorStatus
        }
    }

    var statusColor: Color {
        switch state {
        case .finished:
            .brandSage
        case .permissionDenied, .error:
            .brandPrimary
        default:
            .brandSecondaryText
        }
    }

    func start(duration: TimeInterval) {
        guard duration > 0 else { return }

        Task { [weak self] in
            await self?.schedule(duration: duration)
        }
    }

    func pause() {
        guard let activeAlarmID, isRunning else { return }

        do {
            pausedRemaining = remaining
            try manager.pause(id: activeAlarmID)
            state = .paused
        } catch {
            state = .error
        }
    }

    func resume() {
        guard let activeAlarmID, isPaused else { return }

        do {
            try manager.resume(id: activeAlarmID)
            let resumedRemaining = pausedRemaining ?? remaining
            endsAt = Date().addingTimeInterval(resumedRemaining)
            pausedRemaining = nil
            state = .running
        } catch {
            state = .error
        }
    }

    func stop() {
        guard let activeAlarmID else {
            reset()
            return
        }

        do {
            try manager.cancel(id: activeAlarmID)
            reset()
        } catch {
            state = .error
        }
    }

    func tick(_ date: Date) {
        guard isRunning, let endsAt else { return }
        remaining = max(0, endsAt.timeIntervalSince(date))
        if remaining <= 0 {
            state = .finished
        }
    }

    func observeAlarmUpdates() {
        guard updatesTask == nil else { return }

        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await alarms in manager.alarmUpdates {
                self.applyAlarmUpdates(alarms)
            }
        }
    }

    private func schedule(duration: TimeInterval) async {
        state = .scheduling
        remaining = duration
        totalDuration = duration

        do {
            let authorization = try await manager.requestAuthorization()
            guard authorization == .authorized else {
                state = .permissionDenied
                openSettings()
                return
            }

            if let activeAlarmID {
                try? manager.cancel(id: activeAlarmID)
            }

            let id = UUID()
            let alarm = try await manager.schedule(
                id: id,
                configuration: alarmConfiguration(duration: duration)
            )
            activeAlarmID = alarm.id
            endsAt = Date().addingTimeInterval(duration)
            pausedRemaining = nil
            state = alarm.state == .paused ? .paused : .running
        } catch {
            state = .error
        }
    }

    private func applyAlarmUpdates(_ alarms: [Alarm]) {
        guard let activeAlarmID else { return }

        guard let alarm = alarms.first(where: { $0.id == activeAlarmID }) else {
            if isFinished {
                return
            }
            reset()
            return
        }

        switch alarm.state {
        case .scheduled, .countdown:
            if !isRunning {
                state = .running
            }
        case .paused:
            state = .paused
            pausedRemaining = remaining
        case .alerting:
            remaining = 0
            state = .finished
        @unknown default:
            state = .error
        }
    }

    private func reset() {
        activeAlarmID = nil
        endsAt = nil
        pausedRemaining = nil
        remaining = totalDuration
        state = .idle
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func alarmConfiguration(duration: TimeInterval) -> AlarmManager.AlarmConfiguration<KitchenTimerAlarmMetadata> {
        let stopButton = AlarmButton(
            text: LocalizedStringResource("common.stop", defaultValue: "Stop"),
            textColor: .brandPrimary,
            systemImageName: "stop.fill"
        )
        let alert = AlarmPresentation.Alert(
            title: LocalizedStringResource("kitchen_timer.alarm.title", defaultValue: "Timer finished"),
            stopButton: stopButton
        )
        let presentation = AlarmPresentation(alert: alert)
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: KitchenTimerAlarmMetadata(createdAt: Date()),
            tintColor: .brandPrimary
        )

        return AlarmManager.AlarmConfiguration.timer(
            duration: duration,
            attributes: attributes
        )
    }

    private static func format(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded(.up)))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
