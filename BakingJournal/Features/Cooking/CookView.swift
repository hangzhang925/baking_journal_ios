import SwiftUI

struct CookView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    @State private var now = Date()
    @State private var showingActions = false
    @State private var showingCompletionToast = false
    @State private var completionFeedbackTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            header

            Group {
                if store.steps.isEmpty {
                    EmptyStateView(title: BakingTerms.cookEmptyNeedsSteps, systemImage: "play.circle")
                        .background(Color.brandBackground)
                } else if !store.isReadyToBake {
                    EmptyStateView(title: BakingTerms.cookEmptyNotReady, systemImage: "exclamationmark.circle")
                        .background(Color.brandBackground)
                } else if store.cookState.completedAt != nil {
                    CookSummaryView()
                } else {
                    CookStepView(now: now) {
                        showCompletionToast()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(Color.brandBackground)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
        .onAppear {
            store.beginCookIfNeeded()
        }
        .overlay(alignment: .center) {
            if showingCompletionToast {
                BakingTransientStatusToast(title: BakingTerms.cookCompletedStatus)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.96).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
        }
        .onDisappear {
            completionFeedbackTask?.cancel()
        }
    }

    private var header: some View {
        BakingTopActionRow(
            leading: {
                if navigationController.canGoBack {
                    BakingIconButton(
                        icon: .back,
                        accessibilityLabel: BakingTerms.back
                    ) {
                        navigationController.goBack()
                    }
                }
            },
            trailing: {
                if !store.steps.isEmpty {
                    Button {
                        showingActions = true
                    } label: {
                        BakingTopSystemIconButtonLabel(systemImage: "ellipsis", tint: .brandText)
                    }
                    .buttonStyle(BakingPressFeedbackButtonStyle())
                    .accessibilityLabel(BakingTerms.moreActions)
                    .popover(isPresented: $showingActions, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                        BakingDropdownPopover(width: 164) {
                            if store.cookState.completedAt == nil {
                                Button {
                                    showingActions = false
                                    store.completeBake()
                                } label: {
                                    BakingDropdownRow(title: BakingTerms.cookFinish, foreground: .brandText) {
                                        BakingIconView(
                                            icon: .complete,
                                            size: BakingTouchTarget.dropdownIconGlyph,
                                            color: .brandPrimary
                                        )
                                    }
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                showingActions = false
                                store.resetCook()
                            } label: {
                                BakingDropdownRow(title: BakingTerms.reset, foreground: .brandText) {
                                    BakingIconView(
                                        icon: .delete,
                                        size: BakingTouchTarget.dropdownIconGlyph,
                                        color: .brandText
                                    )
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        )
    }

    private func showCompletionToast() {
        completionFeedbackTask?.cancel()

        withAnimation(BakingMotion.quick) {
            showingCompletionToast = true
        }

        completionFeedbackTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.28)) {
                showingCompletionToast = false
            }
        }
    }
}

private struct CookStepView: View {
    @EnvironmentObject private var store: RecipeStore
    let now: Date
    let onStepCompleted: () -> Void
    @State private var showingRecipePreview = false
    @State private var stepSelection = 0

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: BakingSpace.sm) {
                recipeHeader
            }
            .padding(.horizontal, BakingLayout.screenHorizontalInset)
            .padding(.top, BakingLayout.contentTopInset)

            TabView(selection: $stepSelection) {
                ForEach(Array(store.steps.enumerated()), id: \.element.id) { index, step in
                    ScrollView {
                        VStack(alignment: .leading, spacing: BakingSpace.sm) {
                            CookStepHeaderCard(
                                step: step,
                                stepIndex: index,
                                totalSteps: store.steps.count,
                                isCurrent: index == store.cookState.currentIndex
                            )

                            CookTimerCard(
                                step: step,
                                now: now,
                                isCurrent: index == store.cookState.currentIndex
                            )

                            CookInstructionCard(instruction: stepInstructionText(step))
                        }
                        .padding(.horizontal, BakingLayout.screenHorizontalInset)
                        .padding(.top, BakingSpace.xs)
                        .padding(.bottom, BakingSpace.xxl)
                    }
                    .scrollIndicators(.hidden)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.brandBackground)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomStepStatus
                .padding(.bottom, CookBottomActionMetrics.tabBarClearance)
                .background(BakingSurface.bottomBarBackground)
        }
        .onAppear {
            stepSelection = store.cookState.currentIndex
        }
        .onChange(of: store.cookState.currentIndex) { _, newValue in
            if stepSelection != newValue {
                withAnimation(BakingMotion.standard) {
                    stepSelection = newValue
                }
            }
        }
        .accessibilityAction(named: BakingTerms.cookPreviousStep) {
            store.moveCookStep(-1)
        }
        .accessibilityAction(named: BakingTerms.cookNextStep) {
            store.moveCookStep(1)
        }
        .sheet(isPresented: $showingRecipePreview) {
            RecipePreviewView(toolbarMode: .referenceSheet)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var recipeHeader: some View {
        HStack(alignment: .center, spacing: BakingSpace.sm) {
            CookRecipeNameButton(recipeName: store.currentRecipeDisplayName) {
                showingRecipePreview = true
            }
            .layoutPriority(1)

            Spacer(minLength: BakingSpace.sm)

            if !isSelectedCurrentStep {
                CookReturnToCurrentStepButton(
                    action: returnToCurrentStep
                )
            }
        }
        .padding(.vertical, BakingSpace.xs)
    }

    @ViewBuilder
    private var bottomStepStatus: some View {
        if let step = selectedStep, isSelectedCurrentStep, !store.isCookStepCompleted(step) {
            BakingBottomActionButton(
                title: stepCompletionTitle(for: stepSelection),
                accessibilityLabel: stepCompletionTitle(for: stepSelection)
            ) {
                completeStep(at: stepSelection)
            }
        }
    }

    private var selectedStep: JournalStep? {
        guard store.steps.indices.contains(stepSelection) else { return nil }
        return store.steps[stepSelection]
    }

    private var isSelectedCurrentStep: Bool {
        stepSelection == store.cookState.currentIndex
    }

    private func stepCompletionTitle(for index: Int) -> String {
        index >= store.steps.count - 1 ? BakingTerms.cookFinishBake : BakingTerms.cookCompleteStep
    }

    private func completeStep(at index: Int) {
        if store.completeCookStep(at: index) {
            onStepCompleted()
        }
    }

    private func returnToCurrentStep() {
        let currentIndex = store.cookState.currentIndex
        guard store.steps.indices.contains(currentIndex) else { return }
        withAnimation(BakingMotion.standard) {
            stepSelection = currentIndex
        }
    }

    private func stepInstructionText(_ step: JournalStep) -> String {
        let trimmed = step.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? BakingTerms.cookDefaultStepNote : step.notes
    }
}

private enum CookBottomActionMetrics {
    static let tabBarClearance = BakingComponentMetrics.tabItemHeight + BakingSpace.xxs * 2
}

private struct CookRecipeNameButton: View {
    let recipeName: String
    let action: () -> Void

    var body: some View {
        BakingInlineActionButton(
            title: recipeName,
            accessibilityLabel: BakingTerms.cookOpenRecipePreview,
            role: .secondary,
            action: action
        )
        .accessibilityValue(recipeName)
    }
}

private struct CookReturnToCurrentStepButton: View {
    let action: () -> Void

    var body: some View {
        BakingInlineActionButton(
            title: BakingTerms.cookReturnToCurrentStep,
            accessibilityLabel: BakingTerms.cookReturnToCurrentStep,
            role: .secondary,
            action: action
        )
    }
}

private struct CookCurrentStageBadge: View {
    var body: some View {
        BakingLabel(text: BakingTerms.cookCurrentStage, role: .helperText)
            .contentTransition(.opacity)
    }
}

private struct CookStepHeaderCard: View {
    let step: JournalStep
    let stepIndex: Int
    let totalSteps: Int
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .top, spacing: BakingSpace.md) {
            VStack(alignment: .leading, spacing: BakingSpace.xs) {
                Text(progressText)
                    .bakingLabelStyle(.tableHeader)
                    .contentTransition(.opacity)

                Text(step.name)
                    .font(BakingTypography.tableNumber)
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: BakingSpace.sm)

            if isCurrent {
                CookCurrentStageBadge()
            }
        }
        .padding(BakingTableTheme.rowPadding)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .bakingSurface(.card)
        .animation(BakingMotion.standard, value: isCurrent)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(progressText)
        .accessibilityValue(step.name)
        .accessibilityAddTraits(isCurrent ? [.isSelected] : [])
    }

    private var progressText: String {
        return BakingTerms.cookStepProgress(stepIndex: stepIndex + 1, totalSteps: totalSteps)
    }
}

private struct CookTimerCard: View {
    @EnvironmentObject private var store: RecipeStore
    let step: JournalStep
    let now: Date
    let isCurrent: Bool
    @State private var reminderTime = Date()
    @State private var reminderStepID: UUID?
    @State private var hasEditedReminderTime = false

    var body: some View {
        VStack(alignment: .leading, spacing: BakingSpace.sm) {
            timingMetricStrip

            if shouldShowFoldControls {
                foldReminderCard
                foldRecordsCard
            } else if shouldShowReminder {
                reminderCard
            }
        }
        .onAppear {
            syncReminderTime(force: true)
        }
        .onChange(of: step.id) { _, _ in
            syncReminderTime(force: true)
        }
        .onChange(of: defaultReminderTime) { _, _ in
            syncReminderTime(force: false)
        }
        .onChange(of: scheduledReminderTime) { _, _ in
            syncReminderTime(force: false)
        }
    }

    private var timingMetricStrip: some View {
        HStack(spacing: 0) {
            CookStepMetricCell(
                title: BakingTerms.recipePreviewEstimatedDuration,
                value: durationText
            )

            metricDivider

            CookStepMetricCell(
                title: BakingTerms.cookStartAt,
                value: startTimeText
            )

            metricDivider

            CookStepMetricCell(
                title: BakingTerms.cookFinishAt,
                value: completionTimeText
            )

            if let temperatureText {
                metricDivider

                CookStepMetricCell(
                    title: BakingTerms.stepsFieldTemperature,
                    value: temperatureText
                )
            }
        }
        .padding(.horizontal, BakingComponentMetrics.metricStripHorizontalPadding)
        .padding(.vertical, BakingComponentMetrics.metricStripVerticalPadding)
        .bakingCard()
    }

    private var reminderCard: some View {
        BakingSectionCard(title: BakingTerms.cookReminderSection, headerBottomPadding: 0) {
            VStack(spacing: 0) {
                BakingToggleRow(
                    title: BakingTerms.cookReminderSection,
                    isOn: reminderEnabledBinding
                )

                if isReminderEnabled {
                    BakingTableDivider()

                    BakingFormRow(title: BakingTerms.cookReminderTime) {
                        DatePicker(
                            BakingTerms.cookReminderTime,
                            selection: reminderTimeBinding,
                            displayedComponents: [.hourAndMinute]
                        )
                        .labelsHidden()
                        .tint(.brandPrimary)
                        .accessibilityLabel(BakingTerms.cookReminderTime)
                    }
                }
            }
        }
    }

    private var foldReminderCard: some View {
        BakingSectionCard(title: BakingTerms.cookFoldReminderSection, headerBottomPadding: 0) {
            VStack(spacing: 0) {
                BakingToggleRow(
                    title: BakingTerms.cookFoldReminderToggle,
                    isOn: foldReminderEnabledBinding
                )

                if isFoldReminderEnabled {
                    BakingTableDivider()

                    BakingFormRow(title: BakingTerms.cookFoldFrequency) {
                        Text(foldFrequencyText)
                            .font(BakingTypography.tableNumber)
                            .foregroundStyle(Color.brandText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }

                    BakingTableDivider()

                    BakingFormRow(title: BakingTerms.cookFoldNextTime) {
                        Text(foldNextTimeText)
                            .font(BakingTypography.tableNumber)
                            .foregroundStyle(Color.brandText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                }
            }
        }
    }

    private var foldRecordsCard: some View {
        BakingSectionCard(
            title: BakingTerms.cookFoldRecordsSection,
            detail: foldProgressText,
            headerBottomPadding: BakingSpace.xs
        ) {
            VStack(alignment: .leading, spacing: BakingSpace.sm) {
                if !hasCompletedFoldPlan {
                    HStack {
                        Spacer(minLength: BakingSpace.sm)

                        BakingInlineActionButton(
                            title: BakingTerms.cookFoldAction,
                            accessibilityLabel: BakingTerms.cookFoldAction
                        ) {
                            store.recordFold(for: step)
                        }
                        .frame(width: 118)
                    }
                    .frame(minHeight: BakingTouchTarget.primaryAction)
                } else {
                    Text(BakingTerms.cookFoldCompleted)
                        .bakingLabelStyle(.helperText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                CookFoldRecordTable(records: foldRecords)
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.bottom, BakingSpace.md)
        }
    }

    private var shouldShowReminder: Bool {
        isCurrent
            && step.foldPlan == nil
            && !store.isCookStepCompleted(step)
            && estimatedCompletionAt != nil
            && store.stepMinutes(step) > 0
    }

    private var shouldShowFoldControls: Bool {
        isCurrent && !store.isCookStepCompleted(step) && step.foldPlan != nil
    }

    private var stepStartedAt: Date? {
        store.cookStepStartedAt(for: step)
    }

    private var estimatedCompletionAt: Date? {
        store.cookStepEstimatedCompletionAt(for: step)
    }

    private var scheduledReminderTime: Date? {
        guard store.isStepCompletionReminderEnabled(for: step) else { return nil }
        return store.cookState.timerEndsAt
    }

    private var foldScheduledReminderTime: Date? {
        guard store.isFoldReminderEnabled(for: step) else { return nil }
        return store.cookState.timerEndsAt
    }

    private var defaultReminderTime: Date {
        scheduledReminderTime ?? estimatedCompletionAt ?? now
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: { reminderTime },
            set: { newValue in
                let nextTime = normalizedReminderTime(newValue)
                reminderTime = nextTime
                hasEditedReminderTime = true
                if isReminderEnabled {
                    store.scheduleCookStepReminder(for: step, at: nextTime)
                }
            }
        )
    }

    private var isReminderEnabled: Bool {
        scheduledReminderTime != nil
    }

    private var isFoldReminderEnabled: Bool {
        foldScheduledReminderTime != nil
    }

    private var reminderEnabledBinding: Binding<Bool> {
        Binding(
            get: { isReminderEnabled },
            set: { isEnabled in
                if isEnabled {
                    scheduleReminder()
                } else {
                    store.clearCookStepReminder(for: step)
                    hasEditedReminderTime = false
                }
            }
        )
    }

    private var foldReminderEnabledBinding: Binding<Bool> {
        Binding(
            get: { isFoldReminderEnabled },
            set: { isEnabled in
                withAnimation(BakingMotion.quick) {
                    if isEnabled {
                        store.scheduleFoldReminder(for: step)
                    } else {
                        store.clearFoldReminder(for: step)
                    }
                }
            }
        )
    }

    private var startTimeText: String {
        guard let stepStartedAt else { return BakingTerms.stepsNoValue }
        return BakingFormat.clockTime(stepStartedAt)
    }

    private var completionTimeText: String {
        guard let estimatedCompletionAt else { return BakingTerms.stepsNoValue }
        return BakingFormat.clockTime(estimatedCompletionAt)
    }

    private var durationText: String {
        BakingFormat.duration(minutes: store.stepMinutes(step))
    }

    private var foldRecords: [BakeFoldRecord] {
        store.foldRecords(for: step)
    }

    private var foldProgressText: String? {
        guard let progress = store.foldProgress(for: step) else { return nil }
        return BakingTerms.cookFoldProgress(completed: progress.completed, target: progress.target)
    }

    private var hasCompletedFoldPlan: Bool {
        guard let progress = store.foldProgress(for: step) else { return false }
        return progress.completed >= progress.target
    }

    private var foldFrequencyText: String {
        guard let foldPlan = step.foldPlan else { return BakingTerms.stepsNoValue }
        return BakingFormat.duration(minutes: Double(foldPlan.normalizedIntervalMinutes))
    }

    private var foldNextTimeText: String {
        guard let nextTime = foldScheduledReminderTime ?? store.nextFoldReminderDate(for: step) else {
            return BakingTerms.stepsNoValue
        }
        return BakingFormat.clockTime(nextTime)
    }

    private var temperatureText: String? {
        guard let temperature = step.temperature else { return nil }
        let value = BakingFormat.number(temperature, precision: 0)
        if step.type == .baking {
            return "\(value)\(step.temperatureUnit?.rawValue ?? "F")"
        }
        return "\(value)°"
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(BakingSurfaceTheme.separator)
            .frame(
                width: BakingComponentMetrics.metricStripDividerWidth,
                height: BakingComponentMetrics.metricStripDividerHeight
            )
            .padding(.horizontal, 6)
    }

    private func scheduleReminder() {
        let fireDate = normalizedReminderTime(reminderTime)
        reminderTime = fireDate
        hasEditedReminderTime = false
        store.scheduleCookStepReminder(for: step, at: fireDate)
    }

    private func syncReminderTime(force: Bool) {
        if reminderStepID != step.id {
            reminderStepID = step.id
            reminderTime = defaultReminderTime
            hasEditedReminderTime = false
            return
        }

        guard force || !hasEditedReminderTime else { return }
        reminderTime = defaultReminderTime
    }

    private func normalizedReminderTime(_ date: Date) -> Date {
        let minimumDate = now.addingTimeInterval(1)
        return date < minimumDate ? minimumDate : date
    }
}

private struct CookFoldRecordTable: View {
    let records: [BakeFoldRecord]

    var body: some View {
        VStack(spacing: 0) {
            header

            BakingTableDivider(leadingInset: 0)

            if records.isEmpty {
                Text(BakingTerms.cookFoldRecordsEmpty)
                    .bakingLabelStyle(.helperText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, BakingSpace.md)
                    .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
            } else {
                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                    row(record)

                    if index < records.count - 1 {
                        BakingTableDivider(leadingInset: 0)
                    }
                }
            }
        }
        .bakingInsetSurface()
    }

    private var header: some View {
        HStack(spacing: BakingSpace.md) {
            BakingLabel(text: BakingTerms.cookFoldRecordIndex, role: .tableHeader)

            Spacer(minLength: BakingSpace.md)

            BakingLabel(text: BakingTerms.cookFoldRecordTime, role: .tableHeader)
        }
        .padding(.horizontal, BakingSpace.md)
        .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
    }

    private func row(_ record: BakeFoldRecord) -> some View {
        HStack(spacing: BakingSpace.md) {
            Text("\(record.sequence)")
                .font(BakingTypography.tableNumber)
                .foregroundStyle(Color.brandText)
                .lineLimit(1)

            Spacer(minLength: BakingSpace.md)

            Text(BakingFormat.clockTime(record.foldedAt))
                .font(BakingTypography.tableNumber)
                .foregroundStyle(Color.brandText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, BakingSpace.md)
        .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
    }
}

private struct CookStepMetricCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .bakingLabelStyle(.tableHeader)
                .lineLimit(1)

            Text(value)
                .font(BakingTypography.tableNumber)
                .foregroundStyle(Color.brandText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, minHeight: BakingComponentMetrics.metricStripCellMinHeight, alignment: .leading)
        .contentShape(Rectangle())
    }
}

private struct CookInstructionCard: View {
    let instruction: String

    var body: some View {
        BakingSectionCard(title: BakingTerms.cookTips) {
            Text(instruction)
                .font(BakingTypography.appPrimaryText)
                .foregroundStyle(Color.brandText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(10)
                .bakingInsetSurface()
                .padding(.horizontal, BakingSpace.md)
                .padding(.bottom, BakingSpace.md)
        }
    }
}

private struct CookSummaryView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore

    var body: some View {
        if let activeBakeRecord = store.activeBakeRecord {
            BakeRecordReviewContent(
                record: activeBakeRecord,
                notes: notesBinding,
                onOpenRecipe: {
                    navigationController.push(.recipeWorkspace(.formula))
                }
            )
        } else {
            EmptyStateView(title: BakingTerms.noRecords, systemImage: "clock.arrow.circlepath")
                .background(Color.brandBackground)
        }
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { store.activeBakeRecord?.notes ?? "" },
            set: { notes in
                if let activeBakeRecord = store.activeBakeRecord {
                    store.updateBakeRecordNotes(notes, for: activeBakeRecord)
                }
            }
        )
    }
}
