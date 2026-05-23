import SwiftUI
import UIKit

private struct HistorySwipeSuppressionHandlerKey: EnvironmentKey {
    static let defaultValue: (Bool) -> Void = { _ in }
}

extension EnvironmentValues {
    var historySwipeSuppressionHandler: (Bool) -> Void {
        get { self[HistorySwipeSuppressionHandlerKey.self] }
        set { self[HistorySwipeSuppressionHandlerKey.self] = newValue }
    }
}

enum BakingGesturePolicy {
    static let verticalScrollMinimumDistance: CGFloat = 6
    static let verticalScrollIntentRatio: CGFloat = 1.08
    static let horizontalIntentMinimumDistance: CGFloat = 18
    static let horizontalIntentRatio: CGFloat = 1.55
    static let historySwipeActivationDistance: CGFloat = 18
    static let historySwipeMinimumDistance: CGFloat = 72
    static let historySwipeIntentRatio: CGFloat = 1.55
    static let reorderHoldMaximumDistance: CGFloat = verticalScrollMinimumDistance
    static let reorderDragMinimumDistance: CGFloat = 8

    static func isVerticalScrollIntent(
        _ translation: CGSize,
        minimumDistance: CGFloat = verticalScrollMinimumDistance,
        ratio: CGFloat = verticalScrollIntentRatio
    ) -> Bool {
        let horizontalTravel = abs(translation.width)
        let verticalTravel = abs(translation.height)
        return verticalTravel >= minimumDistance && verticalTravel > horizontalTravel * ratio
    }

    static func isHorizontalIntent(
        _ translation: CGSize,
        minimumDistance: CGFloat = horizontalIntentMinimumDistance,
        ratio: CGFloat = horizontalIntentRatio
    ) -> Bool {
        let horizontalTravel = abs(translation.width)
        let verticalTravel = abs(translation.height)
        return horizontalTravel >= minimumDistance && horizontalTravel > verticalTravel * ratio
    }
}

enum BakingSpace {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 10
    static let lg: CGFloat = 12
    static let xl: CGFloat = 14
    static let xxl: CGFloat = 16
}

enum BakingRadius {
    static let field: CGFloat = 8
    static let chip: CGFloat = 10
    static let compactCard: CGFloat = 12
    static let card: CGFloat = 14
    static let prominentCard: CGFloat = 16
    static let popover: CGFloat = 22
}

enum BakingMotion {
    static let quick = Animation.easeInOut(duration: 0.16)
    static let standard = Animation.easeInOut(duration: 0.22)
}

enum BakingTouchTarget {
    static let primaryAction: CGFloat = 44
    static let primaryActionVisual: CGFloat = 38
    static let primaryActionGlyph: CGFloat = 21
    static let secondaryAction: CGFloat = 40
    static let secondaryActionVisual: CGFloat = 34
    static let secondaryActionGlyph: CGFloat = 18
    static let inlineIconSurface: CGFloat = 30
    static let inlineIconGlyph: CGFloat = 20
    static let dropdownIconSurface: CGFloat = 28
    static let dropdownIconGlyph: CGFloat = 16
    static let materialBadge: CGFloat = 42
    static let materialBadgeGlyph: CGFloat = 24
    static let tabIconSurface: CGFloat = 32
    static let tabIconGlyph: CGFloat = 22
    static let slideActionTrack: CGFloat = 52
    static let slideActionThumb: CGFloat = 44
    static let slideActionGlyph: CGFloat = 20

    static let iconButton: CGFloat = primaryAction
    static let toolbarVisual: CGFloat = primaryActionVisual
}

extension View {
    func bakingCard(
        background: Color = .brandSurface,
        radius: CGFloat = BakingRadius.prominentCard,
        stroke: Color = Color.brandPrimary.opacity(0.08),
        lineWidth: CGFloat = 0.6
    ) -> some View {
        self
            .background(background)
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(stroke, lineWidth: lineWidth)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func bakingFieldSurface(
        background: Color = Color.brandPrimary.opacity(0.075),
        stroke: Color = Color.brandPrimary.opacity(0.10),
        radius: CGFloat = BakingRadius.field
    ) -> some View {
        self
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(stroke, lineWidth: 0.5)
            }
    }
}

struct BakingSystemIconButtonLabel: View {
    let systemImage: String
    var tint: Color = .white
    var background: Color = .brandPrimary
    var visualSize: CGFloat = BakingTouchTarget.toolbarVisual
    var font: Font = .body.weight(.semibold)
    var shape: BakingIconButtonShape = .circle

    var body: some View {
        switch shape {
        case .circle:
            icon
                .clipShape(Circle())
        case .rounded(let radius):
            icon
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
    }

    private var icon: some View {
        Image(systemName: systemImage)
            .font(font)
            .foregroundStyle(tint)
            .frame(width: visualSize, height: visualSize)
            .background(background)
            .frame(width: BakingTouchTarget.iconButton, height: BakingTouchTarget.iconButton)
            .contentShape(Rectangle())
            .accessibilityHidden(true)
    }
}

struct BakingPressFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(BakingMotion.quick, value: configuration.isPressed)
    }
}

final class BakingScrollFriendlyTextField: UITextField {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = panGesture.velocity(in: self)
            if abs(velocity.y) > abs(velocity.x) {
                return false
            }
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

struct BakingInlineTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    var color: UIColor = UIColor(Color.brandText)
    var font: UIFont = .preferredFont(forTextStyle: .body)
    var textAlignment: NSTextAlignment = .left
    var returnKeyType: UIReturnKeyType = .done

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = BakingScrollFriendlyTextField()
        textField.placeholder = placeholder
        textField.text = text
        textField.textColor = color
        textField.font = font
        textField.textAlignment = textAlignment
        textField.borderStyle = .none
        textField.returnKeyType = returnKeyType
        textField.delegate = context.coordinator
        textField.tintColor = UIColor(Color.brandPrimary)
        textField.clearButtonMode = .never
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        uiView.placeholder = placeholder
        uiView.textColor = color
        uiView.font = font
        uiView.textAlignment = textAlignment
        uiView.returnKeyType = returnKeyType
        if !uiView.isFirstResponder, uiView.text != text {
            uiView.text = text
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: BakingInlineTextField

        init(parent: BakingInlineTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

struct BakingNumericTextField: UIViewRepresentable {
    @Binding var value: Double
    let fractionDigits: ClosedRange<Int>
    var minValue: Double = 0
    var color: UIColor = UIColor(Color.brandText)
    var font: UIFont = .monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
    var textAlignment: NSTextAlignment = .right
    var adjustsFontSizeToFitWidth = true
    var isEnabled = true

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = BakingScrollFriendlyTextField()
        textField.keyboardType = fractionDigits.upperBound > 0 ? .decimalPad : .numberPad
        textField.textAlignment = textAlignment
        textField.textColor = color
        textField.font = font
        textField.borderStyle = .none
        textField.delegate = context.coordinator
        textField.text = context.coordinator.formatted(value)
        textField.tintColor = UIColor(Color.brandPrimary)
        textField.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
        textField.minimumFontSize = 12
        textField.isEnabled = isEnabled
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.inputAccessoryView = context.coordinator.makeAccessoryToolbar()
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        uiView.textColor = color
        uiView.font = font
        uiView.textAlignment = textAlignment
        uiView.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
        uiView.isEnabled = isEnabled
        uiView.keyboardType = fractionDigits.upperBound > 0 ? .decimalPad : .numberPad

        let next = context.coordinator.formatted(value)
        if !uiView.isFirstResponder, uiView.text != next {
            uiView.text = next
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: BakingNumericTextField
        private let formatter = NumberFormatter()

        init(parent: BakingNumericTextField) {
            self.parent = parent
            super.init()
            configureFormatter()
        }

        func makeAccessoryToolbar() -> UIToolbar {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let flex = UIBarButtonItem(systemItem: .flexibleSpace)
            let done = UIBarButtonItem(title: BakingTerms.done, style: .done, target: self, action: #selector(doneTapped))
            toolbar.items = [flex, done]
            return toolbar
        }

        func formatted(_ value: Double) -> String {
            configureFormatter()
            let clamped = max(parent.minValue, value)
            return formatter.string(from: NSNumber(value: clamped)) ?? BakingFormat.number(clamped, precision: parent.fractionDigits.upperBound)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async { [weak textField] in
                guard let textField, textField.isFirstResponder else { return }
                self.moveCaretToEnd(of: textField)
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if (textField.text ?? "").isEmpty {
                parent.value = parent.minValue
            }
            textField.text = formatted(parent.value)
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = textField.text ?? formatted(parent.value)
            guard let stringRange = Range(range, in: current) else { return false }
            let next = current.replacingCharacters(in: stringRange, with: string)

            if next.isEmpty {
                parent.value = parent.minValue
                return true
            }

            guard isValid(next) else { return false }

            let normalized = normalizedInput(next)
            if normalized != next {
                update(textField, with: normalized)
                return false
            }

            updateValue(from: normalized)
            return true
        }

        private func configureFormatter() {
            formatter.numberStyle = .decimal
            formatter.usesGroupingSeparator = false
            formatter.minimumFractionDigits = parent.fractionDigits.lowerBound
            formatter.maximumFractionDigits = parent.fractionDigits.upperBound
            formatter.decimalSeparator = "."
        }

        private func isValid(_ text: String) -> Bool {
            let allowed = CharacterSet(charactersIn: "0123456789.")
            guard text.rangeOfCharacter(from: allowed.inverted) == nil else { return false }

            let parts = text.split(separator: ".", omittingEmptySubsequences: false)
            guard parts.count <= 2 else { return false }

            if parent.fractionDigits.upperBound == 0 {
                return !text.contains(".")
            }

            if parts.count == 2 {
                return parts[1].count <= parent.fractionDigits.upperBound
            }

            return true
        }

        private func normalizedInput(_ text: String) -> String {
            guard text.count > 1 else { return text }

            if text.hasPrefix("0"), !text.hasPrefix("0.") {
                let trimmed = text.drop { $0 == "0" }
                return trimmed.isEmpty ? "0" : String(trimmed)
            }

            return text
        }

        private func update(_ textField: UITextField, with text: String) {
            updateValue(from: text)
            textField.text = text
            moveCaretToEnd(of: textField)
        }

        private func updateValue(from text: String) {
            guard let number = Double(text) else { return }
            parent.value = max(parent.minValue, number)
        }

        private func moveCaretToEnd(of textField: UITextField) {
            let end = textField.endOfDocument
            if let range = textField.textRange(from: end, to: end) {
                textField.selectedTextRange = range
            }
        }

        @objc private func doneTapped() {
            dismissActiveKeyboard()
        }
    }
}

struct BakingPercentageField: View {
    @Binding var value: Double
    var maxValue: Double = 100
    var precision: Int = 1
    var font: Font = .subheadline
    var color: Color = .brandPrimary
    var fieldWidth: CGFloat = 34
    var totalWidth: CGFloat? = 62
    var isWaterStyle = false
    var height: CGFloat = 40

    @State private var isShowingPicker = false

    var body: some View {
        Button {
            isShowingPicker = true
        } label: {
            HStack(spacing: 4) {
                Text(BakingFormat.number(clampedValue, precision: precision))
                    .font(displayFont)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(width: fieldWidth, alignment: .trailing)
                Text("%")
                    .font(font)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .frame(width: totalWidth, alignment: .trailing)
            .frame(height: height)
            .bakingFieldSurface(background: editableFieldBackground, stroke: fieldStroke)
            .contentShape(RoundedRectangle(cornerRadius: BakingRadius.field, style: .continuous))
        }
        .buttonStyle(BakingPressFeedbackButtonStyle())
        .accessibilityLabel(BakingTerms.percentagePickerAccessibility)
        .accessibilityValue("\(BakingFormat.number(clampedValue, precision: precision))%")
        .popover(isPresented: $isShowingPicker, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
            BakingPercentagePickerCard(
                value: Binding(
                    get: { clampedValue },
                    set: { value = clamped($0) }
                ),
                maxValue: maxValue,
                precision: precision,
                tint: color,
                surface: isWaterStyle ? Color.waterSurfaceStrong.opacity(0.42) : Color.brandPrimary.opacity(0.075)
            )
            .presentationCompactAdaptation(.popover)
        }
        .onChange(of: maxValue) { _, _ in
            value = clamped(value)
        }
    }

    private var clampedValue: Double {
        clamped(value)
    }

    private func clamped(_ nextValue: Double) -> Double {
        min(max(0, nextValue), effectiveMaxValue)
    }

    private var effectiveMaxValue: Double {
        min(max(0, maxValue), 100)
    }

    private var displayFont: Font {
        switch font {
        case .callout:
            return .callout.monospacedDigit().weight(.semibold)
        case .caption:
            return .caption.monospacedDigit().weight(.semibold)
        default:
            return .subheadline.monospacedDigit().weight(.semibold)
        }
    }

    private var editableFieldBackground: Color {
        if isWaterStyle {
            return Color.waterSurfaceStrong.opacity(0.42)
        }
        return Color.brandPrimary.opacity(0.075)
    }

    private var fieldStroke: Color {
        if isWaterStyle {
            return Color.brandSea.opacity(0.16)
        }
        return Color.brandPrimary.opacity(0.10)
    }
}

struct BakingPercentagePickerCard: View {
    @Binding var value: Double
    var maxValue: Double = 100
    var precision: Int = 1
    var tint: Color = .brandPrimary
    var surface: Color = Color.brandPrimary.opacity(0.075)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(BakingTerms.percentage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)

            BakingPercentagePickerControl(
                value: Binding(
                    get: { clampedValue },
                    set: { value = clamped($0) }
                ),
                maxValue: maxValue,
                precision: precision,
                tint: tint,
                surface: surface
            )
        }
        .padding(14)
        .frame(width: 276)
        .background(
            RoundedRectangle(cornerRadius: BakingRadius.popover, style: .continuous)
                .fill(Color.brandSurface.opacity(0.98))
                .overlay {
                    RoundedRectangle(cornerRadius: BakingRadius.popover, style: .continuous)
                        .stroke(Color.brandPrimary.opacity(0.08), lineWidth: 0.6)
                }
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
        )
        .onChange(of: maxValue) { _, _ in
            value = clamped(value)
        }
    }

    private var clampedValue: Double {
        clamped(value)
    }

    private var effectiveMaxValue: Double {
        min(max(0, maxValue), 100)
    }

    private func clamped(_ nextValue: Double) -> Double {
        min(max(0, nextValue), effectiveMaxValue)
    }
}

struct BakingPercentagePickerControl: View {
    @Binding var value: Double
    var maxValue: Double = 100
    var precision: Int = 1
    var tint: Color = .brandPrimary
    var surface: Color = Color.brandPrimary.opacity(0.075)

    var body: some View {
        VStack(spacing: 10) {
            Slider(value: sliderBinding, in: 0...max(1, effectiveMaxValue), step: step)
                .tint(tint)
                .accessibilityLabel(BakingTerms.percentagePickerAccessibility)
                .accessibilityValue("\(BakingFormat.number(clampedValue, precision: precision))%")

            HStack {
                Text("0%")
                Spacer()
                Text("\(BakingFormat.number(effectiveMaxValue, precision: 0))%")
            }
            .font(.caption2.monospacedDigit().weight(.medium))
            .foregroundStyle(Color.brandSecondaryText)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(BakingFormat.number(clampedValue, precision: precision))
                    .font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
                Text("%")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.brandSecondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(surface)
            .clipShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
        }
        .onChange(of: maxValue) { _, _ in
            value = clamped(value)
        }
    }

    private var sliderBinding: Binding<Double> {
        Binding(
            get: { clampedValue },
            set: { value = clamped($0) }
        )
    }

    private var clampedValue: Double {
        clamped(value)
    }

    private var effectiveMaxValue: Double {
        min(max(0, maxValue), 100)
    }

    private var step: Double {
        precision <= 0 ? 1 : 0.1
    }

    private func clamped(_ nextValue: Double) -> Double {
        min(max(0, nextValue), effectiveMaxValue)
    }
}

enum BakingIconButtonShape {
    case circle
    case rounded(CGFloat)
}

enum BakingSlideActionDirection {
    case leadingToTrailing
    case trailingToLeading
}

struct BakingSlideActionBar: View {
    @Environment(\.historySwipeSuppressionHandler) private var setHistorySwipeSuppressed
    let icon: BakingIcon
    let accessibilityLabel: String
    var direction: BakingSlideActionDirection = .leadingToTrailing
    var tint: Color = .brandPrimary
    var trackBackground: Color = .brandSurface
    var trackAccent: Color = Color.brandPrimary.opacity(0.12)
    var onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isCompleting = false
    @State private var isHorizontalSlideActive = false
    @State private var isVerticalScrollIntent = false

    private let trackHeight: CGFloat = BakingTouchTarget.slideActionTrack
    private let thumbSize: CGFloat = BakingTouchTarget.slideActionThumb
    private let horizontalInset: CGFloat = BakingSpace.xs
    private let completionThreshold: CGFloat = 0.84

    var body: some View {
        GeometryReader { proxy in
            let trackWidth = proxy.size.width
            let travel = max(0, trackWidth - thumbSize - horizontalInset * 2)
            let currentProgress = min(max(progress, 0), 1)

            ZStack {
                Capsule(style: .continuous)
                    .fill(trackBackground)

                Capsule(style: .continuous)
                    .fill(trackAccent)
                    .frame(width: max(thumbSize, thumbSize + currentProgress * travel))
                    .frame(maxWidth: .infinity, alignment: fillAlignment)

                HStack(spacing: BakingSpace.xs) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: direction == .trailingToLeading ? "chevron.left" : "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(tint.opacity(0.24 + Double(index) * 0.16))
                    }
                }
                .allowsHitTesting(false)

                thumb
                    .position(
                        x: thumbCenterX(for: travel),
                        y: proxy.size.height / 2
                    )
                    .gesture(slideGesture(travel: travel))
                    .allowsHitTesting(!isCompleting)
            }
            .padding(horizontalInset)
            .bakingCard(
                background: trackBackground,
                radius: trackHeight / 2,
                stroke: tint.opacity(0.10)
            )
        }
        .frame(height: trackHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var fillAlignment: Alignment {
        switch direction {
        case .leadingToTrailing:
            .leading
        case .trailingToLeading:
            .trailing
        }
    }

    private var thumb: some View {
        ZStack {
            Circle()
                .fill(tint)

            BakingIconView(icon: icon, size: BakingTouchTarget.slideActionGlyph, color: .white)
        }
        .frame(width: thumbSize, height: thumbSize)
    }

    private func thumbCenterX(for travel: CGFloat) -> CGFloat {
        let normalized = progressPosition(for: progress)
        let minX = horizontalInset + thumbSize / 2
        return minX + normalized * travel
    }

    private func progressPosition(for progress: CGFloat) -> CGFloat {
        switch direction {
        case .leadingToTrailing:
            progress
        case .trailingToLeading:
            1 - progress
        }
    }

    private func progress(for normalizedPosition: CGFloat) -> CGFloat {
        switch direction {
        case .leadingToTrailing:
            normalizedPosition
        case .trailingToLeading:
            1 - normalizedPosition
        }
    }

    private func slideGesture(travel: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: BakingGesturePolicy.verticalScrollMinimumDistance, coordinateSpace: .local)
            .onChanged { value in
                guard !isCompleting else { return }
                guard !isVerticalScrollIntent else { return }
                if !isHorizontalSlideActive {
                    if BakingGesturePolicy.isVerticalScrollIntent(value.translation) {
                        isVerticalScrollIntent = true
                        withAnimation(BakingMotion.quick) {
                            progress = 0
                        }
                        return
                    }
                    guard BakingGesturePolicy.isHorizontalIntent(
                        value.translation,
                        minimumDistance: 10,
                        ratio: 1.25
                    ) else { return }
                    isHorizontalSlideActive = true
                    setHistorySwipeSuppressed(true)
                }
                let rawPosition = (value.location.x - thumbSize / 2 - horizontalInset) / max(travel, 1)
                let normalizedPosition = min(max(rawPosition, 0), 1)
                progress = progress(for: normalizedPosition)
            }
            .onEnded { value in
                guard !isCompleting else { return }
                let shouldReleaseHistorySwipe = isHorizontalSlideActive
                defer {
                    isHorizontalSlideActive = false
                    isVerticalScrollIntent = false
                    if shouldReleaseHistorySwipe {
                        setHistorySwipeSuppressed(false)
                    }
                }
                guard isHorizontalSlideActive else {
                    withAnimation(BakingMotion.quick) {
                        progress = 0
                    }
                    return
                }
                let rawPosition = (value.location.x - thumbSize / 2 - horizontalInset) / max(travel, 1)
                let normalizedPosition = min(max(rawPosition, 0), 1)
                let nextProgress = progress(for: normalizedPosition)

                guard nextProgress >= completionThreshold else {
                    withAnimation(BakingMotion.quick) {
                        progress = 0
                    }
                    return
                }

                isCompleting = true
                withAnimation(BakingMotion.standard) {
                    progress = 1
                }
                onComplete()

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.65))
                    isCompleting = false
                    withAnimation(BakingMotion.standard) {
                        progress = 0
                    }
                }
            }
    }
}

struct BakingMaterialIconBadge: View {
    let icon: BakingIcon
    var size: CGFloat = BakingTouchTarget.materialBadge
    var iconSize: CGFloat = BakingTouchTarget.materialBadgeGlyph
    var color: Color = .brandPrimary
    var background: Color = Color.brandPrimary.opacity(0.10)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(background)
            BakingIconView(icon: icon, size: iconSize, color: color)
        }
        .frame(width: size, height: size)
    }
}

struct BakingSwipeToDeleteRow<Content: View>: View {
    @Environment(\.historySwipeSuppressionHandler) private var setHistorySwipeSuppressed
    let canDelete: Bool
    let onDelete: () -> Void
    var onOpenChanged: (Bool) -> Void = { _ in }
    var deleteConfirmationTitle = "删除这个项目？"
    var deleteConfirmationMessage = "删除后无法撤销。"
    var deleteButtonTitle = "删除"
    @ViewBuilder let content: () -> Content
    @State private var offset: CGFloat = 0
    @State private var isHorizontalSwipeActive = false
    @State private var dragStartOffset: CGFloat = 0
    @State private var rowWidth: CGFloat = 0
    @State private var rowHeight: CGFloat = 0
    @State private var showingDeleteConfirmation = false
    @State private var isVerticalScrollIntent = false

    private let actionWidth: CGFloat = 58
    private let buttonSize = CGSize(width: 52, height: 52)
    private let fullSwipeInset: CGFloat = 2

    var body: some View {
        ZStack(alignment: .trailing) {
            if canDelete && offset != 0 {
                deleteAction
            }

            content()
                .offset(x: offset)
                .contentShape(Rectangle())
                .allowsHitTesting(offset == 0)
        }
        .contentShape(Rectangle())
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        rowWidth = proxy.size.width
                        rowHeight = proxy.size.height
                    }
                    .onChange(of: proxy.size.width) { _, newWidth in
                        rowWidth = newWidth
                        offset = max(offset, -fullSwipeWidth)
                    }
                    .onChange(of: proxy.size.height) { _, newHeight in
                        rowHeight = newHeight
                    }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.prominentCard, style: .continuous))
        .simultaneousGesture(
            DragGesture(minimumDistance: 14, coordinateSpace: .local)
                .onChanged { value in
                    guard canDelete else { return }
                    guard !isVerticalScrollIntent else { return }

                    if !isHorizontalSwipeActive {
                        if BakingGesturePolicy.isVerticalScrollIntent(value.translation) {
                            isVerticalScrollIntent = true
                            return
                        }
                        guard BakingGesturePolicy.isHorizontalIntent(value.translation) else { return }
                        isHorizontalSwipeActive = true
                        setHistorySwipeSuppressed(true)
                        dragStartOffset = offset
                    }

                    let nextOffset = dragStartOffset + value.translation.width
                    offset = min(0, max(-fullSwipeWidth, nextOffset))
                }
                .onEnded { value in
                    guard canDelete else { return }
                    let shouldReleaseHistorySwipe = isHorizontalSwipeActive
                    defer {
                        isHorizontalSwipeActive = false
                        isVerticalScrollIntent = false
                        if shouldReleaseHistorySwipe {
                            setHistorySwipeSuppressed(false)
                        }
                        dragStartOffset = 0
                    }

                    guard isHorizontalSwipeActive else { return }
                    withAnimation(BakingMotion.quick) {
                        offset = snappedOffset(for: offset)
                    }
                    onOpenChanged(offset != 0)
                }
        )
        .onTapGesture {
            guard offset != 0 else { return }
            withAnimation(BakingMotion.quick) {
                offset = 0
            }
            onOpenChanged(false)
        }
        .onChange(of: offset) { _, newValue in
            onOpenChanged(newValue != 0)
        }
        .confirmationDialog(deleteConfirmationTitle, isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button(deleteButtonTitle, role: .destructive) {
                closeSwipe()
                onDelete()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(deleteConfirmationMessage)
        }
    }

    private var deleteAction: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            ZStack(alignment: isFullDeleteReveal ? .leading : .center) {
                RoundedRectangle(cornerRadius: BakingRadius.prominentCard, style: .continuous)
                    .fill(Color.brandPrimary)

                Image(systemName: "trash")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: buttonSize.width, height: buttonSize.height)
                    .padding(.leading, isFullDeleteReveal ? BakingSpace.xl : 0)
            }
            .frame(width: deleteActionWidth)
            .frame(height: rowHeight)
            .contentShape(RoundedRectangle(cornerRadius: BakingRadius.prominentCard, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("删除")
        .padding(.trailing, isFullDeleteReveal ? 0 : 3)
    }

    private var deleteActionWidth: CGFloat {
        min(fullSwipeWidth, max(actionWidth, -offset))
    }

    private var fullSwipeWidth: CGFloat {
        max(actionWidth, rowWidth - fullSwipeInset)
    }

    private var isFullDeleteReveal: Bool {
        -offset >= fullSwipeWidth * 0.72
    }

    private func snappedOffset(for offset: CGFloat) -> CGFloat {
        let reveal = -offset
        if reveal >= fullSwipeWidth * 0.48 {
            return -fullSwipeWidth
        }
        if reveal >= actionWidth * 0.52 {
            return -actionWidth
        }
        return 0
    }

    private func closeSwipe() {
        withAnimation(BakingMotion.quick) {
            offset = 0
        }
        onOpenChanged(false)
    }
}

struct BakingFlowLayout: Layout {
    var spacing: CGFloat = BakingSpace.sm

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
