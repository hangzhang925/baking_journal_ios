import SwiftUI
import UIKit

struct AIRecipeImportView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    @State private var jsonText = ""
    @State private var copiedMessage: String?
    @State private var importError: String?

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

            ScrollView {
                LazyVStack(spacing: BakingSpace.lg) {
                    tutorialCard
                    promptCard
                    jsonInputCard
                }
                .padding(.horizontal, BakingLayout.screenHorizontalInset)
                .padding(.top, BakingLayout.contentTopInset)
                .padding(.bottom, BakingSpace.xxl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom) {
            BakingBottomActionButton(
                title: BakingTerms.aiRecipeImportAction,
                accessibilityLabel: BakingTerms.aiRecipeImportAction,
                state: canImport ? .normal : .disabled
            ) {
                importRecipe()
            }
        }
        .background(Color.brandBackground)
        .alert(BakingTerms.copiedToClipboard, isPresented: Binding(
            get: { copiedMessage != nil },
            set: { if !$0 { copiedMessage = nil } }
        )) {
            Button(BakingTerms.ok, role: .cancel) { copiedMessage = nil }
        } message: {
            Text(copiedMessage ?? "")
        }
        .alert(BakingTerms.aiRecipeImportFailedTitle, isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button(BakingTerms.ok, role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }

    private var canImport: Bool {
        !jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var tutorialCard: some View {
        BakingSectionCard(title: BakingTerms.aiRecipeImportTutorialTitle) {
            VStack(alignment: .leading, spacing: BakingSpace.md) {
                tutorialRow(number: "1", text: BakingTerms.aiRecipeImportTutorialCopyPrompt)
                tutorialRow(number: "2", text: BakingTerms.aiRecipeImportTutorialUseAI)
                tutorialRow(number: "3", text: BakingTerms.aiRecipeImportTutorialPasteJSON)
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.bottom, BakingSpace.md)
        }
    }

    private var promptCard: some View {
        BakingSectionCard(title: BakingTerms.aiRecipeImportPromptTitle) {
            VStack(spacing: BakingSpace.md) {
                Text(BakingTerms.aiRecipeImportPromptPreview)
                    .font(BakingTypography.appPrimaryText)
                    .foregroundStyle(Color.brandSecondaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(BakingSpace.md)
                    .bakingInsetSurface()

                BakingActionButton(
                    title: BakingTerms.aiRecipeImportCopyPrompt,
                    accessibilityLabel: BakingTerms.aiRecipeImportCopyPrompt,
                    icon: .copy,
                    role: .secondary
                ) {
                    UIPasteboard.general.string = BakingTerms.aiRecipeImportPrompt
                    copiedMessage = BakingTerms.aiRecipeImportPromptCopied
                }
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.bottom, BakingSpace.md)
        }
    }

    private var jsonInputCard: some View {
        BakingSectionCard(title: BakingTerms.aiRecipeImportJSONTitle) {
            BakingMultilineTextEditor(text: $jsonText)
                .frame(minHeight: 240)
                .padding(10)
                .bakingInsetSurface()
                .accessibilityLabel(BakingTerms.aiRecipeImportJSONAccessibility)
                .padding(.horizontal, BakingSpace.md)
                .padding(.bottom, BakingSpace.md)
        }
    }

    private func tutorialRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: BakingSpace.sm) {
            Text(number)
                .font(BakingTypography.iconCaption)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 22, height: 22)
                .bakingSurface(.readOnly)
                .accessibilityHidden(true)

            Text(text)
                .font(BakingTypography.appPrimaryText)
                .foregroundStyle(Color.brandText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func importRecipe() {
        do {
            _ = try store.importRecipeExchangeJSONString(jsonText)
            navigationController.push(.recipeWorkspace(.formula))
        } catch {
            importError = error.localizedDescription
        }
    }
}
