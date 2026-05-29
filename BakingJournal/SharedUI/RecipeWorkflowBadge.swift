import SwiftUI

struct RecipeWorkflowBadge: View {
    let state: RecipeWorkflowState

    var body: some View {
        Text(state.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(borderColor, lineWidth: 0.6)
            }
    }

    private var foregroundColor: Color {
        switch state {
        case .draft:
            return .brandPrimary
        case .ready:
            return .brandSage
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .draft:
            return Color.brandPrimary.opacity(0.11)
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

