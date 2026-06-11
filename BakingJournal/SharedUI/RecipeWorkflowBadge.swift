import SwiftUI

struct RecipeWorkflowBadge: View {
    let state: RecipeWorkflowState

    var body: some View {
        Text(state.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(state.badgeForegroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(borderColor, lineWidth: 0.6)
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

extension RecipeWorkflowState {
    var badgeForegroundColor: Color {
        switch self {
        case .draft:
            return .brandPrimaryLight
        case .ready:
            return .brandSage
        }
    }
}

struct RecipeKindPinnedLabel: View {
    let kind: RecipeKind

    var body: some View {
        Text(kind.label)
            .font(BakingTypography.rowMeta)
            .foregroundStyle(Color.brandPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, BakingSpace.md)
            .frame(height: BakingComponentMetrics.compactPillHeight)
            .background(BakingSurface.selectedRowBackground)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(BakingSurface.selectedStroke, lineWidth: 0.6)
            }
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel(BakingTerms.recipeKindPinnedAccessibility(kind.label))
    }
}

struct RecipeWorkflowStateButton: View {
    @EnvironmentObject private var store: RecipeStore

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

        _ = store.markReadyToBake()
    }
}
