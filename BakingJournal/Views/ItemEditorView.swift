import SwiftUI

struct ItemEditorView: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var draft: RecipeItem
    @State private var percent: Double

    init(item: RecipeItem) {
        _draft = State(initialValue: item)
        _percent = State(initialValue: 0)
    }

    var body: some View {
        Form {
            Section("材料") {
                TextField("名称", text: $draft.name)
                DecimalField(title: "重量", value: $draft.weight, unit: "g")
                DecimalField(title: "百分比", value: $percent, unit: "%")
            }

            if draft.category == .starter {
                starterSection
            }

            if draft.tag == .egg {
                eggSection
            }

            if draft.tag == .yeast {
                yeastSection
            }
        }
        .navigationTitle(draft.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshPercent()
        }
        .onChange(of: draft) { _, newValue in
            store.updateItem(newValue)
            refreshPercent()
        }
        .onChange(of: percent) { _, newValue in
            store.updateItemPercent(draft, percent: newValue)
            if let updated = store.items.first(where: { $0.id == draft.id }) {
                draft = updated
            }
        }
    }

    private var starterSection: some View {
        Section("种面") {
            Picker("类型", selection: Binding(
                get: { draft.starterType ?? "鲁邦种" },
                set: { newValue in
                    store.applyStarterType(newValue, to: draft)
                    syncDraft()
                }
            )) {
                ForEach(RecipeStore.starterOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }

            Picker("水粉比例", selection: Binding(
                get: { draft.starterRatio ?? "1:1" },
                set: { newValue in
                    store.applyStarterRatio(newValue, to: draft)
                    syncDraft()
                }
            )) {
                ForEach(RecipeStore.starterRatioOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }

            DecimalField(title: "水", value: Binding(
                get: { store.starterBaseWater(draft) },
                set: { value in
                    store.updateStarterParts(draft, water: value)
                    syncDraft()
                }
            ), unit: "g")

            DecimalField(title: "面粉", value: Binding(
                get: { store.flourContribution(draft) },
                set: { value in
                    store.updateStarterParts(draft, flour: value)
                    syncDraft()
                }
            ), unit: "g")

            Toggle("加入种面酵母", isOn: Binding(
                get: { draft.starterYeastWeight != nil },
                set: { enabled in
                    store.updateStarterYeast(draft, weight: enabled ? 1 : nil)
                    syncDraft()
                }
            ))

            if draft.starterYeastWeight != nil {
                DecimalField(title: "种面酵母", value: Binding(
                    get: { draft.starterYeastWeight ?? 0 },
                    set: {
                        store.updateStarterYeast(draft, weight: $0)
                        syncDraft()
                    }
                ), unit: "g")
            }

            Toggle("加入种面鸡蛋", isOn: Binding(
                get: { draft.starterEggCount != nil },
                set: { enabled in
                    store.updateStarterEgg(draft, count: enabled ? 1 : nil)
                    syncDraft()
                }
            ))

            if draft.starterEggCount != nil {
                DecimalField(title: "鸡蛋", value: Binding(
                    get: { draft.starterEggCount ?? 1 },
                    set: {
                        store.updateStarterEgg(draft, count: $0)
                        syncDraft()
                    }
                ), unit: "个")
                LabeledContent("贡献水量", value: BakingFormat.weight(store.starterEggWater(draft)))
            }
        }
    }

    private var eggSection: some View {
        Section("鸡蛋") {
            DecimalField(title: "个数", value: Binding(
                get: { draft.eggCount ?? 1 },
                set: {
                    draft.eggCount = max(0, $0)
                    draft.weight = (draft.eggCount ?? 0) * (draft.eggUnitWeight ?? 45)
                }
            ), unit: "个")

            DecimalField(title: "单个重量", value: Binding(
                get: { draft.eggUnitWeight ?? 45 },
                set: {
                    draft.eggUnitWeight = max(0, $0)
                    draft.weight = (draft.eggCount ?? 0) * (draft.eggUnitWeight ?? 45)
                }
            ), unit: "g")

            DecimalField(title: "水分", value: Binding(
                get: { draft.waterContentPct ?? 75 },
                set: { draft.waterContentPct = max(0, $0) }
            ), unit: "%")
            LabeledContent("贡献水量", value: BakingFormat.weight(store.waterContribution(draft)))
        }
    }

    private var yeastSection: some View {
        Section("酵母") {
            Picker("类型", selection: Binding(
                get: { draft.yeastType ?? "干酵母" },
                set: {
                    draft.yeastType = $0
                    draft.name = $0
                }
            )) {
                ForEach(RecipeStore.yeastOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        }
    }

    private func refreshPercent() {
        guard store.summary.flourWeight > 0 else {
            percent = 0
            return
        }
        percent = draft.weight / store.summary.flourWeight * 100
    }

    private func syncDraft() {
        if let updated = store.items.first(where: { $0.id == draft.id }) {
            draft = updated
        }
    }
}

struct DecimalField: View {
    let title: String
    @Binding var value: Double
    let unit: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: $value, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(minWidth: 72)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}
