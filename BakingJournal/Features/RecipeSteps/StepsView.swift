import SwiftUI
import UIKit
import OSLog

struct StepsView: View {
    private static let reorderLog = Logger(subsystem: "com.hang.BakingJournal", category: "StepsReorder")

    @Environment(\.historySwipeSuppressionHandler) private var setHistorySwipeSuppressed
    @EnvironmentObject private var store: RecipeStore
    var embedded: Bool = false
    @State private var previewSteps: [JournalStep]?
    @State private var isStepListEditing = false
    @State private var activeStepID: UUID?
    @State private var activeStepFrame: CGRect?
    @State private var activeStepGrabOffset: CGSize = .zero
    @State private var activeStepLocation: CGPoint?
    @State private var stepRowFrames: [UUID: CGRect] = [:]
    @State private var suppressNextStepTap = false
    @State private var pendingDeleteStep: JournalStep?
    @State private var showingDeleteConfirmation = false
    @State private var editingStepID: UUID?

    private let reorderCoordinateSpace = "stepsReorderSpace"
    private let tableHorizontalInset = BakingLayout.screenHorizontalInset + BakingSpace.xxl

    var body: some View {
        Group {
            if embedded {
                content
            } else {
                NavigationStack {
                    content
                }
            }
        }
    }

    private var content: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                LazyVStack(spacing: BakingLayout.cardStackSpacing) {
                    StepsOverviewCard(
                        totalMinutes: store.totalStepMinutes(),
                        stepCount: store.steps.count
                    )
                    .padding(.horizontal, BakingLayout.screenHorizontalInset)
                    .padding(.top, BakingLayout.contentTopInset)

                    stepTableSection
                }
                .padding(.bottom, 128)
            }
            .onPreferenceChange(ReorderRowFramePreferenceKey.self) { frames in
                stepRowFrames = frames
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.brandBackground)

            if let activeStep {
                StepDisplayRow(step: activeStep)
                    .frame(width: activeStepFrame?.width)
                    .background(Color.brandSurface)
                    .clipShape(RoundedRectangle(cornerRadius: BakingRadius.prominentCard, style: .continuous))
                    .reorderLiftedAppearance()
                    .offset(activeStepOverlayOffset)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                    .allowsHitTesting(false)
                    .zIndex(10)
            }
        }
        .overlay {
            if showingDeleteConfirmation {
                BakingConfirmationDialog(
                    title: BakingTerms.stepsDeleteConfirmationTitle,
                    message: BakingTerms.stepsDeleteConfirmationMessage,
                    confirmTitle: BakingTerms.delete,
                    cancelTitle: BakingTerms.cancel,
                    confirmTint: .brandPrimary,
                    onConfirm: confirmPendingDelete,
                    onCancel: cancelPendingDelete
                )
                .zIndex(40)
            }
        }
        .animation(BakingMotion.standard, value: showingDeleteConfirmation)
        .coordinateSpace(name: reorderCoordinateSpace)
        .sheet(isPresented: Binding(
            get: { editingStepID != nil },
            set: { if !$0 { editingStepID = nil } }
        )) {
            stepEditorSheet
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    dismissActiveKeyboard()
                } label: {
                    BakingSystemIconButtonLabel(
                        systemImage: "keyboard.chevron.compact.down",
                        visualSize: BakingTouchTarget.secondaryActionVisual,
                        font: .subheadline.weight(.semibold)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.done)
            }
        }
        .onDisappear {
            resetStepReorderState(reason: "steps disappear")
        }
        .onChange(of: editingStepID) { _, newValue in
            if newValue != nil {
                resetStepReorderState(reason: "step editor sheet presented")
            }
        }
        .onChange(of: showingDeleteConfirmation) { _, newValue in
            if newValue {
                resetStepReorderState(keepEditingMode: true, reason: "delete confirmation presented")
            }
        }
        .onChange(of: store.steps.map(\.id)) { _, stepIDs in
            if let activeStepID, !stepIDs.contains(activeStepID) {
                resetStepReorderState(reason: "active step removed")
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                guard !showingDeleteConfirmation, pendingDeleteStep == nil else { return }
                closeStepListEditingIfNeeded()
            }
        )
    }

    private var stepTableSection: some View {
        VStack(spacing: BakingSpace.sm) {
            HStack(spacing: 6) {
                Text(BakingTerms.stepsSectionTitle)
                    .bakingLabelStyle(.sectionHeader)

                Text(BakingTerms.stepsCount(store.steps.count))
                    .bakingLabelStyle(.helperText)
                    .foregroundStyle(Color.brandSecondaryText)

                Spacer()

                AddStepControl { step in
                    presentStepEditor(step)
                }
            }
            .padding(.horizontal, tableHorizontalInset + BakingSpace.sm)

            if displayedSteps.isEmpty {
                Text(BakingTerms.stepsEmptyMessage)
                    .font(.callout)
                    .foregroundStyle(Color.brandSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, BakingSpace.xxl)
                    .padding(.vertical, BakingSpace.xl)
                    .background(Color.brandSurface.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: BakingRadius.prominentCard, style: .continuous))
                    .padding(.horizontal, tableHorizontalInset)
            } else {
                VStack(spacing: 0) {
                    StepTableHeader()

                    Divider()
                        .overlay(Color.brandPrimary.opacity(0.08))
                        .padding(.leading, StepDisplayRow.separatorLeadingInset)

                    ForEach(Array(displayedSteps.enumerated()), id: \.element.id) { index, step in
                        stepRow(step)
                            .opacity(activeStepID == step.id ? ReorderMotion.previewOpacity : 1)
                            .background(ReorderFrameReader(id: step.id, coordinateSpace: reorderCoordinateSpace))
                            .animation(ReorderMotion.animation, value: displayedSteps.map(\.id))

                        if index < displayedSteps.count - 1 {
                            Divider()
                                .overlay(Color.brandPrimary.opacity(0.08))
                                .padding(.leading, StepDisplayRow.separatorLeadingInset)
                        }
                    }
                }
                .bakingCard(background: Color.brandSurface.opacity(0.92), stroke: Color.brandPrimary.opacity(0.07))
                .padding(.horizontal, tableHorizontalInset)
            }
        }
    }

    private var displayedSteps: [JournalStep] {
        previewSteps ?? store.steps
    }

    private var activeStep: JournalStep? {
        guard let activeStepID else { return nil }
        return (previewSteps ?? store.steps).first { $0.id == activeStepID }
            ?? store.steps.first { $0.id == activeStepID }
    }

    private var activeStepOverlayOffset: CGSize {
        guard let frame = activeStepFrame else { return .zero }
        let location = activeStepLocation ?? CGPoint(x: frame.midX, y: frame.midY)
        return CGSize(
            width: location.x - activeStepGrabOffset.width,
            height: location.y - activeStepGrabOffset.height
        )
    }

    @ViewBuilder
    private func stepRow(_ step: JournalStep) -> some View {
        StepDisplayRow(
            step: step,
            isEditing: isStepListEditing,
            onReorderBegan: { drag in
                beginStepReorderIfNeeded(step, drag: drag)
            },
            onReorderChanged: { drag in
                updateStepReorder(with: drag)
            },
            onReorderEnded: { drag in
                if let drag {
                    Self.reorderLog.info("row long-press drag ended step=\(step.id.uuidString, privacy: .public)")
                    updateStepReorder(with: drag)
                    commitStepReorder()
                } else {
                    Self.reorderLog.info("row long-press drag cancelled step=\(step.id.uuidString, privacy: .public)")
                    cancelStepReorder()
                }
            },
            onTap: {
                if suppressNextStepTap || isStepListEditing {
                    suppressNextStepTap = false
                    return
                }
                presentStepEditor(step)
            },
            onDelete: {
                requestDeleteStep(step)
            }
        )
        .contentShape(Rectangle())
    }

    private func beginStepReorderIfNeeded(_ step: JournalStep, drag: StepRowReorderValue) {
        guard activeStepID == nil else { return }
        guard let frame = stepRowFrames[step.id] else {
            Self.reorderLog.error("begin failed missing frame step=\(step.id.uuidString, privacy: .public)")
            return
        }
        activeStepID = step.id
        activeStepFrame = frame
        activeStepLocation = CGPoint(x: frame.minX + drag.startLocation.x, y: frame.minY + drag.startLocation.y)
        activeStepGrabOffset = CGSize(width: drag.startLocation.x, height: drag.startLocation.y)
        previewSteps = store.steps
        isStepListEditing = true
        suppressNextStepTap = true
        setHistorySwipeSuppressed(true)
    }

    private func updateStepReorder(with drag: StepRowReorderValue) {
        guard let activeStepID,
              let activeStepFrame,
              let currentSteps = previewSteps,
              let movingStep = currentSteps.first(where: { $0.id == activeStepID }) else { return }

        let globalLocation = CGPoint(
            x: activeStepFrame.minX + drag.startLocation.x + drag.translation.width,
            y: activeStepFrame.minY + drag.startLocation.y + drag.translation.height
        )
        withTransaction(Transaction(animation: nil)) {
            activeStepLocation = globalLocation
        }

        var remainingSteps = currentSteps.filter { $0.id != activeStepID }
        let centerY = activeStepFrame.midY + drag.translation.height
        let destination = remainingSteps.firstIndex { step in
            guard let frame = stepRowFrames[step.id] else { return false }
            return centerY < frame.midY
        } ?? remainingSteps.count
        remainingSteps.insert(movingStep, at: destination)

        guard remainingSteps.map(\.id) != currentSteps.map(\.id) else { return }
        withAnimation(ReorderMotion.animation) {
            previewSteps = remainingSteps
        }
    }

    private func commitStepReorder() {
        if let previewSteps, previewSteps.map(\.id) != store.steps.map(\.id) {
            store.reorderSteps(previewSteps)
        }
        cancelStepReorder()
    }

    private func cancelStepReorder() {
        withAnimation(ReorderMotion.animation) {
            resetStepReorderState(keepEditingMode: true, reason: "gesture cancel")
        }
    }

    private func resetStepReorderState(keepEditingMode: Bool = false, reason: String) {
        Self.reorderLog.info("reset reason=\(reason, privacy: .public) keepEditing=\(keepEditingMode, privacy: .public)")
        activeStepID = nil
        activeStepFrame = nil
        activeStepLocation = nil
        activeStepGrabOffset = .zero
        previewSteps = nil
        setHistorySwipeSuppressed(false)
        if !keepEditingMode {
            isStepListEditing = false
        }
    }

    private func presentStepEditor(_ step: JournalStep) {
        editingStepID = step.id
    }

    @ViewBuilder
    private var stepEditorSheet: some View {
        if let editingStep {
            StepEditorSheetView(step: editingStep) {
                editingStepID = nil
            }
            .id(editingStep.id)
            .environmentObject(store)
            .presentationDetents([.height(650), .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.brandBackground)
        } else {
            BakingEmptyState(title: BakingTerms.stepsMissingStep, systemImage: "exclamationmark.triangle")
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.brandBackground)
        }
    }

    private var editingStep: JournalStep? {
        guard let editingStepID else { return nil }
        return store.steps.first { $0.id == editingStepID }
    }

    private func requestDeleteStep(_ step: JournalStep) {
        isStepListEditing = true
        pendingDeleteStep = step
        showingDeleteConfirmation = true
    }

    private func confirmPendingDelete() {
        guard let pendingDeleteStep else {
            cancelPendingDelete()
            return
        }
        showingDeleteConfirmation = false
        withAnimation(ReorderMotion.animation) {
            store.removeStep(pendingDeleteStep)
        }
        self.pendingDeleteStep = nil
    }

    private func cancelPendingDelete() {
        showingDeleteConfirmation = false
        pendingDeleteStep = nil
    }

    private func closeStepListEditingIfNeeded() {
        guard isStepListEditing else { return }
        withAnimation(ReorderMotion.animation) {
            resetStepReorderState(reason: "tap outside edit mode")
        }
        suppressNextStepTap = false
    }
}

private struct StepsOverviewCard: View {
    @EnvironmentObject private var store: RecipeStore
    let totalMinutes: Double
    let stepCount: Int
    @State private var showingReadyTooltip = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(BakingTerms.stepsOverviewTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.brandText)

                    Text(store.readinessMessage)
                        .font(.caption)
                        .foregroundStyle(Color.brandSecondaryText)
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    if store.isReadyToBake {
                        store.markDraft()
                    } else if !store.markReadyToBake() {
                        showingReadyTooltip = true
                    }
                } label: {
                    ReadyToBakeButtonLabel(
                        isReady: store.isReadyToBake,
                        canBecomeReady: store.canMarkReadyToBake
                    )
                }
                .buttonStyle(BakingPressFeedbackButtonStyle())
                .accessibilityLabel(store.isReadyToBake ? BakingTerms.stepsMarkDraft : BakingTerms.stepsMarkReady)
                .accessibilityHint(store.readinessMessage)
                .popover(isPresented: $showingReadyTooltip, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                    ReadyToBakeTooltip(
                        title: store.isReadyToBake ? BakingTerms.stepsReadyTooltipTitle : BakingTerms.stepsNotReadyTooltipTitle,
                        message: store.readinessMessage
                    )
                    .presentationCompactAdaptation(.popover)
                }
            }

            HStack(spacing: 6) {
                StepsMetricPill(
                    title: BakingTerms.stepsTotalDuration,
                    value: BakingFormat.duration(minutes: totalMinutes),
                    accent: .brandPrimary
                )
                StepsMetricPill(
                    title: BakingTerms.stepsTableStep,
                    value: "\(stepCount)",
                    accent: .brandText
                )
            }
        }
        .padding(10)
        .bakingCard()
    }
}

private struct ReadyToBakeButtonLabel: View {
    let isReady: Bool
    let canBecomeReady: Bool

    var body: some View {
        BakingSystemIconButtonLabel(
            systemImage: iconName,
            tint: tint,
            visualSize: BakingTouchTarget.secondaryActionVisual,
            font: .title3.weight(.bold)
        )
        .opacity(canBecomeReady || isReady ? 1 : 0.62)
    }

    private var iconName: String {
        if isReady { return "checkmark.circle.fill" }
        return canBecomeReady ? "pencil.and.list.clipboard" : "lock.fill"
    }

    private var tint: Color {
        if isReady { return .brandSage }
        if canBecomeReady { return .brandPrimary }
        return Color.brandSecondaryText.opacity(0.72)
    }
}

private struct ReadyToBakeTooltip: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                BakingIconView(icon: .process, size: 18, color: .brandPrimary)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandText)
            }

            Text(message)
                .font(.caption)
                .foregroundStyle(Color.brandSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 220, alignment: .leading)
        .padding(12)
        .bakingCard(radius: BakingRadius.popover)
    }
}

private struct AddStepControl: View {
    @EnvironmentObject private var store: RecipeStore
    var onOpenEditor: (JournalStep) -> Void
    @State private var showingStepOptions = false

    var body: some View {
        Button {
            showingStepOptions = true
        } label: {
            BakingSystemIconButtonLabel(
                systemImage: "plus",
                visualSize: BakingTouchTarget.secondaryActionVisual,
                font: .caption.weight(.bold)
            )
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(BakingTerms.stepsAddStep)
        .popover(isPresented: $showingStepOptions, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            BakingDropdownPopover(width: 158) {
                ForEach(StepType.allCases) { type in
                    Button {
                        store.addStep(type: type)
                        if let step = store.steps.last {
                            onOpenEditor(step)
                        }
                        showingStepOptions = false
                    } label: {
                        BakingDropdownRow(title: type.label) {
                            BakingIconView(icon: BakingIcon.step(for: type), size: BakingTouchTarget.dropdownIconGlyph, color: .brandPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct StepTableHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: BakingSpace.lg) {
            Color.clear
                .frame(width: StepDisplayRow.iconColumnWidth, height: 1)

            Text(BakingTerms.stepsTableStep)
                .bakingLabelStyle(.tableHeader)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: StepDisplayRow.numericColumnSpacing) {
                Text(BakingTerms.stepsTableDuration)
                    .bakingLabelStyle(.tableHeader)
                    .frame(width: StepDisplayRow.durationColumnWidth, alignment: .trailing)

                Text(BakingTerms.stepsTableTemperature)
                    .bakingLabelStyle(.tableHeader)
                    .frame(width: StepDisplayRow.temperatureColumnWidth, alignment: .trailing)
            }
            .frame(width: StepDisplayRow.numericColumnsWidth, alignment: .trailing)
        }
        .padding(.leading, BakingSpace.sm)
        .padding(.trailing, BakingSpace.md)
        .padding(.top, BakingSpace.sm)
        .padding(.bottom, BakingSpace.xs)
        .accessibilityElement(children: .combine)
    }
}

private struct StepDisplayRow: View {
    static let iconColumnWidth: CGFloat = 40
    static let separatorLeadingInset: CGFloat = BakingSpace.sm + iconColumnWidth + BakingSpace.lg
    static let durationColumnWidth: CGFloat = 64
    static let temperatureColumnWidth: CGFloat = 60
    static let numericColumnSpacing: CGFloat = 10
    static let numericColumnsWidth: CGFloat = durationColumnWidth + numericColumnSpacing + temperatureColumnWidth
    private static let trailingDeleteHitWidth = BakingTouchTarget.primaryAction

    @EnvironmentObject private var store: RecipeStore
    let step: JournalStep
    var isEditing = false
    var onReorderBegan: (StepRowReorderValue) -> Void = { _ in }
    var onReorderChanged: (StepRowReorderValue) -> Void = { _ in }
    var onReorderEnded: (StepRowReorderValue?) -> Void = { _ in }
    var onTap: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: BakingSpace.lg) {
            iconBlock

            VStack(alignment: .leading, spacing: 3) {
                Text(currentStep.name)
                    .bakingLabelStyle(.inputLabel)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 6) {
                    Text(detailText)
                        .bakingLabelStyle(.helperText)
                        .foregroundStyle(Color.brandSecondaryText)
                        .lineLimit(1)

                    if assignedItems.count > 0 {
                        Text(BakingTerms.stepsAssignedCount(assignedItems.count))
                            .bakingLabelStyle(.helperText)
                            .foregroundStyle(Color.brandPrimary.opacity(0.78))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            HStack(alignment: .firstTextBaseline, spacing: Self.numericColumnSpacing) {
                Text(durationText)
                    .font(BakingTypography.tableNumber)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: Self.durationColumnWidth, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(temperatureText)
                    .font(BakingTypography.tableNumber)
                    .foregroundStyle(showsTemperatureField ? Color.waterText : Color.brandSecondaryText)
                    .frame(width: Self.temperatureColumnWidth, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
            .frame(width: Self.numericColumnsWidth, alignment: .trailing)

            if isEditing {
                deleteButton
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(minHeight: 58)
        .padding(.leading, BakingSpace.sm)
        .padding(.trailing, isEditing ? BakingSpace.xs : BakingSpace.md)
        .padding(.vertical, BakingSpace.xs)
        .background(isEditing ? Color.brandPrimary.opacity(0.035) : Color.clear)
        .overlay(alignment: .leading) {
            if isEditing {
                Capsule()
                    .fill(Color.brandPrimary.opacity(0.55))
                    .frame(width: 3)
                    .padding(.vertical, BakingSpace.lg)
                    .transition(.opacity)
            }
        }
        .overlay {
            HStack(spacing: 0) {
                StepRowInteractionSurface(
                    minimumPressDuration: isEditing ? 0.18 : ReorderMotion.holdDuration,
                    onTap: onTap,
                    onLongPressBegan: onReorderBegan,
                    onLongPressChanged: onReorderChanged,
                    onLongPressEnded: onReorderEnded
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Color.clear
                    .frame(width: Self.trailingDeleteHitWidth)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .animation(ReorderMotion.animation, value: isEditing)
    }

    private var deleteButton: some View {
        Button {
            onDelete()
        } label: {
            BakingSystemIconButtonLabel(
                systemImage: "trash",
                visualSize: BakingTouchTarget.secondaryActionVisual,
                font: .caption.weight(.semibold)
            )
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(BakingTerms.stepsDeleteStep)
    }

    private var iconBlock: some View {
        BakingIconView(icon: BakingIcon.step(for: currentStep.type), size: BakingTouchTarget.inlineIconGlyph, color: .brandPrimary)
            .frame(width: BakingTouchTarget.inlineIconSurface, height: BakingTouchTarget.inlineIconSurface)
            .background(Color.brandBackground.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .frame(width: Self.iconColumnWidth, alignment: .center)
    }

    private var currentStep: JournalStep {
        store.steps.first { $0.id == step.id } ?? step
    }

    private var assignedItems: [AllocatedRecipeItem] {
        store.allocatedItems(for: currentStep)
    }

    private var detailText: String {
        if currentStep.type == .baking {
            return (currentStep.productionMethod ?? .bake).label
        }
        return currentStep.type.label
    }

    private var showsTemperatureField: Bool {
        currentStep.type == .fermentation || currentStep.type == .baking
    }

    private var durationText: String {
        StepFormatting.compactDuration(minutes: store.stepMinutes(currentStep))
    }

    private var temperatureText: String {
        guard showsTemperatureField else { return BakingTerms.stepsNoValue }
        let value = BakingFormat.number(currentStep.temperature ?? 0, precision: 0)
        return currentStep.type == .baking ? "\(value)\(currentStep.temperatureUnit?.rawValue ?? TemperatureUnit.fahrenheit.rawValue)" : "\(value)°"
    }
}

private struct StepEditorSheetView: View {
    @EnvironmentObject private var store: RecipeStore
    let step: JournalStep
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BakingLayout.cardStackSpacing) {
                    identityCard
                    timingCard
                    materialsCard
                    notesCard
                }
                .padding(.horizontal, BakingLayout.screenHorizontalInset)
                .padding(.top, BakingSpace.xl)
                .padding(.bottom, 34)
            }
            .background(Color.brandBackground)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onDone) {
                        BakingSystemIconButtonLabel(
                            systemImage: "checkmark",
                            visualSize: BakingTouchTarget.secondaryActionVisual,
                            font: .caption.weight(.semibold)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(BakingTerms.done)
                }
            }
        }
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(BakingTerms.stepsEditorTitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.brandText)

            CompactTextRow(title: BakingTerms.stepsFieldName, text: stepTextBinding(\.name))

            Divider()
                .overlay(Color.brandPrimary.opacity(0.08))

            HStack(spacing: 12) {
                BakingLabel(text: BakingTerms.stepsFieldType, role: .fieldLabel)
                Spacer()
                StepTypeMenu(selection: stepTypeBinding)
            }
            .padding(.vertical, 6)
        }
        .padding(12)
        .bakingCard()
    }

    private var timingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(BakingTerms.stepsTimingSection)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.brandText)

            StepDurationEditor(minutes: durationBinding)

            if currentStep.type == .baking {
                Divider()
                    .overlay(Color.brandPrimary.opacity(0.08))

                HStack(spacing: 12) {
                    BakingLabel(text: BakingTerms.stepsFieldProductionMethod, role: .fieldLabel)
                    Spacer()
                    ProductionMethodMenu(selection: productionMethodBinding)
                }
                .padding(.vertical, 6)

                BakingTemperatureEditorRow(
                    title: BakingTerms.stepsFieldTemperature,
                    value: stepNumberBinding(\.temperature, fallback: 0),
                    unit: stepTemperatureUnitBinding
                )
            } else if currentStep.type == .fermentation {
                Divider()
                    .overlay(Color.brandPrimary.opacity(0.08))

                CompactNumberRow(
                    title: BakingTerms.stepsFieldTemperature,
                    value: stepNumberBinding(\.temperature, fallback: 0),
                    unit: BakingTerms.stepsDegreeUnit
                )
            }
        }
        .padding(12)
        .bakingCard()
    }

    private var materialsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(BakingTerms.stepsMaterialsSection)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.brandText)

                Spacer()

                Button {
                    store.assignAllItems(to: currentStep)
                } label: {
                    BakingSystemIconButtonLabel(
                        systemImage: "checklist.checked",
                        visualSize: BakingTouchTarget.secondaryActionVisual,
                        font: .caption.weight(.semibold)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.stepsAssignAll)
                .disabled(store.items.isEmpty)
                .opacity(store.items.isEmpty ? 0.45 : 1)
            }

            if store.items.isEmpty {
                Text(BakingTerms.stepsMaterialsEmpty)
                    .font(.callout)
                    .foregroundStyle(Color.brandSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, BakingSpace.sm)
            } else {
                BakingFlowLayout(spacing: 8) {
                    ForEach(store.items) { item in
                        AssignmentMaterialChip(
                            item: item,
                            step: currentStep
                        ) {
                            toggleAssignment(item)
                        }
                    }
                }
            }
        }
        .padding(12)
        .bakingCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            BakingLabel(text: BakingTerms.stepsFieldNotes, role: .fieldLabel)

            TextEditor(text: stepTextBinding(\.notes))
                .font(.subheadline)
                .foregroundStyle(Color.brandText)
                .frame(minHeight: 112)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.brandBackground.opacity(0.68))
                .clipShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous)
                        .stroke(Color.brandPrimary.opacity(0.08), lineWidth: 0.5)
                }
                .accessibilityLabel(BakingTerms.stepsFieldNotes)
        }
        .padding(12)
        .bakingCard()
    }

    private var currentStep: JournalStep {
        store.steps.first { $0.id == step.id } ?? step
    }

    private func stepTextBinding(_ keyPath: WritableKeyPath<JournalStep, String>) -> Binding<String> {
        Binding(
            get: { currentStep[keyPath: keyPath] },
            set: {
                var next = currentStep
                next[keyPath: keyPath] = $0
                store.updateStep(next)
            }
        )
    }

    private var stepTypeBinding: Binding<StepType> {
        Binding(
            get: { currentStep.type },
            set: {
                var next = currentStep
                next.type = $0
                if $0 == .baking {
                    next.productionMethod = next.productionMethod ?? .bake
                    next.temperature = next.temperature ?? 350
                    next.temperatureUnit = next.temperatureUnit ?? .fahrenheit
                } else if $0 == .fermentation {
                    next.productionMethod = nil
                    next.temperature = next.temperature ?? 28
                    next.temperatureUnit = nil
                } else {
                    next.productionMethod = nil
                    next.temperature = nil
                    next.temperatureUnit = nil
                }
                store.updateStep(next)
            }
        )
    }

    private var durationBinding: Binding<Double> {
        Binding(
            get: { store.stepMinutes(currentStep) },
            set: {
                var next = currentStep
                next.timeUnit = .min
                next.timeValue = max(0, $0)
                store.updateStep(next)
            }
        )
    }

    private func stepNumberBinding(_ keyPath: WritableKeyPath<JournalStep, Double?>, fallback: Double) -> Binding<Double> {
        Binding(
            get: { currentStep[keyPath: keyPath] ?? fallback },
            set: {
                var next = currentStep
                next[keyPath: keyPath] = max(0, $0)
                store.updateStep(next)
            }
        )
    }

    private var stepTemperatureUnitBinding: Binding<TemperatureUnit> {
        Binding(
            get: { currentStep.temperatureUnit ?? .fahrenheit },
            set: {
                var next = currentStep
                next.temperatureUnit = $0
                store.updateStep(next)
            }
        )
    }

    private var productionMethodBinding: Binding<ProductionMethod> {
        Binding(
            get: { currentStep.productionMethod ?? .bake },
            set: { method in
                var next = currentStep
                next.productionMethod = method
                switch method {
                case .bake:
                    next.temperature = 350
                    next.temperatureUnit = .fahrenheit
                case .steam:
                    next.temperature = 100
                    next.temperatureUnit = .celsius
                }
                store.updateStep(next)
            }
        )
    }

    private func toggleAssignment(_ item: RecipeItem) {
        if store.allocationPercentage(for: item.id, in: currentStep) > 0 {
            store.removeAssignedItem(item.id, from: currentStep)
        } else {
            store.assign(itemId: item.id, to: currentStep)
        }
    }
}

private struct StepTypeMenu: View {
    @Binding var selection: StepType
    @State private var showingMenu = false

    var body: some View {
        Button {
            showingMenu = true
        } label: {
            BakingDropdownTrigger(title: selection.label)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(BakingTerms.stepsFieldType)
        .popover(isPresented: $showingMenu, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
            BakingDropdownPopover(width: 168) {
                ForEach(StepType.allCases) { type in
                    Button {
                        selection = type
                        showingMenu = false
                    } label: {
                        BakingDropdownRow(title: type.label, isSelected: selection == type) {
                            BakingIconView(icon: BakingIcon.step(for: type), size: BakingTouchTarget.dropdownIconGlyph, color: .brandPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ProductionMethodMenu: View {
    @Binding var selection: ProductionMethod
    @State private var showingMenu = false

    var body: some View {
        Button {
            showingMenu = true
        } label: {
            BakingDropdownTrigger(title: selection.label)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(BakingTerms.stepsFieldProductionMethod)
        .popover(isPresented: $showingMenu, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
            BakingDropdownPopover(width: 158) {
                ForEach(ProductionMethod.allCases) { method in
                    Button {
                        selection = method
                        showingMenu = false
                    } label: {
                        BakingDropdownRow(title: method.label, isSelected: selection == method) {
                            Image(systemName: method == .steam ? "humidity" : "oven")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.brandPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct StepDurationEditor: View {
    @Binding var minutes: Double

    var body: some View {
        HStack(spacing: 12) {
            BakingLabel(text: BakingTerms.stepsFieldDuration, role: .fieldLabel)

            Spacer()

            BakingNumericTextField(
                value: $minutes,
                fractionDigits: 0...0,
                color: UIColor(Color.brandText),
                font: .monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
            )
            .frame(width: 74)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(height: 36)
            .bakingFieldSurface()
            .accessibilityLabel(BakingTerms.stepsFieldDuration)

            Text(BakingTerms.stepsMinuteUnit)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)
                .frame(width: 26, alignment: .leading)
        }
        .padding(.vertical, 6)
    }
}

private enum StepFormatting {
    static func compactDuration(minutes: Double) -> String {
        let total = Int(minutes.rounded())
        let hours = total / 60
        let minutes = total % 60
        if hours > 0, minutes > 0 {
            return "\(hours)\(BakingTerms.stepsHourShort) \(minutes)\(BakingTerms.stepsMinuteShort)"
        }
        if hours > 0 { return "\(hours)\(BakingTerms.stepsHourShort)" }
        return "\(minutes)\(BakingTerms.stepsMinuteShort)"
    }
}

private struct AssignmentMaterialChip: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    let step: JournalStep
    let action: () -> Void
    @State private var showingPercentagePicker = false
    @State private var draftPercentage: Double = 0

    var body: some View {
        let palette = item.materialPalette
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                BakingIconView(
                    icon: BakingIcon.material(for: item),
                    size: 13,
                    color: isUnavailable ? Color.brandSecondaryText.opacity(0.85) : palette.tint
                )
                .frame(width: 18, height: 18)
                .background(isUnavailable ? palette.mutedIconSurface : palette.iconSurface)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Text(String(item.name.prefix(3)))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isUnavailable ? Color.brandSecondaryText : Color.brandText)
                    .lineLimit(1)
            }

            Text(weightText)
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(isUnavailable ? Color.brandSecondaryText : palette.text)

            Text(statusText)
                .font(.caption2)
                .foregroundStyle(Color.brandSecondaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(width: 72, alignment: .leading)
        .background {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    (isUnavailable ? palette.mutedSurface : palette.surface.opacity(selected ? 0.96 : 0.8))
                    palette.tint.opacity(selected ? 0.22 : 0.14)
                        .frame(width: proxy.size.width * usedRatio)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(selected ? palette.tint.opacity(0.34) : palette.stroke, lineWidth: selected ? 1 : 0.5)
        }
        .opacity(isUnavailable ? 0.68 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture {
            guard !isUnavailable else { return }
            action()
        }
        .onLongPressGesture(minimumDuration: 0.35) {
            guard availablePercentage > 0 else { return }
            draftPercentage = selected ? selectedPercentage : min(availablePercentage, 50)
            showingPercentagePicker = true
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(item.name)
        .accessibilityValue(statusText)
        .popover(isPresented: $showingPercentagePicker, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
            MaterialPercentagePopover(
                item: item,
                percentage: $draftPercentage,
                maxPercentage: availablePercentage,
                isPresented: $showingPercentagePicker
            ) {
                if draftPercentage <= 0 {
                    store.removeAssignedItem(item.id, from: currentStep)
                } else {
                    store.assign(itemId: item.id, percentage: draftPercentage, to: currentStep)
                }
            }
            .presentationCompactAdaptation(.popover)
        }
    }

    private var currentStep: JournalStep {
        store.steps.first { $0.id == step.id } ?? step
    }

    private var selectedPercentage: Double {
        store.allocationPercentage(for: item.id, in: currentStep)
    }

    private var selected: Bool {
        selectedPercentage > 0
    }

    private var availablePercentage: Double {
        store.remainingPercentage(for: item.id, excluding: currentStep.id)
    }

    private var isUnavailable: Bool {
        !selected && availablePercentage <= 0.01
    }

    private var usedRatio: CGFloat {
        CGFloat(min(1, max(0, store.allocatedPercentage(for: item.id) / 100)))
    }

    private var weightText: String {
        let weight = selected ? store.allocatedWeight(for: item, percentage: selectedPercentage) : item.weight
        return BakingFormat.weight(weight, gramPrecision: item.tag == .yeast ? 1 : 0)
    }

    private var statusText: String {
        if selected {
            return BakingTerms.stepsAssignmentPercent(BakingFormat.number(selectedPercentage, precision: 0))
        }
        if isUnavailable {
            return BakingTerms.stepsUsedUp
        }
        return BakingTerms.stepsRemainingPercent(BakingFormat.number(availablePercentage, precision: 0))
    }
}

private struct MaterialPercentagePopover: View {
    let item: RecipeItem
    @Binding var percentage: Double
    let maxPercentage: Double
    @Binding var isPresented: Bool
    let confirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandText)
                    Text(BakingTerms.stepsChooseAssignmentPercentage)
                        .font(.caption2)
                        .foregroundStyle(Color.brandSecondaryText)
                }

                Spacer()

                Button {
                    confirm()
                    isPresented = false
                } label: {
                    BakingSystemIconButtonLabel(
                        systemImage: "checkmark",
                        visualSize: BakingTouchTarget.secondaryActionVisual,
                        font: .caption.weight(.semibold)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.stepsConfirmAssignment)
            }

            BakingPercentagePickerControl(
                value: $percentage,
                maxValue: maxPercentage,
                precision: 1,
                tint: item.materialPalette.text,
                surface: item.materialPalette.surface.opacity(0.86)
            )

            HStack {
                Text(BakingTerms.stepsAddWeight)
                    .font(.caption)
                    .foregroundStyle(Color.brandSecondaryText)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    BakingNumericTextField(
                        value: weightBinding,
                        fractionDigits: item.tag == .yeast ? 0...1 : 0...0,
                        color: UIColor(Color.brandText),
                        font: .monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
                    )
                    .frame(width: 76)
                    .accessibilityLabel(BakingTerms.stepsAddWeightAccessibility)

                    Text(BakingTerms.unitGram)
                        .font(.headline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color.brandSecondaryText)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(item.materialPalette.surface.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
        }
        .padding(12)
        .frame(width: 292, alignment: .leading)
        .background(Color.brandSurface)
    }

    private var maxWeight: Double {
        item.weight * maxPercentage / 100
    }

    private var currentWeight: Double {
        item.weight * percentage / 100
    }

    private var weightBinding: Binding<Double> {
        Binding(
            get: { currentWeight },
            set: { weight in
                let clampedWeight = min(max(0, weight), maxWeight)
                percentage = item.weight > 0 ? clampedWeight / item.weight * 100 : 0
            }
        )
    }
}

private struct StepRowReorderValue {
    let startLocation: CGPoint
    let location: CGPoint
    let translation: CGSize
}

private struct StepRowInteractionSurface: UIViewRepresentable {
    private static let log = Logger(subsystem: "com.hang.BakingJournal", category: "StepsReorder")

    let minimumPressDuration: TimeInterval
    var onTap: () -> Void
    var onLongPressBegan: (StepRowReorderValue) -> Void
    var onLongPressChanged: (StepRowReorderValue) -> Void
    var onLongPressEnded: (StepRowReorderValue?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let longPressRecognizer = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPressRecognizer.minimumPressDuration = minimumPressDuration
        longPressRecognizer.allowableMovement = BakingTouchTarget.primaryAction
        longPressRecognizer.cancelsTouchesInView = false
        longPressRecognizer.delegate = context.coordinator
        view.addGestureRecognizer(longPressRecognizer)

        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.require(toFail: longPressRecognizer)
        view.addGestureRecognizer(tapRecognizer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        if let recognizer = uiView.gestureRecognizers?.compactMap({ $0 as? UILongPressGestureRecognizer }).first {
            recognizer.minimumPressDuration = minimumPressDuration
            recognizer.allowableMovement = BakingTouchTarget.primaryAction
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: StepRowInteractionSurface
        private var startLocation: CGPoint?
        private var startWindowLocation: CGPoint?

        init(parent: StepRowInteractionSurface) {
            self.parent = parent
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            StepRowInteractionSurface.log.debug("ui tap ended")
            parent.onTap()
        }

        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let location = recognizer.location(in: view)

            switch recognizer.state {
            case .began:
                startLocation = location
                startWindowLocation = windowLocation(for: recognizer)
                parent.onLongPressBegan(StepRowReorderValue(startLocation: location, location: location, translation: .zero))
            case .changed:
                parent.onLongPressChanged(StepRowReorderValue(
                    startLocation: startLocation ?? location,
                    location: location,
                    translation: windowTranslation(for: recognizer)
                ))
            case .ended:
                parent.onLongPressEnded(StepRowReorderValue(
                    startLocation: startLocation ?? location,
                    location: location,
                    translation: windowTranslation(for: recognizer)
                ))
                startLocation = nil
                startWindowLocation = nil
            case .cancelled, .failed:
                parent.onLongPressEnded(nil)
                startLocation = nil
                startWindowLocation = nil
            default:
                break
            }
        }

        private func windowLocation(for recognizer: UIGestureRecognizer) -> CGPoint? {
            guard let window = recognizer.view?.window else { return nil }
            return recognizer.location(in: window)
        }

        private func windowTranslation(for recognizer: UIGestureRecognizer) -> CGSize {
            guard let startWindowLocation, let currentWindowLocation = windowLocation(for: recognizer) else {
                return .zero
            }
            return CGSize(
                width: currentWindowLocation.x - startWindowLocation.x,
                height: currentWindowLocation.y - startWindowLocation.y
            )
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            false
        }
    }
}
