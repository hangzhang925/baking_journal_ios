import SwiftUI

struct StarterView: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var starterStatusFilter: StarterLibraryStatusFilter = .all
    @State private var starterFedSort: StarterFedSort = .newestFirst
    @State private var starterSearchText = ""
    @State private var selectedStarter: StarterProfile?
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
        .sheet(item: $selectedStarter) { starter in
            StarterDetailView(starterID: starter.id)
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
            _ = store.createStarterProfile()
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
                            selectedStarter = starter
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

private struct StarterDetailView: View {
    @EnvironmentObject private var store: RecipeStore
    let starterID: UUID
    @State private var showingFeedSheet = false
    @State private var showingFedToast = false
    @State private var fedFeedbackTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(spacing: BakingLayout.cardStackSpacing) {
                starterHeader
                weightSection
                feedingSection
                reminderSection
            }
            .padding(.horizontal, BakingLayout.screenHorizontalInset)
            .padding(.top, BakingLayout.contentTopInset)
            .padding(.bottom, 94)
        }
        .scrollIndicators(.hidden)
        .background(Color.brandBackground)
        .safeAreaInset(edge: .bottom) {
            feedButton
        }
        .sheet(isPresented: $showingFeedSheet) {
            feedSheet
        }
        .overlay(alignment: .bottom) {
            if showingFedToast {
                StarterFedToast()
                    .padding(.bottom, 88)
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

    private var starterHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(BakingTerms.starterSectionName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)

            HStack(spacing: 8) {
                BakingTopIconButtonLabel(
                    icon: .edit,
                    tint: .brandPrimary,
                    glyphSize: BakingTouchTarget.secondaryActionGlyph
                )

                BakingInlineTextField(
                    text: profileBinding(\.name),
                    placeholder: BakingTerms.starterProfileDefaultName,
                    font: .systemFont(ofSize: 15, weight: .semibold)
                )
                .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)

                Spacer(minLength: BakingSpace.sm)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .bakingTitleInputSurface()
        }
        .padding(10)
        .bakingCard()
    }

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: BakingSpace.sm) {
            sectionTitle(BakingTerms.starterSectionWeight)

            VStack(spacing: 0) {
                StarterInputRow(title: BakingTerms.starterFinalWeight) {
                    weightField(value: starterFinalWeightBinding)
                }

                StarterDivider()

                StarterToggleRow(
                    title: BakingTerms.starterContainerWeightToggle,
                    isOn: profileBinding(\.isContainerWeightEnabled)
                )

                if profile.isContainerWeightEnabled {
                    StarterDivider()

                    StarterInputRow(title: BakingTerms.starterContainerWeight) {
                        weightField(
                            value: numberBinding(\.containerWeight)
                        )
                    }
                }
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.vertical, BakingSpace.xs)
            .bakingCard()
        }
    }

    private var feedSheet: some View {
        NavigationStack {
            VStack(spacing: BakingSpace.xl) {
                VStack(alignment: .leading, spacing: BakingSpace.sm) {
                    StarterInfoRow(
                        title: BakingTerms.starterSectionLastFed,
                        value: BakingFormat.starterTimestamp(profile.lastFedAt)
                    )

                    StarterInfoRow(
                        title: BakingTerms.starterFinalWeight,
                        value: BakingFormat.weight(store.starterFinalWeight(for: profile))
                    )

                    HStack(spacing: BakingSpace.sm) {
                        StarterFeedInlineMetric(
                            title: BakingTerms.starterFeedFlour,
                            value: store.starterFeedFlourWeight(for: profile)
                        )

                        StarterFeedInlineMetric(
                            title: BakingTerms.starterFeedWater,
                            value: store.starterFeedWaterWeight(for: profile),
                            isWater: true
                        )
                    }
                }
                .padding(BakingSpace.md)
                .bakingCard()

                VStack(alignment: .leading, spacing: BakingSpace.sm) {
                    Text(BakingTerms.starterSlideToMarkFed)
                        .bakingLabelStyle(.helperText)
                        .padding(.horizontal, BakingSpace.sm)

                    BakingSlideActionBar(
                        icon: .complete,
                        accessibilityLabel: BakingTerms.starterMarkFed,
                        direction: .trailingToLeading,
                        tint: .brandPrimary,
                        trackBackground: .brandSurface,
                        trackAccent: Color.brandSage.opacity(0.18)
                    ) {
                        store.markStarterFed(profile)
                        showingFeedSheet = false
                        showFedToast()
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, BakingLayout.screenHorizontalInset)
            .padding(.top, BakingSpace.xl)
            .background(Color.brandBackground)
            .navigationTitle(BakingTerms.starterFeedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(BakingTerms.done) {
                        showingFeedSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var feedingSection: some View {
        VStack(alignment: .leading, spacing: BakingSpace.sm) {
            sectionTitle(BakingTerms.starterSectionFeedingMethod)

            VStack(alignment: .leading, spacing: BakingSpace.sm) {
                HStack(spacing: BakingSpace.md) {
                    BakingLabel(text: BakingTerms.starterRatio, role: .fieldLabel)

                    Spacer(minLength: BakingSpace.md)

                    Menu {
                        Picker(BakingTerms.starterRatio, selection: profileBinding(\.feedingRatio)) {
                            ForEach(StarterFeedingRatio.allCases) { ratio in
                                Text(ratio.label).tag(ratio)
                            }
                        }
                    } label: {
                        RectangularDropdownTrigger(title: profile.feedingRatio.label)
                    }
                }
                .buttonStyle(.plain)

                HStack(spacing: BakingSpace.sm) {
                    StarterFeedInlineMetric(
                        title: BakingTerms.starterFeedFlour,
                        value: store.starterFeedFlourWeight(for: profile)
                    )

                    StarterFeedInlineMetric(
                        title: BakingTerms.starterFeedWater,
                        value: store.starterFeedWaterWeight(for: profile),
                        isWater: true
                    )
                }
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.vertical, BakingSpace.sm)
            .bakingCard()
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: BakingSpace.sm) {
            sectionTitle(BakingTerms.starterSectionReminder)

            VStack(spacing: 0) {
                StarterToggleRow(
                    title: BakingTerms.starterReminderToggle,
                    isOn: profileBinding(\.isReminderEnabled)
                )

                if profile.isReminderEnabled {
                    StarterDivider()

                    DatePicker(
                        BakingTerms.starterNextFeedingDate,
                        selection: profileBinding(\.nextFeedingDate),
                        displayedComponents: .date
                    )
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(Color.brandText)
                    .padding(.vertical, BakingSpace.sm)

                    StarterDivider()

                    VStack(alignment: .leading, spacing: BakingSpace.sm) {
                        BakingLabel(text: BakingTerms.starterReminderTimes, role: .fieldLabel)

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
                    .padding(.vertical, BakingSpace.sm)
                }
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.vertical, BakingSpace.xs)
            .bakingCard()
        }
    }

    private var feedButton: some View {
        VStack(alignment: .leading, spacing: BakingSpace.sm) {
            VStack(alignment: .leading, spacing: BakingSpace.xs) {
                BakingLabel(text: BakingTerms.starterSectionLastFed, role: .readOnlyLabel)
                Text(BakingFormat.starterTimestamp(profile.lastFedAt))
                    .font(BakingTypography.tableNumber)
                    .foregroundStyle(Color.brandText)
            }
            .padding(.horizontal, BakingLayout.screenHorizontalInset)

            BakingActionButton(
                title: BakingTerms.starterFeedTitle,
                accessibilityLabel: BakingTerms.starterFeedTitle
            ) {
                showingFeedSheet = true
            }
            .padding(.horizontal, BakingLayout.screenHorizontalInset)
        }
        .padding(.top, BakingSpace.sm)
        .padding(.bottom, BakingSpace.sm)
        .background(BakingSurface.bottomBarBackground)
    }

    private func sectionTitle(_ title: String) -> some View {
        BakingLabel(text: title, role: .sectionHeader)
            .padding(.horizontal, BakingSpace.xxl)
    }

    private func weightField(value: Binding<Double>, isEnabled: Bool = true) -> some View {
        HStack(spacing: BakingSpace.xs) {
            BakingNumericTextField(
                value: value,
                fractionDigits: 0...1,
                color: UIColor(isEnabled ? Color.brandText : Color.brandSecondaryText),
                font: .monospacedDigitSystemFont(ofSize: 15, weight: .semibold),
                isEnabled: isEnabled
            )
            .frame(width: 84)

            Text(BakingTerms.unitGram)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)
        }
        .padding(.horizontal, BakingSpace.sm)
        .padding(.vertical, BakingSpace.xs)
        .bakingSurface(isEnabled ? .inputSurface : .readOnly)
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

    private var starterFinalWeightBinding: Binding<Double> {
        Binding(
            get: { store.starterFinalWeight(for: profile) },
            set: { value in
                store.updateStarterFinalWeight(max(0, value), for: profile)
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

private struct StarterFeedInlineMetric: View {
    let title: String
    let value: Double
    var isWater = false

    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            BakingLabel(text: title, role: .inputLabel)
                .foregroundStyle(isWater ? Color.waterText : Color.brandText)

            Spacer(minLength: BakingSpace.sm)

            ReadOnlyInlineMetric(
                value: BakingFormat.number(value, precision: 0),
                unit: BakingTerms.unitGram,
                font: .callout,
                color: isWater ? .waterText : .primary,
                totalWidth: 76,
                isWaterStyle: isWater,
                height: 36
            )
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bakingSurface(isWater ? .selected : .readOnly)
    }
}

private struct StarterInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: BakingSpace.md) {
            BakingLabel(text: title, role: .inputLabel)

            Spacer(minLength: BakingSpace.md)

            Text(value)
                .font(BakingTypography.tableNumber)
                .foregroundStyle(Color.brandText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.sm)
        .bakingSurface(.readOnly)
    }
}

private struct StarterInputRow<Content: View>: View {
    let title: String
    var isEnabled = true
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: BakingSpace.md) {
            BakingLabel(text: title, role: .inputLabel)
                .foregroundStyle(isEnabled ? Color.brandText : Color.brandSecondaryText)

            Spacer(minLength: BakingSpace.md)

            content()
        }
        .frame(minHeight: 58)
        .opacity(isEnabled ? 1 : 0.62)
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
            HStack(spacing: BakingSpace.md) {
                BakingLabel(text: title, role: .inputLabel)

                Spacer(minLength: BakingSpace.md)

                Toggle(title, isOn: $isOn)
                    .labelsHidden()
                    .tint(.brandPrimary)
                    .allowsHitTesting(false)
            }
            .frame(minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct StarterDivider: View {
    var body: some View {
        Rectangle()
            .fill(BakingSurfaceTheme.separator)
            .frame(height: 0.6)
    }
}
