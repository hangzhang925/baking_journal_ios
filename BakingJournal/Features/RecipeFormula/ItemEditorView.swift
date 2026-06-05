import SwiftUI

struct RecipeItemEditorRouteView: View {
    @EnvironmentObject private var navigationController: AppNavigationController
    @EnvironmentObject private var store: RecipeStore
    let itemID: UUID

    var body: some View {
        VStack(spacing: 0) {
            BakingTopActionRow(leading: {
                if navigationController.canGoBack {
                    BakingIconButton(
                        icon: .back,
                        accessibilityLabel: BakingTerms.back
                    ) {
                        navigationController.goBack()
                    }
                }
            })

            if let item {
                ItemEditorView(item: item)
                    .id(item.id)
            } else {
                BakingEmptyState(title: BakingTerms.formulaItemMissing, systemImage: "exclamationmark.triangle")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.brandBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var item: RecipeItem? {
        store.items.first { $0.id == itemID }
    }
}

struct ItemEditorSheetView: View {
    let item: RecipeItem
    var onDismiss: () -> Void
    var onContentHeightChange: (CGFloat) -> Void = { _ in }
    @StateObject private var dropdownPresenter = DropdownPresenter()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                BakingTopActionRow(
                    trailing: {
                        BakingSystemIconButton(
                            systemImage: "xmark",
                            accessibilityLabel: BakingTerms.done,
                            role: .secondary,
                            size: .secondary,
                            font: .caption.weight(.bold)
                        ) {
                            onDismiss()
                        }
                    }
                )

                ItemEditorView(item: item, onContentHeightChange: onContentHeightChange)
                    .id(item.id)
            }

            if let menu = dropdownPresenter.menu {
                dropdownOverlay(menu)
                    .zIndex(20)
            }
        }
        .background(Color.brandBackground)
        .environmentObject(dropdownPresenter)
        .coordinateSpace(name: "formulaDropdownSpace")
    }

    private func dropdownOverlay(_ menu: ActiveDropdownMenu) -> some View {
        GeometryReader { proxy in
            let layout = dropdownLayout(for: menu, in: proxy.size)

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dropdownPresenter.dismiss()
                }

            BakingDropdownPopover(width: menu.width) {
                ForEach(menu.items) { item in
                    Button {
                        dropdownPresenter.dismiss()
                        item.action()
                    } label: {
                        if menu.reservesLeadingIconSlot {
                            BakingDropdownRow(title: item.title, isSelected: item.isSelected) {
                                if let icon = item.icon {
                                    BakingIconView(icon: icon, size: BakingTouchTarget.dropdownIconGlyph, color: .brandPrimary)
                                } else {
                                    Color.clear
                                }
                            }
                        } else {
                            BakingDropdownTextRow(title: item.title, isSelected: item.isSelected)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .position(
                x: layout.origin.x + menu.width / 2,
                y: layout.origin.y + layout.height / 2
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .topLeading)))
        }
    }

    private func dropdownLayout(for menu: ActiveDropdownMenu, in containerSize: CGSize) -> (origin: CGPoint, height: CGFloat) {
        let rowHeight: CGFloat = 44
        let verticalPadding: CGFloat = 16
        let menuHeight = CGFloat(menu.items.count) * rowHeight + verticalPadding
        let horizontalInset: CGFloat = 8
        let verticalGap: CGFloat = 2
        let rawX = menu.alignment == .trailing ? (menu.frame.maxX - menu.width) : menu.frame.minX
        let x = min(max(horizontalInset, rawX), containerSize.width - menu.width - horizontalInset)

        let availableBelow = containerSize.height - menu.frame.maxY
        let showAbove = availableBelow < menuHeight + 20 && menu.frame.minY > menuHeight + 20
        let y = showAbove
            ? max(8, menu.frame.minY - menuHeight - verticalGap)
            : min(containerSize.height - menuHeight - 8, menu.frame.maxY + verticalGap)

        return (CGPoint(x: x, y: y), menuHeight)
    }
}

struct BakingDropdownTextRow: View {
    let title: String
    var isSelected = false

    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            Text(title)
                .font(BakingTypography.appPrimaryText)
                .foregroundStyle(Color.brandText)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer(minLength: 0)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.brandPrimary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
        .padding(.horizontal, BakingSpace.sm)
        .padding(.vertical, BakingSpace.sm)
        .contentShape(Rectangle())
    }
}

struct ItemEditorView: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    var onContentHeightChange: (CGFloat) -> Void = { _ in }

    var body: some View {
        ScrollView {
            CompactItemEditorCard(item: currentItem)
                .padding(.horizontal, BakingLayout.screenHorizontalInset)
                .padding(.top, BakingSpace.xs)
                .padding(.bottom, 32)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: ItemEditorContentHeightPreferenceKey.self, value: proxy.size.height)
                    }
                )
        }
        .onPreferenceChange(ItemEditorContentHeightPreferenceKey.self) { height in
            onContentHeightChange(height)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.brandBackground)
    }

    private var currentItem: RecipeItem {
        store.items.first { $0.id == item.id } ?? item
    }
}

private struct ItemEditorContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct CompactItemEditorCard: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem

    var body: some View {
        VStack(spacing: 0) {
            if currentItem.category == .starter {
                starterPopupEditor
                    .padding(.horizontal, BakingSpace.md)
                    .padding(.top, BakingSpace.xxs)
                    .padding(.bottom, BakingSpace.xxl)
            } else if currentItem.tag == .egg {
                eggPopupEditor
                    .padding(.horizontal, BakingSpace.md)
                    .padding(.top, BakingSpace.xxs)
                    .padding(.bottom, BakingSpace.xxl)
            } else if usesStackedPopupEditor {
                stackedPopupEditor
                    .padding(.horizontal, BakingSpace.md)
                    .padding(.top, BakingSpace.xxs)
                    .padding(.bottom, BakingSpace.xxl)
            } else {
                editableSummary

                if currentItem.requiresAdvancedFormulaEditor {
                    Divider()
                        .padding(.horizontal, BakingSpace.lg)
                        .opacity(0)

                    advancedEditor
                        .padding(BakingSpace.lg)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var starterPopupEditor: some View {
        advancedEditor
    }

    private var eggPopupEditor: some View {
        EggMiniRecipeEditor(
            item: currentItem,
            canRemove: false,
            name: itemTextBinding(\.name)
        )
    }

    private var stackedPopupEditor: some View {
        VStack(spacing: 0) {
            PopupIdentityTableRow(
                categoryIcon: BakingIcon.material(for: currentItem),
                categoryTitle: currentItem.tag.label,
                itemTint: itemTint,
                iconBackground: iconBackground,
                attributeIcons: popupAttributeIcons
            )

            PopupTableDivider()

            PopupNameTableRow(
                text: itemTextBinding(\.name),
                placeholder: currentItem.category.label
            )

            PopupTableDivider()

            PopupWeightMetricCell(
                title: BakingTerms.formulaTableWeight,
                value: Binding(
                    get: { currentItem.weight },
                    set: { store.updateItemWeight(currentItem, weight: $0) }
                )
            )

            PopupTableDivider()

            if currentItem.category == .flour {
                PopupReadOnlyMetricCell(
                    title: BakingTerms.formulaTablePercentage,
                    value: BakingFormat.number(percent, precision: 1),
                    unit: "%",
                    valueColor: .brandText
                )
            } else {
                PopupPercentMetricCell(
                    title: BakingTerms.formulaTablePercentage,
                    value: Binding(
                        get: { percent },
                        set: { store.updateItemPercent(currentItem, percent: $0) }
                    )
                )
            }
        }
        .bakingCard()
    }

    private var popupHeaderRow: some View {
        HStack(spacing: BakingSpace.sm) {
            BakingIconView(
                icon: BakingIcon.material(for: currentItem),
                size: BakingComponentMetrics.popupIconGlyph,
                color: itemTint
            )
            .frame(
                width: BakingComponentMetrics.popupIconSurface,
                height: BakingComponentMetrics.popupIconSurface
            )
            .background(iconBackground)
            .clipShape(RoundedRectangle(cornerRadius: BakingComponentMetrics.inlineIconCornerRadius, style: .continuous))

            BakingLabel(text: currentItem.tag.label, role: .inputLabel)
                .lineLimit(1)

            if hasWaterContent {
                PopupAttributeIcon(
                    icon: .water,
                    color: .waterText,
                    background: Color.waterSurface.opacity(0.9)
                )
            }

            Spacer(minLength: 0)
        }
        .frame(width: BakingComponentMetrics.popupFormWidth, alignment: .leading)
    }

    private var editableSummary: some View {
        HStack(alignment: .center, spacing: BakingSpace.lg) {
            iconBlock

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if currentItem.tag == .egg {
                        ItemEditorReadOnlyNameLabel(text: BakingTerms.egg)
                    } else {
                        ItemEditorPlainNameField(
                            text: itemTextBinding(\.name),
                            placeholder: currentItem.category.label,
                            tint: itemTint
                        )
                    }

                    if hasWaterContent {
                        Image(systemName: "drop.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.waterText.opacity(0.88))
                            .frame(width: 20, height: 18)
                            .background(Color.waterSurface.opacity(0.9))
                            .clipShape(Capsule())
                    }
                }

                if let detailText {
                    Text(detailText)
                        .font(.caption2)
                        .foregroundStyle(Color.brandSecondaryText)
                        .padding(.leading, BakingSpace.sm)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            HStack(alignment: .center, spacing: BakingSpace.md) {
                if currentItem.category == .starter || currentItem.tag == .egg {
                    ItemEditorReadOnlyNumeric(
                        value: BakingFormat.number(currentItem.weight, precision: 0),
                        unit: BakingTerms.unitGram,
                        color: .brandText,
                        width: 76
                    )
                } else {
                    ItemEditorWeightField(
                        value: Binding(
                            get: { currentItem.weight },
                            set: { store.updateItemWeight(currentItem, weight: $0) }
                        )
                    )
                }

                if currentItem.category != .flour {
                    Divider()
                        .overlay(BakingSurfaceTheme.separator)
                        .opacity(0)
                        .frame(height: 28)

                    if currentItem.category == .starter || currentItem.tag == .egg {
                        ItemEditorReadOnlyNumeric(
                            value: BakingFormat.number(percent, precision: 0),
                            unit: "%",
                            color: .brandText,
                            width: 58
                        )
                    } else {
                        ItemEditorPercentField(
                            value: Binding(
                                get: { percent },
                                set: { store.updateItemPercent(currentItem, percent: $0) }
                            )
                        )
                    }
                }
            }
            .layoutPriority(2)
        }
        .frame(minHeight: 64)
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.sm)
    }

    @ViewBuilder private var advancedEditor: some View {
        if currentItem.category == .starter {
            StarterMiniRecipeEditor(item: currentItem, canRemove: false)
        } else if currentItem.tag == .egg {
            EggMiniRecipeEditor(
                item: currentItem,
                canRemove: false,
                name: itemTextBinding(\.name)
            )
        } else {
            VStack(spacing: BakingSpace.sm) {
                CompactTextRow(title: BakingTerms.formulaFieldName, text: itemTextBinding(\.name))
                itemSpecificEditor
            }
        }
    }

    @ViewBuilder private var itemSpecificEditor: some View {
        if currentItem.tag == .yeast {
            CompactMenuRow(
                title: BakingTerms.formulaYeastType,
                value: currentItem.yeastType ?? BakingTerms.dryYeast,
                options: RecipeStore.yeastOptions,
                displayTitle: BakingTerms.yeastDisplayName
            ) { value in
                var next = currentItem
                next.yeastType = value
                next.name = BakingTerms.yeastDisplayName(value)
                store.updateItem(next)
            }
        }
    }

    private var iconBlock: some View {
        BakingIconView(icon: BakingIcon.material(for: currentItem), size: BakingTouchTarget.inlineIconGlyph, color: itemTint)
            .frame(width: BakingTouchTarget.inlineIconSurface, height: BakingTouchTarget.inlineIconSurface)
            .background(iconBackground)
            .clipShape(RoundedRectangle(cornerRadius: BakingComponentMetrics.inlineIconCornerRadius, style: .continuous))
        .frame(width: 44)
    }

    private var currentItem: RecipeItem {
        store.items.first { $0.id == item.id } ?? item
    }

    private var usesStackedPopupEditor: Bool {
        currentItem.category != .starter && currentItem.tag != .egg
    }

    private var hasWaterContent: Bool {
        store.hasWaterContent(currentItem)
    }

    private var isPureWaterItem: Bool {
        currentItem.tag == .water
    }

    private var itemTint: Color {
        currentItem.materialPalette.tint
    }

    private var iconBackground: Color {
        currentItem.materialPalette.iconSurface
    }

    private var popupAttributeIcons: [PopupAttributeIconStyle] {
        guard hasWaterContent else {
            return []
        }

        return [
            PopupAttributeIconStyle(
                icon: .water,
                color: .waterText,
                background: Color.waterSurface.opacity(0.9)
            )
        ]
    }

    private var percent: Double {
        store.summary.flourWeight > 0 ? currentItem.weight / store.summary.flourWeight * 100 : 0
    }

    private var detailText: String? {
        if currentItem.tag == .egg {
            return nil
        }
        return nil
    }

    private func itemTextBinding(_ keyPath: WritableKeyPath<RecipeItem, String>) -> Binding<String> {
        Binding(
            get: { currentItem[keyPath: keyPath] },
            set: {
                var next = currentItem
                next[keyPath: keyPath] = $0
                store.updateItem(next)
            }
        )
    }
}

struct PopupAttributeIconStyle {
    let icon: BakingIcon
    let color: Color
    let background: Color
}

struct PopupIdentityTableRow: View {
    let categoryIcon: BakingIcon
    let categoryTitle: String
    let itemTint: Color
    let iconBackground: Color
    let attributeIcons: [PopupAttributeIconStyle]

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                HStack(spacing: BakingSpace.sm) {
                    PopupMainIcon(icon: categoryIcon, color: itemTint, background: iconBackground)

                    BakingLabel(text: categoryTitle, role: .inputLabel)
                        .lineLimit(1)

                    ForEach(Array(attributeIcons.enumerated()), id: \.offset) { _, style in
                        PopupAttributeIcon(
                            icon: style.icon,
                            color: style.color,
                            background: style.background
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, BakingSpace.md)
                .padding(.trailing, BakingSpace.sm)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
    }
}

struct PopupNameTableRow: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(alignment: .center, spacing: BakingSpace.sm) {
            BakingLabel(text: BakingTerms.formulaPopupNameLabel, role: .popupRowLabel)
                .lineLimit(1)
                .frame(width: BakingComponentMetrics.popupLabelWidth, alignment: .leading)

            Spacer(minLength: BakingSpace.sm)

            BakingInlineTextField(
                text: $text,
                placeholder: placeholder,
                color: UIColor(Color.brandText),
                font: BakingTypography.popupInputValueUIFont,
                textAlignment: .right
            )
            .bakingFittedInputField(.long)
        }
        .padding(.horizontal, BakingSpace.md)
        .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
    }
}

private struct PopupPercentMetricCell: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        PopupMetricCell(title: title) {
            BakingPercentageField(
                value: $value,
                maxValue: 100,
                precision: 1,
                font: BakingTypography.rowMeta,
                valueFont: BakingTypography.popupNumericInputValue,
                color: .brandText,
                fieldWidth: 46,
                totalWidth: BakingCompactInputFieldSize.short.width,
                height: BakingComponentMetrics.compactInputFieldHeight
            )
        }
    }
}

struct PopupWeightMetricCell: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        PopupMetricCell(title: title) {
            PopupInlineWeightValue(value: $value)
        }
    }
}

struct PopupReadOnlyMetricCell: View {
    let title: String
    let value: String
    let unit: String
    let valueColor: Color

    var body: some View {
        PopupMetricCell(title: title) {
            HStack(alignment: .center, spacing: 4) {
                Text(value)
                    .font(BakingTypography.popupNumericInputValue)
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(unit)
                    .font(BakingTypography.rowMeta)
                    .foregroundStyle(Color.brandSecondaryText)
                    .frame(height: BakingComponentMetrics.compactInputFieldHeight, alignment: .center)
            }
            .bakingFittedInputField(.short, kind: .readOnly)
        }
    }
}

struct PopupMetricCell<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: BakingSpace.sm) {
            BakingLabel(text: title, role: .popupRowLabel)
                .lineLimit(1)

            Spacer(minLength: BakingSpace.sm)

            content()
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.xs)
        .frame(minWidth: BakingComponentMetrics.popupTableMetricCellMinWidth, maxWidth: .infinity, alignment: .leading)
    }
}

private struct PopupInlineWeightValue: View {
    @Binding var value: Double

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            BakingNumericTextField(
                value: $value,
                fractionDigits: 0...0,
                color: UIColor(Color.brandText),
                font: BakingTypography.popupNumericInputValueUIFont,
                textAlignment: .right
            )
            .frame(width: BakingCompactInputFieldSize.short.width - 42, height: BakingComponentMetrics.compactInputFieldHeight)

            Text(BakingTerms.unitGram)
                .font(BakingTypography.rowMeta)
                .foregroundStyle(Color.brandSecondaryText)
                .frame(height: BakingComponentMetrics.compactInputFieldHeight, alignment: .center)
        }
        .bakingFittedInputField(.short)
    }
}

private struct PopupMainIcon: View {
    let icon: BakingIcon
    let color: Color
    let background: Color

    var body: some View {
        BakingIconView(
            icon: icon,
            size: BakingComponentMetrics.popupIconGlyph,
            color: color
        )
        .frame(
            width: BakingComponentMetrics.popupIconSurface,
            height: BakingComponentMetrics.popupIconSurface
        )
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: BakingComponentMetrics.inlineIconCornerRadius, style: .continuous))
    }
}

struct PopupTableDivider: View {
    var body: some View {
        Divider()
            .overlay(BakingSurfaceTheme.separator)
            .padding(.leading, BakingSpace.md)
    }
}

private struct PopupVerticalDivider: View {
    var body: some View {
        Divider()
            .overlay(BakingSurfaceTheme.separator)
    }
}

struct PopupAttributeIcon: View {
    let icon: BakingIcon
    let color: Color
    let background: Color

    var body: some View {
        BakingIconView(
            icon: icon,
            size: BakingComponentMetrics.popupAttributeIconGlyph,
            color: color
        )
        .frame(
            width: BakingComponentMetrics.popupAttributeIconSurface,
            height: BakingComponentMetrics.popupAttributeIconSurface
        )
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: BakingComponentMetrics.compactIconCornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}

private struct PopupNameInputRow: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            BakingLabel(text: BakingTerms.formulaPopupNameLabel, role: .popupRowLabel)
                .lineLimit(1)
                .frame(width: BakingComponentMetrics.popupLabelWidth, alignment: .leading)

            BakingInlineTextField(
                text: $text,
                placeholder: placeholder,
                color: UIColor(Color.brandText),
                font: .systemFont(ofSize: 16, weight: .semibold)
            )
            .padding(.horizontal, BakingSpace.sm)
            .frame(width: BakingComponentMetrics.popupNameFieldWidth, height: BakingComponentMetrics.popupInputHeight, alignment: .leading)
            .bakingSurface(.field)
        }
        .frame(width: BakingComponentMetrics.popupFormWidth, alignment: .leading)
    }
}

private struct PopupPercentField: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            BakingLabel(text: title, role: .popupRowLabel)
                .lineLimit(1)
                .frame(width: BakingComponentMetrics.popupLabelWidth, alignment: .leading)

            BakingPercentageField(
                value: $value,
                maxValue: 100,
                precision: 0,
                font: .caption.weight(.semibold),
                color: .brandPrimary,
                fieldWidth: 38,
                totalWidth: BakingComponentMetrics.popupNumericFieldWidth,
                height: BakingComponentMetrics.popupInputHeight
            )
        }
    }
}

private struct PopupWeightField: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            BakingLabel(text: title, role: .popupRowLabel)
                .lineLimit(1)
                .frame(width: BakingComponentMetrics.popupLabelWidth, alignment: .leading)

            popupNumberContent(
                value: $value,
                valueColor: Color.brandText,
                unitColor: Color.brandSecondaryText
            )
        }
    }
}

private struct PopupReadOnlyNumberField: View {
    let title: String
    let value: String
    let unit: String
    let valueColor: Color

    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            BakingLabel(text: title, role: .popupRowLabel)
                .lineLimit(1)
                .frame(width: BakingComponentMetrics.popupLabelWidth, alignment: .leading)

            BakingNumericValue(
                value: value,
                unit: unit,
                kind: .readOnly,
                role: .secondary,
                width: BakingComponentMetrics.popupNumericFieldWidth,
                valueColor: valueColor,
                unitColor: unit == "%" ? valueColor.opacity(0.62) : Color.brandSecondaryText
            )
            .padding(.horizontal, BakingSpace.sm)
            .frame(width: BakingComponentMetrics.popupNumericFieldWidth, height: BakingComponentMetrics.popupInputHeight, alignment: .trailing)
            .bakingSurface(.readOnly)
        }
    }
}

private func popupNumberContent(
    value: Binding<Double>,
    valueColor: Color,
    unitColor: Color
) -> some View {
    HStack(alignment: .center, spacing: BakingSpace.xs) {
        BakingNumericTextField(
            value: value,
            fractionDigits: 0...0,
            color: UIColor(valueColor),
            font: .monospacedDigitSystemFont(ofSize: 16, weight: .semibold),
            textAlignment: .right
        )
        .frame(width: BakingComponentMetrics.popupNumericFieldWidth - 32)

        Text(BakingTerms.unitGram)
            .font(.caption.weight(.semibold))
            .foregroundStyle(unitColor)
    }
    .padding(.horizontal, BakingSpace.sm)
    .frame(width: BakingComponentMetrics.popupNumericFieldWidth, height: BakingComponentMetrics.popupInputHeight, alignment: .trailing)
    .bakingSurface(.field)
    .contentShape(Rectangle())
}

private struct ItemEditorPlainNameField: View {
    @Binding var text: String
    let placeholder: String
    let tint: Color

    var body: some View {
        VStack(spacing: 3) {
            BakingInlineTextField(
                text: $text,
                placeholder: placeholder,
                color: UIColor(Color.brandText),
                font: .systemFont(ofSize: 15, weight: .semibold)
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(width: 132, alignment: .leading)
            .frame(minHeight: 36)
            .bakingFieldSurface()
        }
        .frame(width: 132, alignment: .leading)
    }
}

private struct ItemEditorReadOnlyNameLabel: View {
    let text: String

    var body: some View {
        BakingLabel(text: text, role: .inputLabel)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(width: 132, alignment: .leading)
            .frame(minHeight: 36)
    }
}

private struct ItemEditorPercentField: View {
    @Binding var value: Double

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            BakingNumericTextField(
                value: $value,
                fractionDigits: 0...0,
                color: UIColor(Color.brandText),
                font: .monospacedDigitSystemFont(ofSize: 15, weight: .semibold),
                textAlignment: .right
            )
            .frame(width: 36)

            Text("%")
                .font(BakingTypography.rowMeta)
                .foregroundStyle(Color.brandSecondaryText)
        }
        .frame(width: 58, alignment: .trailing)
        .frame(minHeight: BakingTouchTarget.secondaryActionVisual)
        .padding(.horizontal, 6)
        .bakingFieldSurface()
        .contentShape(Rectangle())
    }
}

private struct ItemEditorWeightField: View {
    @Binding var value: Double

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            BakingNumericTextField(
                value: $value,
                fractionDigits: 0...0,
                color: UIColor(Color.brandText),
                font: .monospacedDigitSystemFont(ofSize: 15, weight: .semibold),
                textAlignment: .right
            )
            .frame(width: 48)

            Text(BakingTerms.unitGram)
                .font(BakingTypography.rowMeta)
                .foregroundStyle(Color.brandSecondaryText)
        }
        .frame(width: 76, alignment: .trailing)
        .frame(minHeight: BakingTouchTarget.secondaryActionVisual)
        .padding(.horizontal, 6)
        .bakingFieldSurface()
        .contentShape(Rectangle())
    }
}

private struct ItemEditorReadOnlyNumeric: View {
    let value: String
    let unit: String
    let color: Color
    let width: CGFloat

    var body: some View {
        BakingNumericValue(
            value: value,
            unit: unit,
            kind: .readOnly,
            role: .secondary,
            width: width,
            valueColor: color,
            unitColor: unit == "%" ? color.opacity(0.62) : Color.brandSecondaryText
        )
        .frame(minHeight: BakingTouchTarget.secondaryActionVisual, alignment: .trailing)
    }
}
