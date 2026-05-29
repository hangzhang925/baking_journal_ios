import SwiftUI

struct RectangularDropdownTrigger: View {
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.brandText)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(width: 96, alignment: .leading)
        .frame(minHeight: BakingTouchTarget.secondaryActionVisual)
        .background(Color.brandBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.brandPrimary.opacity(0.10), lineWidth: 0.5)
        }
    }
}

struct CompactInfoBadge: View {
    let icon: String
    let text: String
    var isWater = false
    var compact = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font((compact ? Font.caption2 : Font.caption2).weight(.semibold))
            Text(text)
                .font((compact ? Font.caption : Font.subheadline).monospacedDigit().weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(isWater ? Color.waterText : Color.brandText)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 7 : 8)
        .frame(minWidth: compact ? 68 : 84, minHeight: compact ? BakingTouchTarget.dropdownIconSurface : BakingTouchTarget.secondaryActionVisual)
        .background(isWater ? Color.waterSurfaceStrong.opacity(0.42) : Color.brandPrimary.opacity(0.075))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

@MainActor
final class DropdownPresenter: ObservableObject {
    @Published var menu: ActiveDropdownMenu?

    func present(_ menu: ActiveDropdownMenu) {
        withAnimation(.easeInOut(duration: 0.18)) {
            self.menu = menu
        }
    }

    func dismiss() {
        guard menu != nil else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            menu = nil
        }
    }
}

struct ActiveDropdownMenu: Identifiable {
    let id = UUID()
    let frame: CGRect
    let width: CGFloat
    let alignment: DropdownMenuAlignment
    let items: [DropdownMenuItem]
}

enum DropdownMenuAlignment {
    case leading
    case trailing
}

struct DropdownMenuItem: Identifiable {
    let id = UUID()
    let title: String
    var icon: BakingIcon? = nil
    var isSelected = false
    let action: () -> Void
}
