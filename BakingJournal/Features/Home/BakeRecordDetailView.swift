import SwiftUI

struct BakeRecordDetailView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    let recordID: UUID

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

            BakeRecordReviewContent(
                record: record,
                notes: notesBinding,
                onOpenRecipe: linkedRecipe == nil ? nil : openLinkedRecipe
            )
        }
        .background(Color.brandBackground)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var record: BakeRecord {
        store.bakeHistory.first(where: { $0.id == recordID }) ?? BakeRecord(
            id: recordID,
            recipeID: nil,
            recipeName: BakingTerms.unknownRecipe,
            recipeSnapshotName: BakingTerms.unknownRecipe,
            startedAt: Date(),
            completedAt: nil,
            notes: "",
            stepCount: 0
        )
    }

    private var linkedRecipe: SavedRecipe? {
        guard let recipeID = record.recipeID else { return nil }
        return store.savedRecipes.first { $0.id == recipeID }
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { record.notes },
            set: { store.updateBakeRecordNotes($0, for: record) }
        )
    }

    private func openLinkedRecipe() {
        guard let linkedRecipe else { return }
        store.loadRecipe(linkedRecipe)
        navigationController.push(.recipeWorkspace(.formula))
    }
}

enum BakeRecordReviewNotesEditingStyle {
    case popup
    case inline
}

struct BakeRecordReviewContent: View {
    let record: BakeRecord
    @Binding var notes: String
    var onOpenRecipe: (() -> Void)? = nil
    var showsTitleHeader = true
    var notesEditingStyle: BakeRecordReviewNotesEditingStyle = .popup
    @State private var showingReviewNotesEditor = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: BakingSpace.lg) {
                if showsTitleHeader {
                    titleHeader
                }
                timeSummaryTable
                stepTimingTable
                reviewNotesSection
            }
            .padding(.horizontal, BakingLayout.screenHorizontalInset)
            .padding(.top, BakingLayout.contentTopInset)
            .padding(.bottom, BakingSpace.xl)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Color.brandBackground)
        .sheet(isPresented: $showingReviewNotesEditor) {
            BakingNotesEditorSheet(
                title: BakingTerms.reviewNotes,
                text: $notes,
                accessibilityLabel: BakingTerms.reviewNotes
            )
        }
    }

    private var titleHeader: some View {
        HStack(alignment: .center, spacing: BakingSpace.sm) {
            titleControl
                .layoutPriority(1)

            Spacer(minLength: BakingSpace.sm)

            if record.completedAt != nil {
                BakingStatusBadge(text: BakingTerms.cookCompletedStatus)
            }
        }
        .padding(.vertical, BakingSpace.xs)
    }

    @ViewBuilder
    private var titleControl: some View {
        if let onOpenRecipe {
            BakingInlineActionButton(
                title: record.recipeSnapshotName,
                accessibilityLabel: BakingTerms.bakeRecordOpenRecipe,
                role: .secondary,
                action: onOpenRecipe
            )
            .accessibilityLabel(BakingTerms.bakeRecordOpenRecipe)
            .accessibilityValue(record.recipeSnapshotName)
        } else {
            titleText
        }
    }

    private var titleText: some View {
        Text(record.recipeSnapshotName)
            .font(BakingTypography.screenTitle)
            .foregroundStyle(Color.brandText)
            .lineLimit(2)
            .minimumScaleFactor(0.82)
            .multilineTextAlignment(.leading)
            .frame(minHeight: BakingTouchTarget.iconButton, alignment: .leading)
    }

    private var timeSummaryTable: some View {
        BakingSectionCard(title: BakingTerms.time) {
            BakeRecordTableRow(
                title: BakingTerms.start,
                value: BakingFormat.bakeRecordDateTime(record.startedAt)
            )

            BakingTableDivider()

            BakeRecordTableRow(
                title: BakingTerms.end,
                value: completedAtText
            )
        }
    }

    private var stepTimingTable: some View {
        BakingSectionCard(title: BakingTerms.bakeRecordStepTimingSection) {
            BakeRecordStepTimingHeader()

            ForEach(stepTimingRows) { row in
                BakingTableDivider()

                BakeRecordStepTimingRow(row: row)
            }
        }
    }

    @ViewBuilder
    private var reviewNotesSection: some View {
        switch notesEditingStyle {
        case .popup:
            BakingEditableNotesCard(
                title: BakingTerms.reviewNotes,
                text: notes,
                emptyText: BakingTerms.bakeRecordNoReviewNotes,
                accessibilityLabel: BakingTerms.bakeRecordEditReviewNotes
            ) {
                showingReviewNotesEditor = true
            }
        case .inline:
            BakingSectionCard(title: BakingTerms.reviewNotes) {
                BakingMultilineTextEditor(text: $notes)
                    .frame(minHeight: BakingComponentMetrics.popupNotesEditorMinHeight)
                    .background(Color.clear)
                    .padding(10)
                    .bakingInsetSurface()
                    .accessibilityLabel(BakingTerms.reviewNotes)
                    .padding(.horizontal, BakingSpace.md)
                    .padding(.bottom, BakingSpace.md)
            }
        }
    }

    private var completedAtText: String {
        if let completedAt = record.completedAt {
            return BakingFormat.bakeRecordDateTime(completedAt)
        }
        return BakingTerms.notFinished
    }

    private var stepTimingRows: [BakeRecordStepTimingRowData] {
        if !record.stepTimings.isEmpty {
            return record.stepTimings.enumerated().map { index, timing in
                BakeRecordStepTimingRowData(
                    id: timing.id.uuidString,
                    stepName: timing.stepName,
                    startedAt: timing.startedAt,
                    completedAt: timing.completedAt ?? record.completedAt,
                    index: index
                )
            }
        }

        let count = max(record.stepCount, 0)
        guard count > 0 else { return [] }

        let completedAt = record.completedAt ?? record.startedAt
        let totalDuration = max(0, completedAt.timeIntervalSince(record.startedAt))
        let stepDuration = count > 0 ? totalDuration / Double(count) : 0

        return (0..<count).map { index in
            let startedAt = record.startedAt.addingTimeInterval(stepDuration * Double(index))
            let endedAt = index == count - 1
                ? record.completedAt
                : record.startedAt.addingTimeInterval(stepDuration * Double(index + 1))
            return BakeRecordStepTimingRowData(
                id: "fallback-\(index)",
                stepName: BakingTerms.stepDefaultName(index + 1),
                startedAt: startedAt,
                completedAt: endedAt,
                index: index
            )
        }
    }
}

struct BakeRecordReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let record: BakeRecord
    @Binding var notes: String

    var body: some View {
        VStack(spacing: 0) {
            BakingTopActionRow(trailing: {
                BakingSystemIconButton(
                    systemImage: "xmark",
                    accessibilityLabel: BakingTerms.done,
                    role: .secondary,
                    size: .secondary,
                    font: .caption.weight(.bold)
                ) {
                    dismiss()
                }
            })

            BakeRecordReviewContent(
                record: record,
                notes: $notes,
                showsTitleHeader: false,
                notesEditingStyle: .inline
            )
        }
        .background(Color.brandBackground)
        .presentationDetents([BakingPopupSheetMetrics.editSheetTallDetent])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.brandBackground)
    }
}

private struct BakeRecordTableRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .center, spacing: BakingSpace.md) {
            BakingLabel(text: title, role: .popupRowLabel)
                .lineLimit(1)

            Spacer(minLength: BakingSpace.md)

            Text(value)
                .font(BakingTypography.tableNumber)
                .foregroundStyle(Color.brandSecondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, BakingSpace.md)
        .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
    }
}

private struct BakeRecordStepTimingHeader: View {
    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            Text(BakingTerms.bakeRecordStepColumn)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(BakingTerms.start)
                .frame(width: BakeRecordStepTimingMetrics.timeColumnWidth, alignment: .trailing)

            Text(BakingTerms.end)
                .frame(width: BakeRecordStepTimingMetrics.timeColumnWidth, alignment: .trailing)
        }
        .font(BakingTypography.tableHeader)
        .foregroundStyle(Color.brandSecondaryText)
        .padding(.horizontal, BakingSpace.md)
        .frame(minHeight: 40)
    }
}

private enum BakeRecordStepTimingMetrics {
    static let timeColumnWidth: CGFloat = 94
}

private struct BakeRecordStepTimingRow: View {
    let row: BakeRecordStepTimingRowData

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: BakingSpace.sm) {
            Text(row.stepName)
                .font(BakingTypography.tableCell)
                .foregroundStyle(Color.brandText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)

            BakeRecordClockMetric(date: row.startedAt)

            BakeRecordClockMetric(date: row.completedAt)
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.sm)
        .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
    }
}

private struct BakeRecordClockMetric: View {
    let date: Date?

    var body: some View {
        BakingTableMetricValue(
            symbol: nil,
            value: timeParts.value,
            unit: timeParts.unit,
            numericKind: .clockTime,
            width: BakeRecordStepTimingMetrics.timeColumnWidth,
            isActive: date != nil,
            valueColor: .brandSecondaryText,
            unitColor: .brandSecondaryText
        )
    }

    private var timeParts: (value: String, unit: String?) {
        guard let date else { return (BakingTerms.notFinished, nil) }
        return (BakingFormat.bakeRecordClockTime(date), nil)
    }
}

private struct BakeRecordStepTimingRowData: Identifiable {
    let id: String
    let stepName: String
    let startedAt: Date
    let completedAt: Date?
    let index: Int
}
