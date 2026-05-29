import SwiftUI

struct StarterView: View {
    @EnvironmentObject private var store: RecipeStore
    @FocusState private var focusedField: StarterField?
    @State private var showingFedToast = false
    @State private var fedFeedbackTask: Task<Void, Never>?
    @State private var starterWeightSliderMaximum: Double = 1
    @State private var isAdjustingStarterWeight = false

    var body: some View {
        ScrollView {
            VStack(spacing: BakingSpace.xl) {
                starterHeader
                weightSection
                feedingSection
                reminderSection
            }
            .padding(.horizontal, BakingSpace.xl)
            .padding(.top, BakingSpace.sm)
            .padding(.bottom, 94)
        }
        .scrollIndicators(.hidden)
        .background(Color.brandBackground)
        .safeAreaInset(edge: .bottom) {
            feedButton
        }
        .overlay(alignment: .bottom) {
            if showingFedToast {
                StarterFedToast()
                    .padding(.bottom, 88)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button(BakingTerms.done) {
                    focusedField = nil
                }
            }
        }
        .onAppear {
            syncStarterWeightSliderMaximum()
        }
        .onChange(of: store.starterFinalWeight) { _, _ in
            guard !isAdjustingStarterWeight else { return }
            syncStarterWeightSliderMaximum()
        }
        .onDisappear {
            fedFeedbackTask?.cancel()
        }
    }

    private var starterHeader: some View {
        VStack(alignment: .leading, spacing: BakingSpace.sm) {
            sectionTitle(BakingTerms.starterSectionName)

            HStack(spacing: BakingSpace.md) {
                BakingMaterialIconBadge(
                    icon: .starter,
                    size: BakingTouchTarget.materialBadge,
                    iconSize: BakingTouchTarget.materialBadgeGlyph,
                    color: .starterTint,
                    background: .starterIconSurface
                )

                TextField(BakingTerms.starterProfileDefaultName, text: profileBinding(\.name))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.brandText)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.done)

                BakingSystemIconButtonLabel(
                    systemImage: "pencil",
                    tint: focusedField == .name ? .white : .brandPrimary,
                    background: focusedField == .name ? .brandPrimary : Color.brandPrimary.opacity(0.10),
                    visualSize: BakingTouchTarget.secondaryActionVisual,
                    font: .subheadline.weight(.semibold)
                )
            }
            .padding(BakingSpace.md)
            .bakingCard()
            .contentShape(RoundedRectangle(cornerRadius: BakingRadius.prominentCard, style: .continuous))
            .onTapGesture {
                focusedField = .name
            }
        }
    }

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: BakingSpace.sm) {
            sectionTitle(BakingTerms.starterSectionWeight)

            VStack(spacing: BakingSpace.sm) {
                HStack(spacing: BakingSpace.md) {
                    BakingLabel(text: BakingTerms.starterContainerWeight, role: .inputLabel)

                    Spacer(minLength: BakingSpace.md)

                    Toggle(BakingTerms.starterContainerWeightToggle, isOn: profileBinding(\.isContainerWeightEnabled))
                        .labelsHidden()
                        .tint(.brandPrimary)

                    weightField(
                        value: numberBinding(\.containerWeight),
                        field: .containerWeight,
                        isEnabled: store.starterProfile.isContainerWeightEnabled
                    )
                }
                .padding(.horizontal, BakingSpace.md)
                .padding(.vertical, BakingSpace.sm)
                .bakingCard()

                VStack(alignment: .leading, spacing: BakingSpace.md) {
                    StarterMetricCell(
                        title: BakingTerms.starterFinalWeight,
                        value: BakingFormat.weight(store.starterFinalWeight),
                        accent: .brandPrimary,
                        background: .clear
                    )

                    HStack(spacing: BakingSpace.md) {
                        Slider(
                            value: starterWeightReductionBinding,
                            in: 0...max(1, starterWeightSliderMaximum),
                            step: 1,
                            onEditingChanged: handleStarterWeightSliderEditingChanged
                        )
                        .tint(.brandPrimary)
                        .scaleEffect(x: -1, y: 1)

                        weightField(value: starterFinalWeightBinding, field: .finalWeight)
                    }
                    .padding(.horizontal, BakingSpace.sm)
                    .padding(.vertical, BakingSpace.sm)
                    .bakingFieldSurface(
                        background: Color.brandBackground.opacity(0.56),
                        stroke: Color.brandPrimary.opacity(0.10),
                        radius: BakingRadius.compactCard
                    )

                    Text(BakingTerms.starterWeightAdjustHint)
                        .bakingLabelStyle(.helperText)
                }
                .padding(BakingSpace.md)
                .bakingCard(
                    background: Color.brandPrimary.opacity(0.08),
                    stroke: Color.brandPrimary.opacity(0.10)
                )
            }
        }
    }

    private var feedingSection: some View {
        VStack(alignment: .leading, spacing: BakingSpace.sm) {
            sectionTitle(BakingTerms.starterSectionFeedingMethod)

            VStack(alignment: .leading, spacing: BakingSpace.sm) {
                HStack(spacing: BakingSpace.md) {
                    BakingLabel(text: BakingTerms.starterRatio, role: .fieldLabel)

                    Spacer(minLength: BakingSpace.md)

                    Menu {
                        Picker(BakingTerms.starterRatio, selection: profileBinding(\.feedingRatio)) {
                            ForEach(StarterFeedingRatio.allCases) { ratio in
                                Text(ratio.label).tag(ratio)
                            }
                        }
                    } label: {
                        RectangularDropdownTrigger(title: store.starterProfile.feedingRatio.label)
                    }
                }
                .buttonStyle(.plain)

                HStack(spacing: BakingSpace.sm) {
                    StarterFeedInlineMetric(
                        title: BakingTerms.starterFeedFlour,
                        value: store.starterFeedFlourWeight
                    )

                    StarterFeedInlineMetric(
                        title: BakingTerms.starterFeedWater,
                        value: store.starterFeedWaterWeight,
                        isWater: true
                    )
                }
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.vertical, BakingSpace.sm)
            .bakingCard()
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: BakingSpace.sm) {
            sectionTitle(BakingTerms.starterSectionReminder)

            VStack(spacing: 0) {
                DatePicker(
                    BakingTerms.starterSectionLastFed,
                    selection: profileBinding(\.lastFedAt),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandText)
                .padding(.vertical, BakingSpace.sm)

                StarterDivider()

                StarterToggleRow(
                    title: BakingTerms.starterReminderToggle,
                    isOn: profileBinding(\.isReminderEnabled)
                )

                if store.starterProfile.isReminderEnabled {
                    StarterDivider()

                    DatePicker(
                        BakingTerms.starterNextFeedingDate,
                        selection: profileBinding(\.nextFeedingDate),
                        displayedComponents: .date
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandText)
                    .padding(.vertical, BakingSpace.sm)

                    StarterDivider()

                    VStack(alignment: .leading, spacing: BakingSpace.sm) {
                        BakingLabel(text: BakingTerms.starterReminderTimes, role: .fieldLabel)

                        HStack(spacing: BakingSpace.sm) {
                            ForEach(RecipeStore.starterReminderTimeLabels, id: \.self) { time in
                                Text(time)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.brandPrimary)
                                    .padding(.horizontal, BakingSpace.md)
                                    .padding(.vertical, BakingSpace.xs)
                                    .background(Color.brandPrimary.opacity(0.09))
                                    .clipShape(RoundedRectangle(cornerRadius: BakingRadius.field, style: .continuous))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, BakingSpace.sm)
                }
            }
            .padding(.horizontal, BakingSpace.md)
            .padding(.vertical, BakingSpace.xs)
            .bakingCard()
        }
    }

    private var feedButton: some View {
        VStack(alignment: .leading, spacing: BakingSpace.sm) {
            Text(BakingTerms.starterSlideToMarkFed)
                .bakingLabelStyle(.helperText)
                .padding(.horizontal, BakingSpace.xxl)

            BakingSlideActionBar(
                icon: .complete,
                accessibilityLabel: BakingTerms.starterMarkFed,
                direction: .trailingToLeading,
                tint: .brandPrimary,
                trackBackground: .brandSurface,
                trackAccent: Color.brandSage.opacity(0.18)
            ) {
                store.markStarterFed()
                showFedToast()
            }
        }
        .padding(.horizontal, BakingSpace.xl)
        .padding(.top, BakingSpace.sm)
        .padding(.bottom, BakingSpace.sm)
        .background(.bar)
    }

    private func sectionTitle(_ title: String) -> some View {
        BakingLabel(text: title, role: .sectionHeader)
            .padding(.horizontal, BakingSpace.xxl)
    }

    private func weightField(value: Binding<Double>, field: StarterField, isEnabled: Bool = true) -> some View {
        HStack(spacing: BakingSpace.xs) {
            BakingNumericTextField(
                value: value,
                fractionDigits: 0...1,
                color: UIColor(isEnabled ? Color.brandText : Color.brandSecondaryText),
                font: .monospacedDigitSystemFont(ofSize: 20, weight: .semibold),
                isEnabled: isEnabled
            )
            .frame(width: 84)

            Text(BakingTerms.unitGram)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)
        }
        .padding(.horizontal, BakingSpace.sm)
        .padding(.vertical, BakingSpace.xs)
        .bakingSurface(isEnabled ? .field : .readOnly)
    }

    private func profileBinding<Value>(_ keyPath: WritableKeyPath<StarterProfile, Value>) -> Binding<Value> {
        Binding(
            get: { store.starterProfile[keyPath: keyPath] },
            set: { value in
                var next = store.starterProfile
                next[keyPath: keyPath] = value
                store.starterProfile = next
            }
        )
    }

    private func numberBinding(_ keyPath: WritableKeyPath<StarterProfile, Double>) -> Binding<Double> {
        Binding(
            get: { store.starterProfile[keyPath: keyPath] },
            set: { value in
                var next = store.starterProfile
                next[keyPath: keyPath] = max(0, value)
                store.starterProfile = next
            }
        )
    }

    private var starterFinalWeightBinding: Binding<Double> {
        Binding(
            get: { store.starterFinalWeight },
            set: { value in
                store.updateStarterFinalWeight(max(0, value))
            }
        )
    }

    private var starterWeightReductionBinding: Binding<Double> {
        Binding(
            get: { max(0, starterWeightSliderMaximum - store.starterFinalWeight) },
            set: { reduction in
                let clampedReduction = min(max(0, reduction), starterWeightSliderMaximum)
                store.updateStarterFinalWeight(starterWeightSliderMaximum - clampedReduction)
            }
        )
    }

    private func showFedToast() {
        fedFeedbackTask?.cancel()

        withAnimation(BakingMotion.quick) {
            showingFedToast = true
        }

        fedFeedbackTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.28)) {
                showingFedToast = false
            }
        }
    }

    private func handleStarterWeightSliderEditingChanged(_ isEditing: Bool) {
        isAdjustingStarterWeight = isEditing
        if isEditing {
            starterWeightSliderMaximum = max(1, store.starterFinalWeight)
        } else {
            syncStarterWeightSliderMaximum()
        }
    }

    private func syncStarterWeightSliderMaximum() {
        starterWeightSliderMaximum = max(1, store.starterFinalWeight)
    }
}

private struct StarterFedToast: View {
    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            BakingIconView(icon: .complete, size: 16, color: .brandSage)

            Text(BakingTerms.starterFedDone)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandText)
        }
        .padding(.horizontal, BakingSpace.xl)
        .padding(.vertical, BakingSpace.md)
        .bakingCard(
            background: Color.brandSurface.opacity(0.98),
            radius: BakingRadius.card,
            stroke: Color.brandSage.opacity(0.14)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

private struct StarterFeedInlineMetric: View {
    let title: String
    let value: Double
    var isWater = false

    var body: some View {
        HStack(spacing: BakingSpace.sm) {
            BakingLabel(text: title, role: .inputLabel)
                .foregroundStyle(isWater ? Color.waterText : Color.brandText)

            Spacer(minLength: BakingSpace.sm)

            ReadOnlyInlineMetric(
                value: BakingFormat.number(value, precision: 0),
                unit: BakingTerms.unitGram,
                font: .callout,
                color: isWater ? .waterText : .primary,
                totalWidth: 76,
                isWaterStyle: isWater,
                height: 36
            )
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bakingSurface(isWater ? .selected : .readOnly)
    }
}

private struct StarterInputRow<Content: View>: View {
    let title: String
    var isEnabled = true
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: BakingSpace.md) {
            BakingLabel(text: title, role: .inputLabel)
                .foregroundStyle(isEnabled ? Color.brandText : Color.brandSecondaryText)

            Spacer(minLength: BakingSpace.md)

            content()
        }
        .frame(minHeight: 58)
        .opacity(isEnabled ? 1 : 0.62)
    }
}

private struct StarterToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(BakingMotion.quick) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: BakingSpace.md) {
                BakingLabel(text: title, role: .inputLabel)

                Spacer(minLength: BakingSpace.md)

                Toggle(title, isOn: $isOn)
                    .labelsHidden()
                    .tint(.brandPrimary)
                    .allowsHitTesting(false)
            }
            .frame(minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct StarterMetricCell: View {
    let title: String
    let value: String
    var accent: Color = .brandPrimary
    var background: Color = Color.brandBackground.opacity(0.75)

    var body: some View {
        VStack(alignment: .leading, spacing: BakingSpace.xs) {
            BakingLabel(text: title, role: .readOnlyLabel)

            BakingNumericValue(
                value: value,
                kind: .metric,
                role: .primary,
                valueColor: accent
            )
        }
        .padding(.horizontal, BakingSpace.md)
        .padding(.vertical, BakingSpace.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
    }
}

private struct StarterDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.brandPrimary.opacity(0.08))
            .frame(height: 0.6)
    }
}

private enum StarterField: Hashable {
    case name
    case containerWeight
    case finalWeight
}
