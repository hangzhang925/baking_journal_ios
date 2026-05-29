import Foundation

enum HistorySwipeDirection {
    case back
    case forward
}

enum AppRoute: Hashable {
    case recipeSourcePicker
    case bakeRecipePicker
    case recipeWorkspace(RecipeWorkspaceStage)
    case recipeItemEditor(UUID)
    case cook
    case bakeRecordDetail(UUID)
}

struct AppLocation: Equatable {
    let tab: HomeTab
    let path: [AppRoute]
}
