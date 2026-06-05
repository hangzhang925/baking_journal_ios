import SwiftUI

struct BakeHistoryView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    @State private var bakeStartedSort: BakeStartedSort = .newestFirst
    @State private var bakeSearchText = ""

    var body: some View {
        BakingLibraryListShell(
            searchText: $bakeSearchText,
            searchPrompt: BakingTerms.bakeSearchPrompt,
            clearSearchAccessibilityLabel: BakingTerms.clearBakeSearch,
            filters: { bakeFilterControls },
            action: { startBakeButton }
        ) {
            BakingLibraryList {
                Section {
                    if !store.hasLoadedPersistedState {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 220)
                            .listRowBackground(Color.clear)
                    } else if store.bakeHistory.isEmpty {
                        BakingEmptyState(title: BakingTerms.noRecords, systemImage: "clock.arrow.circlepath")
                            .listRowBackground(Color.clear)
                    } else if displayedHistory.isEmpty {
                        BakingEmptyState(title: BakingTerms.noMatchingBakeRecords, systemImage: "line.3.horizontal.decrease.circle")
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(displayedHistory) { record in
                            historyRowButton(for: record)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(BakingSurface.rowBackground)
                        }
                    }
                }
                .listRowBackground(BakingSurface.rowBackground)
            }
        }
    }

    private func historyRowButton(for record: BakeRecord) -> some View {
        Button {
            if record.id == store.activeBakeRecordID && record.completedAt == nil {
                navigationController.push(.cook)
            } else {
                navigationController.push(.bakeRecordDetail(record.id))
            }
        } label: {
            BakeHistoryRow(record: record, icon: icon(for: record))
        }
        .buttonStyle(.plain)
    }

    private var bakeFilterControls: some View {
        Button {
            bakeStartedSort = bakeStartedSort.toggled
        } label: {
            BakingIconButtonLabel(
                icon: bakeStartedSort.icon,
                role: .secondary,
                size: .primary,
                isSelected: bakeStartedSort == .oldestFirst
            )
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(BakingTerms.bakeSortStarted)
        .accessibilityValue(bakeStartedSort.accessibilityValue)
    }

    private var startBakeButton: some View {
        BakingIconButton(
            icon: .add,
            accessibilityLabel: BakingTerms.startBake,
            role: .primary
        ) {
            navigationController.push(.bakeRecipePicker)
        }
    }

    private var displayedHistory: [BakeRecord] {
        let trimmedSearch = bakeSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredByName = trimmedSearch.isEmpty ? store.bakeHistory : store.bakeHistory.filter { record in
            record.recipeSnapshotName.localizedStandardContains(trimmedSearch)
        }
        return filteredByName.sorted { lhs, rhs in
            switch bakeStartedSort {
            case .newestFirst:
                return lhs.startedAt > rhs.startedAt
            case .oldestFirst:
                return lhs.startedAt < rhs.startedAt
            }
        }
    }

    private func icon(for record: BakeRecord) -> BakingIcon {
        if let recipeID = record.recipeID,
           let recipe = store.savedRecipes.first(where: { $0.id == recipeID }) {
            return BakingIcon.recipeKind(recipe.kind)
        }
        return .recipe
    }
}

private enum BakeStartedSort {
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

    var toggled: BakeStartedSort {
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
            return BakingTerms.bakeSortStartedNewest
        case .oldestFirst:
            return BakingTerms.bakeSortStartedOldest
        }
    }
}

struct BakeHistoryRow: View {
    let record: BakeRecord
    let icon: BakingIcon

    var body: some View {
        HStack(spacing: 12) {
            BakingMaterialIconBadge(icon: icon)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.recipeSnapshotName)
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(Color.brandText)

                Text(dateRangeText)
                    .font(.caption)
                    .foregroundStyle(Color.brandSecondaryText)
            }

            Spacer()
        }
        .frame(minHeight: 64)
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.vertical, BakingSpace.sm)
        .contentShape(Rectangle())
    }

    private var dateRangeText: String {
        let start = record.startedAt.formatted(date: .abbreviated, time: .shortened)
        if let completedAt = record.completedAt {
            return "\(start) - \(completedAt.formatted(date: .omitted, time: .shortened))"
        }
        return start
    }
}
