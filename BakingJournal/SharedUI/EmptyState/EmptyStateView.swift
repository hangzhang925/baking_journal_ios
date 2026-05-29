import SwiftUI

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    var message: String? = nil

    var body: some View {
        BakingEmptyState(title: title, systemImage: systemImage, message: message)
    }
}
