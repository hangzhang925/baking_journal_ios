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
    @State private var stepEditorDetent = PresentationDetent.height(560)
    @State private var showingNotesEditor = false

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
                        totalMinutes: store.totalStepMinutes(),
                        stepCount: store.steps.count
                    )

                    RecipeMaterialsRemainingCard()
                        .bakingCard()

                    stepTableSection

                    RecipeStepNotesDisplayCard {
                        showingNotesEditor = true
                    }
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
        .sheet(isPresented: $showingNotesEditor) {
            RecipeStepNotesEditorSheet()
                .environmentObject(store)
                .presentationDetents([.height(BakingPopupSheetMetrics.notesEditorDefaultHeight), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.brandBackground)
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
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(BakingTerms.stepsSectionTitle)
                    .bakingLabelStyle(.sectionHeader)

                Text(BakingTerms.stepsCount(store.steps.count))
                    .bakingLabelStyle(.helperText)
                    .foregroundStyle(Color.brandSecondaryText)

                Spacer()

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
            .padding(.horizontal, BakingSpace.md)
            .padding(.top, BakingSpace.md)
            .padding(.bottom, displayedSteps.isEmpty ? 0 : BakingSpace.xs)

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
                            Divider()
                                .overlay(BakingSurfaceTheme.separator)
                        }
                    }
                }
            }
        }
        .bakingCard()
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
        stepEditorDetent = .height(560)
        editingStepID = step.id
    }

    private func enterStepListEditing() {
        withAnimation(ReorderMotion.animation) {
            isStepListEditing = true
        }
    }

    @ViewBuilder
    private var stepEditorSheet: some View {
        if let editingStep {
            StepTextEditorSheetView(step: editingStep, presentationDetent: $stepEditorDetent)
            .id(editingStep.id)
            .environmentObject(store)
            .presentationDetents([.height(560), .large], selection: $stepEditorDetent)
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
    let totalMinutes: Double
    let stepCount: Int

    var body: some View {
        HStack(spacing: 0) {
            StepsOverviewMetricCell(
                title: BakingTerms.stepsTotalDuration,
                value: BakingFormat.duration(minutes: totalMinutes)
            )

            Divider()
                .overlay(BakingSurfaceTheme.separator)
                .padding(.vertical, BakingSpace.sm)

            StepsOverviewMetricCell(
                title: BakingTerms.stepsTableStep,
                value: "\(stepCount)"
            )
        }
        .frame(minHeight: 66)
        .bakingCard()
    }
}

private struct StepsOverviewMetricCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(BakingTypography.readOnlyLabel)
                .foregroundStyle(Color.brandSecondaryText)

            Text(value)
                .font(BakingTypography.tableNumber)
                .foregroundStyle(Color.brandText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, BakingSpace.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct RecipeMaterialsRemainingCard: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 10 : 0) {
            Button {
                withAnimation(BakingMotion.standard) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: BakingSpace.sm) {
                    Text(BakingTerms.formulaTableIngredient)
                        .font(BakingTypography.sectionTitle)
                        .foregroundStyle(Color.brandText)

                    Spacer(minLength: BakingSpace.sm)

                    Text(BakingTerms.stepsAssignedCount(store.items.count))
                        .font(BakingTypography.appSecondaryText.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color.brandSecondaryText)

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.brandPrimary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .frame(width: 18, height: 18)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(BakingTerms.formulaTableIngredient)
            .accessibilityValue(BakingTerms.stepsAssignedCount(store.items.count))

            if isExpanded {
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
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.xs)
    }
}

private struct RecipeStepNotesDisplayCard: View {
    @EnvironmentObject private var store: RecipeStore
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: BakingSpace.sm) {
                HStack(spacing: BakingSpace.sm) {
                    Text(BakingTerms.stepsPageNotes)
                        .font(BakingTypography.sectionTitle)
                        .foregroundStyle(Color.brandText)

                    Spacer(minLength: BakingSpace.sm)

                    BakingSystemIconButtonLabel(
                        systemImage: noteText.isEmpty ? "plus" : "pencil",
                        visualSize: BakingTouchTarget.secondaryActionVisual,
                        font: .caption.weight(.semibold)
                    )
                }
                .frame(minHeight: BakingTouchTarget.secondaryAction)

                if !noteText.isEmpty {
                    Text(noteText)
                        .font(BakingTypography.appPrimaryText)
                        .foregroundStyle(Color.brandText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, BakingSpace.xs)
                }
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.vertical, BakingSpace.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: BakingRadius.card, style: .continuous))
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .bakingCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(BakingTerms.stepsPageNotes)
        .accessibilityValue(noteText)
    }

    private var noteText: String {
        store.recipeOverallNotes.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct RecipeStepNotesEditorSheet: View {
    @EnvironmentObject private var store: RecipeStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                BakingTopActionRow(trailing: {
                    BakingSystemIconButton(
                        systemImage: "xmark",
                        accessibilityLabel: BakingTerms.done,
                        role: .secondary,
                        size: .secondary,
                        font: .caption.weight(.bold)
                    ) {
                        dismiss()
                    }
                })

                TextEditor(text: Binding(
                    get: { store.recipeOverallNotes },
                    set: { store.recipeOverallNotes = $0 }
                ))
                .font(BakingTypography.appPrimaryText)
                .foregroundStyle(Color.brandText)
                .frame(minHeight: BakingComponentMetrics.notesEditorMinHeight)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(10)
                .bakingInsetSurface()
                .accessibilityLabel(BakingTerms.stepsPageNotes)
                .padding(.horizontal, BakingLayout.screenHorizontalInset)
                .padding(.top, BakingSpace.sm)

                Spacer(minLength: 0)
            }
            .background(Color.brandBackground)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct StepMaterialReferenceChip: View {
    let item: RecipeItem

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
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(width: BakingComponentMetrics.materialChipWidth, alignment: .leading)
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
                Text(durationText)
                    .font(BakingTypography.tableNumber)
                    .foregroundStyle(Color.brandText)
                    .frame(width: Self.durationColumnWidth, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(temperatureText)
                    .font(BakingTypography.tableNumber)
                    .foregroundStyle(showsTemperatureField ? Color.brandText : Color.brandSecondaryText)
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
            .bakingReadOnlySurface()
            .frame(width: Self.iconColumnWidth, alignment: .center)
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

    private var durationText: String {
        guard currentStep.timeValue != nil else { return BakingTerms.stepsNoValue }
        return StepFormatting.compactDuration(minutes: store.stepMinutes(currentStep))
    }

    private var temperatureText: String {
        guard let temperature = currentStep.temperature else { return BakingTerms.stepsNoValue }
        let value = BakingFormat.number(temperature, precision: 0)
        return "\(value)\(currentStep.temperatureUnit?.rawValue ?? TemperatureUnit.fahrenheit.rawValue)"
    }
}

private struct StepTextEditorSheetView: View {
    @EnvironmentObject private var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    let step: JournalStep
    @Binding var presentationDetent: PresentationDetent
    @State private var showingMaterials = false
    @State private var showingDurationPicker = false
    @State private var showingTemperaturePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                editorToolbar

                ScrollView {
                    VStack(alignment: .leading, spacing: BakingLayout.cardStackSpacing) {
                        primaryControlsCard
                        materialControlsCard

                        notesEditorCard
                    }
                    .padding(.horizontal, BakingLayout.screenHorizontalInset)
                    .padding(.top, BakingSpace.sm)
                    .padding(.bottom, 34)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .background(Color.brandBackground)
        }
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
                dismiss()
            }
        })
    }

    private var primaryControlsCard: some View {
        VStack(spacing: 0) {
            StepPopupNameTableRow(
                title: BakingTerms.stepsFieldName,
                text: stepTextBinding(\.name),
                placeholder: BakingTerms.stepsFieldName
            )

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
        .bakingCard()
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
        TextEditor(text: stepNotesBinding)
            .font(BakingTypography.appPrimaryText)
            .foregroundStyle(Color.brandText)
            .frame(minHeight: 260)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .padding(10)
            .bakingInsetSurface()
            .accessibilityLabel(BakingTerms.stepsTextBlockAccessibility)
    }

    private func toggleMaterials() {
        withAnimation(BakingMotion.standard) {
            showingMaterials.toggle()
            presentationDetent = showingMaterials ? .large : .height(560)
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
            "\(allocated.item.name)\(BakingFormat.weight(allocated.weight, gramPrecision: allocated.item.tag == .yeast ? 1 : 0))"
        }
        guard !lines.isEmpty else { return }

        let trimmedExisting = currentStep.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        var next = currentStep
        next.notes = trimmedExisting.isEmpty ? lines.joined(separator: "\n") : trimmedExisting + "\n" + lines.joined(separator: "\n")
        next.materialAllocations = []
        store.updateStep(next)
        showingMaterials = false
        presentationDetent = .height(560)
    }
}

private struct StepPopupNameTableRow: View {
    let title: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(alignment: .center, spacing: BakingSpace.sm) {
            BakingLabel(text: title, role: .popupRowLabel)
                .lineLimit(1)
                .frame(width: BakingComponentMetrics.popupLabelWidth, alignment: .leading)

            Spacer(minLength: BakingSpace.sm)

            BakingInlineTextField(
                text: $text,
                placeholder: placeholder,
                color: UIColor(Color.brandText),
                font: BakingTypography.popupInputValueUIFont,
                textAlignment: .right
            )
            .bakingFittedInputField(.long)
        }
        .padding(.horizontal, BakingSpace.md)
        .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
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
                TextEditor(text: stepTextBinding(\.notes))
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(Color.brandText)
                    .frame(minHeight: 112)
                    .scrollContentBackground(.hidden)
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
            if let unit {
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

            temperatureScroller
        }
        .padding(.horizontal, BakingSpace.sm)
        .padding(.vertical, BakingSpace.sm)
        .bakingPopoverSurface(width: BakingComponentMetrics.temperaturePopoverWidth)
    }

    private var temperatureScroller: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: BakingSpace.sm) {
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
                                .bakingSurface(isSelected(option) ? .selected : .readOnly)
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
            .bakingSurface(.inputSurface)
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
