import SwiftUI
import UIKit

struct EggMiniRecipeEditor: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    let canRemove: Bool
    @Binding var name: String
    @State private var nameFieldFocused = false

    var body: some View {
        VStack(spacing: 0) {
            EggTableRow {
                HStack(spacing: BakingSpace.sm) {
                    BakingLabel(text: BakingTerms.egg, role: .inputLabel)
                        .lineLimit(1)

                    if store.currentRecipeKind.usesHydrationSystem {
                        PopupAttributeIcon(
                            icon: .water,
                            color: .waterText,
                            background: Color.waterSurface.opacity(0.9)
                        )
                    }
                }
            } trailing: {
                EggTypePicker(
                    selection: Binding(
                        get: { currentEggType },
                        set: { store.updateEggType($0, for: currentItem) }
                    )
                )
            }

            EggTableDivider()

            EggTableRow(title: BakingTerms.formulaFieldName) {
                BakingInlineTextField(
                    text: $name,
                    placeholder: BakingTerms.egg,
                    isFocused: $nameFieldFocused,
                    color: UIColor(Color.brandText),
                    font: BakingTypography.popupInputValueUIFont,
                    textAlignment: .right
                )
                .bakingFittedInputField(.long, kind: nameFieldFocused ? .focused : .field)
            }

            EggTableDivider()

            EggTableRow(title: BakingTerms.formulaTableWeight) {
                InlineNumberField(
                    value: Binding(
                        get: { currentItem.weight },
                        set: { store.updateEggWeight(currentItem, weight: $0) }
                    ),
                    unit: BakingTerms.unitGram,
                    font: .callout,
                    color: .brandText,
                    fieldWidth: 52,
                    totalWidth: BakingCompactInputFieldSize.short.width,
                    height: BakingComponentMetrics.compactInputFieldHeight
                )
            }

            if store.currentRecipeKind.usesBakerPercentageSystem {
                EggTableDivider()

                EggTableRow(title: BakingTerms.formulaTablePercentage) {
                    BakingPercentageField(
                        value: Binding(
                            get: { percent },
                            set: { store.updateItemPercent(currentItem, percent: $0) }
                        ),
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

            if store.currentRecipeKind.usesHydrationSystem {
                EggTableDivider()

                EggWaterSummaryRow(
                    waterPercent: displayWaterPercent,
                    waterWeight: store.waterContribution(currentItem)
                )
            }
        }
        .bakingCard()
        .onAppear {
            if name.isEmpty {
                name = BakingTerms.egg
            }
        }
    }

    private var currentItem: RecipeItem {
        store.items.first { $0.id == item.id } ?? item
    }

    private var currentEggType: String {
        let type = currentItem.eggType ?? BakingTerms.beatenEgg
        return RecipeStore.eggOptions.contains(type) ? type : BakingTerms.beatenEgg
    }

    private var displayWaterPercent: Double {
        RecipeStore.waterContent(forEggType: currentEggType)
    }

    private var percent: Double {
        store.summary.flourWeight > 0 ? currentItem.weight / store.summary.flourWeight * 100 : 0
    }
}

private struct EggTypePicker: View {
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
                    items: RecipeStore.eggOptions.map { option in
                        DropdownMenuItem(title: BakingTerms.eggDisplayName(option), isSelected: option == selection) {
                            selection = option
                        }
                    }
                )
            )
        } label: {
            RectangularDropdownTrigger(
                title: BakingTerms.eggDisplayName(selection),
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

private struct EggWaterSummaryRow: View {
    let waterPercent: Double
    let waterWeight: Double

    var body: some View {
        HStack(alignment: .center, spacing: BakingSpace.sm) {
            BakingInlineMetricLabel(
                title: BakingTerms.formulaWaterContent,
                value: BakingFormat.number(waterPercent, precision: 0),
                unit: "%",
                isWater: true
            )

            Spacer(minLength: BakingSpace.sm)

            BakingInlineMetricLabel(
                title: BakingTerms.formulaWaterContribution,
                value: BakingFormat.number(waterWeight, precision: 0),
                unit: BakingTerms.unitGram,
                isWater: true
            )
        }
        .padding(.horizontal, BakingSpace.md)
        .frame(minHeight: BakingComponentMetrics.popupTableRowMinHeight)
    }
}

private struct EggTableRow<Leading: View, Trailing: View>: View {
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

private extension EggTableRow where Leading == BakingLabel, Trailing: View {
    init(title: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.leading = {
            BakingLabel(text: title, role: .popupRowLabel)
        }
        self.trailing = trailing
    }
}

private struct EggTableDivider: View {
    var body: some View {
        Divider()
            .overlay(BakingSurfaceTheme.separator)
            .padding(.leading, BakingSpace.md)
    }
}
