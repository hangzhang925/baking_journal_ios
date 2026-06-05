import SwiftUI
import UIKit

private struct HistorySwipeSuppressionHandlerKey: EnvironmentKey {
    static let defaultValue: (Bool) -> Void = { _ in }
}

extension EnvironmentValues {
    var historySwipeSuppressionHandler: (Bool) -> Void {
        get { self[HistorySwipeSuppressionHandlerKey.self] }
        set { self[HistorySwipeSuppressionHandlerKey.self] = newValue }
    }
}

enum BakingGesturePolicy {
    static let verticalScrollMinimumDistance: CGFloat = 6
    static let verticalScrollIntentRatio: CGFloat = 1.08
    static let horizontalIntentMinimumDistance: CGFloat = 18
    static let horizontalIntentRatio: CGFloat = 1.55
    static let historySwipeActivationDistance: CGFloat = 18
    static let historySwipeMinimumDistance: CGFloat = 72
    static let historySwipeIntentRatio: CGFloat = 1.55
    static let reorderHoldMaximumDistance: CGFloat = verticalScrollMinimumDistance
    static let reorderDragMinimumDistance: CGFloat = 8

    static func isVerticalScrollIntent(
        _ translation: CGSize,
        minimumDistance: CGFloat = verticalScrollMinimumDistance,
        ratio: CGFloat = verticalScrollIntentRatio
    ) -> Bool {
        let horizontalTravel = abs(translation.width)
        let verticalTravel = abs(translation.height)
        return verticalTravel >= minimumDistance && verticalTravel > horizontalTravel * ratio
    }

    static func isHorizontalIntent(
        _ translation: CGSize,
        minimumDistance: CGFloat = horizontalIntentMinimumDistance,
        ratio: CGFloat = horizontalIntentRatio
    ) -> Bool {
        let horizontalTravel = abs(translation.width)
        let verticalTravel = abs(translation.height)
        return horizontalTravel >= minimumDistance && horizontalTravel > verticalTravel * ratio
    }
}

enum BakingSpace {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 10
    static let lg: CGFloat = 12
    static let xl: CGFloat = 14
    static let xxl: CGFloat = 16
}

enum BakingLayout {
    static let screenHorizontalInset: CGFloat = 14
    static let contentTopInset: CGFloat = 6
    static let cardStackSpacing: CGFloat = 10
}

enum BakingSurface {
    static let cardBackground: Color = .brandSurface
    static let cardStroke: Color = .brandDivider
    static let rowBackground: Color = .brandBackground
    static let sectionRowBackground: Color = .brandSurface
    static let fieldBackground: Color = .brandFieldSurface
    static let fieldStroke: Color = .brandFieldStroke
    static let selectedRowBackground: Color = .selectedSurface
    static let selectedStroke: Color = .selectedSurfaceStroke
    static let warmHairline: Color = Color.brandDivider
    static let bottomBarBackground: Color = .brandBackground
}

enum BakingRadius {
    static let field: CGFloat = 8
    static let chip: CGFloat = 10
    static let compactCard: CGFloat = 12
    static let card: CGFloat = 14
    static let prominentCard: CGFloat = 16
    static let popover: CGFloat = 22
}

enum BakingMotion {
    static let quick = Animation.easeInOut(duration: 0.16)
    static let standard = Animation.easeInOut(duration: 0.22)
}

enum BakingTouchTarget {
    static let primaryAction: CGFloat = 44
    static let primaryActionVisual: CGFloat = 42
    static let primaryActionGlyph: CGFloat = 27
    static let secondaryAction: CGFloat = 44
    static let secondaryActionVisual: CGFloat = 38
    static let secondaryActionGlyph: CGFloat = 22
    static let inlineIconSurface: CGFloat = 30
    static let inlineIconGlyph: CGFloat = 20
    static let dropdownIconSurface: CGFloat = 28
    static let dropdownIconGlyph: CGFloat = 16
    static let materialBadge: CGFloat = 42
    static let materialBadgeGlyph: CGFloat = 24
    static let tabIconSurface: CGFloat = 32
    static let tabIconGlyph: CGFloat = 29
    static let slideActionTrack: CGFloat = 52
    static let slideActionThumb: CGFloat = 44
    static let slideActionGlyph: CGFloat = 20

    static let iconButton: CGFloat = primaryAction
    static let toolbarVisual: CGFloat = primaryActionVisual
}

enum BakingComponentRole {
    case primary
    case secondary
    case tertiary
    case success
    case destructive
}

enum BakingComponentState {
    case normal
    case selected
    case focused
    case editing
    case disabled
    case warning
    case success
    case destructive
    case empty
}

enum BakingControlSize {
    case primary
    case secondary
    case compact
    case inline

    var hitTarget: CGFloat {
        switch self {
        case .primary:
            BakingTouchTarget.primaryAction
        case .secondary:
            BakingTouchTarget.secondaryAction
        case .compact:
            BakingTouchTarget.secondaryAction
        case .inline:
            BakingTouchTarget.inlineIconSurface
        }
    }

    var visualSize: CGFloat {
        switch self {
        case .primary:
            BakingTouchTarget.primaryActionVisual
        case .secondary:
            BakingTouchTarget.secondaryActionVisual
        case .compact:
            BakingTouchTarget.dropdownIconSurface
        case .inline:
            BakingTouchTarget.inlineIconSurface
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .primary:
            BakingTouchTarget.primaryActionGlyph
        case .secondary:
            BakingTouchTarget.secondaryActionGlyph
        case .compact:
            BakingTouchTarget.dropdownIconGlyph
        case .inline:
            BakingTouchTarget.inlineIconGlyph
        }
    }
}

enum BakingTypography {
    static let appPrimaryText: Font = .subheadline.weight(.semibold)
    static let appSecondaryText: Font = .caption.weight(.medium)
    static let screenTitle: Font = .title3.weight(.semibold)
    static let sectionTitle: Font = .headline.weight(.semibold)
    static let rowTitle: Font = appPrimaryText
    static let rowValue: Font = appPrimaryText
    static let rowMeta: Font = appSecondaryText.weight(.semibold)
    static let fieldLabel: Font = appSecondaryText.weight(.semibold)
    static let inputLabel: Font = appPrimaryText
    static let inputValue: Font = appPrimaryText.monospacedDigit().weight(.bold)
    static let compactInputValue: Font = .system(size: 18, weight: .semibold)
    static let compactNumericInputValue: Font = .system(size: 18, weight: .semibold, design: .monospaced)
    static let compactInputValueUIFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
    static let compactNumericInputValueUIFont = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .semibold)
    static let popupInputValue: Font = appPrimaryText
    static let popupNumericInputValue: Font = tableNumber
    static let popupInputValueUIFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
    static let popupNumericInputValueUIFont = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
    static let readOnlyLabel: Font = appSecondaryText.weight(.semibold)
    static let readOnlyValue: Font = appPrimaryText.monospacedDigit().weight(.bold)
    static let helperText: Font = appSecondaryText
    static let iconCaption: Font = .caption2.weight(.medium)
    static let tabCaption: Font = .caption2.weight(.semibold)
    static let stageTabLabel: Font = appPrimaryText
    static let tableHeader: Font = appSecondaryText.weight(.semibold)
    static let tableCell: Font = appPrimaryText
    static let tableNumber: Font = appPrimaryText.monospacedDigit().weight(.bold)
    static let actionLabel: Font = appPrimaryText
}

enum BakingLabelRole {
    case sectionHeader
    case fieldLabel
    case popupRowLabel
    case inputLabel
    case readOnlyLabel
    case helperText
    case iconCaption
    case tableHeader
}

enum BakingSurfaceKind {
    case sectionCard
    case insetSurface
    case nestedChip
    case inputSurface
    case waterSurface
    case popoverSurface
    case destructive
    case card
    case compactCard
    case field
    case readOnly
    case selected
    case focused
    case warning
    case success
    case primaryAction
}

enum BakingComponentMetrics {
    static let listRowMinHeight: CGFloat = 72
    static let tabItemHeight: CGFloat = 56
    static let tabSelectedSurfaceWidth: CGFloat = 58
    static let tabSelectedSurfaceHeight: CGFloat = 40
    static let stageItemHeight: CGFloat = 36
    static let stageInlineIcon: CGFloat = BakingTouchTarget.tabIconGlyph
    static let stageIndicatorWidth: CGFloat = 28
    static let stageIndicatorHeight: CGFloat = 2
    static let statusCapsuleWidth: CGFloat = 132
    static let statusCapsuleHeight: CGFloat = 44
    static let statusCapsuleIconSlot: CGFloat = 24
    static let statusCapsuleIconGlyph: CGFloat = 20
    static let statusCapsuleTextSlot: CGFloat = 58
    static let statusCapsuleChevronSlot: CGFloat = 14
    static let titleInputMinHeight: CGFloat = 44
    static let compactFieldHeight: CGFloat = 38
    static let compactPillHeight: CGFloat = 30
    static let optionChipHeight: CGFloat = 40
    static let dropdownTriggerWidth: CGFloat = 104
    static let compactOptionWidth: CGFloat = 58
    static let materialChipWidth: CGFloat = 72
    static let materialChipIcon: CGFloat = 18
    static let materialChipIconGlyph: CGFloat = 13
    static let inlineIconCornerRadius: CGFloat = 9
    static let compactIconCornerRadius: CGFloat = 6
    static let popupIconSurface: CGFloat = 34
    static let popupIconGlyph: CGFloat = 22
    static let popupAttributeIconSurface: CGFloat = 22
    static let popupAttributeIconGlyph: CGFloat = 14
    static let popupInputHeight: CGFloat = 38
    static let popupContentLeadingInset: CGFloat = 52
    static let popupLabelWidth: CGFloat = 52
    static let popupFormWidth: CGFloat = 292
    static let popupNameFieldWidth: CGFloat = 232
    static let popupNumericFieldWidth: CGFloat = 84
    static let popupTableRowMinHeight: CGFloat = 54
    static let popupTableMetricRowMinHeight: CGFloat = 62
    static let popupTableMetricCellMinWidth: CGFloat = 118
    static let compactInputFieldHeight: CGFloat = 38
    static let compactInputShortFieldWidth: CGFloat = 96
    static let compactInputMediumFieldWidth: CGFloat = 136
    static let compactInputLongFieldWidth: CGFloat = 188
    static let compactNameInputFieldWidth: CGFloat = compactInputLongFieldWidth
    static let compactRecipeTitleInputFieldWidth: CGFloat = 236
    static let compactPercentInputFieldWidth: CGFloat = compactInputShortFieldWidth
    static let compactWeightInputFieldWidth: CGFloat = compactInputShortFieldWidth
    static let popoverCompactWidth: CGFloat = 220
    static let popoverMediumWidth: CGFloat = 292
    static let temperaturePopoverWidth: CGFloat = 148
    static let temperatureScrollerHeight: CGFloat = 214
    static let temperatureOptionHeight: CGFloat = 40
    static let notesEditorMinHeight: CGFloat = 260
}

enum BakingPopupSheetSize {
    case compact
    case expanded

    var defaultHeight: CGFloat {
        switch self {
        case .compact:
            return BakingPopupSheetMetrics.compactDefaultHeight
        case .expanded:
            return BakingPopupSheetMetrics.expandedDefaultHeight
        }
    }
}

enum BakingPopupSheetMetrics {
    static let compactDefaultHeight: CGFloat = 280
    static let notesEditorDefaultHeight: CGFloat = 390
    static let expandedDefaultHeight: CGFloat = 720
    static let maximumScreenRatio: CGFloat = 0.96

    static var topChromeHeight: CGFloat {
        BakingTouchTarget.iconButton + BakingSpace.xs * 2
    }

    static func detentHeight(
        for size: BakingPopupSheetSize,
        measuredContentHeight: CGFloat,
        screenHeight: CGFloat? = nil
    ) -> CGFloat {
        let defaultHeight = size.defaultHeight
        let cappedDefaultHeight = capped(defaultHeight, screenHeight: screenHeight)
        guard measuredContentHeight > 0 else { return cappedDefaultHeight }

        let contentHeight = measuredContentHeight + topChromeHeight + BakingSpace.md
        let expandedHeight = max(cappedDefaultHeight, ceil(contentHeight))
        return capped(expandedHeight, screenHeight: screenHeight)
    }

    private static func capped(_ height: CGFloat, screenHeight: CGFloat?) -> CGFloat {
        guard let screenHeight else { return height }
        let maximumHeight = screenHeight * maximumScreenRatio
        return min(height, maximumHeight)
    }
}

enum BakingCompactInputFieldSize {
    case short
    case medium
    case long

    var width: CGFloat {
        switch self {
        case .short:
            return BakingComponentMetrics.compactInputShortFieldWidth
        case .medium:
            return BakingComponentMetrics.compactInputMediumFieldWidth
        case .long:
            return BakingComponentMetrics.compactInputLongFieldWidth
        }
    }
}

enum BakingShadow {
    static let popoverColor: Color = Color.black.opacity(0.07)
    static let popoverRadius: CGFloat = 18
    static let popoverY: CGFloat = 8
    static let liftedColor: Color = Color.black.opacity(0.12)
    static let liftedRadius: CGFloat = 18
    static let liftedY: CGFloat = 9
}

enum BakingNavigationItemTheme {
    static let selectedIconColor: Color = .brandPrimary
    static let selectedTextColor: Color = .brandPrimary
    static let defaultIconColor: Color = .brandSecondaryText
    static let defaultTextColor: Color = .brandSecondaryText
}

struct BakingSurfaceTheme {
    let background: Color
    let stroke: Color
    let radius: CGFloat
    let lineWidth: CGFloat

    static func theme(for kind: BakingSurfaceKind) -> BakingSurfaceTheme {
        switch kind {
        case .sectionCard:
            BakingSurfaceTheme(
                background: BakingSurface.cardBackground,
                stroke: BakingSurface.cardStroke,
                radius: BakingRadius.prominentCard,
                lineWidth: 0.6
            )
        case .insetSurface:
            BakingSurfaceTheme(
                background: BakingSurface.sectionRowBackground,
                stroke: BakingSurface.warmHairline,
                radius: BakingRadius.card,
                lineWidth: 0.5
            )
        case .nestedChip:
            BakingSurfaceTheme(
                background: Color.materialChipSurface,
                stroke: BakingSurface.warmHairline,
                radius: BakingRadius.compactCard,
                lineWidth: 0.6
            )
        case .inputSurface:
            BakingSurfaceTheme(
                background: BakingSurface.fieldBackground,
                stroke: BakingSurface.fieldStroke,
                radius: BakingRadius.field,
                lineWidth: 0.6
            )
        case .waterSurface:
            BakingSurfaceTheme(
                background: Color.waterSurfaceStrong.opacity(0.42),
                stroke: Color.brandSea.opacity(0.16),
                radius: BakingRadius.compactCard,
                lineWidth: 0.6
            )
        case .popoverSurface:
            BakingSurfaceTheme(
                background: Color.brandBackground,
                stroke: BakingSurface.warmHairline,
                radius: BakingRadius.popover,
                lineWidth: 0.6
            )
        case .destructive:
            BakingSurfaceTheme(
                background: BakingSurface.selectedRowBackground,
                stroke: Color.brandPrimary.opacity(0.28),
                radius: BakingRadius.card,
                lineWidth: 0.7
            )
        case .card:
            BakingSurfaceTheme(
                background: BakingSurface.cardBackground,
                stroke: BakingSurface.cardStroke,
                radius: BakingRadius.prominentCard,
                lineWidth: 0.6
            )
        case .compactCard:
            BakingSurfaceTheme(
                background: BakingSurface.cardBackground,
                stroke: BakingSurface.cardStroke,
                radius: BakingRadius.card,
                lineWidth: 0.5
            )
        case .field:
            BakingSurfaceTheme(
                background: BakingSurface.fieldBackground,
                stroke: BakingSurface.fieldStroke,
                radius: BakingRadius.field,
                lineWidth: 0.6
            )
        case .readOnly:
            BakingSurfaceTheme(
                background: BakingSurface.cardBackground,
                stroke: BakingSurface.cardStroke,
                radius: BakingRadius.field,
                lineWidth: 0.5
            )
        case .selected:
            BakingSurfaceTheme(
                background: BakingSurface.selectedRowBackground,
                stroke: BakingSurface.selectedStroke,
                radius: BakingRadius.card,
                lineWidth: 0.7
            )
        case .focused:
            BakingSurfaceTheme(
                background: BakingSurface.selectedRowBackground,
                stroke: BakingSurface.selectedStroke,
                radius: BakingRadius.field,
                lineWidth: 0.9
            )
        case .warning:
            BakingSurfaceTheme(
                background: BakingSurface.selectedRowBackground,
                stroke: BakingSurface.selectedStroke,
                radius: BakingRadius.card,
                lineWidth: 0.7
            )
        case .success:
            BakingSurfaceTheme(
                background: Color.brandSage.opacity(0.10),
                stroke: Color.brandSage.opacity(0.22),
                radius: BakingRadius.card,
                lineWidth: 0.7
            )
        case .primaryAction:
            BakingSurfaceTheme(
                background: Color.brandPrimary,
                stroke: Color.brandPrimary,
                radius: BakingRadius.card,
                lineWidth: 0.7
            )
        }
    }

    static var separator: Color {
        BakingSurface.warmHairline
    }
}

struct BakingLabelTheme {
    let font: Font
    let color: Color

    static func theme(for role: BakingLabelRole) -> BakingLabelTheme {
        switch role {
        case .sectionHeader:
            BakingLabelTheme(font: BakingTypography.sectionTitle, color: .brandSecondaryText)
        case .fieldLabel:
            BakingLabelTheme(font: BakingTypography.fieldLabel, color: .brandSecondaryText)
        case .popupRowLabel:
            BakingLabelTheme(font: BakingTypography.appPrimaryText, color: .brandSecondaryText)
        case .inputLabel:
            BakingLabelTheme(font: BakingTypography.inputLabel, color: .brandText)
        case .readOnlyLabel:
            BakingLabelTheme(font: BakingTypography.readOnlyLabel, color: .brandSecondaryText)
        case .helperText:
            BakingLabelTheme(font: BakingTypography.helperText, color: .brandSecondaryText)
        case .iconCaption:
            BakingLabelTheme(font: BakingTypography.iconCaption, color: .brandSecondaryText)
        case .tableHeader:
            BakingLabelTheme(font: BakingTypography.tableHeader, color: .brandSecondaryText)
        }
    }
}

struct BakingComponentTheme {
    let foreground: Color
    let selectedForeground: Color
    let disabledForeground: Color
    let background: Color
    let selectedBackground: Color
    let stroke: Color
    let selectedStroke: Color

    static func action(role: BakingComponentRole) -> BakingComponentTheme {
        switch role {
        case .primary:
            BakingComponentTheme(
                foreground: .brandPrimary,
                selectedForeground: .brandPrimary,
                disabledForeground: .brandSecondaryText.opacity(0.45),
                background: .clear,
                selectedBackground: BakingSurface.selectedRowBackground,
                stroke: .clear,
                selectedStroke: BakingSurface.selectedStroke
            )
        case .secondary:
            BakingComponentTheme(
                foreground: .brandText,
                selectedForeground: .brandPrimary,
                disabledForeground: .brandSecondaryText.opacity(0.45),
                background: .clear,
                selectedBackground: BakingSurface.selectedRowBackground,
                stroke: .clear,
                selectedStroke: BakingSurface.selectedStroke
            )
        case .tertiary:
            BakingComponentTheme(
                foreground: .brandSecondaryText,
                selectedForeground: .brandText,
                disabledForeground: .brandSecondaryText.opacity(0.38),
                background: .clear,
                selectedBackground: BakingSurface.fieldBackground,
                stroke: .clear,
                selectedStroke: BakingSurface.warmHairline
            )
        case .success:
            BakingComponentTheme(
                foreground: .brandSage,
                selectedForeground: .brandSage,
                disabledForeground: .brandSecondaryText.opacity(0.45),
                background: .clear,
                selectedBackground: Color.brandSage.opacity(0.12),
                stroke: .clear,
                selectedStroke: Color.brandSage.opacity(0.24)
            )
        case .destructive:
            BakingComponentTheme(
                foreground: .brandPrimary,
                selectedForeground: .brandPrimary,
                disabledForeground: .brandSecondaryText.opacity(0.45),
                background: .clear,
                selectedBackground: BakingSurface.selectedRowBackground,
                stroke: .clear,
                selectedStroke: BakingSurface.selectedStroke
            )
        }
    }
}

enum BakingFormTheme {
    static let sectionSpacing: CGFloat = BakingSpace.xl
    static let rowSpacing: CGFloat = BakingSpace.sm
    static let rowHorizontalPadding: CGFloat = BakingSpace.md
    static let rowVerticalPadding: CGFloat = BakingSpace.sm
    static let labelFont: Font = BakingTypography.rowTitle
    static let valueFont: Font = BakingTypography.rowValue
    static let helperFont: Font = BakingTypography.rowMeta
    static let labelColor: Color = .brandText
    static let valueColor: Color = .brandText
    static let secondaryValueColor: Color = .brandSecondaryText
    static let rowBackground: Color = BakingSurface.rowBackground
    static let fieldBackground: Color = BakingSurface.fieldBackground
    static let fieldStroke: Color = BakingSurface.fieldStroke
}

enum BakingValueKind {
    case editable
    case readOnly
    case metric
    case tableNumber
}

enum BakingNumericValueKind {
    case weight
    case percent
    case duration
    case temperature
    case clockTime
    case count
}

struct BakingValueTheme {
    let valueFont: Font
    let unitFont: Font
    let valueColor: Color
    let unitColor: Color
    let alignment: Alignment

    static func theme(
        for kind: BakingValueKind,
        role: BakingComponentRole = .secondary
    ) -> BakingValueTheme {
        switch kind {
        case .editable:
            return BakingValueTheme(
                valueFont: BakingTypography.inputValue,
                unitFont: BakingTypography.rowMeta,
                valueColor: Color.brandText,
                unitColor: Color.brandSecondaryText,
                alignment: .trailing
            )
        case .readOnly:
            return BakingValueTheme(
                valueFont: BakingTypography.readOnlyValue,
                unitFont: BakingTypography.rowMeta,
                valueColor: Color.brandText,
                unitColor: Color.brandSecondaryText.opacity(0.82),
                alignment: .trailing
            )
        case .metric:
            return BakingValueTheme(
                valueFont: BakingTypography.tableNumber,
                unitFont: BakingTypography.rowMeta,
                valueColor: Color.brandText,
                unitColor: Color.brandSecondaryText,
                alignment: .leading
            )
        case .tableNumber:
            return BakingValueTheme(
                valueFont: BakingTypography.tableNumber,
                unitFont: BakingTypography.rowMeta,
                valueColor: Color.brandText,
                unitColor: Color.brandSecondaryText,
                alignment: .trailing
            )
        }
    }
}

enum BakingTableTheme {
    static let horizontalInset: CGFloat = BakingLayout.screenHorizontalInset
    static let rowSpacing: CGFloat = BakingSpace.xs
    static let rowPadding: CGFloat = BakingSpace.sm
    static let headerFont: Font = BakingTypography.tableHeader
    static let cellFont: Font = BakingTypography.tableCell
    static let numberFont: Font = BakingTypography.tableNumber
    static let headerColor: Color = .brandSecondaryText
    static let cellColor: Color = .brandText
    static let secondaryCellColor: Color = .brandSecondaryText
    static let rowBackground: Color = BakingSurface.rowBackground
    static let selectedRowBackground: Color = BakingSurface.selectedRowBackground
    static let rowStroke: Color = .clear
}

extension View {
    func bakingLabelStyle(_ role: BakingLabelRole) -> some View {
        let theme = BakingLabelTheme.theme(for: role)
        return self
            .font(theme.font)
            .foregroundStyle(theme.color)
    }

    func bakingCard(
        background: Color = BakingSurface.cardBackground,
        radius: CGFloat = BakingRadius.prominentCard,
        stroke: Color = BakingSurface.cardStroke,
        lineWidth: CGFloat = 0.6
    ) -> some View {
        self
            .background(background)
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(stroke, lineWidth: lineWidth)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func bakingFieldSurface(
        background: Color = BakingSurface.fieldBackground,
        stroke: Color = BakingSurface.fieldStroke,
        radius: CGFloat = BakingRadius.field
    ) -> some View {
        self
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(stroke, lineWidth: 0.5)
            }
    }

    func bakingFittedInputField(
        width: CGFloat,
        height: CGFloat = BakingComponentMetrics.compactInputFieldHeight,
        alignment: Alignment = .trailing,
        kind: BakingSurfaceKind = .field
    ) -> some View {
        self
            .padding(.horizontal, BakingSpace.sm)
            .frame(width: width, height: height, alignment: alignment)
            .bakingSurface(kind)
    }

    func bakingFittedInputField(
        _ size: BakingCompactInputFieldSize,
        height: CGFloat = BakingComponentMetrics.compactInputFieldHeight,
        alignment: Alignment = .trailing,
        kind: BakingSurfaceKind = .field
    ) -> some View {
        bakingFittedInputField(
            width: size.width,
            height: height,
            alignment: alignment,
            kind: kind
        )
    }

    func bakingSurface(_ kind: BakingSurfaceKind) -> some View {
        let theme = BakingSurfaceTheme.theme(for: kind)
        return self
            .background(theme.background)
            .clipShape(RoundedRectangle(cornerRadius: theme.radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                    .stroke(theme.stroke, lineWidth: theme.lineWidth)
            }
    }

    func bakingSectionCard() -> some View {
        bakingSurface(.sectionCard)
    }

    func bakingInsetSurface() -> some View {
        bakingSurface(.insetSurface)
    }

    func bakingReadOnlySurface() -> some View {
        bakingSurface(.readOnly)
    }

    func bakingSelectedSurface() -> some View {
        bakingSurface(.selected)
    }

    func bakingMaterialCard(palette: MaterialPalette, isSelected: Bool = false) -> some View {
        bakingCard(
            background: isSelected ? palette.selectedChipSurface : palette.chipSurface,
            radius: BakingRadius.compactCard,
            stroke: isSelected ? palette.tint.opacity(0.34) : palette.chipStroke,
            lineWidth: isSelected ? 0.9 : 0.6
        )
    }

    func bakingTitleInputSurface() -> some View {
        self
            .frame(minHeight: BakingComponentMetrics.titleInputMinHeight)
            .bakingSurface(.inputSurface)
    }

    func bakingPopoverSurface(width: CGFloat? = nil) -> some View {
        let theme = BakingSurfaceTheme.theme(for: .popoverSurface)
        return self
            .frame(width: width)
            .background(
                RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                    .fill(theme.background)
                    .overlay {
                        RoundedRectangle(cornerRadius: theme.radius, style: .continuous)
                            .stroke(theme.stroke, lineWidth: theme.lineWidth)
                    }
                    .shadow(
                        color: BakingShadow.popoverColor,
                        radius: BakingShadow.popoverRadius,
                        x: 0,
                        y: BakingShadow.popoverY
                    )
            )
    }

    func bakingLiftedShadow() -> some View {
        shadow(color: BakingShadow.liftedColor, radius: BakingShadow.liftedRadius, x: 0, y: BakingShadow.liftedY)
    }
}

struct BakingSystemIconButtonLabel: View {
    let systemImage: String
    var tint: Color = .brandPrimary
    var background: Color = .clear
    var visualSize: CGFloat = BakingTouchTarget.toolbarVisual
    var font: Font = .system(size: BakingTouchTarget.primaryActionGlyph, weight: .semibold)
    var shape: BakingIconButtonShape = .circle

    var body: some View {
        switch shape {
        case .circle:
            icon
                .clipShape(Circle())
        case .rounded(let radius):
            icon
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
    }

    private var icon: some View {
        Image(systemName: systemImage)
            .font(font)
            .foregroundStyle(tint)
            .frame(width: visualSize, height: visualSize)
            .background(background)
            .frame(width: BakingTouchTarget.iconButton, height: BakingTouchTarget.iconButton)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
    }
}

struct BakingSectionEditButton: View {
    let accessibilityLabel: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            BakingSystemIconButtonLabel(
                systemImage: "minus",
                visualSize: BakingTouchTarget.secondaryActionVisual,
                font: .caption.weight(.bold)
            )
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct BakingTopIconButtonLabel: View {
    let icon: BakingIcon
    var tint: Color = .brandText
    var glyphSize: CGFloat = BakingTouchTarget.tabIconGlyph

    var body: some View {
        BakingIconView(icon: icon, size: glyphSize, color: tint)
            .frame(width: BakingTouchTarget.iconButton, height: BakingTouchTarget.iconButton)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
    }
}

struct BakingTopSystemIconButtonLabel: View {
    let systemImage: String
    var tint: Color = .brandText
    var font: Font = .system(size: BakingTouchTarget.primaryActionGlyph, weight: .semibold)

    var body: some View {
        Image(systemName: systemImage)
            .font(font)
            .foregroundStyle(tint)
            .frame(width: BakingTouchTarget.iconButton, height: BakingTouchTarget.iconButton)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
    }
}

struct BakingIconButtonLabel: View {
    let icon: BakingIcon
    var role: BakingComponentRole = .secondary
    var size: BakingControlSize = .primary
    var isSelected = false
    var tintOverride: Color? = nil
    var showsBadge = false
    var iconVariant: BakingIconVariant = .outline

    var body: some View {
        let theme = BakingComponentTheme.action(role: role)
        let tint = tintOverride ?? (isSelected ? theme.selectedForeground : theme.foreground)

        ZStack(alignment: .topTrailing) {
            BakingIconView(icon: icon, size: size.iconSize, color: tint, variant: iconVariant)
                .frame(width: size.visualSize, height: size.visualSize)

            if showsBadge {
                Circle()
                    .fill(theme.selectedForeground)
                    .frame(width: 7, height: 7)
                    .offset(x: 1, y: 1)
            }
        }
        .frame(width: size.hitTarget, height: size.hitTarget)
        .contentShape(Rectangle())
        .accessibilityHidden(true)
    }
}

struct BakingIconButton: View {
    let icon: BakingIcon
    let accessibilityLabel: String
    var role: BakingComponentRole = .secondary
    var size: BakingControlSize = .primary
    var isSelected = false
    var tintOverride: Color? = nil
    var showsBadge = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            BakingIconButtonLabel(
                icon: icon,
                role: role,
                size: size,
                isSelected: isSelected,
                tintOverride: tintOverride,
                showsBadge: showsBadge
            )
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

struct BakingDisclosureHeader: View {
    let title: String
    let value: String
    var showsValue = true
    let systemImage: String
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: BakingSpace.sm) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: BakingTouchTarget.inlineIconSurface, height: BakingTouchTarget.inlineIconSurface)
                    .bakingSurface(.inputSurface)

                Text(title)
                    .font(BakingTypography.sectionTitle)
                    .foregroundStyle(Color.brandText)

                Spacer(minLength: BakingSpace.sm)

                if showsValue {
                    Text(value)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color.brandSecondaryText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: 132, alignment: .trailing)
                }

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.brandPrimary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .frame(width: 18, height: 18)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

enum BakingToggleIcon {
    case baking(BakingIcon)
    case system(String)
}

struct BakingIconToggleLabel: View {
    let offIcon: BakingToggleIcon
    let onIcon: BakingToggleIcon
    let isOn: Bool
    var role: BakingComponentRole = .primary
    var size: BakingControlSize = .primary
    var systemFont: Font = .body.weight(.semibold)

    var body: some View {
        let theme = BakingComponentTheme.action(role: role)
        let tint = isOn ? theme.selectedForeground : theme.foreground
        let background = isOn ? theme.selectedBackground : BakingSurface.fieldBackground
        let stroke = isOn ? theme.selectedStroke : BakingSurface.warmHairline

        iconView(isOn ? onIcon : offIcon, tint: tint)
            .frame(width: size.visualSize, height: size.visualSize)
            .background(background)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(stroke, lineWidth: 0.7)
            }
            .frame(width: size.hitTarget, height: size.hitTarget)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func iconView(_ icon: BakingToggleIcon, tint: Color) -> some View {
        switch icon {
        case .baking(let bakingIcon):
            BakingIconView(icon: bakingIcon, size: size.iconSize, color: tint)
        case .system(let systemImage):
            Image(systemName: systemImage)
                .font(systemFont)
                .foregroundStyle(tint)
        }
    }
}

struct BakingIconToggle: View {
    @Binding var isOn: Bool
    let offIcon: BakingToggleIcon
    let onIcon: BakingToggleIcon
    let accessibilityLabel: String
    var accessibilityValue: String? = nil
    var role: BakingComponentRole = .primary
    var size: BakingControlSize = .primary
    var systemFont: Font = .body.weight(.semibold)

    var body: some View {
        Button {
            withAnimation(BakingMotion.quick) {
                isOn.toggle()
            }
        } label: {
            BakingIconToggleLabel(
                offIcon: offIcon,
                onIcon: onIcon,
                isOn: isOn,
                role: role,
                size: size,
                systemFont: systemFont
            )
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue ?? "")
    }
}

struct BakingSegmentedIconToggle: View {
    @Binding var isOn: Bool
    let offIcon: BakingToggleIcon
    let onIcon: BakingToggleIcon
    let offLabel: String
    let onLabel: String
    let accessibilityLabel: String
    var accessibilityHint: String? = nil
    var offRole: BakingComponentRole = .primary
    var onRole: BakingComponentRole = .success
    var systemFont: Font = .caption.weight(.bold)

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 0) {
                segment(icon: offIcon, isSelected: !isOn, role: offRole) {
                    setSelection(false)
                }

                segment(icon: onIcon, isSelected: isOn, role: onRole) {
                    setSelection(true)
                }
            }
            .padding(3)
            .frame(width: 78, height: 38)
            .background(BakingSurface.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous)
                    .stroke(BakingSurface.warmHairline, lineWidth: 0.7)
            }

            Text(isOn ? onLabel : offLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isOn ? BakingComponentTheme.action(role: onRole).selectedForeground : BakingComponentTheme.action(role: offRole).selectedForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isOn ? onLabel : offLabel)
        .accessibilityHint(accessibilityHint ?? "")
    }

    private func setSelection(_ nextValue: Bool) {
        guard nextValue != isOn else { return }
        withAnimation(BakingMotion.quick) {
            isOn = nextValue
        }
    }

    private func segment(icon: BakingToggleIcon, isSelected: Bool, role: BakingComponentRole, action: @escaping () -> Void) -> some View {
        let theme = BakingComponentTheme.action(role: role)
        let tint = isSelected ? theme.selectedForeground : Color.brandSecondaryText
        let background = isSelected ? theme.selectedBackground : Color.clear
        let stroke = isSelected ? theme.selectedStroke : Color.clear

        return Button(action: action) {
            toggleIcon(icon, tint: tint)
                .frame(width: 33, height: 30)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: BakingRadius.chip, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: BakingRadius.chip, style: .continuous)
                        .stroke(stroke, lineWidth: 0.7)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
    }

    @ViewBuilder
    private func toggleIcon(_ icon: BakingToggleIcon, tint: Color) -> some View {
        switch icon {
        case .baking(let bakingIcon):
            BakingIconView(icon: bakingIcon, size: BakingTouchTarget.dropdownIconGlyph, color: tint)
        case .system(let systemImage):
            Image(systemName: systemImage)
                .font(systemFont)
                .foregroundStyle(tint)
        }
    }
}

struct BakingSegmentedStageOption: Identifiable {
    let id: String
    let icon: BakingToggleIcon
    let title: String
}

struct BakingSegmentedStageControl: View {
    let selectedID: String
    let options: [BakingSegmentedStageOption]
    let accessibilityLabel: String
    var iconSize: CGFloat = BakingComponentMetrics.stageInlineIcon
    var minHeight: CGFloat = BakingComponentMetrics.stageItemHeight
    var labelFont: Font = BakingTypography.stageTabLabel
    var onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                Button {
                    guard option.id != selectedID else { return }
                    withAnimation(BakingMotion.standard) {
                        onSelect(option.id)
                    }
                } label: {
                    BakingSegmentedStageButtonLabel(
                        option: option,
                        isSelected: option.id == selectedID,
                        iconSize: iconSize,
                        minHeight: minHeight,
                        labelFont: labelFont
                    )
                }
                .buttonStyle(BakingPressFeedbackButtonStyle())
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(option.id == selectedID ? .isSelected : [])
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(selectedOption?.title ?? "")
    }

    private var selectedOption: BakingSegmentedStageOption? {
        options.first { $0.id == selectedID }
    }
}

private struct BakingSegmentedStageButtonLabel: View {
    let option: BakingSegmentedStageOption
    let isSelected: Bool
    let iconSize: CGFloat
    let minHeight: CGFloat
    let labelFont: Font

    var body: some View {
        let tint = isSelected ? BakingNavigationItemTheme.selectedIconColor : BakingNavigationItemTheme.defaultIconColor
        let labelColor = isSelected ? BakingNavigationItemTheme.selectedTextColor : BakingNavigationItemTheme.defaultTextColor

        VStack(spacing: BakingSpace.xxs) {
            HStack(spacing: BakingSpace.xs) {
                stageIcon(option.icon, tint: tint, variant: isSelected ? .selected : .outline)
                    .frame(
                        width: iconSize,
                        height: iconSize
                    )

                Text(option.title)
                    .font(labelFont)
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, minHeight: minHeight - BakingComponentMetrics.stageIndicatorHeight)
            .contentShape(Rectangle())
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(isSelected ? BakingNavigationItemTheme.selectedTextColor : Color.clear)
                .frame(height: BakingComponentMetrics.stageIndicatorHeight)
        }
        .contentShape(Rectangle())
        .animation(BakingMotion.quick, value: isSelected)
    }

    @ViewBuilder
    private func stageIcon(_ icon: BakingToggleIcon, tint: Color, variant: BakingIconVariant) -> some View {
        switch icon {
        case .baking(let bakingIcon):
            BakingIconView(icon: bakingIcon, size: iconSize, color: tint, variant: variant)
        case .system(let systemImage):
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(tint)
        }
    }
}

struct BakingStatusCapsuleOption: Identifiable {
    let id: String
    let icon: BakingToggleIcon
    let title: String
    var role: BakingComponentRole = .primary
}

struct BakingStatusCapsuleMenu: View {
    let selectedID: String
    let options: [BakingStatusCapsuleOption]
    let accessibilityLabel: String
    var systemFont: Font = .caption.weight(.bold)
    var onSelect: (String) -> Void

    @State private var showingOptions = false

    var body: some View {
        Button {
            showingOptions = true
        } label: {
            currentCapsule
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .popover(isPresented: $showingOptions, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            BakingDropdownPopover(width: 168) {
                ForEach(options) { option in
                    let optionTheme = BakingComponentTheme.action(role: option.role)
                    Button {
                        showingOptions = false
                        onSelect(option.id)
                    } label: {
                        BakingDropdownRow(
                            title: option.title,
                            isSelected: option.id == selectedID,
                            selectionTint: optionTheme.selectedForeground
                        ) {
                            statusIcon(
                                option.icon,
                                tint: iconTint(for: option),
                                glyphSize: BakingComponentMetrics.statusCapsuleIconGlyph,
                                systemFont: .system(size: BakingComponentMetrics.statusCapsuleIconGlyph, weight: .semibold)
                            )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(selectedOption.title)
    }

    private var selectedOption: BakingStatusCapsuleOption {
        options.first { $0.id == selectedID } ?? options[0]
    }

    private func iconTint(for option: BakingStatusCapsuleOption) -> Color {
        BakingComponentTheme.action(role: option.role).selectedForeground
    }

    private var currentCapsule: some View {
        let theme = BakingComponentTheme.action(role: selectedOption.role)
        return HStack(spacing: 6) {
            statusIcon(
                selectedOption.icon,
                tint: theme.selectedForeground,
                glyphSize: BakingComponentMetrics.statusCapsuleIconGlyph,
                systemFont: .system(size: BakingComponentMetrics.statusCapsuleIconGlyph, weight: .semibold)
            )
            .frame(
                width: BakingComponentMetrics.statusCapsuleIconSlot,
                height: BakingComponentMetrics.statusCapsuleIconSlot,
                alignment: .center
            )

            Text(selectedOption.title)
                .font(BakingTypography.appPrimaryText)
                .foregroundStyle(Color.brandText)
                .lineLimit(1)
                .frame(width: BakingComponentMetrics.statusCapsuleTextSlot, alignment: .leading)

            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.brandSecondaryText)
                .frame(
                    width: BakingComponentMetrics.statusCapsuleChevronSlot,
                    height: BakingComponentMetrics.statusCapsuleChevronSlot,
                    alignment: .center
                )
        }
        .frame(
            width: BakingComponentMetrics.statusCapsuleWidth,
            height: BakingComponentMetrics.statusCapsuleHeight
        )
        .background(statusCapsuleBackground)
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous)
                .stroke(statusCapsuleStroke, lineWidth: 0.8)
        }
        .frame(minWidth: 44, minHeight: BakingTouchTarget.primaryAction)
        .contentShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
    }

    private var statusCapsuleBackground: Color {
        Color.brandBackground
    }

    private var statusCapsuleStroke: Color {
        BakingSurface.warmHairline
    }

    @ViewBuilder
    private func statusIcon(
        _ icon: BakingToggleIcon,
        tint: Color,
        glyphSize: CGFloat = BakingTouchTarget.dropdownIconGlyph,
        systemFont: Font? = nil
    ) -> some View {
        switch icon {
        case .baking(let bakingIcon):
            BakingIconView(icon: bakingIcon, size: glyphSize, color: tint)
        case .system(let systemImage):
            Image(systemName: systemImage)
                .font(systemFont ?? self.systemFont)
                .foregroundStyle(tint)
        }
    }
}

struct BakingSystemIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var role: BakingComponentRole = .secondary
    var size: BakingControlSize = .primary
    var isSelected = false
    var font: Font = .system(size: BakingTouchTarget.primaryActionGlyph, weight: .semibold)
    var action: () -> Void

    var body: some View {
        let theme = BakingComponentTheme.action(role: role)
        let tint = isSelected ? theme.selectedForeground : theme.foreground

        Button(action: action) {
            Image(systemName: systemImage)
                .font(font)
                .foregroundStyle(tint)
                .frame(width: size.visualSize, height: size.visualSize)
                .frame(width: size.hitTarget, height: size.hitTarget)
                .contentShape(Rectangle())
                .accessibilityHidden(true)
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

struct BakingTabIconLabel: View {
    let icon: BakingIcon
    let isSelected: Bool
    var showsBadge = false

    var body: some View {
        let tint = isSelected ? BakingNavigationItemTheme.selectedIconColor : BakingNavigationItemTheme.defaultIconColor

        ZStack(alignment: .topTrailing) {
            BakingIconView(
                icon: icon,
                size: BakingTouchTarget.tabIconGlyph,
                color: tint,
                variant: isSelected ? .selected : .outline
            )
            .frame(width: BakingTouchTarget.iconButton, height: BakingTouchTarget.iconButton)

            if showsBadge {
                Circle()
                    .fill(BakingNavigationItemTheme.selectedIconColor)
                    .frame(width: 7, height: 7)
                    .offset(x: -6, y: 6)
            }
        }
        .frame(
            width: BakingComponentMetrics.tabSelectedSurfaceWidth,
            height: BakingTouchTarget.iconButton
        )
        .animation(BakingMotion.quick, value: isSelected)
    }
}

struct BakingLabel: View {
    let text: String
    var role: BakingLabelRole = .fieldLabel

    var body: some View {
        Text(text)
            .bakingLabelStyle(role)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
    }
}

struct BakingNumericValue: View {
    let value: String
    var unit: String? = nil
    var kind: BakingValueKind = .tableNumber
    var numericKind: BakingNumericValueKind = .count
    var role: BakingComponentRole = .secondary
    var width: CGFloat? = nil
    var valueColor: Color? = nil
    var unitColor: Color? = nil

    var body: some View {
        let theme = BakingValueTheme.theme(for: kind, role: role)

        HStack(alignment: .firstTextBaseline, spacing: unit == nil ? 0 : 3) {
            Text(value)
                .font(theme.valueFont)
                .foregroundStyle(valueColor ?? theme.valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .contentTransition(.numericText())

            if let unit {
                Text(unit)
                    .font(theme.unitFont)
                    .foregroundStyle(unitColor ?? theme.unitColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(width: width, alignment: theme.alignment)
        .accessibilityElement(children: .combine)
    }
}

struct BakingReadOnlyValue: View {
    let title: String
    let value: String
    var unit: String? = nil
    var role: BakingComponentRole = .secondary

    var body: some View {
        VStack(alignment: .leading, spacing: BakingSpace.xs) {
            BakingLabel(text: title, role: .readOnlyLabel)
            BakingNumericValue(
                value: value,
                unit: unit,
                kind: .readOnly,
                role: role
            )
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.sm)
        .bakingSurface(.readOnly)
    }
}

struct BakingInlineMetricLabel: View {
    let title: String
    let value: String
    var unit: String? = nil
    var role: BakingComponentRole = .secondary
    var width: CGFloat? = nil

    var body: some View {
        let theme = inlineTheme

        HStack(alignment: .firstTextBaseline, spacing: BakingSpace.xs) {
            if !title.isEmpty {
                BakingLabel(text: title, role: .readOnlyLabel)
                    .foregroundStyle(theme.labelColor)
            }

            BakingNumericValue(
                value: value,
                unit: unit,
                kind: .readOnly,
                role: role,
                valueColor: theme.valueColor,
                unitColor: theme.valueColor
            )
        }
        .padding(.horizontal, BakingSpace.md)
        .frame(width: width, alignment: title.isEmpty ? .trailing : .leading)
        .frame(minHeight: BakingComponentMetrics.compactPillHeight)
        .background(theme.background)
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.field, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BakingRadius.field, style: .continuous)
                .stroke(theme.stroke, lineWidth: 0.5)
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }

    private var inlineTheme: (background: Color, stroke: Color, labelColor: Color, valueColor: Color) {
        let theme = BakingInlineLabelTheme.theme(for: role)
        return (
            background: theme.background,
            stroke: theme.stroke,
            labelColor: theme.labelColor,
            valueColor: theme.valueColor
        )
    }
}

struct BakingInlineLabelTheme {
    let background: Color
    let stroke: Color
    let labelColor: Color
    let valueColor: Color

    static func theme(for role: BakingComponentRole) -> BakingInlineLabelTheme {
        switch role {
        case .primary:
            BakingInlineLabelTheme(
                background: BakingSurface.selectedRowBackground,
                stroke: BakingSurface.selectedStroke,
                labelColor: .brandText,
                valueColor: .brandText
            )
        case .success:
            BakingInlineLabelTheme(
                background: Color.waterSurfaceStrong.opacity(0.42),
                stroke: Color.waterSurfaceStrong,
                labelColor: .waterText,
                valueColor: .waterText
            )
        default:
            BakingInlineLabelTheme(
                background: Color.brandFieldSurface.opacity(0.42),
                stroke: BakingSurface.cardStroke,
                labelColor: .brandSecondaryText,
                valueColor: .brandText
            )
        }
    }
}

struct BakingMetricValue: View {
    let title: String
    let value: String
    var unit: String? = nil
    var role: BakingComponentRole = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: BakingSpace.xs) {
            BakingLabel(text: title, role: .readOnlyLabel)
            BakingNumericValue(
                value: value,
                unit: unit,
                kind: .metric,
                role: role
            )
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bakingSurface(.readOnly)
    }
}

struct BakingSearchField: View {
    @Binding var text: String
    let prompt: String
    let clearAccessibilityLabel: String

    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            Image(systemName: "magnifyingglass")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .font(BakingTypography.appPrimaryText)
                .foregroundStyle(Color.brandText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.brandSecondaryText)
                        .frame(width: BakingTouchTarget.secondaryAction, height: BakingTouchTarget.secondaryAction)
                        .contentShape(Rectangle())
                        .accessibilityHidden(true)
                }
                .buttonStyle(BakingPressFeedbackButtonStyle())
                .accessibilityLabel(clearAccessibilityLabel)
            }
        }
        .padding(.leading, BakingSpace.xxl)
        .padding(.trailing, text.isEmpty ? BakingSpace.xxl : BakingSpace.xs)
        .frame(minHeight: BakingTouchTarget.primaryAction)
        .background(Color.brandBackground)
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.field, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BakingRadius.field, style: .continuous)
                .stroke(BakingSurface.warmHairline, lineWidth: 0.7)
        }
        .accessibilityElement(children: .contain)
    }
}

struct BakingActionButton: View {
    let title: String
    let accessibilityLabel: String
    var role: BakingComponentRole = .primary
    var state: BakingComponentState = .normal
    var action: () -> Void

    var body: some View {
        let theme = BakingComponentTheme.action(role: role)
        let isDisabled = state == .disabled

        Button(action: action) {
            Text(title)
                .font(BakingTypography.actionLabel)
                .foregroundStyle(foregroundColor(theme: theme, isDisabled: isDisabled))
                .frame(maxWidth: .infinity)
                .frame(height: BakingTouchTarget.primaryAction)
                .contentShape(RoundedRectangle(cornerRadius: BakingRadius.card, style: .continuous))
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .bakingSurface(surfaceKind)
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel)
    }

    private var surfaceKind: BakingSurfaceKind {
        switch state {
        case .disabled:
            .readOnly
        case .selected, .focused, .editing:
            .focused
        case .warning:
            .warning
        case .success:
            .success
        default:
            role == .primary ? .primaryAction : .readOnly
        }
    }

    private func foregroundColor(theme: BakingComponentTheme, isDisabled: Bool) -> Color {
        guard !isDisabled else { return theme.disabledForeground }
        return role == .primary ? .brandOnPrimary : theme.foreground
    }
}

struct BakingBottomActionButton: View {
    let title: String
    let accessibilityLabel: String
    var role: BakingComponentRole = .primary
    var state: BakingComponentState = .normal
    var action: () -> Void

    var body: some View {
        BakingActionButton(
            title: title,
            accessibilityLabel: accessibilityLabel,
            role: role,
            state: state,
            action: action
        )
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.top, BakingSpace.sm)
        .padding(.bottom, BakingSpace.sm)
        .background(BakingSurface.bottomBarBackground)
    }
}

struct BakingFormSection<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content

    init(_ title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BakingFormTheme.rowSpacing) {
            if let title {
                Text(title)
                    .font(BakingTypography.sectionTitle)
                    .foregroundStyle(BakingFormTheme.secondaryValueColor)
            }

            VStack(spacing: 0) {
                content()
            }
            .bakingCard(
                background: BakingFormTheme.rowBackground,
                radius: BakingRadius.prominentCard,
                stroke: BakingSurface.cardStroke
            )
        }
    }
}

struct BakingFormRow<Value: View>: View {
    let title: String
    var subtitle: String? = nil
    var alignment: VerticalAlignment = .center
    var state: BakingComponentState = .normal
    @ViewBuilder let value: () -> Value

    var body: some View {
        HStack(alignment: alignment, spacing: BakingSpace.md) {
            VStack(alignment: .leading, spacing: BakingSpace.xs) {
                BakingLabel(text: title, role: .fieldLabel)

                if let subtitle {
                    BakingLabel(text: subtitle, role: .helperText)
                }
            }

            Spacer(minLength: BakingSpace.md)

            value()
                .font(BakingFormTheme.valueFont)
                .foregroundStyle(BakingFormTheme.valueColor)
        }
        .padding(.horizontal, BakingFormTheme.rowHorizontalPadding)
        .padding(.vertical, BakingFormTheme.rowVerticalPadding)
        .frame(minHeight: BakingTouchTarget.primaryAction)
        .opacity(state == .disabled ? 0.62 : 1)
    }
}

struct BakingTextInputRow: View {
    let title: String
    @Binding var text: String
    var placeholder: String
    var subtitle: String? = nil
    var state: BakingComponentState = .normal

    var body: some View {
        BakingFormRow(title: title, subtitle: subtitle, state: state) {
            BakingInlineTextField(
                text: $text,
                placeholder: placeholder,
                color: UIColor(state == .disabled ? Color.brandSecondaryText : Color.brandText),
                font: .preferredFont(forTextStyle: .body),
                textAlignment: .right
            )
            .frame(minWidth: 112, minHeight: 28)
            .padding(.horizontal, BakingSpace.sm)
            .padding(.vertical, BakingSpace.xs)
            .bakingSurface(inputSurfaceKind)
        }
    }

    private var inputSurfaceKind: BakingSurfaceKind {
        switch state {
        case .focused, .editing:
            .focused
        case .disabled:
            .readOnly
        default:
            .field
        }
    }
}

struct BakingNumberInputRow: View {
    let title: String
    @Binding var value: Double
    var unit: String? = nil
    var subtitle: String? = nil
    var fractionDigits: ClosedRange<Int> = 0...1
    var minValue: Double = 0
    var state: BakingComponentState = .normal

    var body: some View {
        BakingFormRow(title: title, subtitle: subtitle, state: state) {
            HStack(alignment: .firstTextBaseline, spacing: BakingSpace.xs) {
                BakingNumericTextField(
                    value: $value,
                    fractionDigits: fractionDigits,
                    minValue: minValue,
                    color: UIColor(state == .disabled ? Color.brandSecondaryText : Color.brandText),
                    font: .monospacedDigitSystemFont(ofSize: 15, weight: .semibold),
                    isEnabled: state != .disabled
                )
                .frame(width: 82)

                if let unit {
                    Text(unit)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandSecondaryText)
                }
            }
            .padding(.horizontal, BakingSpace.sm)
            .padding(.vertical, BakingSpace.xs)
            .bakingSurface(inputSurfaceKind)
        }
    }

    private var inputSurfaceKind: BakingSurfaceKind {
        switch state {
        case .focused, .editing:
            .focused
        case .disabled:
            .readOnly
        default:
            .field
        }
    }
}

struct BakingPickerRow: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var state: BakingComponentState = .normal
    var action: () -> Void

    var body: some View {
        BakingFormRow(title: title, subtitle: subtitle, state: state) {
            Button(action: action) {
                HStack(spacing: BakingSpace.xs) {
                    Text(value)
                        .font(BakingTypography.rowValue)
                        .foregroundStyle(Color.brandText)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.brandSecondaryText)
                }
                .padding(.horizontal, BakingSpace.sm)
                .padding(.vertical, BakingSpace.xs)
                .bakingSurface(state == .disabled ? .readOnly : .field)
            }
            .buttonStyle(BakingPressFeedbackButtonStyle())
            .disabled(state == .disabled)
            .accessibilityLabel(title)
            .accessibilityValue(value)
        }
    }
}

struct BakingToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var subtitle: String? = nil
    var state: BakingComponentState = .normal

    var body: some View {
        BakingFormRow(title: title, subtitle: subtitle, state: state) {
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(.brandPrimary)
                .disabled(state == .disabled)
        }
    }
}

struct BakingDateTimeRow: View {
    let title: String
    @Binding var date: Date
    var subtitle: String? = nil
    var displayedComponents: DatePickerComponents = [.date, .hourAndMinute]
    var state: BakingComponentState = .normal

    var body: some View {
        BakingFormRow(title: title, subtitle: subtitle, state: state) {
            DatePicker(
                title,
                selection: $date,
                displayedComponents: displayedComponents
            )
            .labelsHidden()
            .tint(.brandPrimary)
            .disabled(state == .disabled)
        }
    }
}

struct BakingTimePickerPopover: View {
    @Binding var date: Date

    var body: some View {
        BakingWheelTimePicker(date: $date)
            .frame(height: 180)
            .frame(width: BakingComponentMetrics.popoverMediumWidth)
            .padding(.horizontal, BakingSpace.lg)
            .padding(.vertical, BakingSpace.sm)
            .bakingPopoverSurface(width: BakingComponentMetrics.popoverMediumWidth)
    }
}

private struct BakingWheelTimePicker: UIViewRepresentable {
    @Binding var date: Date

    func makeCoordinator() -> Coordinator {
        Coordinator(date: $date)
    }

    func makeUIView(context: Context) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.minuteInterval = 1
        picker.date = date
        picker.tintColor = UIColor(Color.brandPrimary)
        picker.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return picker
    }

    func updateUIView(_ uiView: UIDatePicker, context: Context) {
        if abs(uiView.date.timeIntervalSince(date)) > 0.5 {
            uiView.date = date
        }
        uiView.tintColor = UIColor(Color.brandPrimary)
    }

    final class Coordinator: NSObject {
        @Binding var date: Date

        init(date: Binding<Date>) {
            _date = date
        }

        @objc func changed(_ sender: UIDatePicker) {
            date = sender.date
        }
    }
}

struct BakingTableRow<Content: View>: View {
    var isSelected = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .font(BakingTableTheme.cellFont)
            .foregroundStyle(BakingTableTheme.cellColor)
            .padding(BakingTableTheme.rowPadding)
            .background(isSelected ? BakingTableTheme.selectedRowBackground : BakingTableTheme.rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: BakingRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: BakingRadius.card, style: .continuous)
                    .stroke(BakingTableTheme.rowStroke, lineWidth: 0.5)
            }
    }
}

struct BakingTableColumn {
    let title: String
    var width: CGFloat
    var alignment: Alignment = .trailing

    init(title: String, width: CGFloat, alignment: Alignment = .trailing) {
        self.title = title
        self.width = width
        self.alignment = alignment
    }
}

struct BakingTableHeader: View {
    let title: String
    var columns: [BakingTableColumn] = []

    var body: some View {
        HStack(spacing: BakingSpace.md) {
            BakingLabel(text: title, role: .tableHeader)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                BakingLabel(text: column.title, role: .tableHeader)
                    .frame(width: column.width, alignment: column.alignment)
            }
        }
        .padding(.horizontal, BakingTableTheme.rowPadding)
        .padding(.vertical, BakingSpace.xs)
    }
}

struct BakingTable<Header: View, Rows: View>: View {
    @ViewBuilder let header: () -> Header
    @ViewBuilder let rows: () -> Rows

    var body: some View {
        VStack(spacing: 0) {
            header()

            Divider()
                .opacity(0)
                .overlay(BakingTableTheme.rowStroke)

            rows()
        }
        .bakingSurface(.card)
    }
}

struct BakingEmptyState: View {
    let title: String
    var systemImage: String
    var message: String? = nil

    var body: some View {
        VStack(spacing: BakingSpace.sm) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)

            Text(title)
                .font(BakingTypography.rowTitle)
                .foregroundStyle(Color.brandText)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .bakingLabelStyle(.helperText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(BakingSpace.xxl)
        .bakingSurface(.readOnly)
        .accessibilityElement(children: .combine)
    }
}

struct BakingQuantityColumn: View {
    let value: String
    let unit: String
    var valueFont: Font = BakingTypography.tableNumber
    var unitFont: Font = BakingTypography.rowMeta
    var valueColor: Color = .brandText
    var unitColor: Color? = .brandSecondaryText
    var valueWidth: CGFloat = 54
    var unitWidth: CGFloat = 18
    var spacing: CGFloat = 3

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: spacing) {
            Text(value)
                .font(valueFont)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .frame(width: valueWidth, alignment: .trailing)

            Text(unit)
                .font(unitFont)
                .foregroundStyle(unitColor ?? valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .frame(width: unitWidth, alignment: .trailing)
        }
        .frame(width: valueWidth + spacing + unitWidth, alignment: .leading)
    }
}

struct BakingPercentColumn: View {
    let value: String
    var valueFont: Font = BakingTypography.tableNumber
    var unitFont: Font = BakingTypography.rowMeta
    var color: Color = .brandText
    var unitColor: Color? = .brandSecondaryText
    var width: CGFloat = 60

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(value)
                .font(valueFont)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text("%")
                .font(unitFont)
                .foregroundStyle(unitColor ?? color)
        }
        .frame(width: width, alignment: .leading)
    }
}

struct BakingTopActionRow<Leading: View, Trailing: View>: View {
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            leading()
                .frame(minWidth: BakingTouchTarget.iconButton, alignment: .leading)

            Spacer(minLength: BakingSpace.sm)

            trailing()
        }
        .frame(minHeight: BakingTouchTarget.iconButton)
        .padding(.horizontal, BakingLayout.screenHorizontalInset)
        .padding(.top, BakingSpace.xs)
        .padding(.bottom, BakingSpace.xs)
        .background(Color.brandBackground)
    }
}

extension BakingTopActionRow where Leading == EmptyView {
    init(@ViewBuilder trailing: @escaping () -> Trailing) {
        self.leading = { EmptyView() }
        self.trailing = trailing
    }
}

extension BakingTopActionRow where Trailing == EmptyView {
    init(@ViewBuilder leading: @escaping () -> Leading) {
        self.leading = leading
        self.trailing = { EmptyView() }
    }
}

struct BakingPressFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(BakingMotion.quick, value: configuration.isPressed)
    }
}

struct BakingConfirmationDialog: View {
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    var confirmTint: Color = .brandPrimary
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.24)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onCancel)

            VStack(alignment: .leading, spacing: BakingSpace.xxl) {
                VStack(alignment: .leading, spacing: BakingSpace.sm) {
                    Text(title)
                        .font(BakingTypography.sectionTitle)
                        .foregroundStyle(Color.brandText)

                    Text(message)
                        .font(BakingTypography.appPrimaryText)
                        .foregroundStyle(Color.brandSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: BakingSpace.sm) {
                    Button(action: onCancel) {
                        Text(cancelTitle)
                            .font(BakingTypography.appPrimaryText)
                            .foregroundStyle(Color.brandSecondaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: BakingTouchTarget.primaryAction)
                            .background(Color.brandBackground.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: BakingRadius.card, style: .continuous))
                    }
                    .buttonStyle(BakingPressFeedbackButtonStyle())

                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .font(BakingTypography.appPrimaryText)
                            .foregroundStyle(confirmTint)
                            .frame(maxWidth: .infinity)
                            .frame(height: BakingTouchTarget.primaryAction)
                            .background(confirmTint.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: BakingRadius.card, style: .continuous))
                    }
                    .buttonStyle(BakingPressFeedbackButtonStyle())
                }
            }
            .padding(BakingSpace.xxl)
            .frame(maxWidth: 320)
            .bakingCard(
                background: Color.brandBackground,
                radius: BakingRadius.popover,
                stroke: BakingSurface.warmHairline,
                lineWidth: 0.8
            )
            .shadow(color: Color.black.opacity(0.12), radius: 24, y: 14)
            .padding(.horizontal, BakingLayout.screenHorizontalInset)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .accessibilityElement(children: .contain)
    }
}

final class BakingScrollFriendlyTextField: UITextField {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = panGesture.velocity(in: self)
            if abs(velocity.y) > abs(velocity.x) {
                return false
            }
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

struct BakingInlineTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    var color: UIColor = UIColor(Color.brandText)
    var font: UIFont = .preferredFont(forTextStyle: .body)
    var textAlignment: NSTextAlignment = .left
    var returnKeyType: UIReturnKeyType = .done
    var minimumScaleFactor: CGFloat = 0.72
    var maxLength: Int? = 32

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = BakingScrollFriendlyTextField()
        textField.placeholder = placeholder
        textField.text = text
        textField.textColor = color
        textField.font = font
        textField.textAlignment = textAlignment
        textField.borderStyle = .none
        textField.returnKeyType = returnKeyType
        textField.delegate = context.coordinator
        textField.tintColor = UIColor(Color.brandPrimary)
        textField.clearButtonMode = .never
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = font.pointSize * minimumScaleFactor
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        uiView.placeholder = placeholder
        uiView.textColor = color
        uiView.font = font
        uiView.textAlignment = textAlignment
        uiView.returnKeyType = returnKeyType
        uiView.adjustsFontSizeToFitWidth = true
        uiView.minimumFontSize = font.pointSize * minimumScaleFactor
        if !uiView.isFirstResponder, uiView.text != text {
            uiView.text = text
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: BakingInlineTextField

        init(parent: BakingInlineTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ textField: UITextField) {
            let currentText = textField.text ?? ""
            if textField.markedTextRange != nil {
                parent.text = currentText
                return
            }
            let limitedText = parent.limited(currentText)
            if limitedText != currentText {
                textField.text = limitedText
            }
            parent.text = limitedText
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            guard let maxLength = parent.maxLength else { return true }
            guard textField.markedTextRange == nil else { return true }
            let currentText = textField.text ?? ""
            guard let textRange = Range(range, in: currentText) else { return true }
            let proposedText = currentText.replacingCharacters(in: textRange, with: string)
            return proposedText.count <= maxLength
        }
    }

    private func limited(_ value: String) -> String {
        guard let maxLength, value.count > maxLength else { return value }
        return String(value.prefix(maxLength))
    }
}

struct BakingNumericTextField: UIViewRepresentable {
    @Binding var value: Double
    let fractionDigits: ClosedRange<Int>
    var minValue: Double = 0
    var maxValue: Double? = nil
    var color: UIColor = UIColor(Color.brandText)
    var font: UIFont = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
    var textAlignment: NSTextAlignment = .right
    var adjustsFontSizeToFitWidth = true
    var isEnabled = true
    var showsAccessoryToolbar = false

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = BakingScrollFriendlyTextField()
        textField.keyboardType = fractionDigits.upperBound > 0 ? .decimalPad : .numberPad
        textField.textAlignment = textAlignment
        textField.textColor = color
        textField.font = font
        textField.borderStyle = .none
        textField.delegate = context.coordinator
        textField.text = context.coordinator.formatted(value)
        textField.tintColor = UIColor(Color.brandPrimary)
        textField.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
        textField.minimumFontSize = 12
        textField.isEnabled = isEnabled
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        if showsAccessoryToolbar {
            textField.inputAccessoryView = context.coordinator.makeAccessoryToolbar()
        }
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        uiView.textColor = color
        uiView.font = font
        uiView.textAlignment = textAlignment
        uiView.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
        uiView.isEnabled = isEnabled
        uiView.keyboardType = fractionDigits.upperBound > 0 ? .decimalPad : .numberPad

        let next = context.coordinator.formatted(value)
        let shouldReflectExternalChange = context.coordinator.shouldReflectExternalChange(value)
        if (!uiView.isFirstResponder || shouldReflectExternalChange), uiView.text != next {
            uiView.text = next
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: BakingNumericTextField
        private let formatter = NumberFormatter()
        private var lastPublishedValue: Double?

        init(parent: BakingNumericTextField) {
            self.parent = parent
            super.init()
            configureFormatter()
        }

        func makeAccessoryToolbar() -> UIToolbar {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let flex = UIBarButtonItem(systemItem: .flexibleSpace)
            let done = UIBarButtonItem(title: BakingTerms.done, style: .done, target: self, action: #selector(doneTapped))
            toolbar.items = [flex, done]
            return toolbar
        }

        func formatted(_ value: Double) -> String {
            configureFormatter()
            let clamped = parent.clamped(value)
            return formatter.string(from: NSNumber(value: clamped)) ?? BakingFormat.number(clamped, precision: parent.fractionDigits.upperBound)
        }

        func shouldReflectExternalChange(_ value: Double) -> Bool {
            guard let lastPublishedValue else { return true }
            return abs(value - lastPublishedValue) > 0.000_001
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async { [weak textField] in
                guard let textField, textField.isFirstResponder else { return }
                self.moveCaretToEnd(of: textField)
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if (textField.text ?? "").isEmpty {
                parent.value = parent.minValue
            }
            textField.text = formatted(parent.value)
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = textField.text ?? formatted(parent.value)
            guard let stringRange = Range(range, in: current) else { return false }
            let next = current.replacingCharacters(in: stringRange, with: string)

            if next.isEmpty {
                parent.value = parent.minValue
                lastPublishedValue = parent.minValue
                return true
            }

            guard isValid(next) else { return false }

            let normalized = normalizedInput(next)
            if normalized != next {
                update(textField, with: normalized)
                return false
            }

            updateValue(from: normalized)
            return true
        }

        private func configureFormatter() {
            formatter.numberStyle = .decimal
            formatter.usesGroupingSeparator = false
            formatter.minimumFractionDigits = parent.fractionDigits.lowerBound
            formatter.maximumFractionDigits = parent.fractionDigits.upperBound
            formatter.decimalSeparator = "."
        }

        private func isValid(_ text: String) -> Bool {
            let allowed = CharacterSet(charactersIn: "0123456789.")
            guard text.rangeOfCharacter(from: allowed.inverted) == nil else { return false }

            let parts = text.split(separator: ".", omittingEmptySubsequences: false)
            guard parts.count <= 2 else { return false }

            if parent.fractionDigits.upperBound == 0 {
                return !text.contains(".")
            }

            if parts.count == 2 {
                guard parts[1].count <= parent.fractionDigits.upperBound else { return false }
            }

            guard let number = Double(text) else { return true }
            return parent.contains(number)
        }

        private func normalizedInput(_ text: String) -> String {
            guard text.count > 1 else { return text }

            if text.hasPrefix("0"), !text.hasPrefix("0.") {
                let trimmed = text.drop { $0 == "0" }
                return trimmed.isEmpty ? "0" : String(trimmed)
            }

            return text
        }

        private func update(_ textField: UITextField, with text: String) {
            updateValue(from: text)
            textField.text = text
            moveCaretToEnd(of: textField)
        }

        private func updateValue(from text: String) {
            guard let number = Double(text) else { return }
            let nextValue = parent.clamped(number)
            lastPublishedValue = nextValue
            parent.value = nextValue
        }

        private func moveCaretToEnd(of textField: UITextField) {
            let end = textField.endOfDocument
            if let range = textField.textRange(from: end, to: end) {
                textField.selectedTextRange = range
            }
        }

        @objc private func doneTapped() {
            dismissActiveKeyboard()
        }
    }

    private func clamped(_ nextValue: Double) -> Double {
        let minClamped = max(minValue, nextValue)
        guard let maxValue else { return minClamped }
        return min(minClamped, maxValue)
    }

    private func contains(_ nextValue: Double) -> Bool {
        guard nextValue >= minValue else { return false }
        guard let maxValue else { return true }
        return nextValue <= maxValue
    }
}

struct BakingPercentageField: View {
    @Binding var value: Double
    var maxValue: Double = 100
    var precision: Int = 1
    var font: Font = .subheadline
    var valueFont: Font? = nil
    var color: Color = .brandPrimary
    var fieldWidth: CGFloat = 34
    var totalWidth: CGFloat? = 62
    var isWaterStyle = false
    var height: CGFloat = 40

    @State private var isShowingPicker = false

    var body: some View {
        Button {
            isShowingPicker = true
        } label: {
            HStack(spacing: 4) {
                Text(formattedPercent)
                    .font(displayFont)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(width: fieldWidth, alignment: .trailing)
                Text("%")
                    .font(font)
                    .foregroundStyle(Color.brandSecondaryText)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .frame(width: totalWidth, alignment: .trailing)
            .frame(height: height)
            .bakingSurface(.field)
            .contentShape(RoundedRectangle(cornerRadius: BakingRadius.field, style: .continuous))
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(BakingTerms.percentagePickerAccessibility)
        .accessibilityValue("\(formattedPercent)%")
        .fullScreenCover(isPresented: $isShowingPicker) {
            BakingCenteredPercentagePicker(
                value: Binding(
                    get: { clampedValue },
                    set: { value = clamped($0) }
                ),
                isPresented: $isShowingPicker,
                maxValue: maxValue,
                precision: precision,
                tint: color,
                surface: BakingSurface.fieldBackground
            )
            .presentationBackground(.clear)
        }
        .onChange(of: maxValue) { _, _ in
            value = clamped(value)
        }
    }

    private var clampedValue: Double {
        clamped(value)
    }

    private var formattedPercent: String {
        BakingFormat.number(clampedValue, precision: displayPrecision)
    }

    private var displayPrecision: Int {
        max(precision, 1)
    }

    private func clamped(_ nextValue: Double) -> Double {
        min(max(0, nextValue), effectiveMaxValue)
    }

    private var effectiveMaxValue: Double {
        max(0, maxValue)
    }

    private var displayFont: Font {
        if let valueFont {
            return valueFont
        }

        switch font {
        case .callout:
            return .callout.monospacedDigit().weight(.semibold)
        case .caption:
            return .caption.monospacedDigit().weight(.semibold)
        default:
            return .subheadline.monospacedDigit().weight(.semibold)
        }
    }

}

struct BakingCenteredPercentagePicker: View {
    @Binding var value: Double
    @Binding var isPresented: Bool
    var maxValue: Double = 100
    var precision: Int = 1
    var tint: Color = .brandPrimary
    var surface: Color = BakingSurface.fieldBackground

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            BakingPercentagePickerCard(
                value: $value,
                maxValue: maxValue,
                precision: precision,
                tint: tint,
                surface: surface
            )
            .padding(.horizontal, BakingSpace.xl)
            .transition(.scale(scale: 0.98).combined(with: .opacity))
        }
        .background(Color.clear)
    }
}

struct BakingPercentagePickerCard: View {
    @Binding var value: Double
    var maxValue: Double = 100
    var precision: Int = 1
    var tint: Color = .brandPrimary
    var surface: Color = BakingSurface.fieldBackground

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(BakingTerms.percentage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)

            BakingPercentagePickerControl(
                value: Binding(
                    get: { clampedValue },
                    set: { value = clamped($0) }
                ),
                maxValue: maxValue,
                precision: precision,
                tint: tint,
                surface: surface
            )
        }
        .padding(14)
        .frame(width: 304)
        .background(
            RoundedRectangle(cornerRadius: BakingRadius.popover, style: .continuous)
                .fill(Color.brandBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: BakingRadius.popover, style: .continuous)
                        .stroke(BakingSurface.warmHairline, lineWidth: 0.6)
                }
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
        )
        .onChange(of: maxValue) { _, _ in
            value = clamped(value)
        }
    }

    private var clampedValue: Double {
        clamped(value)
    }

    private var effectiveMaxValue: Double {
        max(0, maxValue)
    }

    private func clamped(_ nextValue: Double) -> Double {
        min(max(0, nextValue), effectiveMaxValue)
    }
}

struct BakingPercentagePickerControl: View {
    @Binding var value: Double
    var maxValue: Double = 100
    var precision: Int = 1
    var tint: Color = .brandPrimary
    var surface: Color = BakingSurface.fieldBackground

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 4) {
                BakingNumericTextField(
                    value: sliderBinding,
                    fractionDigits: 0...1,
                    maxValue: effectiveMaxValue,
                    color: UIColor(tint),
                    font: .monospacedDigitSystemFont(ofSize: 18, weight: .semibold),
                    textAlignment: .right
                )
                .frame(width: 50, height: BakingComponentMetrics.compactInputFieldHeight)
                Text("%")
                    .font(BakingTypography.rowMeta)
                    .foregroundStyle(Color.brandSecondaryText)
                    .frame(height: BakingComponentMetrics.compactInputFieldHeight, alignment: .center)
            }
            .padding(.horizontal, 8)
            .frame(width: BakingCompactInputFieldSize.short.width, height: BakingComponentMetrics.compactInputFieldHeight)
            .background(surface)
            .clipShape(RoundedRectangle(cornerRadius: BakingRadius.field, style: .continuous))

            HStack(spacing: BakingSpace.sm) {
                stepButton(
                    systemImage: "minus",
                    accessibilityLabel: BakingTerms.percentagePickerDecrease
                ) {
                    value = clamped(clampedValue - 1)
                }

                VStack(spacing: 6) {
                    Slider(value: sliderBinding, in: 0...max(1, effectiveMaxValue), step: step)
                        .tint(tint)
                        .accessibilityLabel(BakingTerms.percentagePickerAccessibility)
                        .accessibilityValue("\(formattedPercent)%")

                    HStack {
                        Text("0%")
                        Spacer()
                        Text("\(BakingFormat.number(effectiveMaxValue, precision: 0))%")
                    }
                    .font(.caption2.monospacedDigit().weight(.medium))
                    .foregroundStyle(Color.brandSecondaryText)
                }

                stepButton(
                    systemImage: "plus",
                    accessibilityLabel: BakingTerms.percentagePickerIncrease
                ) {
                    value = clamped(clampedValue + 1)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: maxValue) { _, _ in
            value = clamped(value)
        }
    }

    private func stepButton(
        systemImage: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: BakingTouchTarget.iconButton, height: BakingTouchTarget.iconButton)
                .contentShape(Rectangle())
                .accessibilityHidden(true)
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }

    private var sliderBinding: Binding<Double> {
        Binding(
            get: { clampedValue },
            set: { value = clamped($0) }
        )
    }

    private var clampedValue: Double {
        clamped(value)
    }

    private var formattedPercent: String {
        BakingFormat.number(clampedValue, precision: max(precision, 1))
    }

    private var effectiveMaxValue: Double {
        max(0, maxValue)
    }

    private var step: Double {
        precision <= 0 ? 1 : 0.1
    }

    private func clamped(_ nextValue: Double) -> Double {
        min(max(0, nextValue), effectiveMaxValue)
    }
}

enum BakingIconButtonShape {
    case circle
    case rounded(CGFloat)
}

enum BakingSlideActionDirection {
    case leadingToTrailing
    case trailingToLeading
}

struct BakingSlideActionBar: View {
    @Environment(\.historySwipeSuppressionHandler) private var setHistorySwipeSuppressed
    let icon: BakingIcon
    let accessibilityLabel: String
    var direction: BakingSlideActionDirection = .leadingToTrailing
    var tint: Color = .brandPrimary
    var trackBackground: Color = BakingSurface.fieldBackground
    var trackAccent: Color = BakingSurface.selectedRowBackground
    var onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isCompleting = false
    @State private var isHorizontalSlideActive = false
    @State private var isVerticalScrollIntent = false

    private let trackHeight: CGFloat = BakingTouchTarget.slideActionTrack
    private let thumbSize: CGFloat = BakingTouchTarget.slideActionThumb
    private let horizontalInset: CGFloat = BakingSpace.xs
    private let completionThreshold: CGFloat = 0.84

    var body: some View {
        GeometryReader { proxy in
            let trackWidth = proxy.size.width
            let travel = max(0, trackWidth - thumbSize - horizontalInset * 2)
            let currentProgress = min(max(progress, 0), 1)

            ZStack {
                Capsule(style: .continuous)
                    .fill(trackBackground)

                Capsule(style: .continuous)
                    .fill(trackAccent)
                    .frame(width: max(thumbSize, thumbSize + currentProgress * travel))
                    .frame(maxWidth: .infinity, alignment: fillAlignment)

                HStack(spacing: BakingSpace.xs) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: direction == .trailingToLeading ? "chevron.left" : "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(tint.opacity(0.24 + Double(index) * 0.16))
                    }
                }
                .allowsHitTesting(false)

                thumb
                    .position(
                        x: thumbCenterX(for: travel),
                        y: proxy.size.height / 2
                    )
                    .gesture(slideGesture(travel: travel))
                    .allowsHitTesting(!isCompleting)
            }
            .padding(horizontalInset)
            .bakingCard(
                background: trackBackground,
                radius: trackHeight / 2,
                stroke: tint.opacity(0.10)
            )
        }
        .frame(height: trackHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var fillAlignment: Alignment {
        switch direction {
        case .leadingToTrailing:
            .leading
        case .trailingToLeading:
            .trailing
        }
    }

    private var thumb: some View {
        ZStack {
            Circle()
                .fill(tint)

            BakingIconView(icon: icon, size: BakingTouchTarget.slideActionGlyph, color: .white)
        }
        .frame(width: thumbSize, height: thumbSize)
    }

    private func thumbCenterX(for travel: CGFloat) -> CGFloat {
        let normalized = progressPosition(for: progress)
        let minX = horizontalInset + thumbSize / 2
        return minX + normalized * travel
    }

    private func progressPosition(for progress: CGFloat) -> CGFloat {
        switch direction {
        case .leadingToTrailing:
            progress
        case .trailingToLeading:
            1 - progress
        }
    }

    private func progress(for normalizedPosition: CGFloat) -> CGFloat {
        switch direction {
        case .leadingToTrailing:
            normalizedPosition
        case .trailingToLeading:
            1 - normalizedPosition
        }
    }

    private func slideGesture(travel: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: BakingGesturePolicy.verticalScrollMinimumDistance, coordinateSpace: .local)
            .onChanged { value in
                guard !isCompleting else { return }
                guard !isVerticalScrollIntent else { return }
                if !isHorizontalSlideActive {
                    if BakingGesturePolicy.isVerticalScrollIntent(value.translation) {
                        isVerticalScrollIntent = true
                        withAnimation(BakingMotion.quick) {
                            progress = 0
                        }
                        return
                    }
                    guard BakingGesturePolicy.isHorizontalIntent(
                        value.translation,
                        minimumDistance: 10,
                        ratio: 1.25
                    ) else { return }
                    isHorizontalSlideActive = true
                    setHistorySwipeSuppressed(true)
                }
                let rawPosition = (value.location.x - thumbSize / 2 - horizontalInset) / max(travel, 1)
                let normalizedPosition = min(max(rawPosition, 0), 1)
                progress = progress(for: normalizedPosition)
            }
            .onEnded { value in
                guard !isCompleting else { return }
                let shouldReleaseHistorySwipe = isHorizontalSlideActive
                defer {
                    isHorizontalSlideActive = false
                    isVerticalScrollIntent = false
                    if shouldReleaseHistorySwipe {
                        setHistorySwipeSuppressed(false)
                    }
                }
                guard isHorizontalSlideActive else {
                    withAnimation(BakingMotion.quick) {
                        progress = 0
                    }
                    return
                }
                let rawPosition = (value.location.x - thumbSize / 2 - horizontalInset) / max(travel, 1)
                let normalizedPosition = min(max(rawPosition, 0), 1)
                let nextProgress = progress(for: normalizedPosition)

                guard nextProgress >= completionThreshold else {
                    withAnimation(BakingMotion.quick) {
                        progress = 0
                    }
                    return
                }

                isCompleting = true
                withAnimation(BakingMotion.standard) {
                    progress = 1
                }
                onComplete()

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.65))
                    isCompleting = false
                    withAnimation(BakingMotion.standard) {
                        progress = 0
                    }
                }
            }
    }
}

struct BakingMaterialIconBadge: View {
    let icon: BakingIcon
    var size: CGFloat = BakingTouchTarget.materialBadge
    var iconSize: CGFloat = BakingTouchTarget.materialBadgeGlyph
    var color: Color = .brandPrimary
    var background: Color = BakingSurface.selectedRowBackground

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(background)
            BakingIconView(icon: icon, size: iconSize, color: color)
        }
        .frame(width: size, height: size)
    }
}

struct BakingSwipeToDeleteRow<Content: View>: View {
    @Environment(\.historySwipeSuppressionHandler) private var setHistorySwipeSuppressed
    let canDelete: Bool
    let onDelete: () -> Void
    var onOpenChanged: (Bool) -> Void = { _ in }
    var closeToken: Int = 0
    var deleteConfirmationTitle = BakingTerms.delete
    var deleteConfirmationMessage = BakingTerms.delete
    var deleteButtonTitle = BakingTerms.delete
    @ViewBuilder let content: () -> Content
    @State private var offset: CGFloat = 0
    @State private var isHorizontalSwipeActive = false
    @State private var dragStartOffset: CGFloat = 0
    @State private var rowWidth: CGFloat = 0
    @State private var rowHeight: CGFloat = 0
    @State private var showingDeleteConfirmation = false
    @State private var isVerticalScrollIntent = false

    private let actionWidth: CGFloat = 76
    private let buttonSize = CGSize(width: 50, height: 50)
    private let fullSwipeInset: CGFloat = 2

    var body: some View {
        ZStack(alignment: .trailing) {
            if canDelete && offset != 0 {
                deleteAction
            }

            content()
                .offset(x: offset)
                .contentShape(Rectangle())
                .allowsHitTesting(offset == 0)
        }
        .contentShape(Rectangle())
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        rowWidth = proxy.size.width
                        rowHeight = proxy.size.height
                    }
                    .onChange(of: proxy.size.width) { _, newWidth in
                        rowWidth = newWidth
                        offset = max(offset, -fullSwipeWidth)
                    }
                    .onChange(of: proxy.size.height) { _, newHeight in
                        rowHeight = newHeight
                    }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.prominentCard, style: .continuous))
        .simultaneousGesture(
            DragGesture(minimumDistance: 14, coordinateSpace: .local)
                .onChanged { value in
                    guard canDelete else { return }
                    guard !isVerticalScrollIntent else { return }

                    if !isHorizontalSwipeActive {
                        if BakingGesturePolicy.isVerticalScrollIntent(value.translation) {
                            isVerticalScrollIntent = true
                            return
                        }
                        guard BakingGesturePolicy.isHorizontalIntent(value.translation) else { return }
                        isHorizontalSwipeActive = true
                        setHistorySwipeSuppressed(true)
                        dragStartOffset = offset
                    }

                    let nextOffset = dragStartOffset + value.translation.width
                    offset = min(0, max(-fullSwipeWidth, nextOffset))
                }
                .onEnded { value in
                    guard canDelete else { return }
                    let shouldReleaseHistorySwipe = isHorizontalSwipeActive
                    defer {
                        isHorizontalSwipeActive = false
                        isVerticalScrollIntent = false
                        if shouldReleaseHistorySwipe {
                            setHistorySwipeSuppressed(false)
                        }
                        dragStartOffset = 0
                    }

                    guard isHorizontalSwipeActive else { return }
                    withAnimation(BakingMotion.quick) {
                        offset = snappedOffset(for: offset)
                    }
                    onOpenChanged(offset != 0)
                }
        )
        .onTapGesture {
            guard offset != 0 else { return }
            withAnimation(BakingMotion.quick) {
                offset = 0
            }
            onOpenChanged(false)
        }
        .onChange(of: offset) { _, newValue in
            onOpenChanged(newValue != 0)
        }
        .onChange(of: closeToken) { _, _ in
            guard offset != 0 else { return }
            closeSwipe()
        }
        .confirmationDialog(deleteConfirmationTitle, isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button(deleteButtonTitle, role: .destructive) {
                closeSwipe()
                onDelete()
            }
            Button(BakingTerms.cancel, role: .cancel) {}
        } message: {
            Text(deleteConfirmationMessage)
        }
    }

    private var deleteAction: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: BakingRadius.prominentCard, style: .continuous)
                    .fill(BakingSurfaceTheme.theme(for: .destructive).background)

                Image(systemName: "trash")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: actionWidth, height: buttonSize.height)
            }
            .frame(width: deleteActionWidth)
            .frame(height: rowHeight)
            .contentShape(RoundedRectangle(cornerRadius: BakingRadius.prominentCard, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(BakingTerms.delete)
        .padding(.trailing, 3)
    }

    private var deleteActionWidth: CGFloat {
        min(fullSwipeWidth, max(actionWidth, -offset))
    }

    private var fullSwipeWidth: CGFloat {
        max(actionWidth, rowWidth - fullSwipeInset)
    }

    private func snappedOffset(for offset: CGFloat) -> CGFloat {
        let reveal = -offset
        if reveal >= fullSwipeWidth * 0.72 {
            return -fullSwipeWidth
        }
        if reveal >= actionWidth * 0.52 {
            return -actionWidth
        }
        return 0
    }

    private func closeSwipe() {
        withAnimation(BakingMotion.quick) {
            offset = 0
        }
        onOpenChanged(false)
    }
}

struct BakingFlowLayout: Layout {
    var spacing: CGFloat = BakingSpace.sm

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
