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
                icon: icon,
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

    private var icon: BakingIcon {
        guard let linkedRecipe else { return .recipe }
        return BakingIcon.recipeKind(linkedRecipe.kind)
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

struct BakeRecordReviewContent: View {
    let record: BakeRecord
    let icon: BakingIcon
    @Binding var notes: String
    var onOpenRecipe: (() -> Void)?

    @State private var showingNotesEditor = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: BakingSpace.lg) {
                titleHeader
                timeSummaryTable
                stepTimingTable
                reviewNotesSection
            }
            .padding(.horizontal, BakingLayout.screenHorizontalInset)
            .padding(.top, BakingLayout.contentTopInset)
            .padding(.bottom, BakingSpace.xl)
        }
        .scrollIndicators(.hidden)
        .background(Color.brandBackground)
        .sheet(isPresented: $showingNotesEditor) {
            BakeRecordNotesEditorSheet(notes: $notes)
                .presentationDetents([.height(BakingPopupSheetMetrics.notesEditorDefaultHeight), .large])
        }
    }

    private var titleHeader: some View {
        HStack(spacing: BakingSpace.md) {
            BakingMaterialIconBadge(
                icon: icon,
                color: .brandPrimary,
                background: BakingSurfaceTheme.theme(for: .inputSurface).background
            )

            VStack(alignment: .leading, spacing: BakingSpace.xs) {
                Text(record.recipeSnapshotName)
                    .font(BakingTypography.screenTitle)
                    .foregroundStyle(Color.brandText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(BakingTerms.cookCompletedTitle)
                    .font(BakingTypography.rowMeta)
                    .foregroundStyle(Color.brandSage)
            }

            Spacer(minLength: 0)

            if let onOpenRecipe {
                BakingIconButton(
                    icon: .edit,
                    accessibilityLabel: BakingTerms.bakeRecordOpenRecipe,
                    role: .primary
                ) {
                    onOpenRecipe()
                }
            }
        }
        .padding(.vertical, BakingSpace.xs)
    }

    private var timeSummaryTable: some View {
        BakingSectionCard(title: BakingTerms.time) {
            BakeRecordTableRow(
                title: BakingTerms.start,
                value: record.startedAt.formatted(date: .abbreviated, time: .shortened)
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

    private var reviewNotesSection: some View {
        BakingSectionCard(
            title: BakingTerms.reviewNotes,
            accessory: {
                Button {
                    showingNotesEditor = true
                } label: {
                    BakingIconButtonLabel(
                        icon: .edit,
                        role: .secondary,
                        size: .inline
                    )
                }
                .buttonStyle(BakingPressFeedbackButtonStyle())
                .accessibilityLabel(BakingTerms.bakeRecordEditReviewNotes)
            }
        ) {
            Button {
                showingNotesEditor = true
            } label: {
                Text(reviewNotesText)
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(trimmedNotes.isEmpty ? Color.brandSecondaryText : Color.brandText)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
                    .padding(BakingSpace.md)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(BakingTerms.bakeRecordEditReviewNotes)
            .accessibilityValue(reviewNotesText)
        }
    }

    private var completedAtText: String {
        if let completedAt = record.completedAt {
            return completedAt.formatted(date: .abbreviated, time: .shortened)
        }
        return BakingTerms.notFinished
    }

    private var trimmedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var reviewNotesText: String {
        trimmedNotes.isEmpty ? BakingTerms.bakeRecordNoReviewNotes : notes
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
            symbol: date == nil ? nil : .systemImage("clock", .brandSecondaryText),
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
        let formatted = date.formatted(date: .omitted, time: .shortened)
        let parts = formatted.split(separator: " ")
        guard parts.count > 1, let unit = parts.last else {
            return (formatted, nil)
        }
        return (parts.dropLast().joined(separator: " "), String(unit))
    }
}

private struct BakeRecordStepTimingRowData: Identifiable {
    let id: String
    let stepName: String
    let startedAt: Date
    let completedAt: Date?
    let index: Int
}

private struct BakeRecordNotesEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var notes: String

    var body: some View {
        NavigationStack {
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

                TextEditor(text: $notes)
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(Color.brandText)
                    .frame(minHeight: BakingComponentMetrics.notesEditorMinHeight)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(BakingSpace.md)
                    .bakingInsetSurface()
                    .accessibilityLabel(BakingTerms.reviewNotes)
                    .padding(.horizontal, BakingLayout.screenHorizontalInset)
                    .padding(.top, BakingSpace.sm)

                Spacer(minLength: 0)
            }
            .background(Color.brandBackground)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
