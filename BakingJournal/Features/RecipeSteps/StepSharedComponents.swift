import SwiftUI

enum ReorderMotion {
    static let holdDuration: TimeInterval = 1
    static let holdMaximumDistance: CGFloat = BakingGesturePolicy.reorderHoldMaximumDistance
    static let dragMinimumDistance: CGFloat = BakingGesturePolicy.reorderDragMinimumDistance
    static let liftScale: CGFloat = 1.035
    static let previewOpacity = 0.18
    static let liftShadowRadius: CGFloat = 22
    static let liftShadowY: CGFloat = 12
    static let animation = Animation.spring(response: 0.24, dampingFraction: 0.86)
}

struct ReorderRowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

struct ReorderFrameReader: View {
    let id: UUID
    let coordinateSpace: String

    var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ReorderRowFramePreferenceKey.self,
                value: [id: proxy.frame(in: .named(coordinateSpace))]
            )
        }
    }
}

extension View {
    @ViewBuilder
    func reorderGesture<ReorderGesture: Gesture>(_ gesture: ReorderGesture, enabled: Bool) -> some View {
        if enabled {
            simultaneousGesture(gesture)
        } else {
            self
        }
    }

    func reorderLiftedAppearance() -> some View {
        self
            .scaleEffect(ReorderMotion.liftScale)
            .bakingLiftedShadow()
    }
}

struct StepsMetricPill: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(BakingTypography.appSecondaryText)
                .foregroundStyle(Color.brandSecondaryText)
            Text(value)
                .font(BakingTypography.tableNumber)
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bakingReadOnlySurface()
    }
}

struct StepValuePill: View {
    let icon: String?
    let text: String
    let accent: Color
    var background: Color = BakingSurfaceTheme.theme(for: .inputSurface).background
    var stroke: Color = BakingSurfaceTheme.theme(for: .inputSurface).stroke
    var width: CGFloat = 62

    var body: some View {
        HStack(spacing: 5) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
            }
            Text(text)
                .font(BakingTypography.tableNumber)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(accent)
        .frame(width: width, height: BakingComponentMetrics.compactPillHeight)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.field, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BakingRadius.field, style: .continuous)
                .stroke(stroke, lineWidth: 0.5)
        }
    }
}

struct TemperatureUnitCompactPicker: View {
    @Binding var selection: TemperatureUnit

    var body: some View {
        Picker(BakingTerms.stepsTemperatureUnit, selection: $selection) {
            ForEach(TemperatureUnit.allCases) { unit in
                Text(unit.rawValue).tag(unit)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 110)
        .accessibilityLabel(BakingTerms.stepsTemperatureUnit)
    }
}

struct TemperatureUnitFlipButton: View {
    let unit: TemperatureUnit
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 22, height: 22)
                    .background(BakingSurfaceTheme.theme(for: .selected).background)
                    .clipShape(Circle())

                Text(unit.rawValue)
                    .font(BakingTypography.tableNumber)
                    .foregroundStyle(Color.brandText)
                    .frame(width: 18)
            }
            .frame(width: 82, height: 38)
            .bakingSurface(.nestedChip)
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(BakingTerms.stepsSwitchTemperatureUnit)
        .accessibilityValue(unit.rawValue)
    }
}

struct BakingTemperatureEditorRow: View {
    let title: String
    @Binding var value: Double
    @Binding var unit: TemperatureUnit
    @State private var isFocused = false

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(BakingTypography.appPrimaryText)

            Spacer()

            BakingNumericTextField(
                value: $value,
                fractionDigits: 0...0,
                isFocused: $isFocused,
                color: UIColor(Color.brandText),
                font: .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
            )
            .frame(width: 74)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(height: 36)
            .bakingSurface(isFocused ? .focused : .field)

            TemperatureUnitFlipButton(unit: unit) {
                flipUnit()
            }
        }
        .padding(.vertical, 6)
    }

    private func flipUnit() {
        switch unit {
        case .fahrenheit:
            value = ((value - 32) * 5 / 9).rounded()
            unit = .celsius
        case .celsius:
            value = (value * 9 / 5 + 32).rounded()
            unit = .fahrenheit
        }
    }
}
