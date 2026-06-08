import SwiftUI

struct CookView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    @State private var now = Date()
    @State private var showingActions = false

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
                    CookStepView(now: now)
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
}

private struct CookStepView: View {
    @EnvironmentObject private var store: RecipeStore
    let now: Date
    @State private var notesExpanded = false
    @State private var stepSelection = 0

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: BakingSpace.sm) {
                recipeHeader

                if !trimmedOverallNotes.isEmpty {
                    notesSection
                }
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

                            CookTimerCard(step: step, now: now)

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

            bottomStepStatus
        }
        .background(Color.brandBackground)
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
    }

    private var recipeHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: BakingSpace.sm) {
            BakingLabel(text: store.currentRecipeDisplayName, role: .sectionHeader)
                .foregroundStyle(Color.brandText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer(minLength: BakingSpace.sm)

            CookReturnToCurrentStepButton(
                isEnabled: stepSelection != store.cookState.currentIndex,
                action: returnToCurrentStep
            )
        }
        .padding(.vertical, BakingSpace.xs)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            BakingDisclosureHeader(
                title: BakingTerms.stepsPageNotes,
                value: "",
                showsValue: false,
                systemImage: "note.text",
                isExpanded: notesExpanded
            ) {
                withAnimation(BakingMotion.standard) {
                    notesExpanded.toggle()
                }
            }

            if notesExpanded {
                Text(trimmedOverallNotes)
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(Color.brandText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .bakingInsetSurface()
            }
        }
        .padding(10)
        .bakingSectionCard()
    }

    @ViewBuilder
    private var bottomStepStatus: some View {
        if let step = selectedStep {
            if store.isCookStepCompleted(step) {
                CookStepCompletedBottomStatus()
            } else {
                BakingBottomActionButton(
                    title: stepCompletionTitle(for: stepSelection),
                    accessibilityLabel: stepCompletionTitle(for: stepSelection)
                ) {
                    completeStep(at: stepSelection)
                }
            }
        }
    }

    private var selectedStep: JournalStep? {
        guard store.steps.indices.contains(stepSelection) else { return nil }
        return store.steps[stepSelection]
    }

    private var trimmedOverallNotes: String {
        store.recipeOverallNotes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func stepCompletionTitle(for index: Int) -> String {
        index >= store.steps.count - 1 ? BakingTerms.cookFinishBake : BakingTerms.cookCompleteStep
    }

    private func completeStep(at index: Int) {
        store.completeCookStep(at: index)
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

private struct CookReturnToCurrentStepButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(BakingTerms.cookReturnToCurrentStep)
                .font(BakingTypography.appSecondaryText.weight(.semibold))
                .foregroundStyle(isEnabled ? Color.brandPrimary : Color.brandSecondaryText.opacity(0.52))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, BakingSpace.md)
                .frame(minHeight: BakingTouchTarget.inlineIconSurface)
                .contentShape(Rectangle())
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(BakingTerms.cookReturnToCurrentStep)
    }
}

private struct CookCurrentStageBadge: View {
    var body: some View {
        Text(BakingTerms.cookCurrentStage)
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.brandOnPrimary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.brandPrimary)
            .clipShape(RoundedRectangle(cornerRadius: BakingRadius.chip, style: .continuous))
            .contentTransition(.opacity)
    }
}

private struct CookStepHeaderCard: View {
    let step: JournalStep
    let stepIndex: Int
    let totalSteps: Int
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                if isCurrent {
                    CookCurrentStageBadge()
                }

                Text(progressText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isCurrent ? Color.brandPrimary : Color.brandSecondaryText)
                    .contentTransition(.opacity)
            }

            Text(step.name)
                .font(BakingTypography.rowTitle)
                .foregroundStyle(isCurrent ? Color.brandText : Color.brandSecondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .bakingCard(
            background: isCurrent ? BakingSurface.selectedRowBackground : .clear,
            radius: BakingRadius.card,
            stroke: isCurrent ? BakingSurface.selectedStroke : BakingSurface.warmHairline,
            lineWidth: isCurrent ? 0.9 : 0.5
        )
        .opacity(isCurrent ? 1 : 0.7)
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

    var body: some View {
        HStack(spacing: 0) {
            CookStepMetricCell(
                title: BakingTerms.recipePreviewEstimatedDuration,
                value: durationText
            )

            metricDivider

            Button {
                store.startTimer(for: step)
            } label: {
                CookStepMetricCell(
                    title: BakingTerms.cookFinishAt,
                    value: BakingFormat.clockTime(projectedEnd)
                )
            }
            .buttonStyle(BakingPressFeedbackButtonStyle())
            .accessibilityLabel(isRunning ? BakingTerms.cookRestartTimer : BakingTerms.cookStartTimer)
            .accessibilityValue(BakingFormat.clockTime(projectedEnd))

            metricDivider

            CookStepMetricCell(
                title: BakingTerms.stepsFieldTemperature,
                value: temperatureText ?? BakingTerms.stepsNoValue
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .bakingCard()
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

    private var durationText: String {
        BakingFormat.duration(minutes: store.stepMinutes(step))
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
}

private struct CookStepMetricCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(BakingTypography.appSecondaryText)
                .foregroundStyle(Color.brandSecondaryText)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(BakingTerms.cookTips)
                .font(BakingTypography.appPrimaryText)
                .foregroundStyle(Color.brandSecondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(instruction)
                .font(BakingTypography.appPrimaryText)
                .foregroundStyle(Color.brandText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(10)
                .bakingInsetSurface()
        }
        .padding(10)
        .bakingSectionCard()
    }
}

private struct CookStepCompletedBottomStatus: View {
    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            BakingIconView(icon: .complete, size: BakingTouchTarget.inlineIconGlyph, color: .semanticSuccessDeep)
                .accessibilityHidden(true)

            Text(BakingTerms.cookStepCompleted)
                .font(BakingTypography.actionLabel)
                .foregroundStyle(Color.semanticSuccessDeep)
        }
        .padding(.horizontal, BakingSpace.xxl)
        .frame(minHeight: BakingTouchTarget.primaryAction)
        .bakingSurface(.success)
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.top, BakingSpace.sm)
        .padding(.bottom, BakingSpace.sm)
        .frame(maxWidth: .infinity)
        .background(BakingSurface.bottomBarBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(BakingTerms.cookStepCompleted)
    }
}

private struct CookSummaryView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore

    var body: some View {
        if let activeBakeRecord = store.activeBakeRecord {
            BakeRecordReviewContent(
                record: activeBakeRecord,
                icon: BakingIcon.recipeKind(store.currentRecipeKind),
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
