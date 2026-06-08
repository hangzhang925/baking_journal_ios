import SwiftUI
import UIKit

struct StarterMiniRecipeEditor: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    let canRemove: Bool
    @State private var nameFieldFocused = false

    var body: some View {
        VStack(spacing: BakingSpace.md) {
            identityTable
            modeControl
            contentTable
        }
    }

    private var identityTable: some View {
        VStack(spacing: 0) {
            StarterTableRow {
                HStack(spacing: BakingSpace.sm) {
                    BakingLabel(text: currentItem.tag.label, role: .inputLabel)
                        .lineLimit(1)

                    if store.hasWaterContent(currentItem) {
                        PopupAttributeIcon(
                            icon: .water,
                            color: .waterText,
                            background: Color.waterSurface.opacity(0.9)
                        )
                    }
                }
            } trailing: {
                StarterTypePicker(
                    selection: Binding(
                        get: { currentStarterType },
                        set: { store.applyStarterType($0, to: currentItem) }
                    )
                )
            }

            StarterTableDivider()

            StarterTableRow(title: BakingTerms.formulaFieldName) {
                BakingInlineTextField(
                    text: Binding(
                        get: { currentItem.name },
                        set: { updateName($0) }
                    ),
                    placeholder: currentItem.tag.label,
                    isFocused: $nameFieldFocused,
                    color: UIColor(Color.brandText),
                    font: BakingTypography.popupInputValueUIFont,
                    textAlignment: .right
                )
                .bakingFittedInputField(.long, kind: nameFieldFocused ? .focused : .field)
            }
        }
        .bakingCard()
    }

    private var modeControl: some View {
        BakingSegmentedStageControl(
            selectedID: starterEditMode.id,
            options: StarterEditMode.segmentedOptions,
            accessibilityLabel: "\(BakingTerms.formulaStarterModeRatio) / \(BakingTerms.formulaStarterModeWeight)",
            iconSize: BakingTouchTarget.dropdownIconGlyph,
            minHeight: BakingComponentMetrics.stageItemHeight,
            labelFont: BakingTypography.appPrimaryText
        ) { selectedID in
            guard let selectedMode = StarterEditMode(id: selectedID) else { return }
            store.updateStarterEditMode(selectedMode, for: currentItem)
        }
        .padding(.horizontal, BakingSpace.md)
    }

    private var contentTable: some View {
        VStack(spacing: 0) {
            StarterTableRow(title: BakingTerms.formulaFieldWeight) {
                if starterEditMode == .ratio {
                    StarterWeightInput(
                        value: Binding(
                            get: { currentItem.weight },
                            set: { store.updateItemWeight(currentItem, weight: $0) }
                        )
                    )
                } else {
                    ReadOnlyInlineMetric(
                        value: BakingFormat.number(currentItem.weight, precision: 0),
                        unit: BakingTerms.unitGram,
                        color: .brandText,
                        totalWidth: BakingCompactInputFieldSize.short.width,
                        height: BakingComponentMetrics.compactInputFieldHeight
                    )
                }
            }

            StarterTableDivider()

            StarterTableRow(title: BakingTerms.formulaTablePercentage) {
                if starterEditMode == .ratio {
                    StarterPercentInput(
                        value: Binding(
                            get: { percent },
                            set: { store.updateItemPercent(currentItem, percent: $0) }
                        )
                    )
                } else {
                    ReadOnlyInlineMetric(
                        value: BakingFormat.number(percent, precision: 0),
                        unit: "%",
                        color: .brandText,
                        totalWidth: BakingCompactInputFieldSize.short.width,
                        height: BakingComponentMetrics.compactInputFieldHeight
                    )
                }
            }

            StarterTableDivider()

            if starterEditMode == .ratio {
                StarterTableRow(title: BakingTerms.formulaStarterRatio) {
                    StarterRatioPicker(
                        selection: Binding(
                            get: { currentStarterRatio },
                            set: { store.applyStarterRatio($0, to: currentItem) }
                        ),
                        isEnabled: true
                    )
                }

                StarterTableDivider()

                StarterTableRow(title: BakingTerms.flour) {
                    StarterPartReadOnlyMetric(
                        value: store.flourContribution(currentItem)
                    )
                }

                StarterTableDivider()

                StarterTableRow(title: BakingTerms.water) {
                    StarterPartReadOnlyMetric(
                        value: store.starterBaseWater(currentItem)
                    )
                }
            } else {
                StarterTableRow(title: BakingTerms.flour) {
                    StarterWeightInput(
                        value: Binding(
                            get: { store.flourContribution(currentItem) },
                            set: { store.updateStarterParts(currentItem, flour: $0) }
                        )
                    )
                }

                StarterTableDivider()

                StarterTableRow(title: BakingTerms.water) {
                    StarterWeightInput(
                        value: Binding(
                            get: { store.starterBaseWater(currentItem) },
                            set: { store.updateStarterParts(currentItem, water: $0) }
                        )
                    )
                }
            }

            StarterTableDivider()

            StarterTapAddInRow(
                title: BakingTerms.yeast,
                enabled: Binding(
                    get: { currentItem.starterYeastWeight != nil },
                    set: {
                        store.updateStarterYeast(currentItem, weight: $0 ? max(1, currentItem.starterYeastWeight ?? 1) : nil)
                    }
                ),
                value: Binding(
                    get: { currentItem.starterYeastWeight ?? 1 },
                    set: { store.updateStarterYeast(currentItem, weight: $0) }
                )
            )
            .padding(.horizontal, BakingSpace.md)

            StarterTableDivider()

            StarterTapAddInRow(
                title: BakingTerms.egg,
                enabled: Binding(
                    get: { currentItem.starterEggCount != nil },
                    set: {
                        store.updateStarterEgg(currentItem, count: $0 ? 1 : nil)
                    }
                ),
                value: Binding(
                    get: { store.starterEggWeight(currentItem) },
                    set: { store.updateStarterEgg(currentItem, count: $0 > 0 ? 1 : 0, unitWeight: $0) }
                ),
                isWaterBearing: currentItem.starterEggCount != nil,
                waterText: BakingFormat.weight(store.starterEggWater(currentItem))
            )
            .padding(.horizontal, BakingSpace.md)
        }
        .bakingCard()
    }

    private func updateName(_ name: String) {
        var next = currentItem
        next.name = name
        store.updateItem(next)
    }

    private var currentItem: RecipeItem {
        store.items.first { $0.id == item.id } ?? item
    }

    private var currentStarterType: String {
        currentItem.starterType ?? BakingTerms.levainStarter
    }

    private var currentStarterRatio: String {
        store.starterRatioLabel(for: currentItem)
    }

    private var starterEditMode: StarterEditMode {
        store.starterEditMode(for: currentItem)
    }

    private var percent: Double {
        store.summary.flourWeight > 0 ? currentItem.weight / store.summary.flourWeight * 100 : 0
    }
}

private extension StarterEditMode {
    init?(id: String) {
        self.init(rawValue: id)
    }

    static var segmentedOptions: [BakingSegmentedStageOption] {
        allCases.map(\.segmentedOption)
    }

    var segmentedOption: BakingSegmentedStageOption {
        switch self {
        case .ratio:
            BakingSegmentedStageOption(
                id: id,
                icon: .system("percent"),
                title: BakingTerms.formulaStarterModeRatio
            )
        case .weight:
            BakingSegmentedStageOption(
                id: id,
                icon: .system("scalemass"),
                title: BakingTerms.formulaStarterModeWeight
            )
        }
    }
}

private struct StarterWeightInput: View {
    @Binding var value: Double

    var body: some View {
        InlineNumberField(
            value: $value,
            unit: BakingTerms.unitGram,
            font: .callout,
            color: .brandText,
            fieldWidth: 52,
            totalWidth: BakingCompactInputFieldSize.short.width,
            height: BakingComponentMetrics.compactInputFieldHeight
        )
    }
}

private struct StarterPercentInput: View {
    @Binding var value: Double

    var body: some View {
        BakingPercentageField(
            value: $value,
            maxValue: 100,
            precision: 0,
            font: BakingTypography.rowMeta,
            valueFont: BakingTypography.popupNumericInputValue,
            color: .brandText,
            fieldWidth: 46,
            totalWidth: BakingCompactInputFieldSize.short.width,
            height: BakingComponentMetrics.compactInputFieldHeight
        )
    }
}

private struct StarterPartReadOnlyMetric: View {
    let value: Double

    var body: some View {
        BakingInlineMetricLabel(
            title: "",
            value: BakingFormat.number(value, precision: 0),
            unit: BakingTerms.unitGram,
            role: .secondary,
            width: BakingCompactInputFieldSize.short.width
        )
    }
}

private struct StarterTableRow<Leading: View, Trailing: View>: View {
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    init(@ViewBuilder leading: @escaping () -> Leading, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: BakingSpace.sm) {
            leading()
                .frame(minWidth: BakingComponentMetrics.popupLabelWidth, alignment: .leading)
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, BakingSpace.md)
        .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
    }
}

private extension StarterTableRow where Leading == BakingLabel, Trailing: View {
    init(title: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.leading = {
            BakingLabel(text: title, role: .popupRowLabel)
        }
        self.trailing = trailing
    }
}

private struct StarterTableDivider: View {
    var body: some View {
        Divider()
            .overlay(BakingSurfaceTheme.separator)
            .padding(.leading, BakingSpace.md)
    }
}

private struct StarterTapAddInRow: View {
    let title: String
    @Binding var enabled: Bool
    @Binding var value: Double
    var isWaterBearing = false
    var waterText: String?

    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    enabled.toggle()
                }
            } label: {
                HStack(spacing: BakingSpace.sm) {
                    Image(systemName: enabled ? "checkmark.circle.fill" : "circle")
                        .font(.caption.weight(.semibold))
                    Text(title)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(enabled ? Color.brandPrimary : Color.brandSecondaryText)
                .frame(minHeight: BakingTouchTarget.dropdownIconSurface)
            }
            .buttonStyle(.plain)

            Spacer(minLength: BakingSpace.sm)

            if enabled {
                if isWaterBearing, let waterText {
                    CompactInfoBadge(icon: "drop.fill", text: waterText, isWater: true, compact: true)
                }

                InlineNumberField(
                    value: $value,
                    unit: BakingTerms.unitGram,
                    font: .caption,
                    color: .brandText,
                    fieldWidth: 50,
                    totalWidth: BakingCompactInputFieldSize.short.width,
                    isWaterStyle: isWaterBearing,
                    height: BakingComponentMetrics.compactInputFieldHeight
                )
            }
        }
        .padding(.vertical, BakingSpace.xs)
        .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
        .opacity(enabled ? 1 : 0.85)
    }
}

private struct StarterTypePicker: View {
    @EnvironmentObject private var dropdownPresenter: DropdownPresenter
    @Binding var selection: String
    @State private var triggerFrame: CGRect = .zero

    var body: some View {
        Button {
            dropdownPresenter.present(
                ActiveDropdownMenu(
                    frame: triggerFrame,
                    width: BakingComponentMetrics.popupTypeDropdownMenuWidth,
                    alignment: .leading,
                    reservesLeadingIconSlot: false,
                    items: RecipeStore.starterOptions.map { option in
                        DropdownMenuItem(title: BakingTerms.starterDisplayName(option), isSelected: option == selection) {
                            selection = option
                        }
                    }
                )
            )
        } label: {
            RectangularDropdownTrigger(
                title: BakingTerms.starterDisplayName(selection),
                width: BakingComponentMetrics.popupTypeDropdownWidth
            )
        }
        .buttonStyle(.plain)
        .zIndex(3)
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
}

private struct StarterRatioPicker: View {
    @EnvironmentObject private var dropdownPresenter: DropdownPresenter
    @Binding var selection: String
    let isEnabled: Bool
    @State private var triggerFrame: CGRect = .zero

    var body: some View {
        Button {
            guard isEnabled else { return }
            dropdownPresenter.present(
                ActiveDropdownMenu(
                    frame: triggerFrame,
                    width: BakingCompactInputFieldSize.short.width,
                    alignment: .leading,
                    reservesLeadingIconSlot: false,
                    items: RecipeStore.starterRatioOptions.map { option in
                        DropdownMenuItem(title: option, isSelected: option == selection) {
                            selection = option
                        }
                    }
                )
            )
        } label: {
            RectangularDropdownTrigger(
                title: selection,
                isEnabled: isEnabled,
                width: BakingCompactInputFieldSize.short.width,
                textAlignment: .trailing,
                font: BakingTypography.popupNumericInputValue
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .zIndex(3)
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
}
