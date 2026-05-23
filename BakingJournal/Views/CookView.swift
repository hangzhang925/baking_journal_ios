import SwiftUI

struct CookView: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var now = Date()

    var body: some View {
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
                CookStepView(now: now)
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(Color.brandBackground)
        .toolbar {
            if !store.steps.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.resetCook()
                    } label: {
                        BakingSystemIconButtonLabel(systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(BakingTerms.cookResetAccessibility)
                }
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
        .onAppear {
            store.beginCookIfNeeded()
        }
    }
}

private struct CookStepView: View {
    @Environment(\.historySwipeSuppressionHandler) private var setHistorySwipeSuppressed
    @EnvironmentObject private var store: RecipeStore
    let now: Date
    @State private var isLocalStepSwipeActive = false
    @State private var isVerticalScrollIntent = false

    var body: some View {
        let step = currentStep
        let stepItems = store.allocatedItems(for: step)
        let checked = store.cookState.checked[step.id] ?? []

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                CookCurrentStageCard(
                    step: step,
                    steps: store.steps,
                    stepIndex: store.cookState.currentIndex,
                    totalSteps: store.steps.count,
                    checkedCount: checked.count,
                    totalItemCount: stepItems.count,
                    now: now
                )
                .id(step.id)
                .transition(.opacity.combined(with: .scale(scale: 0.99, anchor: .top)))

                VStack(alignment: .leading, spacing: 7) {
                    CookSectionHeader(
                        title: BakingTerms.cookIngredients,
                        detail: stepItems.isEmpty
                            ? BakingTerms.cookIngredientCount(0)
                            : BakingTerms.cookIngredientProgress(checked: checked.count, total: stepItems.count)
                    )

                    if stepItems.isEmpty {
                        Text(BakingTerms.cookNoStepIngredients)
                            .font(.callout)
                            .foregroundStyle(Color.brandSecondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .bakingCard(radius: BakingRadius.card, stroke: Color.brandPrimary.opacity(0.06))
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 7)], spacing: 7) {
                            ForEach(stepItems) { allocatedItem in
                                let item = allocatedItem.item
                                Button {
                                    store.toggleCookItem(stepId: step.id, itemId: item.id)
                                } label: {
                                    CookMaterialMiniCard(
                                        allocatedItem: allocatedItem,
                                        isChecked: checked.contains(item.id)
                                    )
                                }
                                .buttonStyle(BakingPressFeedbackButtonStyle())
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    CookSectionHeader(title: BakingTerms.cookTips, detail: nil)

                    Text(step.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? BakingTerms.cookDefaultStepNote : step.notes)
                        .font(.callout)
                        .foregroundStyle(Color.brandText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .bakingCard(radius: BakingRadius.card, stroke: Color.brandPrimary.opacity(0.06))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 18)
        }
        .background(Color.brandBackground)
        .simultaneousGesture(
            DragGesture(minimumDistance: 36, coordinateSpace: .local)
                .onChanged { value in
                    guard !isVerticalScrollIntent else { return }
                    if BakingGesturePolicy.isVerticalScrollIntent(value.translation) {
                        isVerticalScrollIntent = true
                        return
                    }
                    guard !isLocalStepSwipeActive else { return }
                    guard BakingGesturePolicy.isHorizontalIntent(
                        value.translation,
                        minimumDistance: 68
                    ) else { return }
                    isLocalStepSwipeActive = true
                    setHistorySwipeSuppressed(true)
                }
                .onEnded { value in
                    let horizontalTravel = value.translation.width
                    let shouldReleaseHistorySwipe = isLocalStepSwipeActive
                    defer {
                        isLocalStepSwipeActive = false
                        isVerticalScrollIntent = false
                        if shouldReleaseHistorySwipe {
                            setHistorySwipeSuppressed(false)
                        }
                    }
                    guard isLocalStepSwipeActive else { return }
                    guard BakingGesturePolicy.isHorizontalIntent(
                        value.translation,
                        minimumDistance: 68
                    ) else { return }
                    withAnimation(BakingMotion.standard) {
                        store.moveCookStep(horizontalTravel < 0 ? 1 : -1)
                    }
                }
        )
        .accessibilityAction(named: BakingTerms.cookPreviousStep) {
            store.moveCookStep(-1)
        }
        .accessibilityAction(named: store.cookState.currentIndex == store.steps.count - 1 ? BakingTerms.cookFinish : BakingTerms.cookNextStep) {
            store.moveCookStep(1)
        }
    }

    private var currentStep: JournalStep {
        store.steps[min(store.cookState.currentIndex, max(store.steps.count - 1, 0))]
    }
}

private struct CookCurrentStageCard: View {
    @EnvironmentObject private var store: RecipeStore
    let step: JournalStep
    let steps: [JournalStep]
    let stepIndex: Int
    let totalSteps: Int
    let checkedCount: Int
    let totalItemCount: Int
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            CookStepProgressStrip(steps: steps, currentIndex: stepIndex)

            HStack(alignment: .top, spacing: 9) {
                BakingMaterialIconBadge(
                    icon: BakingIcon.step(for: step.type),
                    size: BakingTouchTarget.materialBadge,
                    iconSize: BakingTouchTarget.materialBadgeGlyph,
                    color: .brandPrimary,
                    background: Color.brandPrimary.opacity(0.10)
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(BakingTerms.cookStepProgress(stepIndex: stepIndex + 1, totalSteps: totalSteps))
                        Text(BakingTerms.cookCurrentStage)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.brandPrimary.opacity(0.10))
                            .clipShape(Capsule())
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)

                    Text(step.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.brandText)
                        .lineLimit(2)

                    Text(step.type.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandSecondaryText)
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 5) {
                    StepValuePill(
                        icon: "timer",
                        text: remainingText,
                        accent: .brandPrimary,
                        width: 82
                    )

                    if let temperatureText {
                        StepValuePill(
                            icon: "thermometer.medium",
                            text: temperatureText,
                            accent: .waterText,
                            background: Color.waterSurfaceStrong.opacity(0.42),
                            stroke: Color.brandSea.opacity(0.16),
                            width: 82
                        )
                    }
                }
            }

            HStack(spacing: 7) {
                CookTimeMetric(title: BakingTerms.cookNow, value: BakingFormat.clockTime(now), accent: .brandText)

                Button {
                    store.startTimer(for: step)
                } label: {
                    BakingToolbarIconButton(
                        icon: .timer,
                        accessibilityLabel: isRunning ? BakingTerms.cookRestartTimer : BakingTerms.cookStartTimer
                    )
                }
                .buttonStyle(.plain)

                CookTimeMetric(title: BakingTerms.cookFinishAt, value: BakingFormat.clockTime(projectedEnd), accent: .brandPrimary)
            }

            HStack(spacing: 6) {
                StepsMetricPill(
                    title: BakingTerms.cookIngredients,
                    value: "\(totalItemCount)",
                    accent: .brandText
                )
                StepsMetricPill(
                    title: BakingTerms.cookChecked,
                    value: "\(checkedCount)/\(totalItemCount)",
                    accent: checkedCount == totalItemCount ? .brandSage : .brandPrimary
                )
            }
        }
        .padding(10)
        .bakingCard(
            background: Color.brandSurface,
            radius: BakingRadius.prominentCard,
            stroke: Color.brandPrimary.opacity(0.16),
            lineWidth: 0.8
        )
    }

    private var isRunning: Bool {
        store.cookState.timerStepId == step.id && store.cookState.timerEndsAt != nil
    }

    private var projectedEnd: Date {
        if isRunning, let timerEndsAt = store.cookState.timerEndsAt {
            return timerEndsAt
        }
        return now.addingTimeInterval(store.stepMinutes(step) * 60)
    }

    private var remainingText: String {
        guard isRunning, let timerEndsAt = store.cookState.timerEndsAt else {
            return compactDurationText
        }
        return BakingFormat.duration(minutes: max(0, timerEndsAt.timeIntervalSince(now) / 60))
    }

    private var compactDurationText: String {
        BakingFormat.duration(minutes: store.stepMinutes(step))
            .replacingOccurrences(of: " hr", with: "h")
            .replacingOccurrences(of: " min", with: "m")
    }

    private var temperatureText: String? {
        guard let temperature = step.temperature else { return nil }
        let value = BakingFormat.number(temperature, precision: 0)
        if step.type == .baking {
            return "\(value)\(step.temperatureUnit?.rawValue ?? "F")"
        }
        return "\(value)°"
    }
}

private struct CookStepProgressStrip: View {
    let steps: [JournalStep]
    let currentIndex: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    let isCurrent = index == currentIndex

                    HStack(spacing: 6) {
                        BakingIconView(
                            icon: BakingIcon.step(for: step.type),
                            size: isCurrent ? 15 : 12,
                            color: isCurrent ? .brandPrimary : .brandSecondaryText.opacity(0.78)
                        )

                        if isCurrent {
                            Text(step.type.label)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.brandText)
                        }
                    }
                    .frame(height: 26)
                    .padding(.horizontal, isCurrent ? 8 : 7)
                    .background(isCurrent ? Color.brandPrimary.opacity(0.11) : Color.brandBackground.opacity(0.72))
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(isCurrent ? Color.brandPrimary.opacity(0.22) : Color.brandPrimary.opacity(0.06), lineWidth: 0.5)
                    }
                    .accessibilityLabel(BakingTerms.cookStepProgress(stepIndex: index + 1, totalSteps: steps.count))
                    .accessibilityAddTraits(isCurrent ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

private struct CookTimeMetric: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.brandSecondaryText)
            Text(value)
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brandBackground.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.field, style: .continuous))
    }
}

private struct CookMaterialMiniCard: View {
    @EnvironmentObject private var store: RecipeStore
    let allocatedItem: AllocatedRecipeItem
    let isChecked: Bool

    var body: some View {
        let item = allocatedItem.item
        let palette = item.materialPalette

        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 6) {
                BakingIconView(
                    icon: BakingIcon.material(for: item),
                    size: 15,
                    color: isChecked ? Color.brandSage : palette.tint
                )
                .frame(width: 24, height: 24)
                .background(isChecked ? Color.brandSage.opacity(0.10) : palette.iconSurface)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                Spacer()

                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(isChecked ? Color.brandSage : Color.brandSecondaryText.opacity(0.62))
            }

            Text(item.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(BakingFormat.weight(allocatedItem.weight, gramPrecision: item.tag == .yeast ? 1 : 0))
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(isChecked ? Color.brandSage : palette.text)
                    .lineLimit(1)

                Spacer(minLength: 2)

                if store.hasWaterContent(item) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.waterText)
                }
            }

            Text(detailText)
                .font(.caption2)
                .foregroundStyle(Color.brandSecondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 98, alignment: .leading)
        .bakingCard(
            background: cardBackground(palette: palette),
            radius: BakingRadius.compactCard,
            stroke: isChecked ? Color.brandSage.opacity(0.28) : palette.stroke,
            lineWidth: isChecked ? 0.9 : 0.5
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isChecked ? [.isSelected] : [])
    }

    private var detailText: String {
        let item = allocatedItem.item
        if store.hasWaterContent(item) {
            let waterWeight = BakingFormat.weight(store.waterContribution(item) * allocatedItem.percentage / 100)
            return BakingTerms.cookWaterContribution(waterWeight)
        }
        return BakingTerms.cookAllocationPercent(BakingFormat.number(allocatedItem.percentage, precision: 0))
    }

    private func cardBackground(palette: MaterialPalette) -> Color {
        if isChecked {
            return Color.brandSage.opacity(0.095)
        }
        if store.hasWaterContent(allocatedItem.item) {
            return Color.waterSurface.opacity(0.82)
        }
        return palette.surface.opacity(0.86)
    }
}

private struct CookSectionHeader: View {
    let title: String
    let detail: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)

            Spacer()

            if let detail {
                Text(detail)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.brandSecondaryText)
            }
        }
        .padding(.horizontal, 2)
    }
}

private struct CookSummaryView: View {
    @EnvironmentObject private var store: RecipeStore

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        BakingMaterialIconBadge(
                            icon: .complete,
                            size: BakingTouchTarget.materialBadge,
                            iconSize: BakingTouchTarget.materialBadgeGlyph,
                            color: .brandSage,
                            background: Color.brandSage.opacity(0.12)
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(BakingTerms.cookCompletedTitle)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color.brandText)
                            Text(BakingTerms.cookCompletedBody)
                                .font(.caption2)
                                .foregroundStyle(Color.brandSecondaryText)
                        }
                    }

                    HStack(spacing: 6) {
                        StepsMetricPill(
                            title: BakingTerms.cookActualTime,
                            value: BakingFormat.duration(minutes: actualMinutes),
                            accent: .brandSage
                        )
                        StepsMetricPill(
                            title: BakingTerms.cookEstimatedTime,
                            value: BakingFormat.duration(minutes: store.totalStepMinutes()),
                            accent: .brandPrimary
                        )
                    }

                    HStack(spacing: 6) {
                        StepsMetricPill(
                            title: BakingTerms.cookCompletedSteps,
                            value: "\(store.steps.count)/\(store.steps.count)",
                            accent: .brandText
                        )
                        StepsMetricPill(
                            title: BakingTerms.cookIngredientCheck,
                            value: "\(checkedItemCount)/\(totalItemCount)",
                            accent: .brandText
                        )
                    }
                }
                .padding(10)
                .bakingCard()

                if let activeBakeRecord = store.activeBakeRecord {
                    VStack(alignment: .leading, spacing: 8) {
                        CookSectionHeader(title: BakingTerms.reviewNotes, detail: nil)

                        TextEditor(text: Binding(
                            get: { activeBakeRecord.notes },
                            set: { store.updateBakeRecordNotes($0, for: activeBakeRecord) }
                        ))
                        .font(.body)
                        .foregroundStyle(Color.brandText)
                        .frame(minHeight: 140)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .bakingCard(radius: BakingRadius.card, stroke: Color.brandPrimary.opacity(0.06))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
            .padding(.bottom, 96)
        }
        .background(Color.brandBackground)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button {
                    store.resetCook()
                } label: {
                    BakingSystemIconButtonLabel(systemImage: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.cookBakeAgain)
                Spacer()
            }
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(Color.brandSurface.opacity(0.98))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.brandPrimary.opacity(0.08))
                    .frame(height: 0.6)
            }
        }
    }

    private var actualMinutes: Double {
        guard let start = store.cookState.totalStartedAt, let end = store.cookState.completedAt else { return 0 }
        return end.timeIntervalSince(start) / 60
    }

    private var totalItemCount: Int {
        store.steps.reduce(0) { $0 + store.allocatedItems(for: $1).count }
    }

    private var checkedItemCount: Int {
        store.cookState.checked.values.reduce(0) { $0 + $1.count }
    }
}
