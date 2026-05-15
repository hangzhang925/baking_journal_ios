import SwiftUI

struct StepsView: View {
    @EnvironmentObject private var store: RecipeStore
    var embedded: Bool = false
    @State private var expandedStepId: UUID?
    @State private var materialsShelfExpanded = false

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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                StepsOverviewCard(
                    totalMinutes: store.totalStepMinutes(),
                    stepCount: store.steps.count
                )
                .padding(.horizontal, 14)
                .padding(.top, 8)

                if !store.items.isEmpty {
                    MaterialsShelfCard(
                        isExpanded: $materialsShelfExpanded,
                        items: store.items
                    )
                    .padding(.horizontal, 14)
                }

                if store.steps.isEmpty {
                    Text("添加步骤后，就可以把材料分配到每一步。")
                        .font(.callout)
                        .foregroundStyle(Color.brandSecondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.brandSurface.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.horizontal, 14)
                } else {
                    HStack {
                        Text("制作步骤")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.brandSecondaryText)
                        Spacer()
                        Text("\(store.steps.count) 步")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Color.brandSecondaryText)
                    }
                    .padding(.horizontal, 16)

                    ForEach(store.steps) { step in
                        SwipeToDeleteRow(canDelete: true) {
                            store.removeStep(step)
                        } content: {
                            StepCard(
                                step: step,
                                isExpanded: expandedStepId == step.id
                            ) {
                                withAnimation(.easeInOut(duration: 0.24)) {
                                    expandedStepId = expandedStepId == step.id ? nil : step.id
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                    }
                }
            }
            .padding(.bottom, 108)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.brandBackground)
        .navigationTitle("制作步骤")
        .simultaneousGesture(
            TapGesture().onEnded {
                dismissActiveKeyboard()
            }
        )
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    dismissActiveKeyboard()
                }
            }
        }
    }
}

private struct StepsOverviewCard: View {
    @EnvironmentObject private var store: RecipeStore
    let totalMinutes: Double
    let stepCount: Int
    @State private var showingStepOptions = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("制作安排")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.brandText)
                    Text("把步骤拆清楚，开始页就会更顺。")
                        .font(.caption2)
                        .foregroundStyle(Color.brandSecondaryText)
                }

                Spacer()

                Button {
                    showingStepOptions = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(Color.brandPrimary)
                }
                .popover(isPresented: $showingStepOptions, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                    BakingDropdownPopover(width: 158) {
                        ForEach(StepType.allCases) { type in
                            Button {
                                store.addStep(type: type)
                                showingStepOptions = false
                            } label: {
                                BakingDropdownRow(title: type.label) {
                                    BakingIconView(icon: BakingIcon.step(for: type), size: 16, color: .brandPrimary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("添加步骤")
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
        .background(Color.brandSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct StepsMetricPill: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.brandSecondaryText)
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brandBackground.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct StepCard: View {
    @EnvironmentObject private var store: RecipeStore
    let step: JournalStep
    let isExpanded: Bool
    let toggle: () -> Void
    @State private var showingDurationPopover = false
    @State private var showingAssignmentPopover = false
    @State private var isDropTargeted = false
    @State private var showingNotes = false
    private let nameFieldWidth: CGFloat = 136
    private let durationColumnWidth: CGFloat = 88
    private let temperatureColumnWidth: CGFloat = 88

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Button(action: toggle) {
                    ZStack(alignment: .bottomTrailing) {
                        BakingIconView(icon: BakingIcon.step(for: currentStep.type), size: 20, color: .brandPrimary)
                            .frame(width: 30, height: 30)
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
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "收起步骤设置" : "展开步骤设置")

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
                .contentShape(Rectangle())
                .onTapGesture {
                    toggle()
                }

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
                                ),
                                isPresented: $showingDurationPopover
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

                    if showsTemperatureField {
                        CompactNumberRow(
                            title: "温度",
                            value: stepNumberBinding(\.temperature, fallback: 0),
                            unit: currentStep.type == .baking ? (currentStep.temperatureUnit?.rawValue ?? "F") : "°"
                        )

                        if currentStep.type == .baking {
                            Picker("温标", selection: stepTemperatureUnitBinding) {
                                ForEach(TemperatureUnit.allCases) { unit in
                                    Text(unit.rawValue).tag(unit)
                                }
                            }
                            .pickerStyle(.segmented)
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
        .background(Color.brandSurface)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isDropTargeted ? Color.brandPrimary.opacity(0.38) : Color.brandPrimary.opacity(0.08), lineWidth: isDropTargeted ? 1.0 : 0.6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .scaleEffect(isDropTargeted ? 1.01 : 1)
        .dropDestination(for: String.self) { items, _ in
            guard let raw = items.first, let itemId = UUID(uuidString: raw) else { return false }
            store.assign(itemId: itemId, to: currentStep)
            return true
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.16)) {
                isDropTargeted = targeted
            }
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
            FlowLayout(spacing: 6) {
                ForEach(assignedItems) { item in
                    let palette = item.materialPalette
                    HStack(spacing: 4) {
                        if store.hasWaterContent(item) {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(palette.tint)
                        }
                        Text(item.name)
                        Text(BakingFormat.weight(item.weight, gramPrecision: item.tag == .yeast ? 1 : 0))
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

    private var assignedItems: [RecipeItem] {
        store.items(for: currentStep)
    }

    private var stepDetailText: String {
        if isDropTargeted {
            return "松手放到这一步"
        }
        return currentStep.type.label
    }

    private var showsTemperatureField: Bool {
        currentStep.type == .fermentation || currentStep.type == .baking
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
        if assignedItems.contains(where: { $0.id == item.id }) {
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
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("材料库")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.brandText)
                        Text(isExpanded ? "拖到下面的步骤。" : "点开后拖进步骤。")
                            .font(.caption2)
                            .foregroundStyle(Color.brandSecondaryText)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
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
                    FlowLayout(spacing: 6) {
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
        .background(Color.brandSurface)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.brandPrimary.opacity(0.08), lineWidth: 0.6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct MaterialDragCard: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem

    var body: some View {
        let palette = item.materialPalette
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                BakingIconView(
                    icon: BakingIcon.material(for: item),
                    size: 13,
                    color: isAssigned ? Color.brandSecondaryText.opacity(0.85) : palette.tint
                )
                .frame(width: 18, height: 18)
                .background(isAssigned ? palette.mutedIconSurface : palette.iconSurface)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Text(displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isAssigned ? Color.brandSecondaryText : Color.brandText)
                    .lineLimit(1)
            }

            Text(shortWeight)
                .font(.caption2.monospacedDigit().weight(.semibold))
                .foregroundStyle(isAssigned ? Color.brandSecondaryText : palette.text)

            Text(categoryLabel)
                .font(.caption2)
                .foregroundStyle(Color.brandSecondaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 6)
        .frame(width: 78, alignment: .leading)
        .background(isAssigned ? palette.mutedSurface : palette.surface.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isAssigned ? Color.brandSecondaryText.opacity(0.14) : palette.stroke, lineWidth: 0.5)
        }
        .opacity(isAssigned ? 0.74 : 1)
        .draggable(item.id.uuidString) {
            MaterialDragPreview(item: item)
        }
    }

    private var isAssigned: Bool {
        store.stepContaining(itemId: item.id) != nil
    }

    private var displayName: String {
        String(item.name.prefix(3))
    }

    private var categoryLabel: String {
        item.category.label
    }

    private var shortWeight: String {
        "\(Int(item.weight.rounded())) g"
    }
}

private struct MaterialDragPreview: View {
    @EnvironmentObject private var store: RecipeStore
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

private struct StepValuePill: View {
    let icon: String?
    let text: String
    let accent: Color
    var background: Color = Color.brandPrimary.opacity(0.075)
    var stroke: Color = Color.brandPrimary.opacity(0.10)
    var width: CGFloat = 62

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
            }
            Text(text)
                .font(.callout.monospacedDigit().weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(accent)
        .frame(width: width, height: 30)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(stroke, lineWidth: 0.5)
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
                Button("All") {
                    store.assignAllItems(to: currentStep)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.brandBackground.opacity(0.85))
                .clipShape(Capsule())
                Button("完成") {
                    isPresented = false
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
            }

            FlowLayout(spacing: 8) {
                ForEach(store.items) { item in
                    AssignmentMaterialChip(
                        item: item,
                        selected: currentStep.itemIds.contains(item.id)
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
        if currentStep.itemIds.contains(item.id) {
            store.removeAssignedItem(item.id, from: currentStep)
        } else {
            store.assign(itemId: item.id, to: currentStep)
        }
    }

    private var currentStep: JournalStep {
        store.steps.first { $0.id == step.id } ?? step
    }

    private func ownerName(for item: RecipeItem) -> String? {
        guard let owner = store.stepContaining(itemId: item.id), owner.id != currentStep.id else { return nil }
        return owner.name
    }
}

private struct AssignmentMaterialChip: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    Text(String(item.name.prefix(3)))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.brandText)
                        .lineLimit(1)
                }

                Text(BakingFormat.weight(item.weight, gramPrecision: item.tag == .yeast ? 1 : 0))
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(palette.text)

                Text(item.category.label)
                    .font(.caption2)
                    .foregroundStyle(Color.brandSecondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 6)
            .frame(width: 72, alignment: .leading)
            .background(selected ? palette.surface.opacity(0.96) : palette.surface.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? palette.tint.opacity(0.34) : palette.stroke, lineWidth: selected ? 1 : 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct DurationPopoverView: View {
    @Binding var totalMinutes: Int
    @Binding var isPresented: Bool
    @State private var interval: TimeInterval = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("设置耗时")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandText)
                Spacer()
                Button("完成") {
                    totalMinutes = Int((interval / 60).rounded())
                    isPresented = false
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
            }

            CountdownDurationPicker(interval: $interval)
                .frame(height: 180)
                .frame(maxWidth: .infinity)

            Text(displayText)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity, alignment: .center)

            Button("取消") {
                isPresented = false
            }
            .font(.caption)
            .foregroundStyle(Color.brandSecondaryText)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(12)
        .frame(width: 320)
        .background(Color.brandSurface)
        .onAppear {
            interval = TimeInterval(totalMinutes * 60)
        }
    }

    private var displayText: String {
        BakingFormat.duration(minutes: interval / 60)
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

private struct SwipeToDeleteRow<Content: View>: View {
    let canDelete: Bool
    let onDelete: () -> Void
    @ViewBuilder let content: () -> Content
    @State private var offset: CGFloat = 0

    private let actionWidth: CGFloat = 58
    private let buttonSize = CGSize(width: 52, height: 52)

    var body: some View {
        ZStack(alignment: .trailing) {
            if canDelete && offset != 0 {
                Button(role: .destructive) {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        offset = 0
                    }
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(width: buttonSize.width, height: buttonSize.height)
                        .background(Color.brandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("删除")
                .padding(.trailing, 3)
            }

            content()
                .offset(x: offset)
                .contentShape(Rectangle())
                .allowsHitTesting(offset == 0)
        }
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture(minimumDistance: 14, coordinateSpace: .local)
                .onChanged { value in
                    guard canDelete, abs(value.translation.width) > abs(value.translation.height) else { return }
                    let nextOffset: CGFloat
                    if offset == 0 {
                        nextOffset = value.translation.width
                    } else {
                        nextOffset = value.translation.width - actionWidth
                    }
                    offset = min(0, max(-actionWidth, nextOffset))
                }
                .onEnded { value in
                    guard canDelete else { return }
                    let projectedOffset: CGFloat
                    if offset == 0 {
                        projectedOffset = value.translation.width
                    } else {
                        projectedOffset = value.translation.width - actionWidth
                    }

                    withAnimation(.easeInOut(duration: 0.18)) {
                        if projectedOffset < -actionWidth / 2 {
                            offset = -actionWidth
                        } else {
                            offset = 0
                        }
                    }
                }
        )
        .onTapGesture {
            guard offset != 0 else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                offset = 0
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
