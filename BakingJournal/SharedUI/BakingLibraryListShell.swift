import SwiftUI

struct BakingLibraryListShell<Filters: View, Action: View, Content: View>: View {
    @Binding var searchText: String
    let searchPrompt: String
    let clearSearchAccessibilityLabel: String
    @ViewBuilder let filters: () -> Filters
    @ViewBuilder let action: () -> Action
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            BakingTopActionRow(leading: {
                filters()
            }, trailing: {
                action()
            })

            BakingSearchField(
                text: $searchText,
                prompt: searchPrompt,
                clearAccessibilityLabel: clearSearchAccessibilityLabel
            )
            .padding(.horizontal, BakingLayout.screenHorizontalInset)
            .padding(.top, BakingSpace.xs)
            .padding(.bottom, BakingSpace.sm)
            .background(Color.brandBackground)

            content()
        }
        .background(Color.brandBackground)
    }
}

extension BakingLibraryListShell where Filters == EmptyView {
    init(
        searchText: Binding<String>,
        searchPrompt: String,
        clearSearchAccessibilityLabel: String,
        @ViewBuilder action: @escaping () -> Action,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._searchText = searchText
        self.searchPrompt = searchPrompt
        self.clearSearchAccessibilityLabel = clearSearchAccessibilityLabel
        self.filters = { EmptyView() }
        self.action = action
        self.content = content
    }
}

struct BakingLibraryList<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        List {
            content()
        }
        .listStyle(.plain)
        .contentMargins(.top, BakingLayout.contentTopInset, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
    }
}

