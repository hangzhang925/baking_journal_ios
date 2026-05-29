import SwiftUI

struct BakeHistoryView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore

    var body: some View {
        List {
            Section {
                if !store.hasLoadedPersistedState {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 220)
                        .listRowBackground(Color.clear)
                } else if sortedHistory.isEmpty {
                    BakingEmptyState(title: BakingTerms.noRecords, systemImage: "clock.arrow.circlepath")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedHistory) { record in
                        if record.id == store.activeBakeRecordID && record.completedAt == nil {
                            Button {
                                navigationController.push(.cook)
                            } label: {
                                BakeHistoryRow(record: record)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                navigationController.push(.bakeRecordDetail(record.id))
                            } label: {
                                BakeHistoryRow(record: record)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
    }

    private var sortedHistory: [BakeRecord] {
        store.bakeHistory.sorted { $0.startedAt > $1.startedAt }
    }
}

private struct BakeHistoryRow: View {
    let record: BakeRecord

    var body: some View {
        HStack(spacing: 12) {
            BakingMaterialIconBadge(
                icon: .timer,
                size: BakingTouchTarget.materialBadge,
                iconSize: BakingTouchTarget.materialBadgeGlyph,
                color: statusColor,
                background: statusColor.opacity(0.10)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(record.recipeSnapshotName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brandText)

                Text(dateRangeText)
                    .font(.caption)
                    .foregroundStyle(Color.brandSecondaryText)
            }

            Spacer()

            Image(systemName: record.completedAt == nil ? "flame.fill" : "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(statusColor)
        }
        .padding(.vertical, 3)
    }

    private var statusColor: Color {
        record.completedAt == nil ? .brandPrimary : .brandSage
    }

    private var dateRangeText: String {
        let start = record.startedAt.formatted(date: .abbreviated, time: .shortened)
        if let completedAt = record.completedAt {
            return "\(start) - \(completedAt.formatted(date: .omitted, time: .shortened))"
        }
        return start
    }
}
