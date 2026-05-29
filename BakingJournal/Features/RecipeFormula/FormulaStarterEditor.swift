import SwiftUI
import UIKit

struct StarterMiniRecipeEditor: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    let canRemove: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                StarterTypePicker(
                    selection: Binding(
                        get: { currentStarterType },
                        set: { store.applyStarterType($0, to: currentItem) }
                    )
                )

                CompactSummaryPill(
                    title: BakingTerms.formulaFieldWeight,
                    value: BakingFormat.number(currentItem.weight, precision: 0),
                    unit: BakingTerms.unitGram
                )
                CompactSummaryPill(
                    title: BakingTerms.formulaWaterContent,
                    value: BakingFormat.number(starterHydration, precision: 0),
                    unit: "%",
                    isWater: true
                )

                Spacer(minLength: 0)
            }

            StarterPartsRow(
                flour: Binding(
                    get: { store.flourContribution(currentItem) },
                    set: { store.updateStarterParts(currentItem, flour: $0) }
                ),
                water: Binding(
                    get: { store.starterBaseWater(currentItem) },
                    set: { store.updateStarterParts(currentItem, water: $0) }
                )
            )

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
        }
    }

    private var currentItem: RecipeItem {
        store.items.first { $0.id == item.id } ?? item
    }

    private var currentStarterType: String {
        currentItem.starterType ?? BakingTerms.levainStarter
    }

    private var starterHydration: Double {
        let flour = store.flourContribution(currentItem)
        guard flour > 0 else { return 0 }
        return store.starterBaseWater(currentItem) / flour * 100
    }
}

private struct StarterPartsRow: View {
    @Binding var flour: Double
    @Binding var water: Double

    var body: some View {
        HStack(spacing: 8) {
            StarterPartEntry(title: BakingTerms.flour, value: $flour)
            StarterPartEntry(title: BakingTerms.water, value: $water, isWater: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.brandBackground.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct StarterPartEntry: View {
    let title: String
    @Binding var value: Double
    var isWater = false

    var body: some View {
        HStack(spacing: 8) {
            BakingLabel(text: title, role: .inputLabel)
                .foregroundStyle(isWater ? Color.waterText.opacity(0.86) : Color.brandText)

            BakingNumericTextField(
                value: $value,
                fractionDigits: 0...0,
                color: UIColor(isWater ? Color.waterText : Color.brandText),
                font: .monospacedDigitSystemFont(ofSize: 17, weight: .semibold),
                adjustsFontSizeToFitWidth: false
            )
            .frame(width: 48)

            Text(BakingTerms.unitGram)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(minWidth: 136, alignment: .leading)
        .bakingSurface(isWater ? .selected : .field)
    }
}

private struct StarterTapAddInRow: View {
    let title: String
    @Binding var enabled: Bool
    @Binding var value: Double
    var isWaterBearing = false
    var waterText: String?

    var body: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    enabled.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: enabled ? "checkmark.circle.fill" : "circle")
                        .font(.caption.weight(.semibold))
                    Text(title)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(enabled ? Color.brandPrimary : Color.brandSecondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background((enabled ? Color.brandPrimary.opacity(0.08) : Color.brandBackground.opacity(0.5)))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            if enabled {
                InlineNumberField(
                    value: $value,
                    unit: BakingTerms.unitGram,
                    font: .caption,
                    color: isWaterBearing ? .waterText : .primary,
                    fieldWidth: 26,
                    totalWidth: 58,
                    isWaterStyle: isWaterBearing,
                    height: 32
                )

                if isWaterBearing, let waterText {
                    CompactInfoBadge(icon: "drop.fill", text: waterText, isWater: true, compact: true)
                }

                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.brandBackground.opacity(enabled ? 0.68 : 0.52))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                    width: 156,
                    alignment: .leading,
                    items: RecipeStore.starterOptions.map { option in
                        DropdownMenuItem(title: BakingTerms.starterDisplayName(option), icon: .starter, isSelected: option == selection) {
                            selection = option
                        }
                    }
                )
            )
        } label: {
            RectangularDropdownTrigger(title: BakingTerms.starterDisplayName(selection))
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
