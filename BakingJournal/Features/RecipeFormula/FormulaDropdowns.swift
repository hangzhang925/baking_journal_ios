import SwiftUI

struct RectangularDropdownTrigger: View {
    let title: String
    var isEnabled = true
    var width: CGFloat = BakingComponentMetrics.dropdownTriggerWidth
    var textAlignment: Alignment = .leading
    var font: Font = BakingTypography.appSecondaryText.weight(.semibold)

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: textAlignment)
            if isEnabled {
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.brandTertiaryText)
                    .frame(width: 14, alignment: .trailing)
            }
        }
        .font(font)
        .foregroundStyle(isEnabled ? Color.brandText : Color.brandSecondaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(width: width, alignment: .leading)
        .frame(minHeight: BakingTouchTarget.secondaryActionVisual)
        .bakingSurface(isEnabled ? .dropdown : .readOnly)
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
                .font(compact ? BakingTypography.appSecondaryText.monospacedDigit().weight(.semibold) : BakingTypography.tableNumber)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(isWater ? Color.waterText : Color.brandText)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 7 : 8)
        .frame(minWidth: compact ? 68 : 84, minHeight: compact ? BakingTouchTarget.dropdownIconSurface : BakingTouchTarget.secondaryActionVisual)
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

    func fittedWidth(in containerSize: CGSize) -> CGFloat {
        BakingDropdownMenuWidth.fitting(
            titles: items.map(\.title),
            minimumWidth: width,
            containerWidth: containerSize.width,
            showsLeadingSlot: false
        )
    }
}

enum DropdownMenuAlignment {
    case leading
    case trailing
}

struct DropdownMenuItem: Identifiable {
    let id = UUID()
    let title: String
    var isSelected = false
    let action: () -> Void
}
