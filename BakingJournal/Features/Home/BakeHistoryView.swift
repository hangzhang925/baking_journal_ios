import SwiftUI

struct BakeHistoryView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    @State private var bakeStartedSort: BakeStartedSort = .newestFirst
    @State private var bakeSearchText = ""
    @State private var bakeRecordPendingDeletion: BakeRecord?
    @State private var showingDeleteBakeRecordConfirmation = false

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
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    bakeRecordPendingDeletion = record
                                    showingDeleteBakeRecordConfirmation = true
                                } label: {
                                    Label(BakingTerms.delete, systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listRowBackground(BakingSurface.rowBackground)
            }
        }
        .confirmationDialog(
            BakingTerms.bakeRecordDeleteConfirmationTitle,
            isPresented: $showingDeleteBakeRecordConfirmation,
            titleVisibility: .visible,
            presenting: bakeRecordPendingDeletion
        ) { record in
            Button(BakingTerms.bakeRecordDeleteConfirmationButton, role: .destructive) {
                store.deleteBakeRecord(record)
                bakeRecordPendingDeletion = nil
            }
            Button(BakingTerms.cancel, role: .cancel) {
                bakeRecordPendingDeletion = nil
            }
        } message: { record in
            Text(BakingTerms.bakeRecordDeleteConfirmationMessage(record.recipeSnapshotName))
        }
        .onChange(of: showingDeleteBakeRecordConfirmation) { _, isPresented in
            if !isPresented {
                bakeRecordPendingDeletion = nil
            }
        }
    }

    private func historyRowButton(for record: BakeRecord) -> some View {
        Button {
            if store.canResumeBake(record) {
                store.resumeBake(record)
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

    private var isOngoing: Bool {
        record.completedAt == nil
    }

    var body: some View {
        HStack(spacing: BakingSpace.lg) {
            BakingMaterialIconBadge(icon: icon)

            VStack(alignment: .leading, spacing: BakingSpace.xs) {
                Text(record.recipeSnapshotName)
                    .font(BakingTypography.rowTitle)
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(stepCountText)
                    .font(BakingTypography.rowMeta.monospacedDigit())
                    .foregroundStyle(Color.brandSecondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                if isOngoing {
                    BakeRecordOngoingBadge()
                } else {
                    Color.clear
                        .accessibilityHidden(true)
                }
            }
            .frame(width: BakingComponentMetrics.libraryRowStatusColumnWidth, alignment: .center)

            VStack(alignment: .trailing, spacing: BakingSpace.xs) {
                RecipeLibraryMetadataLine(
                    title: BakingTerms.bakeRecordStartedAt,
                    value: record.startedAt.formatted(date: .numeric, time: .shortened)
                )

                if let completedAt = record.completedAt {
                    RecipeLibraryMetadataLine(
                        title: BakingTerms.bakeRecordCompletedAt,
                        value: completedAt.formatted(date: .omitted, time: .shortened)
                    )
                }
            }
            .frame(width: BakingComponentMetrics.libraryRowMetadataColumnWidth, alignment: .trailing)
        }
        .frame(minHeight: BakingComponentMetrics.listRowMinHeight)
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.vertical, BakingSpace.sm)
        .contentShape(Rectangle())
    }

    private var stepCountText: String {
        BakingTerms.recipeMetadataLine(BakingTerms.stepCount, BakingFormat.number(Double(record.stepCount), precision: 0))
    }
}

struct BakeRecordOngoingBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.brandPrimaryLight)
                .frame(width: 6, height: 6)

            Text(BakingTerms.bakeRecordOngoing)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.brandPrimaryLight)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(BakingSurface.selectedRowBackground)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Color.brandPrimaryLight.opacity(0.18), lineWidth: 0.6)
        }
        .accessibilityLabel(BakingTerms.bakeRecordOngoing)
    }
}
