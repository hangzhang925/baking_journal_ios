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
        VStack(spacing: BakingSpace.sm) {
            VStack(alignment: .leading, spacing: BakingSpace.sm) {
                recipeHeader

                if !trimmedOverallNotes.isEmpty {
                    notesSection
                }

                CookStepCarousel(
                    steps: store.steps,
                    currentIndex: store.cookState.currentIndex,
                    selectedIndex: carouselBinding
                )
            }
            .padding(.horizontal, BakingLayout.screenHorizontalInset)
            .padding(.top, BakingLayout.contentTopInset)

            TabView(selection: $stepSelection) {
                ForEach(Array(store.steps.enumerated()), id: \.element.id) { index, step in
                    ScrollView {
                        VStack(alignment: .leading, spacing: BakingSpace.sm) {
                            CookTimerCard(step: step, now: now)

                            instructionSection(step: step)
                        }
                        .padding(.horizontal, BakingLayout.screenHorizontalInset)
                        .padding(.top, BakingSpace.xs)
                        .padding(.bottom, 18)
                    }
                    .scrollIndicators(.hidden)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.brandBackground)
        .onAppear {
            stepSelection = store.cookState.currentIndex
        }
        .onChange(of: stepSelection) { _, newValue in
            if newValue != store.cookState.currentIndex {
                store.goToCookStep(newValue)
            }
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

    private var carouselBinding: Binding<Int?> {
        Binding(
            get: { stepSelection },
            set: { if let newValue = $0 { stepSelection = newValue } }
        )
    }

    private var recipeHeader: some View {
        HStack(spacing: BakingSpace.md) {
            BakingMaterialIconBadge(
                icon: BakingIcon.recipeKind(store.currentRecipeKind),
                color: .brandPrimary,
                background: BakingSurfaceTheme.theme(for: .inputSurface).background
            )

            Text(store.currentRecipeDisplayName)
                .font(BakingTypography.screenTitle)
                .foregroundStyle(Color.brandText)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 0)
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

    private func instructionSection(step: JournalStep) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(BakingTerms.cookCurrentStage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(BakingSurfaceTheme.theme(for: .selected).background)
                    .clipShape(Capsule())

                Text(BakingTerms.cookTips)
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(Color.brandSecondaryText)

                Spacer(minLength: 0)
            }

            Text(stepInstructionText(step))
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

    private var currentStep: JournalStep {
        store.steps[min(store.cookState.currentIndex, max(store.steps.count - 1, 0))]
    }

    private var trimmedOverallNotes: String {
        store.recipeOverallNotes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func stepInstructionText(_ step: JournalStep) -> String {
        let trimmed = step.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? BakingTerms.cookDefaultStepNote : step.notes
    }
}

private struct CookStepCarousel: View {
    let steps: [JournalStep]
    let currentIndex: Int
    @Binding var selectedIndex: Int?

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let cardWidth = max(0, width * 0.78)
            let sideInset = max(0, (width - cardWidth) / 2)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: BakingSpace.sm) {
                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        CookStepCarouselCard(
                            step: step,
                            stepIndex: index,
                            totalSteps: steps.count,
                            isCurrent: index == currentIndex
                        )
                        .frame(width: cardWidth)
                        .id(index)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(BakingMotion.standard) {
                                selectedIndex = index
                            }
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, sideInset, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedIndex)
        }
        .frame(height: 64)
    }
}

private struct CookStepCarouselCard: View {
    let step: JournalStep
    let stepIndex: Int
    let totalSteps: Int
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(BakingTerms.cookStepProgress(stepIndex: stepIndex + 1, totalSteps: totalSteps))
                .font(.caption.weight(.semibold))
                .foregroundStyle(isCurrent ? Color.brandPrimary : Color.brandSecondaryText)

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
            background: isCurrent ? BakingSurface.selectedRowBackground : BakingSurfaceTheme.theme(for: .readOnly).background,
            radius: BakingRadius.card,
            stroke: isCurrent ? BakingSurface.selectedStroke : BakingSurfaceTheme.theme(for: .readOnly).stroke,
            lineWidth: isCurrent ? 0.9 : 0.5
        )
        .opacity(isCurrent ? 1 : 0.7)
        .animation(BakingMotion.standard, value: isCurrent)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(BakingTerms.cookStepProgress(stepIndex: stepIndex + 1, totalSteps: totalSteps))
        .accessibilityValue(step.name)
        .accessibilityAddTraits(isCurrent ? [.isSelected] : [])
    }
}

private struct CookTimerCard: View {
    @EnvironmentObject private var store: RecipeStore
    let step: JournalStep
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                CookTimeMetric(
                    title: BakingTerms.recipePreviewEstimatedDuration,
                    value: durationText,
                    accent: .brandPrimary
                )

                Button {
                    store.startTimer(for: step)
                } label: {
                    BakingToolbarIconButton(
                        icon: .timer,
                        accessibilityLabel: isRunning ? BakingTerms.cookRestartTimer : BakingTerms.cookStartTimer
                    )
                }
                .buttonStyle(.plain)

                CookTimeMetric(
                    title: BakingTerms.cookFinishAt,
                    value: BakingFormat.clockTime(projectedEnd),
                    accent: .brandText
                )
            }

            if let temperatureText {
                StepValuePill(
                    icon: "thermometer.medium",
                    text: temperatureText,
                    accent: .waterText,
                    background: BakingSurfaceTheme.theme(for: .waterSurface).background,
                    stroke: BakingSurfaceTheme.theme(for: .waterSurface).stroke,
                    width: 92
                )
            }
        }
        .padding(10)
        .bakingSectionCard()
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
                .font(BakingTypography.tableNumber)
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bakingReadOnlySurface()
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
