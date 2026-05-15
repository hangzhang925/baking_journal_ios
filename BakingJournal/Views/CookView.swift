import SwiftUI

struct CookView: View {
    @EnvironmentObject private var store: RecipeStore
    @State private var now = Date()

    var body: some View {
        NavigationStack {
            Group {
                if store.steps.isEmpty {
                    EmptyStateView(title: "先添加制作步骤，再开始。", systemImage: "play.circle")
                        .background(Color.brandBackground)
                } else if store.cookState.completedAt != nil {
                    CookSummaryView()
                } else {
                    CookStepView(now: now)
                }
            }
            .navigationTitle("开始开炉")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.resetCook()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .accessibilityLabel("重置")
                }
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
    }
}

private struct CookStepView: View {
    @EnvironmentObject private var store: RecipeStore
    let now: Date

    var body: some View {
        let step = currentStep
        let stepItems = store.items(for: step)
        let checked = store.cookState.checked[step.id] ?? []

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("步骤 \(store.cookState.currentIndex + 1)/\(store.steps.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                    Spacer()
                    Text(BakingFormat.duration(minutes: store.stepMinutes(step)))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        BakingIconView(icon: BakingIcon.step(for: step.type), size: 18, color: .brandPrimary)
                        Text(step.type.label)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                    Text(step.name)
                        .font(.largeTitle.weight(.bold))
                    if let temperature = step.temperature {
                        Text("\(BakingFormat.number(temperature, precision: 0))\(step.temperatureUnit?.rawValue ?? "F")")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Color.brandSea)
                    }
                }

                TimerPanel(step: step, now: now)

                VStack(alignment: .leading, spacing: 10) {
                    Text("材料")
                        .font(.headline)
                    if stepItems.isEmpty {
                        Text("这个步骤没有指定材料")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(stepItems) { item in
                            Button {
                                store.toggleCookItem(stepId: step.id, itemId: item.id)
                            } label: {
                                HStack {
                                    Image(systemName: checked.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(checked.contains(item.id) ? Color.brandSage : .secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(item.name)
                                            if store.hasWaterContent(item) {
                                                Image(systemName: "drop.fill")
                                                    .font(.caption2)
                                                    .foregroundStyle(Color.waterText)
                                            }
                                        }
                                        if store.hasWaterContent(item) {
                                            Text("贡献水量 \(BakingFormat.weight(store.waterContribution(item)))")
                                                .font(.caption)
                                                .foregroundStyle(Color.waterText.opacity(0.82))
                                        }
                                    }
                                    Spacer()
                                    Text(BakingFormat.weight(item.weight, gramPrecision: item.tag == .yeast ? 1 : 0))
                                        .monospacedDigit()
                                }
                                .padding()
                                .background(store.hasWaterContent(item) ? Color.waterSurface : Color.brandSurface)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(store.hasWaterContent(item) ? Color.brandSea.opacity(0.28) : Color.clear, lineWidth: 1)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("操作")
                        .font(.headline)
                    Text(step.notes.isEmpty ? "按你的记录完成这个步骤。" : step.notes)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.brandSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                HStack {
                    Button {
                        store.moveCookStep(-1)
                    } label: {
                        Label("上一步", systemImage: "chevron.left")
                    }
                    .buttonStyle(.bordered)
                    .disabled(store.cookState.currentIndex == 0)

                    Spacer()

                    Text("\(checked.count)/\(stepItems.count) 材料")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Button {
                        store.moveCookStep(1)
                    } label: {
                        Label(store.cookState.currentIndex == store.steps.count - 1 ? "完成" : "下一步", systemImage: "chevron.right")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .background(Color.brandBackground)
    }

    private var currentStep: JournalStep {
        store.steps[min(store.cookState.currentIndex, max(store.steps.count - 1, 0))]
    }
}

private struct TimerPanel: View {
    @EnvironmentObject private var store: RecipeStore
    let step: JournalStep
    let now: Date

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text("当前")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(now, style: .time)
                    .font(.headline.monospacedDigit())
            }
            Spacer()
            Button {
                store.startTimer(for: step)
            } label: {
                HStack(spacing: 6) {
                    BakingIconView(icon: .timer, size: 18, color: .white)
                    Text(timerLabel)
                        .monospacedDigit()
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
            VStack(alignment: .trailing) {
                Text("预计完成")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(projectedEnd, style: .time)
                    .font(.headline.monospacedDigit())
            }
        }
        .padding()
        .background(Color.brandSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var isRunning: Bool {
        store.cookState.timerStepId == step.id && store.cookState.timerEndsAt != nil
    }

    private var projectedEnd: Date {
        if isRunning, let timerEndsAt = store.cookState.timerEndsAt {
            return timerEndsAt
        }
        return now.addingTimeInterval(store.stepMinutes(step) * 60)
    }

    private var timerLabel: String {
        guard isRunning, let timerEndsAt = store.cookState.timerEndsAt else {
            return "开始倒计时"
        }
        return BakingFormat.duration(minutes: max(0, timerEndsAt.timeIntervalSince(now) / 60))
    }
}

private struct CookSummaryView: View {
    @EnvironmentObject private var store: RecipeStore

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    BakingIconView(icon: .complete, size: 28, color: .brandSage)
                    Text("制作完成")
                }
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.brandSage)
            }

            Section {
                LabeledContent("实际耗时", value: BakingFormat.duration(minutes: actualMinutes))
                LabeledContent("预计耗时", value: BakingFormat.duration(minutes: store.totalStepMinutes()))
                LabeledContent("完成步骤", value: "\(store.steps.count)/\(store.steps.count)")
                LabeledContent("材料确认", value: "\(checkedItemCount)/\(totalItemCount)")
            }

            if let activeBakeRecord = store.activeBakeRecord {
                Section("复盘备注") {
                    TextEditor(text: Binding(
                        get: { activeBakeRecord.notes },
                        set: { store.updateBakeRecordNotes($0, for: activeBakeRecord) }
                    ))
                    .frame(minHeight: 120)
                }
            }

            Button {
                store.resetCook()
            } label: {
                Label("再做一次", systemImage: "arrow.clockwise")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.brandBackground)
    }

    private var actualMinutes: Double {
        guard let start = store.cookState.totalStartedAt, let end = store.cookState.completedAt else { return 0 }
        return end.timeIntervalSince(start) / 60
    }

    private var totalItemCount: Int {
        store.steps.reduce(0) { $0 + store.items(for: $1).count }
    }

    private var checkedItemCount: Int {
        store.cookState.checked.values.reduce(0) { $0 + $1.count }
    }
}
