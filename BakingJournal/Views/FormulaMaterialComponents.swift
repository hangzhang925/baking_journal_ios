import SwiftUI

struct AddItemControl: View {
    @EnvironmentObject private var store: RecipeStore
    @EnvironmentObject private var dropdownPresenter: DropdownPresenter
    let category: ItemCategory
    @State private var triggerFrame: CGRect = .zero

    var body: some View {
        Group {
            switch category {
            case .flour:
                Button {
                    dropdownPresenter.present(
                        ActiveDropdownMenu(
                            frame: triggerFrame,
                            width: 170,
                            alignment: .trailing,
                            items: flourMenuItems
                        )
                    )
                } label: {
                    plusIcon
                }

            case .basic:
                Button {
                    dropdownPresenter.present(
                        ActiveDropdownMenu(
                            frame: triggerFrame,
                            width: 158,
                            alignment: .trailing,
                            items: basicMenuItems
                        )
                    )
                } label: {
                    plusIcon
                }

            default:
                Button {
                    store.addItem(category: category)
                } label: {
                    plusIcon
                }
            }
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(BakingTerms.formulaAddCategory(category.label))
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        triggerFrame = proxy.frame(in: .named("formulaDropdownSpace"))
                    }
                    .onChange(of: proxy.frame(in: .named("formulaDropdownSpace"))) { _, newValue in
                        triggerFrame = newValue
                    }
            }
        )
    }

    private var plusIcon: some View {
        BakingSystemIconButtonLabel(
            systemImage: "plus",
            visualSize: BakingTouchTarget.secondaryActionVisual,
            font: .caption.weight(.bold)
        )
    }

    private func icon(for tag: ItemTag) -> BakingIcon {
        switch tag {
        case .water: .water
        case .salt: .salt
        case .butter: .butter
        case .yeast: .yeast
        case .egg: .egg
        case .sugar: .sugar
        case .flour: .flour
        case .starter: .starter
        case .other: .other
        }
    }

    private var flourMenuItems: [DropdownMenuItem] {
        [
            DropdownMenuItem(title: ItemCategory.flour.label, icon: .flour) {
                store.addItem(category: .flour)
            },
            DropdownMenuItem(title: ItemCategory.starter.label, icon: .starter) {
                store.addItem(category: .starter)
            }
        ]
    }

    private var basicMenuItems: [DropdownMenuItem] {
        [ItemTag.water, .salt, .butter, .yeast, .egg, .sugar, .other].map { tag in
            DropdownMenuItem(title: tag.label, icon: icon(for: tag)) {
                store.addItem(category: tag == .other ? .other : .basic, tag: tag)
            }
        }
    }
}

struct FormulaItemCard: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    let isExpanded: Bool
    let canRemove: Bool
    var reorderCoordinateSpace: String?
    let toggle: () -> Void
    var onInlineInteractionChanged: (Bool) -> Void = { _ in }
    var onReorderChanged: (DragGesture.Value) -> Void = { _ in }
    var onReorderEnded: (DragGesture.Value?) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                iconControl

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        InlineNameField(
                            text: itemTextBinding(\.name),
                            placeholder: currentItem.category.label,
                            font: .callout.weight(.semibold),
                            isWaterStyle: isPureWaterItem
                        )
                        if hasWaterContent {
                            Image(systemName: "drop.fill")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.waterText.opacity(0.88))
                                .frame(width: 20, height: 18)
                                .background(Color.waterSurface.opacity(0.9))
                                .clipShape(Capsule())
                        }
                        if !hasWaterContent {
                            Color.clear
                                .frame(width: 20, height: 18)
                        }
                    }
                    if let detailText {
                        Text(detailText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(0)

                HStack(alignment: .top, spacing: 6) {
                    if currentItem.category == .starter {
                        ReadOnlyInlineMetric(
                            value: BakingFormat.number(percent, precision: 1),
                            unit: "%",
                            font: .callout,
                            color: .brandPrimary,
                            totalWidth: 62,
                            isWaterStyle: isPureWaterItem
                        )
                        ReadOnlyInlineMetric(
                            value: BakingFormat.number(currentItem.weight, precision: 0),
                            unit: "g",
                            font: .callout,
                            color: .primary,
                            totalWidth: 76,
                            isWaterStyle: isPureWaterItem
                        )
                    } else if currentItem.tag == .egg && isWholeEgg {
                        ReadOnlyInlineMetric(
                            value: BakingFormat.number(percent, precision: 1),
                            unit: "%",
                            font: .callout,
                            color: isPureWaterItem ? .waterText : .brandPrimary,
                            totalWidth: 58,
                            isWaterStyle: isPureWaterItem
                        )
                        ReadOnlyInlineMetric(
                            value: BakingFormat.number(currentItem.weight, precision: 0),
                            unit: "g",
                            font: .callout,
                            color: isPureWaterItem ? .waterText : .primary,
                            totalWidth: 76,
                            isWaterStyle: isPureWaterItem
                        )
                    } else {
                        if currentItem.category != .flour {
                            BakingPercentageField(value: Binding(
                                get: { percent },
                                set: { store.updateItemPercent(currentItem, percent: $0) }
                            ), precision: 1, font: .callout, color: isPureWaterItem ? .waterText : .brandPrimary, fieldWidth: 34, totalWidth: 62, isWaterStyle: isPureWaterItem)
                        } else {
                            Color.clear
                                .frame(width: 58, height: 1)
                        }

                        InlineNumberField(value: Binding(
                            get: { currentItem.weight },
                            set: { store.updateItemWeight(currentItem, weight: $0) }
                        ), unit: "g", font: .callout, color: isPureWaterItem ? .waterText : .primary, fieldWidth: 48, totalWidth: 76, isWaterStyle: isPureWaterItem)
                    }
                }
                .layoutPriority(2)
            }
            .frame(minHeight: 64)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)

            if isExpanded && currentItem.requiresAdvancedFormulaEditor {
                Divider().padding(.horizontal, 12)

                if currentItem.category == .starter {
                    StarterMiniRecipeEditor(
                        item: currentItem,
                        canRemove: canRemove
                    )
                    .padding(12)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                        removal: .opacity
                    ))
                } else if currentItem.tag == .egg {
                    EggMiniRecipeEditor(
                        item: currentItem,
                        canRemove: canRemove,
                        name: itemTextBinding(\.name)
                    )
                    .padding(12)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                        removal: .opacity
                    ))
                } else if currentItem.category == .other {
                    OtherMiniRecipeEditor(
                        item: currentItem,
                        canRemove: canRemove
                    )
                    .padding(12)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                        removal: .opacity
                    ))
                } else {
                    VStack(spacing: 8) {
                        CompactTextRow(title: BakingTerms.formulaFieldName, text: itemTextBinding(\.name))

                        itemSpecificEditor

                        if canRemove {
                            Button(role: .destructive) {
                                store.removeItem(currentItem)
                            } label: {
                                BakingSystemIconButtonLabel(
                                    systemImage: "trash",
                                    tint: .white,
                                    background: .brandPrimary,
                                    shape: .rounded(BakingRadius.card)
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(BakingTerms.formulaDeleteMaterial)
                            .padding(.top, 2)
                        }
                    }
                    .padding(12)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                        removal: .opacity
                    ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isExpanded)
        .frame(maxWidth: .infinity)
        .bakingCard(background: cardBackground, stroke: cardStroke)
    }

    @ViewBuilder private var iconControl: some View {
        let control = Button {
            if currentItem.requiresAdvancedFormulaEditor {
                toggle()
            }
        } label: {
            iconControlLabel
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel(currentItem.requiresAdvancedFormulaEditor ? (isExpanded ? BakingTerms.formulaCollapseMaterialSettings : BakingTerms.formulaExpandMaterialSettings) : currentItem.name)

        if let reorderCoordinateSpace {
            control.simultaneousGesture(reorderGesture(coordinateSpace: reorderCoordinateSpace))
        } else {
            control
        }
    }

    private var iconControlLabel: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                BakingIconView(icon: BakingIcon.material(for: currentItem), size: BakingTouchTarget.inlineIconGlyph, color: itemTint)
                    .frame(width: BakingTouchTarget.inlineIconSurface, height: BakingTouchTarget.inlineIconSurface)
                    .background(iconBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                if currentItem.requiresAdvancedFormulaEditor {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.brandPrimary)
                        .frame(width: 14, height: 14)
                        .background(Color.brandSurface)
                        .clipShape(Circle())
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .offset(x: 3, y: 3)
                }
            }
            .frame(width: BakingTouchTarget.inlineIconSurface, height: BakingTouchTarget.inlineIconSurface)

            if let iconCaptionText {
                Text(iconCaptionText)
                    .font(.caption2)
                    .foregroundStyle(Color.brandSecondaryText)
                    .lineLimit(1)
            }
        }
        .frame(width: 44)
    }

    private func reorderGesture(coordinateSpace: String) -> some Gesture {
        LongPressGesture(minimumDuration: ReorderMotion.holdDuration, maximumDistance: ReorderMotion.holdMaximumDistance)
            .sequenced(before: DragGesture(minimumDistance: ReorderMotion.dragMinimumDistance, coordinateSpace: .named(coordinateSpace)))
            .onChanged { value in
                guard case .second(true, let drag?) = value else { return }
                onReorderChanged(drag)
            }
            .onEnded { value in
                guard case .second(true, let drag?) = value else {
                    onReorderEnded(nil)
                    return
                }
                onReorderEnded(drag)
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

    private var cardBackground: Color {
        currentItem.materialPalette.surface
    }

    private var cardStroke: Color {
        currentItem.materialPalette.stroke
    }

    private var percent: Double {
        store.summary.flourWeight > 0 ? currentItem.weight / store.summary.flourWeight * 100 : 0
    }

    private var detailText: String? {
        if currentItem.category == .starter {
            return BakingTerms.formulaStarterDetail(
                flour: BakingFormat.weight(store.flourContribution(currentItem)),
                water: BakingFormat.weight(store.starterBaseWater(currentItem))
            )
        }
        if currentItem.tag == .egg {
            return nil
        }
        return nil
    }

    private var iconCaptionText: String? {
        if currentItem.category == .starter {
            return ItemCategory.starter.label
        }
        return currentItem.tag.label
    }

    private var isWholeEgg: Bool {
        (currentItem.eggType ?? BakingTerms.wholeEgg) == BakingTerms.wholeEgg
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

    private func itemNumberBinding(_ keyPath: WritableKeyPath<RecipeItem, Double?>, fallback: Double) -> Binding<Double> {
        Binding(
            get: { currentItem[keyPath: keyPath] ?? fallback },
            set: {
                var next = currentItem
                next[keyPath: keyPath] = max(0, $0)
                store.updateItem(next)
            }
        )
    }

    private func updateEgg(count: Double, unitWeight: Double) {
        var next = currentItem
        next.eggCount = max(0, count)
        next.eggUnitWeight = max(0, unitWeight)
        next.weight = (next.eggCount ?? 0) * (next.eggUnitWeight ?? 45)
        store.updateItem(next)
    }
}

extension RecipeItem {
    var requiresAdvancedFormulaEditor: Bool {
        category == .starter || category == .other || tag == .egg
    }
}

private struct OtherMiniRecipeEditor: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    let canRemove: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(BakingTerms.formulaWaterContent)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)

            Spacer(minLength: 0)

            BakingPercentageField(
                value: waterContentBinding,
                precision: 0,
                font: .caption,
                color: waterContentPct > 0 ? .waterText : .brandSecondaryText,
                fieldWidth: 30,
                totalWidth: 64,
                isWaterStyle: true,
                height: 32
            )

            CompactInfoBadge(
                icon: "drop.fill",
                text: BakingFormat.weight(store.waterContribution(currentItem)),
                isWater: true,
                compact: true
            )

            if canRemove {
                Button(role: .destructive) {
                    store.removeItem(currentItem)
                } label: {
                    BakingSystemIconButtonLabel(
                        systemImage: "trash",
                        tint: .white,
                        background: .brandPrimary,
                        shape: .rounded(BakingRadius.card)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.formulaDeleteMaterial)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.brandBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var currentItem: RecipeItem {
        store.items.first { $0.id == item.id } ?? item
    }

    private var waterContentPct: Double {
        currentItem.waterContentPct ?? 0
    }

    private var waterContentBinding: Binding<Double> {
        Binding(
            get: { waterContentPct },
            set: { value in
                var next = currentItem
                next.waterContentPct = min(max(0, value), 100)
                store.updateItem(next)
            }
        )
    }
}
