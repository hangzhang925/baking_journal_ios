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
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    var onDismiss: () -> Void
    @StateObject private var dropdownPresenter = DropdownPresenter()
    @StateObject private var keyboardState = BakingKeyboardState()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                BakingTopActionRow(
                    leading: {
                        HStack(spacing: BakingSpace.sm) {
                            BakingIconView(
                                icon: BakingIcon.material(for: item),
                                size: BakingTouchTarget.dropdownIconGlyph,
                                color: hasWaterContent ? .waterText : item.materialPalette.tint
                            )
                                .frame(width: BakingTouchTarget.dropdownIconSurface, height: BakingTouchTarget.dropdownIconSurface)
                                .background(hasWaterContent ? Color.waterSurfaceStrong.opacity(0.42) : item.materialPalette.iconSurface)
                                .clipShape(RoundedRectangle(cornerRadius: BakingRadius.field, style: .continuous))

                            Text(item.name)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color.brandText)
                                .lineLimit(1)

                            if hasWaterContent {
                                Image(systemName: "drop.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.waterText)
                                    .accessibilityLabel(BakingTerms.formulaWaterMark)
                            }
                        }
                    },
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

                ItemEditorView(item: item)
                    .id(item.id)
            }

            if let menu = dropdownPresenter.menu {
                dropdownOverlay(menu)
                    .zIndex(20)
            }
        }
        .offset(y: keyboardAvoidanceOffset)
        .animation(.easeOut(duration: keyboardState.animationDuration), value: keyboardAvoidanceOffset)
        .background(Color.brandBackground)
        .environmentObject(dropdownPresenter)
        .coordinateSpace(name: "formulaDropdownSpace")
    }

    private var keyboardAvoidanceOffset: CGFloat {
        guard keyboardState.height > 0 else { return 0 }
        return -min(190, keyboardState.height * 0.46)
    }

    private var hasWaterContent: Bool {
        store.hasWaterContent(item)
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
                        BakingDropdownRow(title: item.title, isSelected: item.isSelected) {
                            if let icon = item.icon {
                                BakingIconView(icon: icon, size: BakingTouchTarget.dropdownIconGlyph, color: .brandPrimary)
                            } else {
                                Color.clear
                            }
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

struct ItemEditorView: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem

    var body: some View {
        ScrollView {
            CompactItemEditorCard(item: currentItem)
                .padding(.horizontal, BakingLayout.screenHorizontalInset)
                .padding(.top, BakingSpace.lg)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.brandBackground)
    }

    private var currentItem: RecipeItem {
        store.items.first { $0.id == item.id } ?? item
    }
}

private struct CompactItemEditorCard: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem

    var body: some View {
        VStack(spacing: 0) {
            previewRow

            Divider()
                .padding(.horizontal, BakingSpace.lg)

            editableSummary

            if currentItem.requiresAdvancedFormulaEditor {
                Divider()
                    .padding(.horizontal, BakingSpace.lg)

                advancedEditor
                    .padding(BakingSpace.lg)
            }
        }
        .frame(maxWidth: .infinity)
        .bakingCard(background: currentItem.materialPalette.surface, stroke: currentItem.materialPalette.stroke)
    }

    private var previewRow: some View {
        FormulaItemDisplayRow(item: currentItem)
            .allowsHitTesting(false)
    }

    private var editableSummary: some View {
        HStack(alignment: .center, spacing: BakingSpace.md) {
            iconBlock

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    InlineNameField(
                        text: itemTextBinding(\.name),
                        placeholder: currentItem.category.label,
                        font: .callout.weight(.semibold)
                    )

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
                        .foregroundStyle(isPureWaterItem ? Color.waterText.opacity(0.82) : Color.brandSecondaryText)
                        .padding(.leading, BakingSpace.sm)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            HStack(alignment: .top, spacing: 6) {
                if currentItem.category == .starter || (currentItem.tag == .egg && isWholeEgg) {
                    ReadOnlyInlineMetric(
                        value: BakingFormat.number(percent, precision: 0),
                        unit: "%",
                        font: .callout,
                        color: .brandPrimary,
                        totalWidth: 62,
                        isWaterStyle: false
                    )
                    ReadOnlyInlineMetric(
                        value: BakingFormat.number(currentItem.weight, precision: 0),
                        unit: BakingTerms.unitGram,
                        font: .callout,
                        color: .brandText,
                        totalWidth: 76,
                        isWaterStyle: false
                    )
                } else {
                    if currentItem.category != .flour {
                        BakingPercentageField(
                            value: Binding(
                                get: { percent },
                                set: { store.updateItemPercent(currentItem, percent: $0) }
                            ),
                            precision: 0,
                            font: .callout,
                            color: .brandPrimary,
                            fieldWidth: 34,
                            totalWidth: 62,
                            isWaterStyle: false
                        )
                    } else {
                        Color.clear
                            .frame(width: 58, height: 1)
                    }

                    InlineNumberField(
                        value: Binding(
                            get: { currentItem.weight },
                            set: { store.updateItemWeight(currentItem, weight: $0) }
                        ),
                        unit: BakingTerms.unitGram,
                        font: .callout,
                        color: .brandText,
                        fieldWidth: 48,
                        totalWidth: 76,
                        isWaterStyle: false
                    )
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
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .frame(width: 44)
    }

    private var currentItem: RecipeItem {
        store.items.first { $0.id == item.id } ?? item
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

    private var percent: Double {
        store.summary.flourWeight > 0 ? currentItem.weight / store.summary.flourWeight * 100 : 0
    }

    private var isWholeEgg: Bool {
        (currentItem.eggType ?? BakingTerms.wholeEgg) == BakingTerms.wholeEgg
    }

    private var detailText: String? {
        if currentItem.category == .starter {
            return BakingTerms.formulaStarterDetail(
                flour: BakingFormat.weight(store.flourContribution(currentItem)),
                water: BakingFormat.weight(store.starterBaseWater(currentItem))
            )
        }
        if currentItem.tag == .egg {
            guard isWholeEgg else {
                return BakingTerms.formulaEggWaterDetail(BakingFormat.weight(store.waterContribution(currentItem)))
            }
            return BakingTerms.formulaEggDetail(
                count: BakingFormat.number(currentItem.eggCount ?? 1, precision: 1),
                water: BakingFormat.weight(store.waterContribution(currentItem))
            )
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
