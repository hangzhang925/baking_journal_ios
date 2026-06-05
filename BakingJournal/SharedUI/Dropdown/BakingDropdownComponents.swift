import SwiftUI

struct BakingDropdownTrigger: View {
    let title: String
    var tint: Color = .brandText
    var background: Color = BakingSurfaceTheme.theme(for: .readOnly).background

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
        }
        .font(BakingTypography.appPrimaryText)
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(background)
        .clipShape(Capsule())
    }
}

struct BakingDropdownPopover<Content: View>: View {
    var width: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            content()
        }
        .padding(8)
        .frame(width: width)
        .presentationCompactAdaptation(.popover)
        .bakingPopoverSurface(width: width)
    }
}

struct BakingDropdownRow<Leading: View>: View {
    let title: String
    var isSelected: Bool = false
    var foreground: Color = .brandText
    var selectionTint: Color = .brandPrimary
    @ViewBuilder var leading: Leading

    var body: some View {
        HStack(spacing: 10) {
            leading
                .frame(width: 20, height: 20)

            Text(title)
                .font(BakingTypography.appPrimaryText)
                .foregroundStyle(foreground)

            Spacer(minLength: 0)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(selectionTint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
