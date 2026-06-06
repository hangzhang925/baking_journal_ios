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
    case starterDetail(UUID)
    case cook
    case toolbox
    case kitchenTimer
    case bakeRecordDetail(UUID)
}

struct AppLocation: Equatable {
    let tab: HomeTab
    let path: [AppRoute]
}
