import SwiftUI

struct StepsView: View {
    @Environment(\.historySwipeSuppressionHandler) private var setHistorySwipeSuppressed
    @EnvironmentObject private var store: RecipeStore
    var embedded: Bool = false
    @State private var expandedStepId: UUID?
    @State private var materialsShelfExpanded = false
    @State private var previewSteps: [JournalStep]?
    @State private var activeStepID: UUID?
    @State private var activeStepFrame: CGRect?
    @State private var activeStepGrabOffset: CGSize = .zero
    @State private var activeStepLocation: CGPoint?
    @State private var stepRowFrames: [UUID: CGRect] = [:]
    @State private var openSwipeStepID: UUID?

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
                LazyVStack(alignment: .leading, spacing: 10) {
                    StepsOverviewCard(
                        totalMinutes: store.totalStepMinutes(),
                        stepCount: store.steps.count
                    )
                    .padding(.horizontal, 14)
                    .padding(.top, 6)

                    if !store.items.isEmpty {
                        MaterialsShelfCard(
                            isExpanded: $materialsShelfExpanded,
                            items: store.items
                        )
                        .padding(.horizontal, 14)
                    }

                    StepSectionHeader(stepCount: store.steps.count)
                        .padding(.horizontal, 14)

                    if !store.steps.isEmpty {
                        ForEach(displayedSteps) { step in
                            stepRow(step)
                                .opacity(activeStepID == step.id ? ReorderMotion.previewOpacity : 1)
                                .background(ReorderFrameReader(id: step.id, coordinateSpace: reorderCoordinateSpace))
                                .padding(.horizontal, 14)
                                .animation(ReorderMotion.animation, value: displayedSteps.map(\.id))
                        }
                    }
                }
                .padding(.bottom, 108)
            }
            .onPreferenceChange(ReorderRowFramePreferenceKey.self) { frames in
                stepRowFrames = frames
            }

            if let activeStep {
                StepCard(
                    step: activeStep,
                    isExpanded: expandedStepId == activeStep.id
                ) {
                    withAnimation(.easeInOut(duration: 0.24)) {
                        expandedStepId = expandedStepId == activeStep.id ? nil : activeStep.id
                    }
                }
                .frame(width: activeStepFrame?.width)
                .reorderLiftedAppearance()
                .offset(activeStepOverlayOffset)
                .allowsHitTesting(false)
                .zIndex(10)
            }
        }
        .coordinateSpace(name: reorderCoordinateSpace)
        .scrollDismissesKeyboard(.interactively)
        .background(Color.brandBackground)
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
                .accessibilityLabel("完成")
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
        let location = activeStepLocation ?? CGPoint(
            x: frame.midX,
            y: frame.midY
        )
        return CGSize(
            width: location.x - activeStepGrabOffset.width,
            height: location.y - activeStepGrabOffset.height
        )
    }

    private func stepRow(_ step: JournalStep) -> some View {
        BakingSwipeToDeleteRow(canDelete: activeStepID == nil) {
            store.removeStep(step)
        } onOpenChanged: { isOpen in
            updateOpenSwipeStep(step.id, isOpen: isOpen)
        } content: {
            StepCard(
                step: step,
                isExpanded: expandedStepId == step.id,
                reorderCoordinateSpace: canStartStepReorder(step) ? reorderCoordinateSpace : nil
            ) {
                withAnimation(.easeInOut(duration: 0.24)) {
                    expandedStepId = expandedStepId == step.id ? nil : step.id
                }
            } onReorderChanged: { drag in
                beginStepReorderIfNeeded(step, drag: drag)
                updateStepReorder(with: drag.location)
            } onReorderEnded: { drag in
                guard let drag else {
                    cancelStepReorder()
                    return
                }
                updateStepReorder(with: drag.location)
                commitStepReorder()
            }
        }
    }

    private func canStartStepReorder(_ step: JournalStep) -> Bool {
        openSwipeStepID == nil
            && expandedStepId != step.id
            && activeStepID == nil
    }

    private func updateOpenSwipeStep(_ stepID: UUID, isOpen: Bool) {
        if isOpen {
            openSwipeStepID = stepID
        } else if openSwipeStepID == stepID {
            openSwipeStepID = nil
        }
    }

    private func beginStepReorderIfNeeded(_ step: JournalStep, drag: DragGesture.Value) {
        guard activeStepID == nil else { return }
        let frame = stepRowFrames[step.id]
        activeStepID = step.id
        setHistorySwipeSuppressed(true)
        activeStepFrame = frame
        activeStepLocation = drag.location
        if let frame {
            activeStepGrabOffset = CGSize(
                width: drag.startLocation.x - frame.minX,
                height: drag.startLocation.y - frame.minY
            )
        }
        previewSteps = store.steps
    }

    private func updateStepReorder(with location: CGPoint) {
        activeStepLocation = location
        guard let activeStepID,
              let currentSteps = previewSteps,
              let movingStep = currentSteps.first(where: { $0.id == activeStepID }) else { return }

        var remainingSteps = currentSteps.filter { $0.id != activeStepID }
        let destination = remainingSteps.firstIndex { step in
            guard let frame = stepRowFrames[step.id] else { return false }
            return location.y < frame.midY
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
            activeStepID = nil
            activeStepFrame = nil
            activeStepLocation = nil
            previewSteps = nil
            activeStepGrabOffset = .zero
            setHistorySwipeSuppressed(false)
        }
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
                    Text("制作安排")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.brandText)
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
                .accessibilityLabel(store.isReadyToBake ? "改回草稿" : "标记为准备烘焙")
                .accessibilityHint(store.isReadyToBake ? "点按后配方会回到草稿状态" : "点按后配方可以开始烘焙")
                .popover(isPresented: $showingReadyTooltip, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                    ReadyToBakeTooltip(
                        title: store.isReadyToBake ? "已准备好" : "还不能烘焙",
                        message: store.readinessMessage
                    )
                    .presentationCompactAdaptation(.popover)
                }
            }

            HStack(spacing: 6) {
                StepsMetricPill(
                    title: "总时长",
                    value: BakingFormat.duration(minutes: totalMinutes),
                    accent: .brandPrimary
                )
                StepsMetricPill(
                    title: "步骤",
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
        Image(systemName: iconName)
            .font(.title3.weight(.bold))
            .foregroundStyle(foregroundColor)
            .frame(width: BakingTouchTarget.iconButton, height: BakingTouchTarget.iconButton)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous)
                .stroke(borderColor, lineWidth: 0.8)
        }
        .shadow(color: shadowColor, radius: isReady || canBecomeReady ? 8 : 0, x: 0, y: 4)
        .opacity(canBecomeReady || isReady ? 1 : 0.62)
    }

    private var iconName: String {
        if isReady { return "checkmark" }
        return canBecomeReady ? "pencil.and.list.clipboard" : "lock.fill"
    }

    private var foregroundColor: Color {
        if isReady || canBecomeReady { return .brandSurface }
        return .brandSecondaryText
    }

    private var backgroundColor: Color {
        if isReady { return .brandSage }
        if canBecomeReady { return .brandPrimary }
        return Color.brandSecondaryText.opacity(0.10)
    }

    private var borderColor: Color {
        if isReady { return Color.brandSage.opacity(0.28) }
        if canBecomeReady { return Color.brandPrimary.opacity(0.28) }
        return Color.brandSecondaryText.opacity(0.16)
    }

    private var shadowColor: Color {
        if isReady { return Color.brandSage.opacity(0.16) }
        if canBecomeReady { return Color.brandPrimary.opacity(0.18) }
        return .clear
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

private struct StepSectionHeader: View {
    @EnvironmentObject private var store: RecipeStore
    let stepCount: Int
    @State private var showingStepOptions = false

    var body: some View {
        HStack(spacing: 10) {
            Text("\(stepCount) 步")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)

            Spacer()

            Button {
                showingStepOptions = true
            } label: {
                BakingSystemIconButtonLabel(
                    systemImage: "plus",
                    visualSize: BakingTouchTarget.secondaryActionVisual,
                    font: .caption.weight(.bold)
                )
            }
            .popover(isPresented: $showingStepOptions, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                BakingDropdownPopover(width: 158) {
                    ForEach(StepType.allCases) { type in
                        Button {
                            store.addStep(type: type)
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
            .buttonStyle(.plain)
            .accessibilityLabel("添加步骤")
        }
        .padding(.leading, 2)
        .padding(.vertical, 2)
    }
}

private struct StepCard: View {
    @EnvironmentObject private var store: RecipeStore
    let step: JournalStep
    let isExpanded: Bool
    var reorderCoordinateSpace: String?
    let toggle: () -> Void
    var onReorderChanged: (DragGesture.Value) -> Void = { _ in }
    var onReorderEnded: (DragGesture.Value?) -> Void = { _ in }
    @State private var showingDurationPopover = false
    @State private var showingAssignmentPopover = false
    @State private var isDropTargeted = false
    @State private var showingNotes = false
    @State private var showingProductionMethodPopover = false
    private let nameFieldWidth: CGFloat = 136
    private let durationColumnWidth: CGFloat = 88
    private let temperatureColumnWidth: CGFloat = 88

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                iconControl

                VStack(alignment: .leading, spacing: 1) {
                    TextField(currentStep.type.label, text: stepTextBinding(\.name))
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.brandText)
                        .textFieldStyle(.plain)
                        .lineLimit(1)
                        .frame(width: nameFieldWidth, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.brandPrimary.opacity(0.075))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.brandPrimary.opacity(0.10), lineWidth: 0.5)
                        }
                    Text(stepDetailText)
                        .font(.caption2)
                        .foregroundStyle(isDropTargeted ? Color.brandPrimary : Color.brandSecondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)

                HStack(alignment: .top, spacing: 8) {
                    Button {
                        showingDurationPopover = true
                    } label: {
                        StepValuePill(
                            icon: "timer",
                            text: compactDurationText,
                            accent: .brandPrimary,
                            width: durationColumnWidth
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(width: durationColumnWidth, alignment: .trailing)

                    if showsTemperatureField {
                        Button {
                            toggle()
                        } label: {
                            StepValuePill(
                                icon: nil,
                                text: temperatureText,
                                accent: .waterText,
                                background: Color.waterSurfaceStrong.opacity(0.42),
                                stroke: Color.brandSea.opacity(0.16),
                                width: temperatureColumnWidth
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(width: temperatureColumnWidth, alignment: .trailing)
                    } else {
                        Color.clear
                            .frame(width: temperatureColumnWidth, height: 30)
                    }
                }
                .frame(width: durationColumnWidth + temperatureColumnWidth + 8, alignment: .trailing)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            if isExpanded {
                Divider().padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 8) {
                        StepInlineControl(
                            icon: "timer",
                            title: "耗时",
                            value: compactDurationText,
                            accent: .brandPrimary
                        ) {
                            showingDurationPopover.toggle()
                        }
                        .popover(isPresented: $showingDurationPopover, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                            DurationPopoverView(
                                totalMinutes: Binding(
                                    get: { Int(store.stepMinutes(currentStep).rounded()) },
                                    set: { updateDuration(minutes: $0) }
                                )
                            )
                            .presentationCompactAdaptation(.popover)
                        }

                        StepInlineControl(
                            icon: "checklist",
                            title: "材料",
                            value: "\(assignedItems.count)",
                            accent: .brandText
                        ) {
                            showingAssignmentPopover.toggle()
                        }
                        .popover(isPresented: $showingAssignmentPopover, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                            AssignmentPopoverView(
                                step: currentStep,
                                isPresented: $showingAssignmentPopover
                            )
                            .presentationCompactAdaptation(.popover)
                        }

                        StepInlineControl(
                            icon: "note.text",
                            title: "备注",
                            value: currentStep.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "1",
                            accent: .brandText,
                            emphasized: showingNotes
                        ) {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                showingNotes.toggle()
                            }
                        }

                        Spacer(minLength: 0)
                    }

                    if currentStep.type == .baking {
                        StepInlineControl(
                            icon: productionMethod == .steam ? "humidity" : "oven",
                            title: "方式",
                            value: productionMethod.label,
                            accent: .brandPrimary
                        ) {
                            showingProductionMethodPopover.toggle()
                        }
                        .popover(isPresented: $showingProductionMethodPopover, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                            BakingDropdownPopover(width: 158) {
                                ForEach(ProductionMethod.allCases) { method in
                                    Button {
                                        updateProductionMethod(method)
                                        showingProductionMethodPopover = false
                                    } label: {
                                        BakingDropdownRow(title: method.label, isSelected: productionMethod == method) {
                                            Image(systemName: method == .steam ? "humidity" : "oven")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(Color.brandPrimary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .presentationCompactAdaptation(.popover)
                        }
                    }

                    if showsTemperatureField {
                        if currentStep.type == .baking {
                            BakingTemperatureEditorRow(
                                title: "温度",
                                value: stepNumberBinding(\.temperature, fallback: 0),
                                unit: stepTemperatureUnitBinding
                            )
                        } else {
                            CompactNumberRow(
                                title: "温度",
                                value: stepNumberBinding(\.temperature, fallback: 0),
                                unit: "°"
                            )
                        }
                    }

                    assignedMaterialsPreview

                    if showingNotes {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("备注")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.brandSecondaryText)
                                Spacer()
                                Image(systemName: "chevron.up")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color.brandPrimary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    showingNotes = false
                                }
                            }

                            TextEditor(text: stepTextBinding(\.notes))
                                .font(.subheadline)
                                .foregroundStyle(Color.brandText)
                                .frame(minHeight: 72)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(Color.brandBackground.opacity(0.68))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.brandPrimary.opacity(0.08), lineWidth: 0.5)
                            }
                        }
                    }
                }
                .padding(10)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.985, anchor: .top)),
                    removal: .opacity
                ))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isExpanded)
        .bakingCard(
            radius: BakingRadius.card,
            stroke: isDropTargeted ? Color.brandPrimary.opacity(0.38) : Color.brandPrimary.opacity(0.08),
            lineWidth: isDropTargeted ? 1.0 : 0.6
        )
        .scaleEffect(isDropTargeted ? 1.01 : 1)
        .dropDestination(for: StepMaterialDragPayload.self) { items, _ in
            guard let itemId = items.first?.id else { return false }
            store.assign(itemId: itemId, to: currentStep)
            return true
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.16)) {
                isDropTargeted = targeted
            }
        }
    }

    @ViewBuilder private var iconControl: some View {
        let control = Button(action: toggle) {
            iconControlLabel
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel(isExpanded ? "收起步骤设置" : "展开步骤设置")

        if let reorderCoordinateSpace {
            control.simultaneousGesture(reorderGesture(coordinateSpace: reorderCoordinateSpace))
        } else {
            control
        }
    }

    private var iconControlLabel: some View {
        ZStack(alignment: .bottomTrailing) {
            BakingIconView(icon: BakingIcon.step(for: currentStep.type), size: BakingTouchTarget.inlineIconGlyph, color: .brandPrimary)
                .frame(width: BakingTouchTarget.inlineIconSurface, height: BakingTouchTarget.inlineIconSurface)
                .background(Color.brandBackground.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 14, height: 14)
                .background(Color.brandSurface)
                .clipShape(Circle())
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .offset(x: 3, y: 3)
        }
    }

    private func reorderGesture(coordinateSpace: String) -> some Gesture {
        LongPressGesture(minimumDuration: ReorderMotion.holdDuration, maximumDistance: ReorderMotion.holdMaximumDistance)
            .sequenced(before: DragGesture(minimumDistance: ReorderMotion.dragMinimumDistance, coordinateSpace: .named(coordinateSpace)))
            .onChanged { value in
                guard case .second(true, let drag?) = value else { return }
                onReorderChanged(drag)
            }
            .onEnded { value in
                guard case .second(true, let drag?) = value else {
                    onReorderEnded(nil)
                    return
                }
                onReorderEnded(drag)
            }
    }

    @ViewBuilder private var assignedMaterialsPreview: some View {
        if assignedItems.isEmpty {
            Text("这个步骤还没有材料")
                .font(.caption)
                .foregroundStyle(Color.brandSecondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 2)
        } else {
            BakingFlowLayout(spacing: 6) {
                ForEach(assignedItems) { allocatedItem in
                    let item = allocatedItem.item
                    let palette = item.materialPalette
                    HStack(spacing: 4) {
                        if store.hasWaterContent(item) {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(palette.tint)
                        }
                        Text(item.name)
                        Text(BakingFormat.weight(allocatedItem.weight, gramPrecision: item.tag == .yeast ? 1 : 0))
                            .foregroundStyle(palette.text.opacity(0.76))
                    }
                    .font(.caption2.monospacedDigit().weight(.medium))
                    .foregroundStyle(Color.brandText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(palette.surface.opacity(0.82))
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var currentStep: JournalStep {
        store.steps.first { $0.id == step.id } ?? step
    }

    private var assignedItems: [AllocatedRecipeItem] {
        store.allocatedItems(for: currentStep)
    }

    private var stepDetailText: String {
        if isDropTargeted {
            return "松手放到这一步"
        }
        if currentStep.type == .baking {
            return productionMethod.label
        }
        return currentStep.type.label
    }

    private var showsTemperatureField: Bool {
        currentStep.type == .fermentation || currentStep.type == .baking
    }

    private var productionMethod: ProductionMethod {
        currentStep.productionMethod ?? .bake
    }

    private var compactDurationText: String {
        let total = Int(store.stepMinutes(currentStep).rounded())
        let hours = total / 60
        let minutes = total % 60
        if hours > 0, minutes > 0 { return "\(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(minutes)m"
    }

    private var fullDurationText: String {
        BakingFormat.duration(minutes: store.stepMinutes(currentStep))
    }

    private var temperatureText: String {
        let value = BakingFormat.number(currentStep.temperature ?? 0, precision: 0)
        return currentStep.type == .baking ? "\(value)\(currentStep.temperatureUnit?.rawValue ?? "F")" : "\(value)°"
    }

    private func updateProductionMethod(_ method: ProductionMethod) {
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

    private func updateDuration(minutes: Int) {
        var next = currentStep
        next.timeUnit = .min
        next.timeValue = Double(max(0, minutes))
        store.updateStep(next)
    }

    private func toggleAssignment(for item: RecipeItem) {
        if assignedItems.contains(where: { $0.item.id == item.id }) {
            store.removeAssignedItem(item.id, from: currentStep)
        } else {
            store.assign(itemId: item.id, to: currentStep)
        }
    }
}

private struct StepInlineControl: View {
    let icon: String
    let title: String
    let value: String?
    let accent: Color
    var emphasized: Bool = false
    var action: () -> Void

    init(icon: String, title: String, value: String? = nil, accent: Color, emphasized: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.value = value
        self.accent = accent
        self.emphasized = emphasized
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
                if let value {
                    Text(value)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(accent.opacity(0.78))
                }
            }
            .foregroundStyle(accent)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(emphasized ? Color.brandPrimary.opacity(0.11) : Color.brandBackground.opacity(0.82))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(emphasized ? Color.brandPrimary.opacity(0.22) : Color.brandPrimary.opacity(0.08), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct MaterialsShelfCard: View {
    @Binding var isExpanded: Bool
    let items: [RecipeItem]

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    Text("材料库")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.brandText)

                    Spacer()

                    HStack(spacing: 8) {
                        Text("\(items.count) 个材料")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(Color.brandSecondaryText)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.brandPrimary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .contentShape(Rectangle())
                .padding(10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().padding(.horizontal, 12)

                VStack(alignment: .leading, spacing: 8) {
                    BakingFlowLayout(spacing: 6) {
                        ForEach(items) { item in
                            MaterialDragCard(item: item)
                        }
                    }
                }
                .padding(10)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.985, anchor: .top)),
                    removal: .opacity
                ))
            }
        }
        .bakingCard()
    }
}

private struct MaterialDragCard: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem

    var body: some View {
        let palette = item.materialPalette
        Group {
            if isFullyAssigned {
                cardContent(palette: palette)
            } else {
                cardContent(palette: palette)
                    .draggable(StepMaterialDragPayload(id: item.id)) {
                        MaterialDragPreview(item: item)
                    }
            }
        }
        .opacity(isFullyAssigned ? 0.66 : 1)
    }

    private func cardContent(palette: MaterialPalette) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                BakingIconView(
                    icon: BakingIcon.material(for: item),
                    size: 13,
                    color: isFullyAssigned ? Color.brandSecondaryText.opacity(0.85) : palette.tint
                )
                .frame(width: 18, height: 18)
                .background(isFullyAssigned ? palette.mutedIconSurface : palette.iconSurface)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Text(displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isFullyAssigned ? Color.brandSecondaryText : Color.brandText)
                    .lineLimit(1)
            }

            Text(shortWeight)
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(isFullyAssigned ? Color.brandSecondaryText : palette.text)

            Text(remainingText)
                .font(.caption2)
                .foregroundStyle(Color.brandSecondaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(width: 78, alignment: .leading)
        .background {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    (isFullyAssigned ? palette.mutedSurface : palette.surface.opacity(0.84))
                    palette.tint.opacity(isFullyAssigned ? 0.16 : 0.20)
                        .frame(width: proxy.size.width * usedRatio)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isFullyAssigned ? Color.brandSecondaryText.opacity(0.14) : palette.stroke, lineWidth: 0.5)
        }
    }

    private var isFullyAssigned: Bool {
        store.remainingPercentage(for: item.id) <= 0.01
    }

    private var usedRatio: CGFloat {
        CGFloat(min(1, max(0, store.allocatedPercentage(for: item.id) / 100)))
    }

    private var displayName: String {
        String(item.name.prefix(3))
    }

    private var remainingText: String {
        let remaining = store.remainingPercentage(for: item.id)
        return remaining <= 0.01 ? "已用完" : "剩 \(BakingFormat.number(remaining, precision: 0))%"
    }

    private var shortWeight: String {
        "\(Int(item.weight.rounded())) g"
    }
}

private struct MaterialDragPreview: View {
    let item: RecipeItem

    var body: some View {
        let palette = item.materialPalette
        HStack(spacing: 8) {
            BakingIconView(
                icon: BakingIcon.material(for: item),
                size: 16,
                color: palette.tint
            )
            .frame(width: 24, height: 24)
            .background(palette.iconSurface)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.brandText)
                Text(BakingFormat.weight(item.weight, gramPrecision: item.tag == .yeast ? 1 : 0))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(palette.text)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct StepSummaryPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.brandSecondaryText)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brandBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct StepInfoBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.callout.monospacedDigit().weight(.semibold))
            .foregroundStyle(Color.brandSecondaryText)
            .frame(width: 66, height: 31, alignment: .center)
            .background(Color.brandPrimary.opacity(0.075))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.brandPrimary.opacity(0.10), lineWidth: 0.5)
            }
    }
}


private struct AssignmentPopoverView: View {
    @EnvironmentObject private var store: RecipeStore
    let step: JournalStep
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("分配材料")
                    .font(.subheadline.weight(.semibold))
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
                .accessibilityLabel("全部分配")
                Button {
                    isPresented = false
                } label: {
                    BakingSystemIconButtonLabel(
                        systemImage: "checkmark",
                        visualSize: BakingTouchTarget.secondaryActionVisual,
                        font: .caption.weight(.semibold)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("完成")
            }

            BakingFlowLayout(spacing: 8) {
                ForEach(store.items) { item in
                    AssignmentMaterialChip(
                        item: item,
                        step: currentStep
                    ) {
                        toggle(item)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 348, alignment: .leading)
        .background(Color.brandSurface)
    }

    private func toggle(_ item: RecipeItem) {
        if store.allocationPercentage(for: item.id, in: currentStep) > 0 {
            store.removeAssignedItem(item.id, from: currentStep)
        } else {
            store.assign(itemId: item.id, to: currentStep)
        }
    }

    private var currentStep: JournalStep {
        store.steps.first { $0.id == step.id } ?? step
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
            return "\(BakingFormat.number(selectedPercentage, precision: 0))%"
        }
        if isUnavailable {
            return "已用完"
        }
        return "剩 \(BakingFormat.number(availablePercentage, precision: 0))%"
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
                    Text("选择这一步要加入的比例")
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
                .accessibilityLabel("确认分配")
            }

            BakingPercentagePickerControl(
                value: $percentage,
                maxValue: maxPercentage,
                precision: 1,
                tint: item.materialPalette.text,
                surface: item.materialPalette.surface.opacity(0.86)
            )

            HStack {
                Text("加入")
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
                    .accessibilityLabel("加入克数")

                    Text("g")
                        .font(.headline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color.brandSecondaryText)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(item.materialPalette.surface.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

private struct DurationPopoverView: View {
    @Binding var totalMinutes: Int
    @State private var interval: TimeInterval = 0
    @State private var hasSyncedInitialValue = false

    var body: some View {
        VStack(spacing: 0) {
            CountdownDurationPicker(interval: $interval)
                .frame(height: 180)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 292)
        .background(Color.brandSurface)
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
