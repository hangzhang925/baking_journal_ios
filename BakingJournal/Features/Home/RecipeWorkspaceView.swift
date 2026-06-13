import SwiftUI
import UIKit
import Photos
import UniformTypeIdentifiers

enum RecipeWorkspaceStage: String, CaseIterable, Hashable, Identifiable {
    case preview
    case formula
    case steps
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preview: BakingTerms.workspaceStagePreview
        case .formula: BakingTerms.workspaceStageFormula
        case .steps: BakingTerms.workspaceStageSteps
        case .history: BakingTerms.workspaceStageHistory
        }
    }

    var icon: BakingToggleIcon {
        switch self {
        case .preview:
            return .baking(.preview)
        case .formula:
            return .baking(.recipe)
        case .steps:
            return .baking(.process)
        case .history:
            return .baking(.bakes)
        }
    }

    var segmentedOption: BakingSegmentedStageOption {
        BakingSegmentedStageOption(id: id, icon: icon, title: title)
    }
}

struct RecipeWorkspaceView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    @State private var stage: RecipeWorkspaceStage
    @State private var pendingWorkspaceAction: WorkspaceConfirmationAction?
    @State private var showingWorkspaceActions = false
    @State private var showingTextTutorial = false
    @State private var exportError: String?
    @State private var exportSuccessMessage: String?
    @State private var jsonExportDocument = RecipeBackupDocument(data: Data())
    @State private var showingJSONExportInstructions = false
    @State private var showingJSONExporter = false
    @State private var jsonExportError: String?

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
        .confirmationDialog(
            pendingWorkspaceAction?.title ?? "",
            isPresented: Binding(
                get: { pendingWorkspaceAction != nil },
                set: { if !$0 { pendingWorkspaceAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let pendingWorkspaceAction {
                Button(pendingWorkspaceAction.confirmTitle, role: pendingWorkspaceAction.role) {
                    perform(pendingWorkspaceAction)
                }
            }

            Button(BakingTerms.cancel, role: .cancel) {
                pendingWorkspaceAction = nil
            }
        } message: {
            if let pendingWorkspaceAction {
                Text(pendingWorkspaceAction.message(recipeName: store.currentRecipeDisplayName))
            }
        }
        .sheet(isPresented: $showingTextTutorial) {
            RecipePreviewTextTutorialSheet(text: previewShareContent.textTutorial)
        }
        .fileExporter(
            isPresented: $showingJSONExporter,
            document: jsonExportDocument,
            contentType: .json,
            defaultFilename: jsonExportFilename
        ) { result in
            if case .failure(let error) = result {
                jsonExportError = error.localizedDescription
            }
        }
        .sheet(isPresented: $showingJSONExportInstructions) {
            RecipeExportInstructionSheet {
                showingJSONExportInstructions = false
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(250))
                    showingJSONExporter = true
                }
            }
        }
        .alert(BakingTerms.recipePreviewExportFailed, isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button(BakingTerms.ok, role: .cancel) {
                exportError = nil
            }
        } message: {
            Text(exportError ?? "")
        }
        .alert(BakingTerms.recipePreviewSaveImageSucceeded, isPresented: Binding(
            get: { exportSuccessMessage != nil },
            set: { if !$0 { exportSuccessMessage = nil } }
        )) {
            Button(BakingTerms.ok, role: .cancel) {
                exportSuccessMessage = nil
            }
        } message: {
            Text(exportSuccessMessage ?? "")
        }
        .alert(BakingTerms.formulaFileOperationFailed, isPresented: Binding(
            get: { jsonExportError != nil },
            set: { if !$0 { jsonExportError = nil } }
        )) {
            Button(BakingTerms.ok, role: .cancel) {
                jsonExportError = nil
            }
        } message: {
            Text(jsonExportError ?? "")
        }
        .onAppear {
            store.refreshCurrentRecipeForDisplay()
        }
    }

    @ViewBuilder
    private func workspaceContent(_ stage: RecipeWorkspaceStage) -> some View {
        switch stage {
        case .preview:
            RecipePreviewView(toolbarMode: .embedded)
        case .formula:
            FormulaView(embedded: true)
        case .steps:
            StepsView(embedded: true)
        case .history:
            RecipeBakeHistoryStageView()
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
                center: {
                    RecipeKindPinnedLabel(kind: store.currentRecipeKind)
                },
                trailing: {
                    Button {
                        showingWorkspaceActions = true
                    } label: {
                        BakingTopSystemIconButtonLabel(systemImage: "ellipsis", tint: .brandText)
                    }
                    .buttonStyle(BakingPressFeedbackButtonStyle())
                    .accessibilityLabel(BakingTerms.moreActions)
                    .popover(isPresented: $showingWorkspaceActions, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                        BakingDropdownPopover(width: 188) {
                            workspaceDirectActionRow(
                                title: BakingTerms.saveAsImage
                            ) {
                                saveLongImage()
                            }

                            workspaceDirectActionRow(
                                title: BakingTerms.generateTextTutorial
                            ) {
                                showingTextTutorial = true
                            }

                            workspaceDirectActionRow(
                                title: BakingTerms.formulaExportJSON
                            ) {
                                exportJSON()
                            }

                            workspaceActionRow(
                                action: store.isReadyToBake ? .startBake : .reviewBeforeBake
                            )

                            workspaceActionRow(
                                action: .copyRecipe
                            )

                            workspaceActionRow(
                                action: .deleteRecipe,
                                isEnabled: currentRecipe != nil
                            )
                        }
                    }
                }
            )
            .padding(.horizontal, -14)

            BakingSegmentedStageControl(
                selectedID: stage.id,
                options: RecipeWorkspaceStage.allCases.map(\.segmentedOption),
                accessibilityLabel: BakingTerms.workspaceStagePicker
            ) { selectedID in
                guard let selectedStage = RecipeWorkspaceStage(rawValue: selectedID) else { return }
                stage = selectedStage
            }
            .padding(.horizontal, -4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 0)
        .padding(.bottom, BakingSpace.xs)
        .background(Color.brandBackground)
    }

    private var currentRecipe: SavedRecipe? {
        guard let currentRecipeID = store.currentRecipeID else { return nil }
        return store.savedRecipes.first { $0.id == currentRecipeID }
    }

    private var previewShareContent: RecipePreviewShareContent {
        RecipePreviewShareContent(store: store)
    }

    private var jsonExportFilename: String {
        store.currentRecipeDisplayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
    }

    private func workspaceDirectActionRow(
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            showingWorkspaceActions = false
            action()
        } label: {
            BakingDropdownRow(title: title, showsLeadingSlot: false) {
                EmptyView()
            }
        }
        .buttonStyle(.plain)
    }

    private func workspaceActionRow(
        action: WorkspaceConfirmationAction,
        isEnabled: Bool = true
    ) -> some View {
        Button {
            showingWorkspaceActions = false
            pendingWorkspaceAction = action
        } label: {
            BakingDropdownRow(title: action.menuTitle, showsLeadingSlot: false) {
                EmptyView()
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func perform(_ action: WorkspaceConfirmationAction) {
        pendingWorkspaceAction = nil
        switch action {
        case .startBake:
            guard store.startNewBake() else { return }
            navigationController.selectTab(.history)
            navigationController.push(.cook)
        case .reviewBeforeBake:
            stage = .steps
        case .copyRecipe:
            store.copyCurrentRecipe()
            stage = .formula
        case .deleteRecipe:
            if let currentRecipe {
                store.deleteRecipe(currentRecipe)
            }
            navigationController.popToHome()
        }
    }

    private func saveLongImage() {
        guard let image = previewShareContent.renderLongImage() else {
            exportError = BakingTerms.recipePreviewExportRenderFailed
            return
        }
        saveImageToPhotoLibrary(image)
    }

    private func exportJSON() {
        do {
            jsonExportDocument = RecipeBackupDocument(data: try store.exportCurrentRecipeExchangeData())
            showingJSONExportInstructions = true
        } catch {
            jsonExportError = error.localizedDescription
        }
    }

    private func saveImageToPhotoLibrary(_ image: UIImage) {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            performPhotoLibrarySave(image)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                Task { @MainActor in
                    if status == .authorized || status == .limited {
                        performPhotoLibrarySave(image)
                    } else {
                        exportError = BakingTerms.recipePreviewPhotoAccessDenied
                    }
                }
            }
        case .denied, .restricted:
            exportError = BakingTerms.recipePreviewPhotoAccessDenied
        @unknown default:
            exportError = BakingTerms.recipePreviewPhotoAccessDenied
        }
    }

    private func performPhotoLibrarySave(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            Task { @MainActor in
                if success {
                    exportSuccessMessage = BakingTerms.recipePreviewSaveImageSucceededMessage
                } else {
                    exportError = error?.localizedDescription ?? BakingTerms.recipePreviewSaveImageFailed
                }
            }
        }
    }
}

private enum WorkspaceConfirmationAction: Identifiable {
    case startBake
    case reviewBeforeBake
    case copyRecipe
    case deleteRecipe

    var id: String {
        switch self {
        case .startBake:
            return "startBake"
        case .reviewBeforeBake:
            return "reviewBeforeBake"
        case .copyRecipe:
            return "copyRecipe"
        case .deleteRecipe:
            return "deleteRecipe"
        }
    }

    var title: String {
        switch self {
        case .startBake:
            return BakingTerms.startBakeConfirmationTitle
        case .reviewBeforeBake:
            return BakingTerms.reviewBeforeBakeConfirmationTitle
        case .copyRecipe:
            return BakingTerms.copyRecipeConfirmationTitle
        case .deleteRecipe:
            return BakingTerms.deleteRecipeConfirmationTitle
        }
    }

    func message(recipeName: String) -> String {
        switch self {
        case .startBake:
            return BakingTerms.startBakeConfirmationMessage
        case .reviewBeforeBake:
            return BakingTerms.reviewBeforeBakeConfirmationMessage
        case .copyRecipe:
            return BakingTerms.copyRecipeConfirmationMessage
        case .deleteRecipe:
            return BakingTerms.deleteRecipeConfirmationMessage(recipeName)
        }
    }

    var confirmTitle: String {
        switch self {
        case .startBake:
            return BakingTerms.startBake
        case .reviewBeforeBake:
            return BakingTerms.viewIncompleteSteps
        case .copyRecipe:
            return BakingTerms.copyRecipe
        case .deleteRecipe:
            return BakingTerms.deleteRecipeConfirmationButton
        }
    }

    var menuTitle: String {
        switch self {
        case .startBake, .reviewBeforeBake:
            return BakingTerms.bakeAction
        case .copyRecipe:
            return BakingTerms.copy
        case .deleteRecipe:
            return BakingTerms.delete
        }
    }

    var role: ButtonRole? {
        switch self {
        case .deleteRecipe:
            return .destructive
        default:
            return nil
        }
    }
}

private struct RecipeBakeHistoryStageView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    @State private var selectedBakeRecord: BakeRecord?

    var body: some View {
        BakingLibraryList {
            Section {
                if recipeHistory.isEmpty {
                    BakingEmptyState(title: BakingTerms.noRecords, systemImage: "clock.arrow.circlepath")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(recipeHistory) { record in
                        Button {
                            if store.canResumeBake(record) {
                                openCurrentBake(record)
                            } else {
                                selectedBakeRecord = record
                            }
                        } label: {
                            BakeHistoryRow(record: record, icon: recipeIcon)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(BakingSurface.rowBackground)
                    }
                }
            }
            .listRowBackground(BakingSurface.rowBackground)
        }
        .sheet(item: $selectedBakeRecord) { record in
            BakeRecordReviewSheet(
                record: record,
                notes: notesBinding(for: record)
            )
        }
    }

    private var recipeHistory: [BakeRecord] {
        guard let currentRecipeID = store.currentRecipeID else { return [] }
        return store.bakeHistory
            .filter { $0.recipeID == currentRecipeID }
            .sorted { $0.startedAt > $1.startedAt }
    }

    private func openCurrentBake(_ record: BakeRecord) {
        store.resumeBake(record)
        navigationController.selectTab(.history)
        navigationController.push(.cook)
    }

    private func notesBinding(for record: BakeRecord) -> Binding<String> {
        Binding(
            get: {
                store.bakeHistory.first(where: { $0.id == record.id })?.notes ?? record.notes
            },
            set: { notes in
                store.updateBakeRecordNotes(notes, for: record)
            }
        )
    }

    private var recipeIcon: BakingIcon {
        guard let currentRecipeID = store.currentRecipeID,
              let recipe = store.savedRecipes.first(where: { $0.id == currentRecipeID }) else {
            return .recipe
        }
        return BakingIcon.recipeKind(recipe.kind)
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
