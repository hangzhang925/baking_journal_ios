import SwiftUI

enum RecipeWorkspaceStage: String, CaseIterable, Hashable, Identifiable {
    case preview
    case formula
    case steps

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preview: BakingTerms.workspaceStagePreview
        case .formula: BakingTerms.workspaceStageFormula
        case .steps: BakingTerms.workspaceStageSteps
        }
    }

    var isPrimaryTab: Bool {
        switch self {
        case .preview: false
        case .formula, .steps: true
        }
    }
}

struct RecipeWorkspaceView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    @State private var stage: RecipeWorkspaceStage
    @State private var justSaved = false

    init(initialStage: RecipeWorkspaceStage = .formula) {
        _stage = State(initialValue: initialStage)
    }

    var body: some View {
        VStack(spacing: 0) {
            workspaceHeader

            WorkspaceStagePageContainer(selection: $stage) { stage in
                workspaceContent(stage)
            }
        }
        .background(Color.brandBackground)
    }

    @ViewBuilder
    private func workspaceContent(_ stage: RecipeWorkspaceStage) -> some View {
        switch stage {
        case .preview:
            RecipePreviewView(showsToolbar: false)
        case .formula:
            FormulaView(embedded: true)
        case .steps:
            StepsView(embedded: true)
        }
    }

    private var workspaceHeader: some View {
        VStack(spacing: BakingSpace.xs) {
            BakingTopActionRow(
                leading: {
                    if navigationController.canGoBack {
                        BakingIconButton(
                            icon: .back,
                            accessibilityLabel: BakingTerms.back
                        ) {
                            navigationController.goBack()
                        }
                    }
                },
                trailing: {
                    saveButton
                }
            )
            .padding(.horizontal, -14)

            HStack(spacing: BakingSpace.sm) {
                ForEach(RecipeWorkspaceStage.allCases) { stage in
                    workspaceStageButton(stage)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(BakingTerms.workspaceStagePicker)

        }
        .padding(.horizontal, 16)
        .padding(.top, 0)
        .padding(.bottom, 8)
        .background(Color.brandBackground)
    }

    private func workspaceStageButton(_ nextStage: RecipeWorkspaceStage) -> some View {
        Button {
            withAnimation(BakingMotion.standard) {
                stage = nextStage
            }
        } label: {
            workspaceStageButtonLabel(nextStage)
                .frame(maxWidth: nextStage.isPrimaryTab ? .infinity : nil)
                .frame(width: nextStage.isPrimaryTab ? nil : 72)
                .frame(height: nextStage.isPrimaryTab ? 38 : 34)
                .background(
                    RoundedRectangle(cornerRadius: BakingRadius.card, style: .continuous)
                        .fill(stage == nextStage ? Color.brandPrimary.opacity(0.12) : Color.brandSurface.opacity(0.92))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: BakingRadius.card, style: .continuous)
                        .stroke(stage == nextStage ? Color.brandPrimary.opacity(0.24) : Color.brandPrimary.opacity(0.08), lineWidth: 0.6)
                }
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(nextStage.title)
    }

    @ViewBuilder
    private func workspaceStageButtonLabel(_ nextStage: RecipeWorkspaceStage) -> some View {
        let tint = stage == nextStage ? Color.brandPrimary : Color.brandSecondaryText
        switch nextStage {
        case .preview:
            BakingIconView(icon: .preview, size: BakingTouchTarget.secondaryActionGlyph, color: tint)
        case .formula, .steps:
            Text(nextStage.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
        }
    }

    private var saveButton: some View {
        BakingIconButton(
            icon: .save,
            accessibilityLabel: justSaved ? BakingTerms.saved : BakingTerms.save,
            role: justSaved ? .success : .primary
        ) {
            store.saveCurrentRecipe()
            flashSavedState()
        }
    }

    private func flashSavedState() {
        justSaved = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            justSaved = false
        }
    }
}

private struct WorkspaceStagePageContainer<Content: View>: View {
    @Binding var selection: RecipeWorkspaceStage
    @ViewBuilder let content: (RecipeWorkspaceStage) -> Content

    var body: some View {
        TabView(selection: $selection) {
            ForEach(RecipeWorkspaceStage.allCases) { stage in
                content(stage)
                    .tag(stage)
                    .background(Color.brandBackground)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color.brandBackground)
    }
}
