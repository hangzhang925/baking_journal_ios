import SwiftUI

struct BakeRecordDetailView: View {
    @EnvironmentObject private var store: RecipeStore
    let recordID: UUID

    var body: some View {
        List {
            Section(BakingTerms.time) {
                LabeledContent(BakingTerms.start) {
                    Text(record.startedAt.formatted(date: .abbreviated, time: .shortened))
                }
                LabeledContent(BakingTerms.end) {
                    if let completedAt = record.completedAt {
                        Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                    } else {
                        Text(BakingTerms.notFinished)
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent(BakingTerms.stepCount) {
                    Text("\(record.stepCount)")
                        .monospacedDigit()
                }
            }

            Section(BakingTerms.reviewNotes) {
                TextEditor(text: notesBinding)
                    .frame(minHeight: 160)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
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

    private var notesBinding: Binding<String> {
        Binding(
            get: { record.notes },
            set: { store.updateBakeRecordNotes($0, for: record) }
        )
    }
}

