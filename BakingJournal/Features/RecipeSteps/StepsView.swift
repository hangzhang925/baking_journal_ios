import SwiftUI
import UIKit
import OSLog

struct StepsView: View {
    private static let reorderLog = Logger(subsystem: "com.openbakery.bready", category: "StepsReorder")

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
                LazyVStack(spacing: BakingSpace.lg) {
                    StepsOverviewCard(
                        totalMinutes: store.totalStepMinutes()
                    )

                    RecipeMaterialsRemainingCard()
                        .bakingCard()

                    stepsModeControlCard
                    stepTableSection
                }
                .padding(.horizontal, BakingLayout.screenHorizontalInset)
                .padding(.top, BakingLayout.contentTopInset)
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
                guard store.stepsMode == .custom,
                      !showingDeleteConfirmation,
                      pendingDeleteStep == nil else { return }
                closeStepListEditingIfNeeded()
            }
        )
    }

    @ViewBuilder
    private var stepTableSection: some View {
        if store.stepsMode == .simple {
            simpleStepSection
        } else {
            customStepTableSection
        }
    }

    private var stepsModeControlCard: some View {
        VStack(spacing: 0) {
            BakingToggleRow(
                title: BakingTerms.stepsModeCustomToggle,
                isOn: customStepsEnabledBinding,
                accessibilityValueOn: BakingTerms.stepsModeCustom,
                accessibilityValueOff: BakingTerms.stepsModeSimple
            )
        }
        .bakingCard()
    }

    private var simpleStepSection: some View {
        Button {
            presentSimpleStepEditor()
        } label: {
            BakingSectionCard(
                title: BakingTerms.stepsSectionTitle,
                headerBottomPadding: 0
            ) {
                Text(simpleStepNotesText)
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(simpleStepHasText ? Color.brandText : Color.brandSecondaryText)
                    .lineLimit(6)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
                    .padding(.horizontal, BakingSpace.md)
                    .padding(.vertical, BakingSpace.sm)
            }
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(BakingTerms.stepsSimpleEditAccessibility)
        .accessibilityValue(simpleStepNotesText)
    }

    private var customStepTableSection: some View {
        BakingSectionCard(
            title: BakingTerms.stepsSectionTitle,
            headerBottomPadding: displayedSteps.isEmpty ? 0 : BakingSpace.xs,
            accessory: {
                HStack(spacing: BakingSpace.xs) {
                    Button {
                        withAnimation(ReorderMotion.animation) {
                            isStepListEditing.toggle()
                        }
                    } label: {
                        BakingSystemIconButtonLabel(
                            systemImage: "minus",
                            visualSize: BakingTouchTarget.secondaryActionVisual,
                            font: .caption.weight(.bold)
                        )
                    }
                    .buttonStyle(.borderless)
                    .disabled(store.steps.isEmpty)
                    .opacity(store.steps.isEmpty ? 0.45 : 1)
                    .accessibilityLabel(BakingTerms.stepsEditSteps)

                    Button {
                        let step = store.addTextStep()
                        presentStepEditor(step)
                    } label: {
                        BakingSystemIconButtonLabel(
                            systemImage: "plus",
                            visualSize: BakingTouchTarget.secondaryActionVisual,
                            font: .caption.weight(.bold)
                        )
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(BakingTerms.stepsAddStep)
                }
            }
        ) {
            if displayedSteps.isEmpty {
                Text(BakingTerms.stepsEmptyMessage)
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(Color.brandSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, BakingSpace.md)
                    .padding(.vertical, BakingSpace.xl)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(displayedSteps.enumerated()), id: \.element.id) { index, step in
                        stepRow(step)
                            .opacity(activeStepID == step.id ? ReorderMotion.previewOpacity : 1)
                            .background(ReorderFrameReader(id: step.id, coordinateSpace: reorderCoordinateSpace))
                            .animation(ReorderMotion.animation, value: displayedSteps.map(\.id))

                        if index < displayedSteps.count - 1 {
                            BakingTableDivider()
                        }
                    }
                }
            }
        }
    }

    private var customStepsEnabledBinding: Binding<Bool> {
        Binding(
            get: { store.stepsMode == .custom },
            set: { store.setStepsMode($0 ? .custom : .simple) }
        )
    }

    private var simpleStep: JournalStep? {
        store.steps.first
    }

    private var simpleStepNotesText: String {
        let trimmed = simpleStep?.notes.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? BakingTerms.stepsNoValue : trimmed
    }

    private var simpleStepHasText: Bool {
        !(simpleStep?.notes.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty
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

    private func presentSimpleStepEditor() {
        if let simpleStep {
            presentStepEditor(simpleStep)
            return
        }

        store.setStepsMode(.simple)
        if let simpleStep = store.steps.first {
            presentStepEditor(simpleStep)
        }
    }

    private func enterStepListEditing() {
        withAnimation(ReorderMotion.animation) {
            isStepListEditing = true
        }
    }

    @ViewBuilder
    private var stepEditorSheet: some View {
        if let editingStep {
            Group {
                if store.stepsMode == .simple {
                    SimpleStepEditorSheetView(
                        step: editingStep,
                        onDismiss: {
                            editingStepID = nil
                        }
                    )
                } else {
                    StepTextEditorSheetView(
                        step: editingStep,
                        recipeKind: store.currentRecipeKind,
                        isScrollEnabled: true,
                        onDismiss: {
                            editingStepID = nil
                        }
                    )
                }
            }
            .id(editingStep.id)
            .environmentObject(store)
            .presentationDetents([BakingPopupSheetMetrics.editSheetTallDetent])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.brandBackground)
        } else {
            BakingEmptyState(title: BakingTerms.stepsMissingStep, systemImage: "exclamationmark.triangle")
                .presentationDetents([BakingPopupSheetMetrics.editSheetTallDetent])
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
    let totalMinutes: Double

    var body: some View {
        BakingInfoRow(
            title: BakingTerms.stepsTotalDuration,
            value: BakingFormat.duration(minutes: totalMinutes),
            valueFont: BakingTypography.appPrimaryText.monospacedDigit(),
            valueColor: .brandText
        )
        .bakingCard()
    }
}

private struct RecipeMaterialsRemainingCard: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 10 : 0) {
            BakingDisclosureRow(
                title: BakingTerms.formulaTableIngredient,
                value: BakingTerms.stepsAssignedCount(store.items.count),
                isExpanded: isExpanded
            ) {
                withAnimation(BakingMotion.standard) {
                    isExpanded.toggle()
                }
            }

            if isExpanded {
                Group {
                    if store.items.isEmpty {
                        Text(BakingTerms.stepsMaterialsEmpty)
                            .font(BakingTypography.appPrimaryText)
                            .foregroundStyle(Color.brandSecondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, BakingSpace.sm)
                    } else {
                        BakingFlowLayout(spacing: 8) {
                            ForEach(store.items) { item in
                                StepMaterialReferenceChip(item: item)
                            }
                        }
                    }
                }
                .padding(.horizontal, BakingFormTheme.rowHorizontalPadding)
            }
        }
        .padding(.bottom, isExpanded ? BakingSpace.sm : 0)
    }
}

private struct StepMaterialReferenceChip: View {
    let item: RecipeItem

    var body: some View {
        let palette = item.materialPalette
        VStack(alignment: .leading, spacing: 3) {
            Text(item.name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.brandText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(weightText)
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(palette.text)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(minWidth: BakingComponentMetrics.materialChipWidth, alignment: .leading)
        .background(palette.chipSurface)
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous)
                .stroke(palette.chipStroke, lineWidth: 0.6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.name)
        .accessibilityValue(weightText)
    }

    private var weightText: String {
        BakingFormat.weight(item.weight, gramPrecision: item.tag == .yeast ? 1 : 0)
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
                ForEach(StepCategory.available(for: store.currentRecipeKind)) { category in
                    Button {
                        let step = store.addStep(type: category.stepType)
                        var next = step
                        next.name = category.label
                        store.updateStep(next)
                        onOpenEditor(next)
                        showingStepOptions = false
                    } label: {
                        BakingDropdownRow(
                            title: category.label,
                            showsLeadingSlot: false
                        ) {
                            EmptyView()
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
    static let separatorLeadingInset: CGFloat = BakingSpace.sm
    static let durationColumnWidth: CGFloat = 70
    static let temperatureColumnWidth: CGFloat = 72
    static let numericColumnSpacing: CGFloat = 8
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
            VStack(alignment: .leading, spacing: 3) {
                Text(titleText)
                    .bakingLabelStyle(.inputLabel)
                    .foregroundStyle(hasTitle ? Color.brandText : Color.brandSecondaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(displayText)
                    .bakingLabelStyle(.helperText)
                    .foregroundStyle(Color.brandSecondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            HStack(alignment: .firstTextBaseline, spacing: Self.numericColumnSpacing) {
                BakingTableMetricValue(
                    symbol: nil,
                    value: durationValue.value,
                    unit: durationValue.unit,
                    numericKind: .duration,
                    width: Self.durationColumnWidth,
                    isActive: showsDurationField
                )

                BakingTableMetricValue(
                    symbol: nil,
                    value: temperatureValue.value,
                    unit: temperatureValue.unit,
                    numericKind: .temperature,
                    width: Self.temperatureColumnWidth,
                    isActive: showsTemperatureField
                )
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
        .background(isEditing ? BakingSurfaceTheme.theme(for: .focused).background.opacity(0.45) : Color.clear)
        .overlay(alignment: .leading) {
            if isEditing {
                Capsule()
                    .fill(BakingSurfaceTheme.theme(for: .selected).stroke)
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
                tint: BakingComponentTheme.action(role: .destructive).foreground,
                visualSize: BakingTouchTarget.secondaryActionVisual,
                font: .caption.weight(.semibold)
            )
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(BakingTerms.stepsDeleteStep)
    }

    private var currentStep: JournalStep {
        store.steps.first { $0.id == step.id } ?? step
    }

    private var hasTitle: Bool {
        !currentStep.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var titleText: String {
        hasTitle ? currentStep.name : BakingTerms.stepsNoValue
    }

    private var hasNotes: Bool {
        !currentStep.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var displayText: String {
        hasNotes ? currentStep.notes : BakingTerms.stepsNoValue
    }

    private var showsTemperatureField: Bool {
        currentStep.temperature != nil
    }

    private var showsDurationField: Bool {
        currentStep.timeValue != nil
    }

    private var durationValue: (value: String, unit: String?) {
        guard showsDurationField else { return (BakingTerms.stepsNoValue, nil) }
        return StepFormatting.compactDurationParts(minutes: store.stepMinutes(currentStep))
    }

    private var temperatureValue: (value: String, unit: String?) {
        guard let temperature = currentStep.temperature else { return (BakingTerms.stepsNoValue, nil) }
        let value = BakingFormat.number(temperature, precision: 0)
        return (value, currentStep.temperatureUnit?.rawValue ?? TemperatureUnit.fahrenheit.rawValue)
    }
}

private struct SimpleStepEditorSheetView: View {
    @EnvironmentObject private var store: RecipeStore
    let step: JournalStep
    var onDismiss: () -> Void
    @State private var showingMaterials = false

    var body: some View {
        VStack(spacing: 0) {
            editorToolbar

            ScrollView {
                VStack(alignment: .leading, spacing: BakingLayout.cardStackSpacing) {
                    materialsCard
                    notesCard
                }
                .padding(.horizontal, BakingLayout.screenHorizontalInset)
                .padding(.top, BakingSpace.sm)
                .padding(.bottom, 34)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.brandBackground)
        .animation(BakingMotion.standard, value: showingMaterials)
    }

    private var editorToolbar: some View {
        BakingTopActionRow(trailing: {
            BakingSystemIconButton(
                systemImage: "xmark",
                accessibilityLabel: BakingTerms.done,
                role: .secondary,
                size: .secondary,
                font: .caption.weight(.bold)
            ) {
                onDismiss()
            }
        })
    }

    private var materialsCard: some View {
        VStack(spacing: 0) {
            StepPopupActionTableRow(title: BakingTerms.stepsMaterialsSection) {
                Button {
                    toggleMaterials()
                } label: {
                    BakingSystemIconButtonLabel(
                        systemImage: "checklist",
                        visualSize: BakingTouchTarget.secondaryActionVisual,
                        font: .caption.weight(.semibold)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.stepsMaterialsSection)
            }

            if showingMaterials {
                PopupTableDivider()

                materialPickerContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .bakingCard()
    }

    private var materialPickerContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if store.items.isEmpty {
                Text(BakingTerms.stepsMaterialsEmpty)
                    .font(BakingTypography.appPrimaryText)
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

                HStack {
                    Spacer()

                    BakingActionButton(
                        title: BakingTerms.stepsInsertSelectedMaterials,
                        accessibilityLabel: BakingTerms.stepsInsertSelectedMaterials,
                        role: .primary,
                        state: hasSelectedMaterials ? .normal : .disabled
                    ) {
                        appendSelectedMaterials()
                    }
                    .frame(width: 118)
                }
                .frame(height: BakingTouchTarget.secondaryAction)
            }
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.sm)
    }

    private var notesCard: some View {
        BakingSectionCard(title: BakingTerms.stepsFieldNotes) {
            BakingMultilineTextEditor(text: stepNotesBinding)
                .frame(minHeight: BakingComponentMetrics.popupNotesEditorMinHeight)
                .background(Color.clear)
                .padding(10)
                .bakingInsetSurface()
                .accessibilityLabel(BakingTerms.stepsTextBlockAccessibility)
                .padding(.horizontal, BakingSpace.md)
                .padding(.bottom, BakingSpace.md)
        }
    }

    private var currentStep: JournalStep {
        store.steps.first { $0.id == step.id } ?? step
    }

    private var stepNotesBinding: Binding<String> {
        Binding(
            get: { currentStep.notes },
            set: {
                var next = currentStep
                next.notes = $0
                store.updateStep(next)
            }
        )
    }

    private var selectedMaterials: [AllocatedRecipeItem] {
        store.allocatedItems(for: currentStep)
    }

    private var hasSelectedMaterials: Bool {
        !selectedMaterials.isEmpty
    }

    private func toggleMaterials() {
        withAnimation(BakingMotion.standard) {
            showingMaterials.toggle()
        }
    }

    private func toggleAssignment(_ item: RecipeItem) {
        if store.allocationPercentage(for: item.id, in: currentStep) > 0 {
            store.removeAssignedItem(item.id, from: currentStep)
        } else {
            store.assign(itemId: item.id, to: currentStep)
        }
    }

    private func appendSelectedMaterials() {
        let lines = selectedMaterials.map { allocated in
            "\(allocated.item.name)\(BakingFormat.compactWeight(allocated.weight, gramPrecision: allocated.item.tag == .yeast ? 1 : 0))"
        }
        appendNoteLines(lines, clearsMaterialAllocations: true)
    }

    private func appendNoteLines(_ lines: [String], clearsMaterialAllocations: Bool = false) {
        guard !lines.isEmpty else { return }

        let trimmedExisting = currentStep.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        var next = currentStep
        next.notes = trimmedExisting.isEmpty ? lines.joined(separator: "\n") : trimmedExisting + "\n" + lines.joined(separator: "\n")
        if clearsMaterialAllocations {
            next.materialAllocations = []
        }
        store.updateStep(next)
    }
}

private struct StepTextEditorSheetView: View {
    @EnvironmentObject private var store: RecipeStore
    let step: JournalStep
    let recipeKind: RecipeKind
    var isScrollEnabled = true
    var onDismiss: () -> Void
    var onContentHeightChange: (CGFloat) -> Void = { _ in }
    @State private var selectedCategory: StepCategory
    @State private var showingCategoryPicker = false
    @State private var showingStarterPicker = false
    @State private var selectedStarterID: UUID?
    @State private var showingMaterials = false
    @State private var showingDurationPicker = false
    @State private var showingTemperaturePicker = false

    init(
        step: JournalStep,
        recipeKind: RecipeKind,
        isScrollEnabled: Bool = true,
        onDismiss: @escaping () -> Void,
        onContentHeightChange: @escaping (CGFloat) -> Void = { _ in }
    ) {
        self.step = step
        self.recipeKind = recipeKind
        self.isScrollEnabled = isScrollEnabled
        self.onDismiss = onDismiss
        self.onContentHeightChange = onContentHeightChange
        _selectedCategory = State(initialValue: StepCategory.defaultCategory(for: step, recipeKind: recipeKind))
    }

    var body: some View {
        VStack(spacing: 0) {
            editorToolbar

            ScrollView {
                VStack(alignment: .leading, spacing: BakingLayout.cardStackSpacing) {
                    primaryControlsCard
                    if currentStep.foldPlan != nil {
                        StepFoldPlanCard(step: currentStep)
                    }
                    stepContentCard

                    notesEditorCard
                }
                .padding(.horizontal, BakingLayout.screenHorizontalInset)
                .padding(.top, BakingSpace.sm)
                .padding(.bottom, 34)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: StepEditorContentHeightPreferenceKey.self, value: proxy.size.height)
                    }
                )
            }
            .onPreferenceChange(StepEditorContentHeightPreferenceKey.self) { height in
                onContentHeightChange(height)
            }
            .scrollDisabled(!isScrollEnabled)
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.brandBackground)
        .animation(BakingMotion.standard, value: showingMaterials)
        .animation(BakingMotion.standard, value: showingStarterPicker)
        .animation(BakingMotion.standard, value: selectedCategory)
        .onAppear {
            normalizeSelectedCategoryIfNeeded()
        }
        .onChange(of: store.currentRecipeKind) { _, _ in
            normalizeSelectedCategoryIfNeeded()
        }
    }

    private var editorToolbar: some View {
        BakingTopActionRow(trailing: {
            BakingSystemIconButton(
                systemImage: "xmark",
                accessibilityLabel: BakingTerms.done,
                role: .secondary,
                size: .secondary,
                font: .caption.weight(.bold)
            ) {
                onDismiss()
            }
        })
    }

    private var primaryControlsCard: some View {
        VStack(spacing: 0) {
            StepPopupActionTableRow(title: BakingTerms.stepsFieldCategory) {
                Button {
                    showingCategoryPicker = true
                } label: {
                    BakingDropdownTrigger(title: selectedCategory.label)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.stepsFieldCategory)
                .popover(isPresented: $showingCategoryPicker, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                    BakingDropdownPopover(width: 176) {
                        ForEach(availableCategories) { category in
                            Button {
                                selectCategory(category)
                                showingCategoryPicker = false
                            } label: {
                                BakingDropdownRow(
                                    title: category.label,
                                    isSelected: selectedCategory == category,
                                    showsLeadingSlot: false
                                ) {
                                    EmptyView()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            PopupTableDivider()

            StepPopupNameTableRow(
                title: BakingTerms.stepsFieldName,
                text: stepTextBinding(\.name),
                placeholder: BakingTerms.stepsFieldName
            )

            if !isStarterCategory {
                PopupTableDivider()

                StepPopupActionTableRow(title: BakingTerms.stepsFieldTemperature) {
                    Button {
                        showingTemperaturePicker = true
                    } label: {
                        StepCompactValueButton(systemImage: "thermometer.medium", text: temperatureText, tint: .waterText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(BakingTerms.stepsFieldTemperature)
                    .popover(isPresented: $showingTemperaturePicker, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                        TemperaturePopoverView(
                            value: stepNumberBinding(\.temperature, fallback: defaultTemperatureValue),
                            unit: stepTemperatureUnitBinding
                        )
                        .presentationCompactAdaptation(.popover)
                    }
                }

                PopupTableDivider()

                if currentStep.foldPlan == nil {
                    StepPopupActionTableRow(title: BakingTerms.stepsFieldDuration) {
                        Button {
                            showingDurationPicker = true
                        } label: {
                            StepCompactValueButton(systemImage: "timer", text: durationText, tint: .brandPrimary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(BakingTerms.stepsFieldDuration)
                        .popover(isPresented: $showingDurationPicker, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                            DurationPopoverView(totalMinutes: durationMinutesBinding)
                                .presentationCompactAdaptation(.popover)
                        }
                    }
                }
            }
        }
        .bakingCard()
    }

    @ViewBuilder
    private var stepContentCard: some View {
        switch selectedCategory {
        case .makeStarter:
            starterPickerCard
        case .prepWork, .mixing, .batterMixing:
            materialControlsCard
        case .shaping:
            shapingDoughDividerCard
        case .fermentation, .baking, .proofing, .cooling, .custom:
            EmptyView()
        }
    }

    private var materialControlsCard: some View {
        VStack(spacing: 0) {
            StepPopupActionTableRow(title: BakingTerms.stepsMaterialsSection) {
                Button {
                    toggleMaterials()
                } label: {
                    BakingSystemIconButtonLabel(
                        systemImage: "checklist",
                        visualSize: BakingTouchTarget.secondaryActionVisual,
                        font: .caption.weight(.semibold)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.stepsMaterialsSection)
            }

            if showingMaterials {
                PopupTableDivider()

                materialPickerContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .bakingCard()
    }

    private var shapingDoughDividerCard: some View {
        BakingSectionCard(title: BakingTerms.stepsDoughSplitSection, headerBottomPadding: 0) {
            VStack(spacing: 0) {
                StepPopupActionTableRow(title: BakingTerms.stepsDoughTotalWeight) {
                    BakingNumericValue(
                        value: totalDoughWeightParts.value,
                        unit: totalDoughWeightParts.unit,
                        kind: .tableNumber,
                        numericKind: .weight
                    )
                }

                PopupTableDivider()

                StepPopupActionTableRow(title: BakingTerms.stepsDoughPieceCount) {
                    StepPopupCountInput(
                        value: shapingPieceCountBinding,
                        accessibilityLabel: BakingTerms.stepsDoughPieceCount
                    )
                }

                PopupTableDivider()

                StepPopupActionTableRow(title: BakingTerms.stepsDoughEachWeight) {
                    BakingNumericValue(
                        value: doughPieceWeightParts.value,
                        unit: doughPieceWeightParts.unit,
                        kind: .tableNumber,
                        numericKind: .weight
                    )
                }
            }
        }
    }

    private var starterPickerCard: some View {
        VStack(spacing: 0) {
            StepPopupActionTableRow(title: BakingTerms.stepsStarterPickerSection) {
                Button {
                    toggleStarterPicker()
                } label: {
                    BakingSystemIconButtonLabel(
                        systemImage: "checklist",
                        visualSize: BakingTouchTarget.secondaryActionVisual,
                        font: .caption.weight(.semibold)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.stepsStarterPickerAccessibility)
            }

            if showingStarterPicker {
                PopupTableDivider()

                starterPickerContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .bakingCard()
    }

    private var starterPickerContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if starterItems.isEmpty {
                Text(BakingTerms.stepsStarterPickerEmpty)
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(Color.brandSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, BakingSpace.sm)
            } else {
                VStack(spacing: BakingSpace.sm) {
                    ForEach(starterItems) { item in
                        StepStarterSelectionCard(
                            item: item,
                            componentLines: starterComponentLines(for: item),
                            isSelected: selectedStarterID == item.id
                        ) {
                            selectedStarterID = item.id
                        }
                    }
                }

                HStack {
                    Spacer()

                    BakingActionButton(
                        title: BakingTerms.stepsInsertSelectedMaterials,
                        accessibilityLabel: BakingTerms.stepsInsertSelectedMaterials,
                        role: .primary,
                        state: selectedStarter == nil ? .disabled : .normal
                    ) {
                        appendSelectedStarterComponents()
                    }
                    .frame(width: 118)
                }
                .frame(height: BakingTouchTarget.secondaryAction)
            }
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.sm)
    }

    private var materialPickerContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if store.items.isEmpty {
                Text(BakingTerms.stepsMaterialsEmpty)
                    .font(BakingTypography.appPrimaryText)
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

                HStack {
                    Spacer()

                    BakingActionButton(
                        title: BakingTerms.stepsInsertSelectedMaterials,
                        accessibilityLabel: BakingTerms.stepsInsertSelectedMaterials,
                        role: .primary,
                        state: hasSelectedMaterials ? .normal : .disabled
                    ) {
                        appendSelectedMaterials()
                    }
                    .frame(width: 118)
                }
                .frame(height: BakingTouchTarget.secondaryAction)
            }
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.sm)
    }

    private var notesEditorCard: some View {
        BakingSectionCard(title: BakingTerms.stepsFieldNotes) {
            BakingMultilineTextEditor(text: stepNotesBinding)
                .frame(minHeight: BakingComponentMetrics.popupNotesEditorMinHeight)
                .background(Color.clear)
                .padding(10)
                .bakingInsetSurface()
                .accessibilityLabel(BakingTerms.stepsTextBlockAccessibility)
                .padding(.horizontal, BakingSpace.md)
                .padding(.bottom, BakingSpace.md)
        }
    }

    private func toggleMaterials() {
        withAnimation(BakingMotion.standard) {
            showingMaterials.toggle()
        }
    }

    private func toggleStarterPicker() {
        withAnimation(BakingMotion.standard) {
            showingStarterPicker.toggle()
        }
    }

    private func selectCategory(_ category: StepCategory) {
        selectedCategory = category
        showingMaterials = false
        showingStarterPicker = false
        var next = currentStep
        next.type = category.stepType
        if shouldSyncNameWithCategory {
            next.name = category.label
        }
        store.updateStep(next)
    }

    private var availableCategories: [StepCategory] {
        StepCategory.available(for: store.currentRecipeKind)
    }

    private func normalizeSelectedCategoryIfNeeded() {
        guard !availableCategories.contains(selectedCategory) else { return }
        selectedCategory = StepCategory.defaultCategory(for: currentStep, recipeKind: store.currentRecipeKind)
    }

    private var currentStep: JournalStep {
        store.steps.first { $0.id == step.id } ?? step
    }

    private var isStarterCategory: Bool {
        selectedCategory == .makeStarter
    }

    private var starterItems: [RecipeItem] {
        store.items.filter { $0.category == .starter }
    }

    private var selectedStarter: RecipeItem? {
        guard let selectedStarterID else { return nil }
        return starterItems.first { $0.id == selectedStarterID }
    }

    private var shouldSyncNameWithCategory: Bool {
        let trimmedName = currentStep.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return true }
        if StepCategory.allCases.map(\.label).contains(trimmedName) { return true }
        return trimmedName == generatedStepName
    }

    private var generatedStepName: String {
        guard let index = store.steps.firstIndex(where: { $0.id == currentStep.id }) else {
            return BakingTerms.stepDefaultName(store.steps.count + 1)
        }
        return BakingTerms.stepDefaultName(index + 1)
    }

    private var totalDoughWeightParts: BakingFormattedUnitValue {
        BakingFormat.weightParts(store.summary.doughWeight)
    }

    private var doughPieceWeightParts: BakingFormattedUnitValue {
        BakingFormat.weightParts(store.summary.doughWeight / shapingPieceCount)
    }

    private var shapingPieceCount: Double {
        max(1, (currentStep.shapingPieceCount ?? 1).rounded())
    }

    private var shapingPieceCountBinding: Binding<Double> {
        Binding(
            get: { shapingPieceCount },
            set: { value in
                var next = currentStep
                next.shapingPieceCount = max(1, value.rounded())
                store.updateStep(next)
            }
        )
    }

    private var stepNotesBinding: Binding<String> {
        Binding(
            get: { currentStep.notes },
            set: {
                var next = currentStep
                next.notes = $0
                store.updateStep(next)
            }
        )
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

    private var durationText: String {
        guard currentStep.timeValue != nil else { return BakingTerms.stepsNoValue }
        return StepFormatting.compactDuration(minutes: store.stepMinutes(currentStep))
    }

    private var durationMinutesBinding: Binding<Int> {
        Binding(
            get: { Int(store.stepMinutes(currentStep).rounded()) },
            set: { updateDuration(minutes: $0) }
        )
    }

    private var temperatureText: String {
        guard let temperature = currentStep.temperature else { return BakingTerms.stepsNoValue }
        let value = BakingFormat.number(temperature, precision: 0)
        return "\(value)\(currentStep.temperatureUnit?.rawValue ?? TemperatureUnit.fahrenheit.rawValue)"
    }

    private func updateDuration(minutes: Int) {
        var next = currentStep
        next.timeUnit = .min
        next.timeValue = Double(max(0, minutes))
        store.updateStep(next)
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

    private var defaultTemperatureValue: Double {
        (currentStep.temperatureUnit ?? .fahrenheit) == .fahrenheit ? 350 : 180
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

    private var selectedMaterials: [AllocatedRecipeItem] {
        store.allocatedItems(for: currentStep)
    }

    private var hasSelectedMaterials: Bool {
        !selectedMaterials.isEmpty
    }

    private func toggleAssignment(_ item: RecipeItem) {
        if store.allocationPercentage(for: item.id, in: currentStep) > 0 {
            store.removeAssignedItem(item.id, from: currentStep)
        } else {
            store.assign(itemId: item.id, to: currentStep)
        }
    }

    private func appendSelectedMaterials() {
        let lines = selectedMaterials.map { allocated in
            "\(allocated.item.name)\(BakingFormat.compactWeight(allocated.weight, gramPrecision: allocated.item.tag == .yeast ? 1 : 0))"
        }
        appendNoteLines(lines, clearsMaterialAllocations: true)
        showingMaterials = false
    }

    private func appendSelectedStarterComponents() {
        guard let selectedStarter else { return }
        appendNoteLines(starterComponentLines(for: selectedStarter).map(\.noteText), clearsMaterialAllocations: true)
        showingStarterPicker = false
    }

    private func appendNoteLines(_ lines: [String], clearsMaterialAllocations: Bool = false) {
        guard !lines.isEmpty else { return }

        let trimmedExisting = currentStep.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        var next = currentStep
        next.notes = trimmedExisting.isEmpty ? lines.joined(separator: "\n") : trimmedExisting + "\n" + lines.joined(separator: "\n")
        if clearsMaterialAllocations {
            next.materialAllocations = []
        }
        store.updateStep(next)
    }

    private func starterComponentLines(for item: RecipeItem) -> [StepStarterComponentLine] {
        var lines = [
            StepStarterComponentLine(kind: .flour, name: BakingTerms.flour, weight: store.flourContribution(item), icon: .flour),
            StepStarterComponentLine(kind: .water, name: BakingTerms.water, weight: store.starterBaseWater(item), icon: .water)
        ]

        if let yeastWeight = item.starterYeastWeight, yeastWeight > 0 {
            lines.append(StepStarterComponentLine(kind: .yeast, name: BakingTerms.yeast, weight: yeastWeight, icon: .yeast))
        }

        let eggWeight = store.starterEggWeight(item)
        if eggWeight > 0 {
            lines.append(StepStarterComponentLine(kind: .egg, name: BakingTerms.egg, weight: eggWeight, icon: .egg))
        }

        return lines
    }
}

private enum StepCategory: CaseIterable, Identifiable {
    case makeStarter
    case prepWork
    case mixing
    case batterMixing
    case fermentation
    case shaping
    case proofing
    case baking
    case cooling
    case custom

    var id: Self { self }

    var label: String {
        switch self {
        case .makeStarter: BakingTerms.stepsCategoryMakeStarter
        case .prepWork: BakingTerms.stepsCategoryPrepWork
        case .mixing: BakingTerms.stepsCategoryMixing
        case .batterMixing: BakingTerms.stepsCategoryBatterMixing
        case .fermentation: BakingTerms.stepsCategoryFermentation
        case .baking: BakingTerms.stepsCategoryBaking
        case .shaping: BakingTerms.stepsCategoryShaping
        case .proofing: BakingTerms.stepsCategoryProofing
        case .cooling: BakingTerms.stepsCategoryCooling
        case .custom: BakingTerms.stepsCategoryCustom
        }
    }

    var icon: BakingIcon {
        switch self {
        case .makeStarter: .starter
        case .prepWork: .other
        case .mixing, .batterMixing: .mixing
        case .fermentation: .fermentation
        case .baking: .baking
        case .shaping: .shaping
        case .proofing: .timer
        case .cooling: .rest
        case .custom: .other
        }
    }

    var stepType: StepType {
        switch self {
        case .makeStarter, .prepWork:
            .prep
        case .mixing, .batterMixing:
            .mixing
        case .fermentation:
            .fermentation
        case .baking:
            .baking
        case .shaping:
            .shaping
        case .proofing:
            .rest
        case .cooling:
            .rest
        case .custom:
            .other
        }
    }

    static func available(for recipeKind: RecipeKind) -> [StepCategory] {
        switch recipeKind {
        case .chiffon:
            [.prepWork, .batterMixing, .baking, .cooling, .custom]
        case .toast, .countryBread, .custom:
            [.makeStarter, .prepWork, .mixing, .fermentation, .shaping, .proofing, .baking, .custom]
        }
    }

    static func defaultCategory(for step: JournalStep, recipeKind: RecipeKind) -> StepCategory {
        let availableCategories = available(for: recipeKind)
        let trimmedName = step.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let namedCategory = availableCategories.first(where: { $0.label == trimmedName }) {
            return namedCategory
        }

        let preferredCategory: StepCategory = switch recipeKind {
        case .chiffon:
            switch step.type {
            case .prep: .prepWork
            case .mixing: .batterMixing
            case .fermentation: .custom
            case .rest: .cooling
            case .shaping: .custom
            case .baking: .baking
            case .other: .custom
            }
        case .toast, .countryBread, .custom:
            switch step.type {
            case .prep: .prepWork
            case .mixing: .mixing
            case .fermentation: .fermentation
            case .rest: .proofing
            case .shaping: .shaping
            case .baking: .baking
            case .other: .custom
            }
        }

        return availableCategories.contains(preferredCategory) ? preferredCategory : (availableCategories.first ?? .custom)
    }
}

private enum StepStarterComponentKind {
    case flour
    case water
    case yeast
    case egg
}

private struct StepStarterComponentLine: Identifiable {
    let id = UUID()
    let kind: StepStarterComponentKind
    let name: String
    let weight: Double
    let icon: BakingIcon

    var weightText: String {
        BakingFormat.weight(weight)
    }

    var noteText: String {
        "\(name)\(weightText)"
    }
}

private struct StepStarterSelectionCard: View {
    let item: RecipeItem
    let componentLines: [StepStarterComponentLine]
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: BakingSpace.sm) {
                header

                if isSelected {
                    VStack(spacing: BakingSpace.xs) {
                        ForEach(componentLines) { line in
                            StepStarterComponentRow(line: line, palette: item.materialPalette)
                        }
                    }
                    .padding(BakingSpace.sm)
                    .bakingInsetSurface()
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(BakingSpace.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .bakingMaterialCard(palette: item.materialPalette, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.name)
        .accessibilityValue(isSelected ? BakingTerms.stepsStarterPickerAccessibility : "")
    }

    private var header: some View {
        HStack(spacing: BakingSpace.sm) {
            BakingIconView(icon: .starter, size: BakingTouchTarget.inlineIconGlyph, color: item.materialPalette.tint)
                .frame(width: BakingTouchTarget.inlineIconSurface, height: BakingTouchTarget.inlineIconSurface)
                .background(item.materialPalette.iconSurface)
                .clipShape(RoundedRectangle(cornerRadius: BakingComponentMetrics.inlineIconCornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: BakingSpace.xs) {
                Text(item.name)
                    .bakingLabelStyle(.inputLabel)
                    .lineLimit(1)

                Text(BakingTerms.formulaStarterDetail(
                    flour: BakingFormat.weight(componentWeight(.flour)),
                    water: BakingFormat.weight(componentWeight(.water))
                ))
                .bakingLabelStyle(.helperText)
                .lineLimit(1)
            }

            Spacer(minLength: BakingSpace.sm)

            if isSelected {
                BakingIconView(icon: .complete, size: BakingTouchTarget.dropdownIconGlyph, color: item.materialPalette.tint)
            }
        }
    }

    private func componentWeight(_ kind: StepStarterComponentKind) -> Double {
        componentLines.first { $0.kind == kind }?.weight ?? 0
    }
}

private struct StepStarterComponentRow: View {
    let line: StepStarterComponentLine
    let palette: MaterialPalette

    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            BakingIconView(icon: line.icon, size: 13, color: palette.tint)
                .frame(width: 18, height: 18)
                .background(palette.iconSurface)
                .clipShape(RoundedRectangle(cornerRadius: BakingComponentMetrics.compactIconCornerRadius, style: .continuous))

            BakingLabel(text: line.name, role: .fieldLabel)

            Spacer(minLength: BakingSpace.sm)

            Text(line.weightText)
                .font(BakingTypography.tableNumber)
                .foregroundStyle(Color.brandText)
                .lineLimit(1)
        }
        .frame(minHeight: BakingTouchTarget.dropdownIconSurface)
    }
}

private struct StepEditorContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct StepPopupNameTableRow: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    @State private var isFocused = false

    var body: some View {
        HStack(alignment: .center, spacing: BakingSpace.sm) {
            BakingLabel(text: title, role: .popupRowLabel)
                .lineLimit(1)
                .frame(width: BakingComponentMetrics.popupLabelWidth, alignment: .leading)

            Spacer(minLength: BakingSpace.sm)

            BakingInlineTextField(
                text: $text,
                placeholder: placeholder,
                isFocused: $isFocused,
                color: UIColor(Color.brandText),
                font: BakingTypography.popupInputValueUIFont,
                textAlignment: .right
            )
            .bakingFittedInputField(.long, kind: isFocused ? .focused : .field)
        }
        .padding(.horizontal, BakingSpace.md)
        .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
    }
}

private struct StepPopupCountInput: View {
    @Binding var value: Double
    let accessibilityLabel: String
    @State private var isFocused = false

    var body: some View {
        BakingNumericTextField(
            value: $value,
            fractionDigits: 0...0,
            minValue: 1,
            isFocused: $isFocused,
            color: UIColor(Color.brandText),
            font: BakingTypography.popupNumericInputValueUIFont
        )
        .frame(width: 58)
        .padding(.horizontal, BakingSpace.sm)
        .frame(width: BakingComponentMetrics.popupNumericFieldWidth, height: BakingComponentMetrics.popupInputHeight)
        .bakingSurface(isFocused ? .focused : .field)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct StepPopupActionTableRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: BakingSpace.sm) {
            BakingLabel(text: title, role: .popupRowLabel)
                .lineLimit(1)

            Spacer(minLength: BakingSpace.sm)

            content()
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.xs)
        .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
    }
}

private struct StepFoldPlanCard: View {
    @EnvironmentObject private var store: RecipeStore
    let step: JournalStep
    @State private var showingFrequencyPicker = false

    var body: some View {
        if let foldPlan = currentStep.foldPlan {
            BakingSectionCard(title: BakingTerms.stepsFoldPlanSection, headerBottomPadding: 0) {
                VStack(spacing: 0) {
                    StepPopupActionTableRow(title: BakingTerms.stepsFoldCount) {
                        StepPopupCountInput(
                            value: foldCountBinding,
                            accessibilityLabel: BakingTerms.stepsFoldCount
                        )
                    }

                    PopupTableDivider()

                    StepPopupActionTableRow(title: BakingTerms.stepsFoldFrequency) {
                        Button {
                            showingFrequencyPicker = true
                        } label: {
                            StepCompactValueButton(
                                systemImage: "timer",
                                text: StepFormatting.compactDuration(minutes: Double(foldPlan.normalizedIntervalMinutes)),
                                tint: .brandPrimary
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(BakingTerms.stepsFoldFrequency)
                        .popover(isPresented: $showingFrequencyPicker, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                            DurationPopoverView(totalMinutes: foldIntervalMinutesBinding)
                                .presentationCompactAdaptation(.popover)
                        }
                    }

                    PopupTableDivider()

                    StepPopupActionTableRow(title: BakingTerms.stepsFoldTotalDuration) {
                        Text(BakingFormat.duration(minutes: Double(foldPlan.totalMinutes)))
                            .font(BakingTypography.tableNumber)
                            .foregroundStyle(Color.brandText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                }
            }
        }
    }

    private var currentStep: JournalStep {
        store.steps.first { $0.id == step.id } ?? step
    }

    private var foldCountBinding: Binding<Double> {
        Binding(
            get: { Double(currentStep.foldPlan?.normalizedTargetCount ?? 1) },
            set: { value in
                updateFoldPlan { plan in
                    plan.targetCount = max(1, Int(value.rounded()))
                }
            }
        )
    }

    private var foldIntervalMinutesBinding: Binding<Int> {
        Binding(
            get: { currentStep.foldPlan?.normalizedIntervalMinutes ?? 30 },
            set: { value in
                updateFoldPlan { plan in
                    plan.intervalMinutes = max(1, value)
                }
            }
        )
    }

    private func updateFoldPlan(_ update: (inout StepFoldPlan) -> Void) {
        var next = currentStep
        var foldPlan = next.foldPlan ?? StepFoldPlan(targetCount: 4, intervalMinutes: 30)
        update(&foldPlan)
        next.foldPlan = StepFoldPlan(
            targetCount: foldPlan.normalizedTargetCount,
            intervalMinutes: foldPlan.normalizedIntervalMinutes
        )
        store.updateStep(next)
    }
}

private struct StepEditorSheetView: View {
    @EnvironmentObject private var store: RecipeStore
    let step: JournalStep
    @Binding var presentationDetent: PresentationDetent
    @State private var materialsExpanded = false
    @State private var notesExpanded = false
    @State private var showingDurationPicker = false
    @State private var showingTemperaturePicker = false

    init(step: JournalStep, presentationDetent: Binding<PresentationDetent>) {
        self.step = step
        _presentationDetent = presentationDetent
        _materialsExpanded = State(initialValue: step.materialAllocations.contains { $0.percentage > 0 })
        _notesExpanded = State(initialValue: !step.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BakingLayout.cardStackSpacing) {
                    primaryControlsCard
                    if currentStep.foldPlan != nil {
                        StepFoldPlanCard(step: currentStep)
                    }
                    materialsCard
                    notesCard
                }
                .padding(.horizontal, BakingLayout.screenHorizontalInset)
                .padding(.top, BakingSpace.sm)
                .padding(.bottom, 34)
            }
            .background(Color.brandBackground)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var primaryControlsCard: some View {
        HStack(spacing: BakingSpace.sm) {
            InlineNameField(
                text: stepTextBinding(\.name),
                placeholder: currentStep.type.label,
                font: BakingTypography.appPrimaryText,
                height: 42
            )
                .accessibilityLabel(BakingTerms.stepsFieldName)

            Spacer(minLength: 0)

            if showsTemperatureField {
                Button {
                    showingTemperaturePicker = true
                } label: {
                    StepCompactValueButton(systemImage: "thermometer.medium", text: temperatureText, tint: .waterText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.stepsFieldTemperature)
                .popover(isPresented: $showingTemperaturePicker, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                    TemperaturePopoverView(
                        value: stepNumberBinding(\.temperature, fallback: 0),
                        unit: currentStep.type == .baking ? stepTemperatureUnitBinding : nil
                    )
                    .presentationCompactAdaptation(.popover)
                }
            }

            if currentStep.foldPlan == nil {
                Button {
                    showingDurationPicker = true
                } label: {
                    StepCompactValueButton(systemImage: "timer", text: durationText, tint: .brandPrimary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.stepsFieldDuration)
                .popover(isPresented: $showingDurationPicker, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                    DurationPopoverView(totalMinutes: durationMinutesBinding)
                        .presentationCompactAdaptation(.popover)
                }
            }
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.xs)
    }

    private var materialsCard: some View {
        VStack(alignment: .leading, spacing: materialsExpanded ? 10 : 0) {
            BakingDisclosureHeader(
                title: BakingTerms.stepsMaterialsSection,
                value: assignedMaterialCountText,
                systemImage: "checklist",
                isExpanded: materialsExpanded
            ) {
                withAnimation(BakingMotion.standard) {
                    materialsExpanded.toggle()
                }
            }

            if materialsExpanded {
                HStack {
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
                .frame(height: BakingTouchTarget.secondaryAction)

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
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.xs)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: notesExpanded ? 8 : 0) {
            BakingDisclosureHeader(
                title: BakingTerms.stepsFieldNotes,
                value: notesValueText,
                showsValue: false,
                systemImage: "note.text",
                isExpanded: notesExpanded
            ) {
                withAnimation(BakingMotion.standard) {
                    notesExpanded.toggle()
                }
            }

            if notesExpanded {
                BakingMultilineTextEditor(text: stepTextBinding(\.notes))
                    .frame(minHeight: 112)
                    .padding(8)
                    .bakingInsetSurface()
                    .accessibilityLabel(BakingTerms.stepsFieldNotes)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.xs)
    }

    private var currentStep: JournalStep {
        store.steps.first { $0.id == step.id } ?? step
    }

    private var durationText: String {
        StepFormatting.compactDuration(minutes: store.stepMinutes(currentStep))
    }

    private var durationMinutesBinding: Binding<Int> {
        Binding(
            get: { Int(store.stepMinutes(currentStep).rounded()) },
            set: { updateDuration(minutes: $0) }
        )
    }

    private var temperatureText: String {
        let value = BakingFormat.number(currentStep.temperature ?? 0, precision: 0)
        return currentStep.type == .baking ? "\(value)\(currentStep.temperatureUnit?.rawValue ?? TemperatureUnit.fahrenheit.rawValue)" : "\(value)°"
    }

    private var showsTemperatureField: Bool {
        currentStep.type == .fermentation || currentStep.type == .baking
    }

    private var assignedMaterialCountText: String {
        let count = store.allocatedItems(for: currentStep).count
        return count == 0 ? BakingTerms.stepsNoValue : BakingTerms.stepsAssignedCount(count)
    }

    private var notesValueText: String {
        currentStep.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? BakingTerms.stepsNoValue : currentStep.notes
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

    private func updateDuration(minutes: Int) {
        var next = currentStep
        next.timeUnit = .min
        next.timeValue = Double(max(0, minutes))
        store.updateStep(next)
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
                        BakingDropdownRow(
                            title: method.label,
                            isSelected: selection == method,
                            showsLeadingSlot: false
                        ) {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct StepCompactValueButton: View {
    let systemImage: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.semibold))
            Text(text)
                .font(BakingTypography.appSecondaryText.monospacedDigit().weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
        .foregroundStyle(tint)
        .frame(width: 76, height: 42)
        .bakingSurface(.inputSurface)
    }
}

private struct TemperaturePopoverView: View {
    @Binding var value: Double
    var unit: Binding<TemperatureUnit>?

    var body: some View {
        VStack(spacing: BakingSpace.sm) {
            temperatureScroller

            if let unit {
                Divider()
                    .overlay(BakingSurfaceTheme.separator)

                Picker(BakingTerms.stepsTemperatureUnit, selection: convertedUnitBinding(unit)) {
                    ForEach(TemperatureUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .tint(.brandPrimary)
                .accessibilityLabel(BakingTerms.stepsFieldTemperature)
            }
        }
        .padding(.horizontal, BakingSpace.sm)
        .padding(.vertical, BakingSpace.sm)
        .bakingPopoverSurface(width: BakingComponentMetrics.temperaturePopoverWidth)
    }

    private var temperatureScroller: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: BakingSpace.xs) {
                    ForEach(temperatureValues, id: \.self) { option in
                        Button {
                            withAnimation(BakingMotion.quick) {
                                value = Double(option)
                            }
                        } label: {
                            Text("\(option)")
                                .font(BakingTypography.tableNumber)
                                .foregroundStyle(isSelected(option) ? Color.brandPrimary : Color.brandText)
                                .frame(maxWidth: .infinity)
                                .frame(height: BakingComponentMetrics.temperatureOptionHeight)
                                .background {
                                    if isSelected(option) {
                                        RoundedRectangle(cornerRadius: BakingRadius.chip, style: .continuous)
                                            .fill(BakingSurfaceTheme.theme(for: .selected).background)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: BakingRadius.chip, style: .continuous)
                                                    .stroke(BakingSurfaceTheme.theme(for: .selected).stroke, lineWidth: 0.6)
                                            }
                                    }
                                }
                        }
                        .buttonStyle(BakingPressFeedbackButtonStyle())
                        .id(option)
                    }
                }
                .padding(.vertical, BakingSpace.xs)
            }
            .frame(height: BakingComponentMetrics.temperatureScrollerHeight)
            .onAppear {
                scrollToCurrent(proxy)
            }
            .onChange(of: value) { _, _ in
                scrollToCurrent(proxy)
            }
            .onChange(of: unit?.wrappedValue) { _, _ in
                scrollToCurrent(proxy)
            }
        }
    }

    private func scrollToCurrent(_ proxy: ScrollViewProxy) {
        let roundedValue = Int(value.rounded())
        let target: Int
        if temperatureValues.contains(roundedValue) {
            target = roundedValue
        } else {
            target = temperatureValues.min(by: { abs($0 - roundedValue) < abs($1 - roundedValue) }) ?? roundedValue
        }

        DispatchQueue.main.async {
            withAnimation(BakingMotion.quick) {
                proxy.scrollTo(target, anchor: .center)
            }
        }
    }

    private var temperatureValues: [Int] {
        let current = Int(value.rounded())
        let unitValue = unit?.wrappedValue
        let range: ClosedRange<Int>
        let step: Int
        if unitValue == .fahrenheit {
            range = 150...500
            step = 5
        } else if unitValue == .celsius {
            range = 20...260
            step = 5
        } else {
            range = 16...40
            step = 1
        }
        let base = stride(from: range.lowerBound, through: range.upperBound, by: step).map { $0 }
        guard !base.contains(current), range.contains(current) else { return base }
        return (base + [current]).sorted()
    }

    private func isSelected(_ option: Int) -> Bool {
        Int(value.rounded()) == option
    }

    private func convertedUnitBinding(_ unit: Binding<TemperatureUnit>) -> Binding<TemperatureUnit> {
        Binding(
            get: { unit.wrappedValue },
            set: { nextUnit in
                guard nextUnit != unit.wrappedValue else { return }
                switch (unit.wrappedValue, nextUnit) {
                case (.fahrenheit, .celsius):
                    value = ((value - 32) * 5 / 9).rounded()
                case (.celsius, .fahrenheit):
                    value = (value * 9 / 5 + 32).rounded()
                default:
                    break
                }
                unit.wrappedValue = nextUnit
            }
        )
    }
}

private struct DurationPopoverView: View {
    @Binding var totalMinutes: Int
    @State private var interval: TimeInterval = 0
    @State private var hasSyncedInitialValue = false

    var body: some View {
        CountdownDurationPicker(interval: $interval)
            .frame(height: 180)
            .frame(width: BakingComponentMetrics.popoverMediumWidth)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .bakingPopoverSurface(width: BakingComponentMetrics.popoverMediumWidth)
            .onAppear {
                syncInitialValueIfNeeded()
            }
            .onChange(of: interval) { _, _ in
                persistInterval()
            }
            .onDisappear {
                persistInterval()
            }
    }

    private func syncInitialValueIfNeeded() {
        guard !hasSyncedInitialValue else { return }
        interval = TimeInterval(max(1, totalMinutes) * 60)
        hasSyncedInitialValue = true
    }

    private func persistInterval() {
        let minutes = Int((interval / 60).rounded())
        guard totalMinutes != minutes else { return }
        totalMinutes = minutes
    }
}

private struct CountdownDurationPicker: UIViewRepresentable {
    @Binding var interval: TimeInterval

    func makeCoordinator() -> Coordinator {
        Coordinator(interval: $interval)
    }

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .countDownTimer
        picker.preferredDatePickerStyle = .wheels
        picker.countDownDuration = max(60, interval)
        picker.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        let next = max(60, interval)
        if uiView.countDownDuration != next {
            uiView.countDownDuration = next
        }
    }

    final class Coordinator: NSObject {
        @Binding var interval: TimeInterval

        init(interval: Binding<TimeInterval>) {
            _interval = interval
        }

        @objc func changed(_ sender: UIDatePicker) {
            interval = sender.countDownDuration
        }
    }
}

private enum StepFormatting {
    static func compactDuration(minutes: Double) -> String {
        let parts = compactDurationParts(minutes: minutes)
        guard let unit = parts.unit else { return parts.value }
        return "\(parts.value)\(unit)"
    }

    static func compactDurationParts(minutes: Double) -> (value: String, unit: String?) {
        let total = Int(minutes.rounded())
        let hours = total / 60
        let minutes = total % 60
        if hours > 0, minutes > 0 {
            return ("\(hours):\(String(format: "%02d", minutes))", BakingTerms.stepsHourShort)
        }
        if hours > 0 { return ("\(hours)", BakingTerms.stepsHourShort) }
        return ("\(minutes)", BakingTerms.stepsMinuteShort)
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
                    color: palette.tint
                )
                .frame(width: 18, height: 18)
                .background(palette.iconSurface)
                .clipShape(RoundedRectangle(cornerRadius: BakingComponentMetrics.compactIconCornerRadius, style: .continuous))

                Text(String(item.name.prefix(3)))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)
            }

            Text(weightText)
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(palette.text)

            Text(statusText)
                .font(BakingTypography.appSecondaryText)
                .foregroundStyle(Color.brandSecondaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(width: BakingComponentMetrics.materialChipWidth, alignment: .leading)
        .background {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    (selected ? palette.selectedChipSurface : palette.chipSurface)
                    palette.tint.opacity(selected ? 0.22 : 0.14)
                        .frame(width: proxy.size.width * usedRatio)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous)
                .stroke(selected ? palette.tint.opacity(0.34) : palette.chipStroke, lineWidth: selected ? 1 : 0.6)
        }
        .contentShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
        .onTapGesture {
            action()
        }
        .onLongPressGesture(minimumDuration: 0.35) {
            draftPercentage = selected ? selectedPercentage : 100
            showingPercentagePicker = true
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(item.name)
        .accessibilityValue(statusText)
        .popover(isPresented: $showingPercentagePicker, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
            MaterialPercentagePopover(
                item: item,
                percentage: $draftPercentage,
                maxPercentage: 100,
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

    private var usedRatio: CGFloat {
        CGFloat(min(1, max(0, selectedPercentage / 100)))
    }

    private var weightText: String {
        let weight = selected ? store.allocatedWeight(for: item, percentage: selectedPercentage) : item.weight
        return BakingFormat.weight(weight, gramPrecision: item.tag == .yeast ? 1 : 0)
    }

    private var statusText: String {
        if selected {
            return BakingTerms.stepsAssignmentPercent(BakingFormat.number(selectedPercentage, precision: 0))
        }
        return BakingFormat.weight(item.weight, gramPrecision: item.tag == .yeast ? 1 : 0)
    }
}

private struct MaterialPercentagePopover: View {
    let item: RecipeItem
    @Binding var percentage: Double
    let maxPercentage: Double
    @Binding var isPresented: Bool
    let confirm: () -> Void
    @State private var weightFieldFocused = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BakingPercentagePickerControl(
                value: $percentage,
                maxValue: maxPercentage,
                precision: 1,
                tint: .brandPrimary,
                surface: BakingSurfaceTheme.theme(for: .inputSurface).background
            )

            HStack {
                Text(BakingTerms.stepsAddWeight)
                    .font(BakingTypography.appSecondaryText)
                    .foregroundStyle(Color.brandSecondaryText)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    BakingNumericTextField(
                        value: weightBinding,
                        fractionDigits: item.tag == .yeast ? 0...1 : 0...0,
                        isFocused: $weightFieldFocused,
                        color: UIColor(Color.brandText),
                        font: .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
                    )
                    .frame(width: 76)
                    .accessibilityLabel(BakingTerms.stepsAddWeightAccessibility)

                    Text(BakingTerms.unitGram)
                        .font(BakingTypography.rowMeta)
                        .foregroundStyle(Color.brandSecondaryText)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .bakingSurface(weightFieldFocused ? .focused : .inputSurface)
        }
        .padding(12)
        .bakingPopoverSurface(width: BakingComponentMetrics.popoverMediumWidth)
        .onDisappear {
            confirm()
        }
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
    private static let log = Logger(subsystem: "com.openbakery.bready", category: "StepsReorder")

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
