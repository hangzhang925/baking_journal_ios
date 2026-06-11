import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var selectedPage: OnboardingPage = .recipeList

    var body: some View {
        TabView(selection: $selectedPage) {
            OnboardingPageView(
                icon: .recipe,
                title: BakingTerms.onboardingRecipeListTitle,
                message: BakingTerms.onboardingRecipeListMessage
            ) {
                OnboardingRecipeListPreview()
            }
            .tag(OnboardingPage.recipeList)

            OnboardingPageView(
                icon: .preview,
                title: BakingTerms.onboardingRecipeViewTitle,
                message: BakingTerms.onboardingRecipeViewMessage
            ) {
                OnboardingRecipeViewPreview()
            }
            .tag(OnboardingPage.recipeView)

            OnboardingPageView(
                icon: .baking,
                title: BakingTerms.onboardingOngoingBakeTitle,
                message: BakingTerms.onboardingOngoingBakeMessage
            ) {
                OnboardingOngoingBakePreview()
            }
            .tag(OnboardingPage.ongoingBake)

            OnboardingPageView(
                icon: .starter,
                title: BakingTerms.onboardingStarterFeedingTitle,
                message: BakingTerms.onboardingStarterFeedingMessage
            ) {
                OnboardingStarterFeedingPreview()
            }
            .tag(OnboardingPage.starterFeeding)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Color.brandBackground)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BakingBottomActionButton(
                title: selectedPage.isFinalPage ? BakingTerms.onboardingFinish : BakingTerms.onboardingNext,
                accessibilityLabel: selectedPage.isFinalPage ? BakingTerms.onboardingFinish : BakingTerms.onboardingNext
            ) {
                advance()
            }
        }
    }

    private func advance() {
        guard let nextPage = selectedPage.next else {
            onComplete()
            return
        }

        withAnimation(BakingMotion.standard) {
            selectedPage = nextPage
        }
    }
}

private enum OnboardingPage: Int {
    case recipeList
    case recipeView
    case ongoingBake
    case starterFeeding

    var next: OnboardingPage? {
        OnboardingPage(rawValue: rawValue + 1)
    }

    var isFinalPage: Bool {
        next == nil
    }
}

private struct OnboardingPageView<Preview: View>: View {
    let icon: BakingIcon
    let title: String
    let message: String
    @ViewBuilder let preview: () -> Preview

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BakingSpace.xxl) {
                VStack(alignment: .leading, spacing: BakingSpace.lg) {
                    BakingMaterialIconBadge(
                        icon: icon,
                        size: BakingTouchTarget.materialBadge + BakingSpace.xxl,
                        iconSize: BakingTouchTarget.materialBadgeGlyph + BakingSpace.sm
                    )

                    VStack(alignment: .leading, spacing: BakingSpace.sm) {
                        Text(title)
                            .font(BakingTypography.screenTitle)
                            .foregroundStyle(Color.brandText)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(message)
                            .font(BakingTypography.appPrimaryText)
                            .foregroundStyle(Color.brandSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                preview()
            }
            .padding(.horizontal, BakingLayout.screenHorizontalInset)
            .padding(.top, BakingSpace.xxl + BakingSpace.lg)
            .padding(.bottom, BakingTouchTarget.primaryAction + BakingSpace.xxl * 4)
        }
        .scrollIndicators(.hidden)
    }
}

private struct OnboardingRecipeListPreview: View {
    private let rows = [
        OnboardingRecipeListRowData(
            icon: .recipeToast,
            title: BakingTerms.onboardingSampleRecipeMilkToast,
            detail: BakingTerms.onboardingSampleUpdatedToday,
            state: .ready,
            bakeCount: BakingTerms.onboardingSampleBakeCount(6)
        ),
        OnboardingRecipeListRowData(
            icon: .recipeCountryBread,
            title: BakingTerms.onboardingSampleRecipeCountryBread,
            detail: BakingTerms.onboardingSampleUpdatedYesterday,
            state: .draft,
            bakeCount: BakingTerms.onboardingSampleBakeCount(2)
        ),
        OnboardingRecipeListRowData(
            icon: .recipeCake,
            title: BakingTerms.onboardingSampleRecipeChiffon,
            detail: BakingTerms.onboardingSampleUpdatedLastWeek,
            state: .ready,
            bakeCount: BakingTerms.onboardingSampleBakeCount(4)
        )
    ]

    var body: some View {
        BakingSectionCard(title: BakingTerms.onboardingRecipeListPreviewTitle) {
            VStack(spacing: BakingSpace.sm) {
                OnboardingSearchPreviewLine()

                VStack(spacing: BakingSpace.xs) {
                    ForEach(rows) { row in
                        OnboardingRecipeListRow(row: row)
                    }
                }
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.bottom, BakingSpace.md)
        }
    }
}

private struct OnboardingSearchPreviewLine: View {
    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            BakingIconView(
                icon: .filterAll,
                size: BakingTouchTarget.dropdownIconGlyph,
                color: .brandSecondaryText
            )

            Text(BakingTerms.recipeSearchPrompt)
                .font(BakingTypography.appPrimaryText)
                .foregroundStyle(Color.brandSecondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, BakingSpace.md)
        .frame(maxWidth: .infinity, minHeight: BakingTouchTarget.primaryAction, alignment: .leading)
        .bakingSurface(.inputSurface)
    }
}

private struct OnboardingRecipeListRowData: Identifiable {
    let id = UUID()
    let icon: BakingIcon
    let title: String
    let detail: String
    let state: RecipeWorkflowState
    let bakeCount: String
}

private struct OnboardingRecipeListRow: View {
    let row: OnboardingRecipeListRowData

    var body: some View {
        HStack(spacing: BakingSpace.md) {
            BakingMaterialIconBadge(
                icon: row.icon,
                size: BakingTouchTarget.secondaryAction,
                iconSize: BakingTouchTarget.secondaryActionGlyph
            )

            VStack(alignment: .leading, spacing: BakingSpace.xs) {
                Text(row.title)
                    .font(BakingTypography.rowTitle)
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(row.detail)
                    .bakingLabelStyle(.helperText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: BakingSpace.xs) {
                RecipeWorkflowBadge(state: row.state)

                Text(row.bakeCount)
                    .bakingLabelStyle(.helperText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
        .padding(.horizontal, BakingSpace.sm)
        .padding(.vertical, BakingSpace.sm)
        .bakingSurface(row.state == .ready ? .selected : .readOnly)
    }
}

private struct OnboardingRecipeViewPreview: View {
    private let formulaRows = [
        OnboardingFormulaRowData(
            icon: .flour,
            title: BakingTerms.highGlutenFlour,
            percent: "100",
            weight: "450"
        ),
        OnboardingFormulaRowData(
            icon: .water,
            title: BakingTerms.water,
            percent: "68",
            weight: "306"
        ),
        OnboardingFormulaRowData(
            icon: .starter,
            title: BakingTerms.starterDisplayName(BakingTerms.levainStarter),
            percent: "20",
            weight: "90"
        ),
        OnboardingFormulaRowData(
            icon: .salt,
            title: BakingTerms.salt,
            percent: "2",
            weight: "9"
        )
    ]

    var body: some View {
        BakingSectionCard(
            title: BakingTerms.onboardingRecipeViewPreviewTitle,
            detail: BakingTerms.onboardingRecipeViewPreviewDetail
        ) {
            VStack(spacing: BakingSpace.sm) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: BakingSpace.sm) {
                        formulaMetricStrip
                    }

                    VStack(spacing: BakingSpace.sm) {
                        formulaMetricStrip
                    }
                }

                VStack(spacing: BakingSpace.xs) {
                    ForEach(formulaRows) { row in
                        OnboardingFormulaRow(row: row)
                    }
                }
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.bottom, BakingSpace.md)
        }
    }

    private var formulaMetricStrip: some View {
        Group {
            BakingMetricValue(
                title: BakingTerms.onboardingMetricDoughWeight,
                value: "858",
                unit: BakingTerms.unitGram
            )

            BakingMetricValue(
                title: BakingTerms.onboardingMetricHydration,
                value: "72",
                unit: "%"
            )
        }
    }
}

private struct OnboardingFormulaRowData: Identifiable {
    let id = UUID()
    let icon: BakingIcon
    let title: String
    let percent: String
    let weight: String
}

private struct OnboardingFormulaRow: View {
    let row: OnboardingFormulaRowData

    var body: some View {
        HStack(spacing: BakingSpace.md) {
            BakingMaterialIconBadge(
                icon: row.icon,
                size: BakingTouchTarget.secondaryAction,
                iconSize: BakingTouchTarget.secondaryActionGlyph
            )

            Text(row.title)
                .font(BakingTypography.rowTitle)
                .foregroundStyle(Color.brandText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, alignment: .leading)

            BakingNumericValue(
                value: row.percent,
                unit: "%",
                kind: .tableNumber,
                width: BakingComponentMetrics.compactOptionWidth
            )

            BakingNumericValue(
                value: row.weight,
                unit: BakingTerms.unitGram,
                kind: .tableNumber,
                width: BakingComponentMetrics.compactInputShortFieldWidth
            )
        }
        .padding(.horizontal, BakingSpace.sm)
        .padding(.vertical, BakingSpace.sm)
        .bakingSurface(.readOnly)
    }
}

private struct OnboardingOngoingBakePreview: View {
    private let steps = [
        OnboardingBakeStepData(
            icon: .mixing,
            title: BakingTerms.onboardingSampleStepMixing,
            detail: BakingTerms.onboardingSampleStepCompleted,
            state: .success
        ),
        OnboardingBakeStepData(
            icon: .fermentation,
            title: BakingTerms.onboardingSampleStepFermentation,
            detail: BakingTerms.onboardingSampleStepCurrent,
            state: .selected
        ),
        OnboardingBakeStepData(
            icon: .baking,
            title: BakingTerms.onboardingSampleStepBake,
            detail: BakingTerms.onboardingSampleStepUpcoming,
            state: .normal
        )
    ]

    var body: some View {
        BakingSectionCard(
            title: BakingTerms.onboardingOngoingPreviewTitle,
            detail: BakingTerms.onboardingStepProgress(2, 5)
        ) {
            VStack(spacing: BakingSpace.sm) {
                ProgressView(value: 0.4)
                    .progressViewStyle(.linear)
                    .tint(.brandPrimary)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: BakingSpace.sm) {
                        BakingMetricValue(
                            title: BakingTerms.onboardingCurrentStep,
                            value: "2",
                            unit: "/5"
                        )

                        BakingMetricValue(
                            title: BakingTerms.onboardingMetricRemaining,
                            value: "3",
                            unit: BakingTerms.stepsHourShort
                        )
                    }

                    VStack(spacing: BakingSpace.sm) {
                        BakingMetricValue(
                            title: BakingTerms.onboardingCurrentStep,
                            value: "2",
                            unit: "/5"
                        )

                        BakingMetricValue(
                            title: BakingTerms.onboardingMetricRemaining,
                            value: "3",
                            unit: BakingTerms.stepsHourShort
                        )
                    }
                }

                VStack(spacing: BakingSpace.xs) {
                    ForEach(steps) { step in
                        OnboardingBakeStepRow(step: step)
                    }
                }
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.bottom, BakingSpace.md)
        }
    }
}

private struct OnboardingBakeStepData: Identifiable {
    let id = UUID()
    let icon: BakingIcon
    let title: String
    let detail: String
    let state: BakingComponentState
}

private struct OnboardingBakeStepRow: View {
    let step: OnboardingBakeStepData

    var body: some View {
        HStack(spacing: BakingSpace.md) {
            BakingMaterialIconBadge(
                icon: step.state == .success ? .complete : step.icon,
                size: BakingTouchTarget.secondaryAction,
                iconSize: BakingTouchTarget.secondaryActionGlyph
            )

            VStack(alignment: .leading, spacing: BakingSpace.xs) {
                Text(step.title)
                    .font(BakingTypography.rowTitle)
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(step.detail)
                    .bakingLabelStyle(.helperText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, BakingSpace.sm)
        .padding(.vertical, BakingSpace.sm)
        .bakingSurface(surfaceKind)
    }

    private var surfaceKind: BakingSurfaceKind {
        switch step.state {
        case .success:
            return .success
        case .selected:
            return .selected
        default:
            return .readOnly
        }
    }
}

private struct OnboardingStarterFeedingPreview: View {
    private let ingredientRows = [
        OnboardingFormulaRowData(
            icon: .starter,
            title: BakingTerms.onboardingStarterSeed,
            percent: "1",
            weight: "50"
        ),
        OnboardingFormulaRowData(
            icon: .flour,
            title: BakingTerms.flour,
            percent: "2",
            weight: "100"
        ),
        OnboardingFormulaRowData(
            icon: .water,
            title: BakingTerms.water,
            percent: "2",
            weight: "100"
        )
    ]

    var body: some View {
        BakingSectionCard(
            title: BakingTerms.onboardingStarterPreviewTitle,
            detail: BakingTerms.starterDisplayName(BakingTerms.levainStarter)
        ) {
            VStack(spacing: BakingSpace.sm) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: BakingSpace.sm) {
                        starterMetricStrip
                    }

                    VStack(spacing: BakingSpace.sm) {
                        starterMetricStrip
                    }
                }

                VStack(spacing: BakingSpace.xs) {
                    ForEach(ingredientRows) { row in
                        OnboardingFormulaRow(row: row)
                    }
                }

                HStack(spacing: BakingSpace.sm) {
                    BakingIconView(
                        icon: .timer,
                        size: BakingTouchTarget.dropdownIconGlyph,
                        color: .brandSage
                    )

                    Text(BakingTerms.onboardingStarterNextFeeding)
                        .font(BakingTypography.rowTitle)
                        .foregroundStyle(Color.brandText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Spacer(minLength: 0)

                    Text(BakingTerms.onboardingSampleTomorrowMorning)
                        .bakingLabelStyle(.helperText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                .padding(.horizontal, BakingSpace.sm)
                .padding(.vertical, BakingSpace.sm)
                .bakingSurface(.selected)
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.bottom, BakingSpace.md)
        }
    }

    private var starterMetricStrip: some View {
        Group {
            BakingMetricValue(
                title: BakingTerms.onboardingStarterRatio,
                value: "1:2:2"
            )

            BakingMetricValue(
                title: BakingTerms.onboardingStarterMaturity,
                value: "8",
                unit: BakingTerms.stepsHourShort
            )

            BakingMetricValue(
                title: BakingTerms.onboardingStarterTemperature,
                value: "24",
                unit: BakingTerms.onboardingCelsiusUnit
            )
        }
    }
}
