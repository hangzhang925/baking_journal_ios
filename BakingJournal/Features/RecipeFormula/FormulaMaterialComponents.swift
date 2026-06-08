import SwiftUI
import UIKit
import OSLog

struct AddItemControl: View {
    @EnvironmentObject private var store: RecipeStore
    @EnvironmentObject private var dropdownPresenter: DropdownPresenter
    let category: ItemCategory
    var onOpenEditor: (RecipeItem) -> Void
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
                    openEditor(for: store.addItem(category: category))
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
                openEditor(for: store.addItem(category: .flour))
            },
            DropdownMenuItem(title: ItemCategory.starter.label, icon: .starter) {
                openEditor(for: store.addItem(category: .starter))
            }
        ]
    }

    private var basicMenuItems: [DropdownMenuItem] {
        [ItemTag.water, .salt, .butter, .yeast, .egg, .sugar, .other].map { tag in
            DropdownMenuItem(title: tag.label, icon: icon(for: tag)) {
                openEditor(for: store.addItem(category: tag == .other ? .other : .basic, tag: tag))
            }
        }
    }

    private func openEditor(for item: RecipeItem) {
        dropdownPresenter.dismiss()
        onOpenEditor(item)
    }
}

struct FormulaItemDisplayRow: View {
    static let separatorLeadingInset: CGFloat = BakingSpace.sm
    static let percentColumnWidth: CGFloat = 54
    static let weightValueWidth: CGFloat = 48
    static let weightUnitWidth: CGFloat = 14
    static let weightColumnWidth: CGFloat = weightValueWidth + 3 + weightUnitWidth
    static let numericColumnSpacing: CGFloat = 10
    static let numericColumnsWidth: CGFloat = percentColumnWidth + numericColumnSpacing + weightColumnWidth
    private static let trailingDeleteHitWidth = BakingTouchTarget.primaryAction

    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    var isEditing = false
    var canDelete = true
    var onReorderBegan: (FormulaRowReorderValue) -> Void = { _ in }
    var onReorderChanged: (FormulaRowReorderValue) -> Void = { _ in }
    var onReorderEnded: (FormulaRowReorderValue?) -> Void = { _ in }
    var onTap: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        HStack(alignment: .center, spacing: BakingSpace.lg) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(currentItem.name)
                        .bakingLabelStyle(.inputLabel)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if hasWaterContent {
                        Image(systemName: "drop.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.waterText.opacity(0.88))
                            .frame(width: 12, alignment: .leading)
                    }
                }

                if let detailText {
                    Text(detailText)
                        .bakingLabelStyle(.helperText)
                        .foregroundStyle(Color.brandSecondaryText)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            HStack(alignment: .firstTextBaseline, spacing: BakingSpace.sm) {
                Group {
                    if currentItem.category != .flour {
                        BakingPercentColumn(
                            value: BakingFormat.number(percent, precision: 0),
                            color: Color.brandText,
                            unitColor: Color.brandSecondaryText,
                            width: Self.percentColumnWidth
                        )
                    } else {
                        Color.clear
                            .frame(width: Self.percentColumnWidth, height: 1)
                    }
                }

                BakingQuantityColumn(
                    value: weightParts.value,
                    unit: weightParts.unit,
                    valueFont: BakingTypography.tableNumber,
                    unitFont: BakingTypography.rowMeta,
                    valueColor: Color.brandText,
                    unitColor: Color.brandSecondaryText,
                    valueWidth: Self.weightValueWidth,
                    unitWidth: Self.weightUnitWidth
                )
            }
            .frame(width: Self.numericColumnsWidth, alignment: .trailing)
            .layoutPriority(0)

            if isEditing {
                deleteButton
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(minHeight: 58)
        .padding(.leading, BakingSpace.sm)
        .padding(.trailing, isEditing ? BakingSpace.xs : BakingSpace.md)
        .padding(.vertical, BakingSpace.xs)
        .background(rowBackground)
        .overlay(alignment: .leading) {
            if isEditing {
                Capsule()
                    .fill(BakingSurfaceTheme.theme(for: .selected).stroke)
                    .frame(width: 3)
                    .padding(.vertical, BakingSpace.lg)
                    .transition(.opacity)
            }
        }
        .overlay {
            HStack(spacing: 0) {
                FormulaRowInteractionSurface(
                    minimumPressDuration: isEditing ? 0.18 : ReorderMotion.holdDuration,
                    onTap: onTap,
                    onLongPressBegan: onReorderBegan,
                    onLongPressChanged: onReorderChanged,
                    onLongPressEnded: onReorderEnded
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Keep only the delete button's hit target out of the reorder surface.
                Color.clear
                    .frame(width: Self.trailingDeleteHitWidth)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .animation(ReorderMotion.animation, value: isEditing)
    }

    private var deleteButton: some View {
        Button {
            onDelete()
        } label: {
            BakingSystemIconButtonLabel(
                systemImage: "trash",
                tint: canDelete ? BakingComponentTheme.action(role: .destructive).foreground : .brandSecondaryText.opacity(0.45),
                visualSize: BakingTouchTarget.secondaryActionVisual,
                font: .caption.weight(.semibold)
            )
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .disabled(!canDelete)
        .accessibilityLabel(BakingTerms.formulaDeleteMaterial)
    }

    private var currentItem: RecipeItem {
        store.items.first(where: { $0.id == item.id }) ?? item
    }

    private var hasWaterContent: Bool {
        store.hasWaterContent(currentItem)
    }

    private var isPureWaterItem: Bool {
        currentItem.tag == .water
    }

    private var rowBackground: Color {
        isEditing ? Color.materialChipSurface.opacity(0.55) : Color.clear
    }

    private var percent: Double {
        store.summary.flourWeight > 0 ? currentItem.weight / store.summary.flourWeight * 100 : 0
    }

    private var weightParts: BakingFormattedUnitValue {
        BakingFormat.weightParts(currentItem.weight, gramPrecision: currentItem.tag == .yeast ? 1 : 0)
    }

    private var detailText: String? {
        if currentItem.tag == .egg {
            return nil
        }
        return nil
    }

}

struct FormulaIngredientTableHeader: View {
    var showsPercentage = true

    var body: some View {
        HStack(alignment: .center, spacing: BakingSpace.lg) {
            Text(BakingTerms.formulaTableIngredient)
                .bakingLabelStyle(.tableHeader)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: FormulaItemDisplayRow.numericColumnSpacing) {
                Text(BakingTerms.formulaTablePercentage)
                    .bakingLabelStyle(.tableHeader)
                    .frame(width: FormulaItemDisplayRow.percentColumnWidth, alignment: .trailing)
                    .opacity(showsPercentage ? 1 : 0)

                Text(BakingTerms.formulaTableWeight)
                    .bakingLabelStyle(.tableHeader)
                    .frame(width: FormulaItemDisplayRow.weightColumnWidth, alignment: .trailing)
            }
            .frame(width: FormulaItemDisplayRow.numericColumnsWidth, alignment: .trailing)
        }
        .padding(.leading, BakingSpace.sm)
        .padding(.trailing, BakingSpace.md)
        .padding(.top, BakingSpace.sm)
        .padding(.bottom, BakingSpace.xs)
        .accessibilityElement(children: .combine)
    }
}

struct FormulaRowReorderValue {
    let startLocation: CGPoint
    let location: CGPoint
    let translation: CGSize
}

private struct FormulaRowInteractionSurface: UIViewRepresentable {
    private static let log = Logger(subsystem: "com.hang.BakingJournal", category: "FormulaReorder")

    let minimumPressDuration: TimeInterval
    var onTap: () -> Void
    var onLongPressBegan: (FormulaRowReorderValue) -> Void
    var onLongPressChanged: (FormulaRowReorderValue) -> Void
    var onLongPressEnded: (FormulaRowReorderValue?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let longPressRecognizer = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPressRecognizer.minimumPressDuration = minimumPressDuration
        longPressRecognizer.allowableMovement = BakingTouchTarget.primaryAction
        longPressRecognizer.cancelsTouchesInView = false
        longPressRecognizer.delegate = context.coordinator
        view.addGestureRecognizer(longPressRecognizer)

        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.require(toFail: longPressRecognizer)
        view.addGestureRecognizer(tapRecognizer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
        if let recognizer = uiView.gestureRecognizers?.compactMap({ $0 as? UILongPressGestureRecognizer }).first {
            recognizer.minimumPressDuration = minimumPressDuration
            recognizer.allowableMovement = BakingTouchTarget.primaryAction
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: FormulaRowInteractionSurface
        private var startLocation: CGPoint?
        private var startWindowLocation: CGPoint?

        init(parent: FormulaRowInteractionSurface) {
            self.parent = parent
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            FormulaRowInteractionSurface.log.debug("ui tap ended")
            parent.onTap()
        }

        @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let location = recognizer.location(in: view)

            switch recognizer.state {
            case .began:
                FormulaRowInteractionSurface.log.debug("ui longPress began location=(\(location.x, privacy: .public), \(location.y, privacy: .public))")
                startLocation = location
                startWindowLocation = windowLocation(for: recognizer)
                parent.onLongPressBegan(FormulaRowReorderValue(startLocation: location, location: location, translation: .zero))
            case .changed:
                FormulaRowInteractionSurface.log.debug("ui longPress changed location=(\(location.x, privacy: .public), \(location.y, privacy: .public))")
                parent.onLongPressChanged(FormulaRowReorderValue(
                    startLocation: startLocation ?? location,
                    location: location,
                    translation: windowTranslation(for: recognizer)
                ))
            case .ended:
                FormulaRowInteractionSurface.log.debug("ui longPress ended location=(\(location.x, privacy: .public), \(location.y, privacy: .public))")
                parent.onLongPressEnded(FormulaRowReorderValue(
                    startLocation: startLocation ?? location,
                    location: location,
                    translation: windowTranslation(for: recognizer)
                ))
                startLocation = nil
                startWindowLocation = nil
            case .cancelled, .failed:
                FormulaRowInteractionSurface.log.debug("ui longPress cancelled state=\(recognizer.state.rawValue, privacy: .public)")
                parent.onLongPressEnded(nil)
                startLocation = nil
                startWindowLocation = nil
            default:
                break
            }
        }

        private func windowLocation(for recognizer: UIGestureRecognizer) -> CGPoint? {
            guard let window = recognizer.view?.window else { return nil }
            return recognizer.location(in: window)
        }

        private func windowTranslation(for recognizer: UIGestureRecognizer) -> CGSize {
            guard let startWindowLocation, let currentWindowLocation = windowLocation(for: recognizer) else {
                return .zero
            }
            return CGSize(
                width: currentWindowLocation.x - startWindowLocation.x,
                height: currentWindowLocation.y - startWindowLocation.y
            )
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            false
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
                        if currentItem.tag == .egg {
                            BakingLabel(text: BakingTerms.egg, role: .inputLabel)
                                .frame(width: 132, alignment: .leading)
                                .frame(minHeight: 40)
                        } else {
                            InlineNameField(
                                text: itemTextBinding(\.name),
                                placeholder: currentItem.category.label,
                                font: BakingTypography.appPrimaryText
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
                        if !hasWaterContent {
                            Color.clear
                                .frame(width: 20, height: 18)
                        }
                    }
                    if let detailText {
                        Text(detailText)
                            .font(BakingTypography.appSecondaryText)
                            .foregroundStyle(Color.brandSecondaryText)
                            .padding(.leading, 8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(0)

                HStack(alignment: .top, spacing: 6) {
                    if currentItem.category == .starter {
                        ReadOnlyInlineMetric(
                            value: BakingFormat.number(percent, precision: 0),
                            unit: "%",
                            font: .callout,
                            color: .brandText,
                            totalWidth: 62,
                            isWaterStyle: isPureWaterItem
                        )
                        ReadOnlyInlineMetric(
                            value: BakingFormat.number(currentItem.weight, precision: 0),
                            unit: BakingTerms.unitGram,
                            font: .callout,
                            color: .brandText,
                            totalWidth: 76,
                            isWaterStyle: false
                        )
                    } else if currentItem.tag == .egg {
                        ReadOnlyInlineMetric(
                            value: BakingFormat.number(percent, precision: 0),
                            unit: "%",
                            font: .callout,
                            color: .brandText,
                            totalWidth: 58,
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
                            BakingPercentageField(value: Binding(
                                get: { percent },
                                set: { store.updateItemPercent(currentItem, percent: $0) }
                            ), precision: 0, font: .callout, color: .brandText, fieldWidth: 34, totalWidth: 62, isWaterStyle: false)
                        } else {
                            Color.clear
                                .frame(width: 58, height: 1)
                        }

                        InlineNumberField(value: Binding(
                            get: { currentItem.weight },
                            set: { store.updateItemWeight(currentItem, weight: $0) }
                        ), unit: BakingTerms.unitGram, font: .callout, color: .brandText, fieldWidth: 48, totalWidth: 76, isWaterStyle: false)
                    }
                }
                .layoutPriority(2)
            }
            .frame(minHeight: 64)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)

            if isExpanded && currentItem.requiresAdvancedFormulaEditor {
                Divider().padding(.horizontal, 12).opacity(0)

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
                                    tint: BakingComponentTheme.action(role: .destructive).foreground,
                                    background: BakingSurfaceTheme.theme(for: .destructive).background,
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
        .bakingMaterialCard(palette: currentItem.materialPalette)
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
        ZStack(alignment: .bottomTrailing) {
            BakingIconView(icon: BakingIcon.material(for: currentItem), size: BakingTouchTarget.inlineIconGlyph, color: itemTint)
                .frame(width: BakingTouchTarget.inlineIconSurface, height: BakingTouchTarget.inlineIconSurface)
                .background(iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: BakingComponentMetrics.inlineIconCornerRadius, style: .continuous))

            if currentItem.requiresAdvancedFormulaEditor {
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 14, height: 14)
                    .background(Color.brandBackground)
                    .clipShape(Circle())
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .offset(x: 3, y: 3)
            }
        }
        .frame(width: BakingTouchTarget.inlineIconSurface, height: BakingTouchTarget.inlineIconSurface)
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
        currentItem.materialPalette.chipSurface
    }

    private var cardStroke: Color {
        currentItem.materialPalette.chipStroke
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
                precision: 1,
                font: .caption,
                color: .brandText,
                fieldWidth: 40,
                totalWidth: 74,
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
                        tint: BakingComponentTheme.action(role: .destructive).foreground,
                        background: BakingSurfaceTheme.theme(for: .destructive).background,
                        shape: .rounded(BakingRadius.card)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(BakingTerms.formulaDeleteMaterial)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
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
