import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var selectedTab: HomeTab = .recipes
    @State private var presentingNewRecipeWorkspace = false
    @State private var presentingSelectedRecipe = false

    var body: some View {
        TabView(selection: $selectedTab) {
            recipeLibrary
                .tabItem {
                    Label("配方", systemImage: "book.closed")
                }
                .tag(HomeTab.recipes)

            BakeHistoryView()
                .tabItem {
                    Label("记录", systemImage: "timer")
                }
                .tag(HomeTab.history)
        }
        .background(Color.brandBackground)
        .navigationTitle(selectedTab.title)
        .toolbar {
            if selectedTab == .recipes {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.createNewRecipe()
                        presentingNewRecipeWorkspace = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3.weight(.semibold))
                    }
                    .accessibilityLabel("新配方")
                }
            }
        }
        .navigationDestination(isPresented: $presentingNewRecipeWorkspace) {
            RecipeWorkspaceView()
        }
        .navigationDestination(isPresented: $presentingSelectedRecipe) {
            RecipePreviewView()
        }
    }

    private var recipeLibrary: some View {
        List {
            Section {
                if sortedRecipes.isEmpty {
                    ContentUnavailableView("暂无配方", systemImage: "book.closed")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedRecipes) { recipe in
                        Button {
                            store.loadRecipe(recipe)
                            presentingSelectedRecipe = true
                        } label: {
                            RecipeLibraryRow(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.deleteRecipe(recipe)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
    }

    private var sortedRecipes: [SavedRecipe] {
        store.savedRecipes.sorted { $0.updatedAt > $1.updatedAt }
    }
}

private enum HomeTab {
    case recipes
    case history

    var title: String {
        switch self {
        case .recipes: "配方"
        case .history: "烘焙记录"
        }
    }
}

private struct RecipeLibraryRow: View {
    let recipe: SavedRecipe

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.10))
                BakingIconView(icon: .recipe, size: 24, color: .brandPrimary)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brandText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.brandSecondaryText.opacity(0.72))
        }
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}

private struct BakeHistoryView: View {
    @EnvironmentObject private var store: RecipeStore

    var body: some View {
        List {
            Section {
                if sortedHistory.isEmpty {
                    ContentUnavailableView("暂无记录", systemImage: "clock.arrow.circlepath")
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedHistory) { record in
                        NavigationLink {
                            BakeRecordDetailView(recordID: record.id)
                        } label: {
                            BakeHistoryRow(record: record)
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
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.10))
                BakingIconView(icon: .timer, size: 22, color: statusColor)
            }
            .frame(width: 40, height: 40)

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

enum RecipeWorkspaceStage: String, CaseIterable, Identifiable {
    case formula
    case steps

    var id: String { rawValue }

    var title: String {
        switch self {
        case .formula: "配方"
        case .steps: "步骤"
        }
    }
}

struct RecipeWorkspaceView: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var stage: RecipeWorkspaceStage = .formula
    @State private var justSaved = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                workspaceStageControl
                saveButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 8)
            .background(Color.brandBackground)

            Group {
                switch stage {
                case .formula:
                    FormulaView(embedded: true)
                case .steps:
                    StepsView(embedded: true)
                }
            }
        }
        .navigationTitle(store.currentRecipeDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.brandBackground)
    }

    private var workspaceStageControl: some View {
        HStack(spacing: 4) {
            stageButton(.formula, title: "1 配方")
            stageButton(.steps, title: "2 步骤")
        }
        .padding(4)
        .background(Color.brandText.opacity(0.08))
        .clipShape(Capsule())
    }

    private func stageButton(_ target: RecipeWorkspaceStage, title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                stage = target
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(stage == target ? Color.brandText : Color.brandSecondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(stage == target ? Color.brandSurface : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var saveButton: some View {
        Button {
            store.saveCurrentRecipe()
            flashSavedState()
        } label: {
            Text(justSaved ? "已保存" : "保存")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(justSaved ? Color.brandSage : Color.brandPrimary)
                .frame(width: 88)
                .padding(.vertical, 10)
                .background(Color.brandSurface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(justSaved ? "已保存" : "保存")
    }

    private func flashSavedState() {
        justSaved = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            justSaved = false
        }
    }
}

private struct BakeRecordDetailView: View {
    @EnvironmentObject private var store: RecipeStore
    let recordID: UUID

    var body: some View {
        List {
            Section("时间") {
                LabeledContent("开始") {
                    Text(record.startedAt.formatted(date: .abbreviated, time: .shortened))
                }
                LabeledContent("结束") {
                    if let completedAt = record.completedAt {
                        Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                    } else {
                        Text("未结束")
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent("步骤数") {
                    Text("\(record.stepCount)")
                        .monospacedDigit()
                }
            }

            Section("复盘备注") {
                TextEditor(text: notesBinding)
                    .frame(minHeight: 160)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
        .navigationTitle(record.recipeSnapshotName)
    }

    private var record: BakeRecord {
        store.bakeHistory.first(where: { $0.id == recordID }) ?? BakeRecord(
            id: recordID,
            recipeID: nil,
            recipeName: "未知配方",
            recipeSnapshotName: "未知配方",
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
