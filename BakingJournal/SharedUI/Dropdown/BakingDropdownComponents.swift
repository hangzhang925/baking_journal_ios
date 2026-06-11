import SwiftUI
import UIKit

enum BakingDropdownMenuWidth {
    static func fitting(
        titles: [String],
        minimumWidth: CGFloat = BakingComponentMetrics.dropdownMenuDefaultMinWidth,
        maximumWidth: CGFloat = BakingComponentMetrics.dropdownMenuMaxWidth,
        showsLeadingSlot: Bool = false,
        reservesSelectionSlot: Bool = true
    ) -> CGFloat {
        let titleWidth = titles
            .map(measuredTitleWidth)
            .max() ?? 0
        let leadingWidth = showsLeadingSlot
            ? BakingComponentMetrics.dropdownRowLeadingSlotWidth + BakingComponentMetrics.dropdownRowTextSpacing
            : 0
        let selectionWidth = reservesSelectionSlot
            ? BakingComponentMetrics.dropdownRowTextSpacing + BakingComponentMetrics.dropdownRowSelectionSlotWidth
            : 0
        let chromeWidth = BakingComponentMetrics.dropdownPopoverPadding * 2
            + BakingComponentMetrics.dropdownRowHorizontalPadding * 2
            + leadingWidth
            + selectionWidth
        let desiredWidth = ceil(titleWidth + chromeWidth)

        return min(max(minimumWidth, desiredWidth), maximumWidth)
    }

    static func fitting(
        titles: [String],
        minimumWidth: CGFloat = BakingComponentMetrics.dropdownMenuDefaultMinWidth,
        containerWidth: CGFloat,
        showsLeadingSlot: Bool = false,
        reservesSelectionSlot: Bool = true
    ) -> CGFloat {
        let availableWidth = max(
            0,
            containerWidth - BakingComponentMetrics.dropdownMenuHorizontalScreenInset * 2
        )
        let maximumWidth = min(BakingComponentMetrics.dropdownMenuMaxWidth, availableWidth)

        return fitting(
            titles: titles,
            minimumWidth: minimumWidth,
            maximumWidth: maximumWidth,
            showsLeadingSlot: showsLeadingSlot,
            reservesSelectionSlot: reservesSelectionSlot
        )
    }

    private static func measuredTitleWidth(_ title: String) -> CGFloat {
        let string = title as NSString
        let normalWidth = string.size(withAttributes: [.font: BakingTypography.dropdownRowUIFont]).width
        let selectedWidth = string.size(withAttributes: [.font: BakingTypography.dropdownSelectedRowUIFont]).width
        return ceil(max(normalWidth, selectedWidth))
    }
}

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
        .padding(BakingComponentMetrics.dropdownPopoverPadding)
        .frame(minWidth: width)
        .fixedSize(horizontal: true, vertical: false)
        .presentationCompactAdaptation(.popover)
        .bakingPopoverSurface()
    }
}

struct BakingDropdownRow<Leading: View>: View {
    let title: String
    var isSelected: Bool = false
    var foreground: Color = .brandText
    var selectionTint: Color = .brandPrimaryLight
    var showsLeadingSlot = true
    @ViewBuilder var leading: Leading

    var body: some View {
        HStack(spacing: BakingComponentMetrics.dropdownRowTextSpacing) {
            if showsLeadingSlot {
                leading
                    .frame(
                        width: BakingComponentMetrics.dropdownRowLeadingSlotWidth,
                        height: BakingComponentMetrics.dropdownRowLeadingSlotWidth
                    )
            }

            Text(title)
                .font(isSelected ? BakingTypography.appPrimaryText.weight(.bold) : BakingTypography.appPrimaryText)
                .foregroundStyle(isSelected ? selectionTint : foreground)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(minHeight: BakingTouchTarget.dropdownIconSurface, alignment: .center)
                .layoutPriority(1)

            Spacer(minLength: 0)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(selectionTint)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .padding(.horizontal, BakingComponentMetrics.dropdownRowHorizontalPadding)
        .background(isSelected ? Color.selectedSurface : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.chip, style: .continuous))
        .contentShape(Rectangle())
    }
}
