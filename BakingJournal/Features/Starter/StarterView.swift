import SwiftUI
import UIKit

struct StarterView: View {
    @EnvironmentObject private var store: RecipeStore
    @EnvironmentObject private var navigationController: AppNavigationController
    @State private var starterStatusFilter: StarterLibraryStatusFilter = .all
    @State private var starterFedSort: StarterFedSort = .newestFirst
    @State private var starterSearchText = ""
    @State private var starterPendingDeletion: StarterProfile?
    @State private var showingDeleteStarterConfirmation = false

    var body: some View {
        BakingLibraryListShell(
            searchText: $starterSearchText,
            searchPrompt: BakingTerms.starterSearchPrompt,
            clearSearchAccessibilityLabel: BakingTerms.clearStarterSearch,
            filters: { starterFilterControls },
            action: { addStarterButton }
        ) {
            starterLibrary
        }
    }

    private var starterFilterControls: some View {
        HStack(spacing: BakingSpace.xs) {
            Button {
                starterStatusFilter = starterStatusFilter.next
            } label: {
                BakingIconButtonLabel(
                    icon: starterStatusFilter.icon,
                    role: .primary,
                    size: .primary,
                    isSelected: starterStatusFilter != .all
                )
            }
            .buttonStyle(BakingPressFeedbackButtonStyle())
            .accessibilityLabel(BakingTerms.starterStatusFilter)
            .accessibilityValue(starterStatusFilter.accessibilityValue)

            Button {
                starterFedSort = starterFedSort.toggled
            } label: {
                BakingIconButtonLabel(
                    icon: starterFedSort.icon,
                    role: .secondary,
                    size: .primary,
                    isSelected: starterFedSort == .oldestFirst
                )
            }
            .buttonStyle(BakingPressFeedbackButtonStyle())
            .accessibilityLabel(BakingTerms.starterSortFed)
            .accessibilityValue(starterFedSort.accessibilityValue)
        }
    }

    private var addStarterButton: some View {
        BakingIconButton(
            icon: .add,
            accessibilityLabel: BakingTerms.addStarter,
            role: .primary
        ) {
            let profile = store.createStarterProfile()
            navigationController.push(.starterDetail(profile.id))
        }
    }

    private var starterLibrary: some View {
        BakingLibraryList {
            Section {
                if !store.hasLoadedPersistedState {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .listRowBackground(Color.clear)
                } else if store.starterProfiles.isEmpty {
                    BakingEmptyState(title: BakingTerms.noStarters, systemImage: "cup.and.saucer")
                        .listRowBackground(Color.clear)
                } else if displayedStarters.isEmpty {
                    BakingEmptyState(title: BakingTerms.noMatchingStarters, systemImage: "line.3.horizontal.decrease.circle")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(displayedStarters) { starter in
                        Button {
                            navigationController.push(.starterDetail(starter.id))
                        } label: {
                            StarterLibraryRow(profile: starter)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(BakingSurface.rowBackground)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                starterPendingDeletion = starter
                                showingDeleteStarterConfirmation = true
                            } label: {
                                Label(BakingTerms.delete, systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listRowBackground(BakingSurface.rowBackground)
        }
        .confirmationDialog(
            BakingTerms.starterDeleteConfirmationTitle,
            isPresented: $showingDeleteStarterConfirmation,
            titleVisibility: .visible,
            presenting: starterPendingDeletion
        ) { starter in
            Button(BakingTerms.starterDeleteConfirmationButton, role: .destructive) {
                store.deleteStarterProfile(starter)
                starterPendingDeletion = nil
            }
            Button(BakingTerms.cancel, role: .cancel) {
                starterPendingDeletion = nil
            }
        } message: { starter in
            Text(BakingTerms.starterDeleteConfirmationMessage(store.starterDisplayName(for: starter)))
        }
        .onChange(of: showingDeleteStarterConfirmation) { _, isPresented in
            if !isPresented {
                starterPendingDeletion = nil
            }
        }
    }

    private var displayedStarters: [StarterProfile] {
        let filteredByStatus = store.starterProfiles.filter { starter in
            starterStatusFilter.includes(starter, store: store)
        }
        let trimmedSearch = starterSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredByName = trimmedSearch.isEmpty ? filteredByStatus : filteredByStatus.filter { starter in
            store.starterDisplayName(for: starter).localizedStandardContains(trimmedSearch)
        }
        return filteredByName.sorted { lhs, rhs in
            switch starterFedSort {
            case .newestFirst:
                return lhs.lastFedAt > rhs.lastFedAt
            case .oldestFirst:
                return lhs.lastFedAt < rhs.lastFedAt
            }
        }
    }
}

struct StarterDetailRouteView: View {
    @EnvironmentObject private var store: RecipeStore
    @EnvironmentObject private var navigationController: AppNavigationController
    let starterID: UUID
    @State private var showingFedToast = false
    @State private var showingRatioPicker = false
    @State private var fedFeedbackTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            BakingTopActionRow(leading: {
                if navigationController.canGoBack {
                    BakingIconButton(
                        icon: .back,
                        accessibilityLabel: BakingTerms.back
                    ) {
                        navigationController.goBack()
                    }
                }
            })

            ScrollView {
                VStack(spacing: BakingLayout.cardStackSpacing) {
                    nameSection
                    weightSection
                    feedingSection
                    reminderSection
                    lastFedSection
                }
                .padding(.horizontal, BakingLayout.screenHorizontalInset)
                .padding(.top, BakingLayout.contentTopInset)
                .padding(.bottom, BakingSpace.xl)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.brandBackground)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            feedBar
        }
        .overlay(alignment: .bottom) {
            if showingFedToast {
                StarterFedToast()
                    .padding(.bottom, 96)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
        }
        .onDisappear {
            fedFeedbackTask?.cancel()
        }
    }

    private var profile: StarterProfile {
        store.starterProfiles.first(where: { $0.id == starterID }) ?? StarterProfile(id: starterID)
    }

    private var nameSection: some View {
        starterSection(BakingTerms.starterSectionName) {
            HStack(spacing: BakingSpace.sm) {
                BakingMaterialIconBadge(icon: .starter)

                BakingInlineTextField(
                    text: profileBinding(\.name),
                    placeholder: BakingTerms.starterProfileDefaultName,
                    color: UIColor(Color.brandText),
                    font: BakingTypography.popupInputValueUIFont,
                    textAlignment: .left
                )
                .padding(.horizontal, BakingSpace.sm)
                .frame(maxWidth: .infinity, minHeight: BakingComponentMetrics.compactInputFieldHeight, alignment: .leading)
                .bakingSurface(.field)
            }
            .padding(.horizontal, BakingSpace.md)
            .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
        }
    }

    private var weightSection: some View {
        starterSection(BakingTerms.starterSectionWeight) {
            StarterMetricRow(title: BakingTerms.starterContainerWeight) {
                StarterWeightField(value: numberBinding(\.containerWeight))
            }

            PopupTableDivider()

            StarterMetricRow(title: BakingTerms.starterTotalWeight) {
                StarterWeightField(value: numberBinding(\.measuredWeight))
            }

            PopupTableDivider()

            StarterMetricRow(title: BakingTerms.starterFinalWeight) {
                StarterReadOnlyField(value: store.starterFinalWeight(for: profile))
            }
        }
    }

    private var feedingSection: some View {
        starterSection(BakingTerms.starterSectionFeedingMethod) {
            StarterMetricRow(title: BakingTerms.starterRatio) {
                Button {
                    showingRatioPicker = true
                } label: {
                    RectangularDropdownTrigger(
                        title: profile.feedingRatio.label,
                        width: BakingCompactInputFieldSize.short.width,
                        textAlignment: .trailing,
                        font: BakingTypography.appPrimaryText
                    )
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingRatioPicker, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                    BakingDropdownPopover(width: 156) {
                        ForEach(StarterFeedingRatio.allCases) { ratio in
                            Button {
                                profileBinding(\.feedingRatio).wrappedValue = ratio
                                showingRatioPicker = false
                            } label: {
                                BakingDropdownRow(
                                    title: ratio.label,
                                    isSelected: ratio == profile.feedingRatio
                                ) {
                                    Color.clear
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            PopupTableDivider()

            StarterMetricRow(title: BakingTerms.starterFeedFlour) {
                StarterReadOnlyField(value: store.starterFeedFlourWeight(for: profile))
            }

            PopupTableDivider()

            StarterMetricRow(title: BakingTerms.starterFeedWater) {
                StarterReadOnlyField(value: store.starterFeedWaterWeight(for: profile), color: .waterText)
            }
        }
    }

    private var reminderSection: some View {
        starterSection(BakingTerms.starterSectionReminder) {
            StarterToggleRow(
                title: BakingTerms.starterReminderToggle,
                isOn: profileBinding(\.isReminderEnabled)
            )

            if profile.isReminderEnabled {
                PopupTableDivider()

                StarterMetricRow(title: BakingTerms.starterNextFeedingDate) {
                    DatePicker(
                        "",
                        selection: profileBinding(\.nextFeedingDate),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .tint(.brandPrimary)
                }

                PopupTableDivider()

                VStack(alignment: .leading, spacing: BakingSpace.sm) {
                    BakingLabel(text: BakingTerms.starterReminderTimes, role: .popupRowLabel)

                    HStack(spacing: BakingSpace.sm) {
                        ForEach(RecipeStore.starterReminderTimeLabels, id: \.self) { time in
                            Text(time)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.brandPrimary)
                                .padding(.horizontal, BakingSpace.md)
                                .padding(.vertical, BakingSpace.xs)
                                .bakingSurface(.inputSurface)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, BakingSpace.md)
                .padding(.vertical, BakingSpace.sm)
            }
        }
    }

    private var lastFedSection: some View {
        starterSection(BakingTerms.starterSectionLastFed) {
            StarterMetricRow(title: BakingTerms.starterLastFed) {
                Text(BakingFormat.starterTimestamp(profile.lastFedAt))
                    .font(BakingTypography.tableNumber)
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
    }

    private var feedBar: some View {
        BakingSlideActionBar(
            icon: .complete,
            accessibilityLabel: BakingTerms.starterMarkFed,
            direction: .trailingToLeading,
            tint: .brandPrimary
        ) {
            store.markStarterFed(profile)
            showFedToast()
        }
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.top, BakingSpace.md)
        .padding(.bottom, BakingSpace.sm + tabBarClearance)
        .background(BakingSurface.bottomBarBackground)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BakingSurfaceTheme.separator)
                .frame(height: 0.6)
        }
    }

    private var tabBarClearance: CGFloat {
        BakingComponentMetrics.tabItemHeight + BakingSpace.xxs * 2
    }

    @ViewBuilder
    private func starterSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: BakingSpace.sm) {
            BakingLabel(text: title, role: .sectionHeader)
                .padding(.horizontal, BakingSpace.xxl)

            VStack(spacing: 0) {
                content()
            }
            .bakingCard()
        }
    }

    private func profileBinding<Value>(_ keyPath: WritableKeyPath<StarterProfile, Value>) -> Binding<Value> {
        Binding(
            get: { profile[keyPath: keyPath] },
            set: { value in
                var next = profile
                next[keyPath: keyPath] = value
                store.updateStarterProfile(next)
            }
        )
    }

    private func numberBinding(_ keyPath: WritableKeyPath<StarterProfile, Double>) -> Binding<Double> {
        Binding(
            get: { profile[keyPath: keyPath] },
            set: { value in
                var next = profile
                next[keyPath: keyPath] = max(0, value)
                store.updateStarterProfile(next)
            }
        )
    }

    private func showFedToast() {
        fedFeedbackTask?.cancel()

        withAnimation(BakingMotion.quick) {
            showingFedToast = true
        }

        fedFeedbackTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.28)) {
                showingFedToast = false
            }
        }
    }
}

private struct StarterMetricRow<Content: View>: View {
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
        .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
    }
}

private struct StarterWeightField: View {
    @Binding var value: Double

    var body: some View {
        InlineNumberField(
            value: $value,
            unit: BakingTerms.unitGram,
            color: .brandText,
            fieldWidth: 52,
            totalWidth: BakingCompactInputFieldSize.short.width,
            height: BakingComponentMetrics.compactInputFieldHeight
        )
    }
}

private struct StarterReadOnlyField: View {
    let value: Double
    var color: Color = .brandText

    var body: some View {
        ReadOnlyInlineMetric(
            value: BakingFormat.number(value, precision: 0),
            unit: BakingTerms.unitGram,
            color: color,
            totalWidth: BakingCompactInputFieldSize.short.width,
            height: BakingComponentMetrics.compactInputFieldHeight
        )
    }
}

private struct StarterToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(BakingMotion.quick) {
                isOn.toggle()
            }
        } label: {
            HStack(alignment: .center, spacing: BakingSpace.sm) {
                BakingLabel(text: title, role: .popupRowLabel)
                    .lineLimit(1)

                Spacer(minLength: BakingSpace.sm)

                Toggle(title, isOn: $isOn)
                    .labelsHidden()
                    .tint(.brandPrimary)
                    .allowsHitTesting(false)
            }
            .padding(.horizontal, BakingSpace.md)
            .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct StarterFedToast: View {
    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            BakingIconView(icon: .complete, size: 16, color: .brandSage)

            Text(BakingTerms.starterFedDone)
                .font(BakingTypography.appPrimaryText)
                .foregroundStyle(Color.brandText)
        }
        .padding(.horizontal, BakingSpace.xl)
        .padding(.vertical, BakingSpace.md)
        .bakingSurface(.success)
        .bakingLiftedShadow()
    }
}

private struct StarterLibraryRow: View {
    @EnvironmentObject private var store: RecipeStore
    let profile: StarterProfile

    var body: some View {
        HStack(spacing: BakingSpace.lg) {
            BakingMaterialIconBadge(icon: .starter)

            VStack(alignment: .leading, spacing: BakingSpace.xs) {
                Text(store.starterDisplayName(for: profile))
                    .font(BakingTypography.rowTitle)
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                HStack(spacing: BakingSpace.xs) {
                    BakingIconView(icon: .water, size: BakingComponentMetrics.materialChipIcon, color: .waterText)

                    Text(BakingFormat.weight(store.starterFinalWeight(for: profile)))
                        .font(BakingTypography.rowMeta.monospacedDigit())
                        .foregroundStyle(Color.waterText)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(BakingTerms.starterFinalWeight)
                .accessibilityValue(BakingFormat.weight(store.starterFinalWeight(for: profile)))
            }

            Spacer(minLength: BakingSpace.md)

            VStack(alignment: .trailing, spacing: BakingSpace.xs) {
                RecipeLibraryMetadataLine(
                    title: BakingTerms.starterLastFed,
                    value: profile.lastFedAt.formatted(date: .numeric, time: .omitted)
                )
                RecipeLibraryMetadataLine(
                    title: BakingTerms.starterRatio,
                    value: profile.feedingRatio.label
                )
            }
        }
        .frame(minHeight: 64)
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.vertical, BakingSpace.sm)
        .contentShape(Rectangle())
    }
}

private enum StarterLibraryStatusFilter {
    case all
    case due
    case fresh

    var next: StarterLibraryStatusFilter {
        switch self {
        case .all:
            return .due
        case .due:
            return .fresh
        case .fresh:
            return .all
        }
    }

    var icon: BakingIcon {
        switch self {
        case .all:
            return .filterAll
        case .due:
            return .starter
        case .fresh:
            return .complete
        }
    }

    var accessibilityValue: String {
        switch self {
        case .all:
            return BakingTerms.starterStatusFilterAll
        case .due:
            return BakingTerms.starterStatusFilterDue
        case .fresh:
            return BakingTerms.starterStatusFilterFresh
        }
    }

    @MainActor
    func includes(_ profile: StarterProfile, store: RecipeStore) -> Bool {
        switch self {
        case .all:
            return true
        case .due:
            return store.isStarterReminderDue(for: profile)
        case .fresh:
            return !store.isStarterReminderDue(for: profile)
        }
    }
}

private enum StarterFedSort {
    case newestFirst
    case oldestFirst

    var icon: BakingIcon {
        switch self {
        case .newestFirst:
            return .sortNewest
        case .oldestFirst:
            return .sortOldest
        }
    }

    var toggled: StarterFedSort {
        switch self {
        case .newestFirst:
            return .oldestFirst
        case .oldestFirst:
            return .newestFirst
        }
    }

    var accessibilityValue: String {
        switch self {
        case .newestFirst:
            return BakingTerms.starterSortFedNewest
        case .oldestFirst:
            return BakingTerms.starterSortFedOldest
        }
    }
}
