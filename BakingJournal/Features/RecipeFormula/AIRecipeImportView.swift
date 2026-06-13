import SwiftUI
import UniformTypeIdentifiers

struct AIRecipeImportView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    @State private var importingRecipe = false
    @State private var importError: String?
    @State private var showingImportSuccess = false
    @State private var importFeedbackTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .top) {
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
                        fileCard
                    }
                    .padding(.horizontal, BakingLayout.screenHorizontalInset)
                    .padding(.top, BakingLayout.contentTopInset)
                    .padding(.bottom, BakingSpace.xxl)
                }
            }
            .safeAreaInset(edge: .bottom) {
                BakingBottomActionButton(
                    title: BakingTerms.recipeImportSelectFileAction,
                    accessibilityLabel: BakingTerms.recipeImportSelectFileAction
                ) {
                    importingRecipe = true
                }
            }
            .background(Color.brandBackground)
            .fileImporter(
                isPresented: $importingRecipe,
                allowedContentTypes: [.json]
            ) { result in
                importRecipe(result)
            }

            if showingImportSuccess {
                BakingTransientStatusToast(title: BakingTerms.recipeImportSucceeded)
                    .padding(.top, BakingSpace.lg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(BakingMotion.quick, value: showingImportSuccess)
        .alert(BakingTerms.aiRecipeImportFailedTitle, isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button(BakingTerms.ok, role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
        .onDisappear {
            importFeedbackTask?.cancel()
        }
    }

    private var tutorialCard: some View {
        BakingSectionCard(title: BakingTerms.aiRecipeImportTutorialTitle) {
            VStack(alignment: .leading, spacing: BakingSpace.md) {
                RecipeTransferInstructionRow(number: "1", text: BakingTerms.recipeImportTutorialChooseFile)
                RecipeTransferInstructionRow(number: "2", text: BakingTerms.recipeImportTutorialLoadRecipe)
                RecipeTransferInstructionRow(number: "3", text: BakingTerms.recipeImportTutorialEditAfterImport)
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.bottom, BakingSpace.md)
        }
    }

    private var fileCard: some View {
        BakingSectionCard(title: BakingTerms.recipeImportFileTitle) {
            Text(BakingTerms.recipeImportFileDescription)
                .font(BakingTypography.appPrimaryText)
                .foregroundStyle(Color.brandSecondaryText)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(BakingSpace.md)
                .bakingInsetSurface()
                .padding(.horizontal, BakingSpace.md)
                .padding(.bottom, BakingSpace.md)
        }
    }

    private func importRecipe(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            let data = try Data(contentsOf: url)
            try store.importRecipeData(data)
            showImportSuccess()
        } catch {
            importError = error.localizedDescription
        }
    }

    private func showImportSuccess() {
        importFeedbackTask?.cancel()

        withAnimation(BakingMotion.quick) {
            showingImportSuccess = true
        }

        importFeedbackTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.0))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                showingImportSuccess = false
            }
            navigationController.push(.recipeWorkspace(.formula))
        }
    }
}
