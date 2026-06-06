import SwiftUI

struct BakingDropdownTrigger: View {
    let title: String
    var tint: Color = .brandText
    var chevronTint: Color = .brandTertiaryText

    var body: some View {
        HStack(spacing: 5) {
            Text(title)
                .lineLimit(1)
                .foregroundStyle(tint)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(chevronTint)
        }
        .font(BakingTypography.appPrimaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .bakingSurface(.dropdown)
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
    var selectionTint: Color = .brandPrimaryLight
    @ViewBuilder var leading: Leading

    var body: some View {
        HStack(spacing: 10) {
            leading
                .frame(width: 20, height: 20)

            Text(title)
                .font(isSelected ? BakingTypography.appPrimaryText.weight(.bold) : BakingTypography.appPrimaryText)
                .foregroundStyle(isSelected ? selectionTint : foreground)

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
        .background(isSelected ? Color.selectedSurface : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.chip, style: .continuous))
        .contentShape(Rectangle())
    }
}
