import SwiftUI

struct RecipeWorkflowBadge: View {
    let state: RecipeWorkflowState

    var body: some View {
        Text(state.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(borderColor, lineWidth: 0.6)
            }
    }

    private var foregroundColor: Color {
        switch state {
        case .draft:
            return .brandPrimaryLight   // accent-hover reads cleaner on the soft gold fill
        case .ready:
            return .brandSage
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .draft:
            return BakingSurface.selectedRowBackground
        case .ready:
            return Color.brandSage.opacity(0.12)
        }
    }

    private var borderColor: Color {
        switch state {
        case .draft:
            return Color.brandPrimary.opacity(0.18)
        case .ready:
            return Color.brandSage.opacity(0.20)
        }
    }
}

struct RecipeWorkflowStateButton: View {
    @EnvironmentObject private var store: RecipeStore

    @State private var showingReadyConfirmation = false
    @State private var showingNeedsStepDialog = false

    var body: some View {
        BakingStatusCapsuleMenu(
            selectedID: selectedStatusID,
            options: statusOptions,
            accessibilityLabel: BakingTerms.stepsStatusMenuAccessibility,
            systemFont: .title3.weight(.semibold)
        ) { selectedID in
            selectStatus(selectedID)
        }
        .confirmationDialog(
            BakingTerms.workflowReadyConfirmationTitle,
            isPresented: $showingReadyConfirmation,
            titleVisibility: .visible
        ) {
            Button(BakingTerms.stepsMarkReady) {
                _ = store.markReadyToBake()
            }
            Button(BakingTerms.cancel, role: .cancel) {}
        }
        .confirmationDialog(
            BakingTerms.readinessNeedsSteps,
            isPresented: $showingNeedsStepDialog,
            titleVisibility: .visible
        ) {
            Button(BakingTerms.done, role: .cancel) {}
        }
    }

    private var selectedStatusID: String {
        store.isReadyToBake ? "ready" : "draft"
    }

    private var statusOptions: [BakingStatusCapsuleOption] {
        [
            BakingStatusCapsuleOption(
                id: "draft",
                icon: .baking(.edit),
                title: BakingTerms.stepsStateDraftShort,
                role: .primary
            ),
            BakingStatusCapsuleOption(
                id: "ready",
                icon: .baking(.complete),
                title: BakingTerms.stepsStateReadyShort,
                role: .success
            )
        ]
    }

    private func selectStatus(_ selectedID: String) {
        guard selectedID != selectedStatusID else { return }

        if selectedID == "draft" {
            store.markDraft()
            return
        }

        guard store.canMarkReadyToBake else {
            showingNeedsStepDialog = true
            return
        }

        if store.steps.count < 3 || store.items.count < 3 {
            showingReadyConfirmation = true
        } else {
            _ = store.markReadyToBake()
        }
    }
}
