import SwiftUI

struct EggMiniRecipeEditor: View {
    @EnvironmentObject private var store: RecipeStore
    let item: RecipeItem
    let canRemove: Bool
    @Binding var name: String

    private let wholeEggUnitWeight = 50.0
    private let eggTypeWaterContent: [String: Double] = [
        BakingTerms.wholeEgg: 75,
        BakingTerms.beatenEgg: 75,
        BakingTerms.yolk: 48,
        BakingTerms.white: 88
    ]

    var body: some View {
        HStack(spacing: 10) {
            EggTypePicker(
                selection: Binding(
                    get: { currentEggType },
                    set: { updateEggType($0) }
                )
            )

            if isWholeEgg {
                EggCountSelector(
                    count: Binding(
                        get: { max(0, currentItem.eggCount ?? wholeEggCountFallback) },
                        set: { updateWholeEggCount($0) }
                    )
                )

                Spacer(minLength: 0)

                CompactInfoBadge(icon: "scalemass", text: BakingFormat.weight(currentItem.weight))
                CompactInfoBadge(icon: "drop.fill", text: BakingFormat.weight(store.waterContribution(currentItem)), isWater: true)
            } else {
                Spacer(minLength: 0)

                InlineNumberField(
                    value: Binding(
                        get: { currentItem.weight },
                        set: { updateLiquidEggWeight($0) }
                    ),
                    unit: "g",
                    font: .subheadline,
                    color: .primary,
                    fieldWidth: 42,
                    totalWidth: 78,
                    height: 36
                )

                HStack(spacing: 5) {
                    Image(systemName: "drop.fill")
                        .font(.caption2.weight(.semibold))
                    Text(BakingFormat.weight(store.waterContribution(currentItem)))
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                }
                .foregroundStyle(Color.waterText)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minWidth: 92, alignment: .leading)
                .background(Color.waterSurfaceStrong.opacity(0.42))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

    private func updateEgg(count: Double, unitWeight: Double) {
        var next = currentItem
        next.eggCount = max(0, count)
        next.eggUnitWeight = max(0, unitWeight)
        next.weight = (next.eggCount ?? 0) * (next.eggUnitWeight ?? 45)
        store.updateItem(next)
    }

    private func updateWholeEggCount(_ count: Double) {
        var next = currentItem
        let roundedCount = max(0, count.rounded())
        next.eggType = BakingTerms.wholeEgg
        next.name = BakingTerms.eggDisplayName(BakingTerms.wholeEgg)
        next.waterContentPct = eggTypeWaterContent[BakingTerms.wholeEgg]
        next.eggCount = roundedCount
        next.eggUnitWeight = wholeEggUnitWeight
        next.weight = roundedCount * wholeEggUnitWeight
        store.updateItem(next)
    }

    private var displayWaterPercent: Double {
        currentItem.waterContentPct ?? 75
    }

    private var currentEggType: String {
        currentItem.eggType ?? BakingTerms.wholeEgg
    }

    private var isWholeEgg: Bool {
        currentEggType == BakingTerms.wholeEgg
    }

    private var wholeEggCountFallback: Double {
        let unitWeight = currentItem.eggUnitWeight ?? wholeEggUnitWeight
        guard unitWeight > 0 else { return 1 }
        return max(1, (currentItem.weight / unitWeight).rounded())
    }

    private func updateLiquidEggWeight(_ weight: Double) {
        var next = currentItem
        next.weight = max(0, weight)
        next.eggCount = nil
        next.eggUnitWeight = nil
        store.updateItem(next)
    }

    private func updateEggType(_ type: String) {
        var next = currentItem
        next.eggType = type
        next.name = BakingTerms.eggDisplayName(type)
        next.waterContentPct = eggTypeWaterContent[type] ?? 75

        if type == BakingTerms.wholeEgg {
            let count = next.eggCount ?? max(1, (next.weight / wholeEggUnitWeight).rounded())
            next.eggCount = count
            next.eggUnitWeight = wholeEggUnitWeight
            next.weight = count * wholeEggUnitWeight
        } else {
            next.eggCount = nil
            next.eggUnitWeight = nil
            if next.weight == 0 {
                next.weight = 50
            }
        }

        store.updateItem(next)
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
                    width: 148,
                    alignment: .leading,
                    items: RecipeStore.eggOptions.map { option in
                        DropdownMenuItem(title: BakingTerms.eggDisplayName(option), isSelected: option == selection) {
                            selection = option
                        }
                    }
                )
            )
        } label: {
            RectangularDropdownTrigger(title: BakingTerms.eggDisplayName(selection))
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

private struct EggCountSelector: View {
    @Binding var count: Double
    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack(spacing: 0) {
                Text("\(Int(count.rounded()))")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Color.brandText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: 44, alignment: .center)
            .background(Color.brandPrimary.opacity(0.075))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.brandPrimary.opacity(0.10), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingPicker, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            EggCountWheelPopover(count: $count)
        }
    }
}

private struct EggCountWheelPopover: View {
    @Binding var count: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    BakingSystemIconButtonLabel(
                        systemImage: "checkmark",
                        visualSize: BakingTouchTarget.secondaryActionVisual,
                        font: .subheadline.weight(.semibold)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("完成")
            }

            Picker("鸡蛋个数", selection: Binding(
                get: { Int(max(1, count.rounded())) },
                set: { count = Double($0) }
            )) {
                ForEach(1...10, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(width: 88, height: 120)
        }
        .padding(12)
        .presentationCompactAdaptation(.popover)
        .background(Color.brandSurface)
    }
}
