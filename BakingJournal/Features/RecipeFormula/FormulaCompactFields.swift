import SwiftUI
import UIKit

struct CompactSummaryPill: View {
    let title: String
    let value: String
    var unit: String? = nil
    var isWater = false

    var body: some View {
        HStack(spacing: 6) {
            BakingLabel(text: title, role: .readOnlyLabel)
                .foregroundStyle(isWater ? Color.waterText.opacity(0.82) : Color.brandSecondaryText)
            BakingNumericValue(
                value: value,
                unit: unit,
                kind: .readOnly,
                role: .secondary,
                valueColor: isWater ? .waterText : .brandText
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bakingSurface(isWater ? .selected : .readOnly)
    }
}

struct CompactTextRow: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            BakingLabel(text: title, role: .fieldLabel)
            Spacer()
            TextField(title, text: $text)
                .font(BakingTypography.rowValue)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}

struct CompactNumberRow: View {
    let title: String
    @Binding var value: Double
    let unit: String

    var body: some View {
        HStack(spacing: 12) {
            BakingLabel(text: title, role: .fieldLabel)
            Spacer()
            BakingNumericTextField(
                value: $value,
                fractionDigits: 0...2,
                color: UIColor(Color.brandText),
                font: .monospacedDigitSystemFont(ofSize: 15, weight: .medium)
            )
            .frame(minWidth: 70)
            Text(unit)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)
        }
        .padding(.vertical, 6)
    }
}

struct InlineNameField: View {
    @Binding var text: String
    let placeholder: String
    var font: Font = .body.weight(.semibold)
    var isWaterStyle = false
    var fieldWidth: CGFloat = 132
    var height: CGFloat = 40

    var body: some View {
        BakingInlineTextField(
            text: $text,
            placeholder: placeholder,
            color: UIColor(Color.brandText),
            font: uiFont
        )
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .frame(width: fieldWidth, alignment: .leading)
            .frame(height: height)
            .bakingSurface(.field)
    }

    private var editableFieldBackground: Color {
        isWaterStyle ? Color.waterSurfaceStrong.opacity(0.25) : Color.brandPrimary.opacity(0.075)
    }

    private var uiFont: UIFont {
        switch font {
        case .caption:
            return .systemFont(ofSize: 12, weight: .semibold)
        case .subheadline:
            return .systemFont(ofSize: 15, weight: .semibold)
        default:
            return .systemFont(ofSize: 16, weight: .semibold)
        }
    }
}

struct InlineNumberField: View {
    @Binding var value: Double
    let unit: String
    var font: Font = .subheadline
    var color: Color = .primary
    var fieldWidth: CGFloat = 64
    var totalWidth: CGFloat? = nil
    var isWaterStyle = false
    var fractionDigits: ClosedRange<Int> = 0...0
    var height: CGFloat = 40

    var body: some View {
        HStack(spacing: 4) {
            BakingNumericTextField(
                value: $value,
                fractionDigits: fractionDigits,
                color: UIColor(color),
                font: uiFont
            )
                .frame(width: fieldWidth)
            Text(unit)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.brandSecondaryText)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .frame(width: totalWidth, alignment: .trailing)
        .frame(height: height)
        .bakingSurface(.field)
    }

    private var uiFont: UIFont {
        switch font {
        case .subheadline:
            return .monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        case .callout:
            return .monospacedDigitSystemFont(ofSize: 16, weight: .semibold)
        default:
            return .monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        }
    }
}

struct ReadOnlyInlineMetric: View {
    let value: String
    let unit: String
    var font: Font = .subheadline
    var color: Color = .primary
    var totalWidth: CGFloat? = nil
    var isWaterStyle = false
    var height: CGFloat = 40

    var body: some View {
        HStack(spacing: 4) {
            BakingNumericValue(
                value: value,
                unit: unit,
                kind: .readOnly,
                role: .secondary,
                valueColor: color,
                unitColor: Color.brandSecondaryText.opacity(0.82)
            )
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .frame(width: totalWidth, alignment: .trailing)
        .frame(height: height)
        .bakingSurface(.readOnly)
    }

    private var displayFont: Font {
        switch font {
        case .callout:
            return .callout.monospacedDigit().weight(.semibold)
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

struct CompactReadOnlyRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            BakingLabel(text: title, role: .fieldLabel)
            Spacer()
            Text(value)
                .font(BakingTypography.rowValue.monospacedDigit())
                .foregroundStyle(Color.brandSecondaryText)
        }
        .padding(.vertical, 6)
    }
}

struct CompactMenuRow: View {
    let title: String
    let value: String
    let options: [String]
    var displayTitle: (String) -> String = { $0 }
    let onSelect: (String) -> Void
    @State private var showingOptions = false

    var body: some View {
        HStack(spacing: 12) {
            BakingLabel(text: title, role: .fieldLabel)
            Spacer()
            Button {
                showingOptions = true
            } label: {
                BakingDropdownTrigger(
                    title: displayTitle(value),
                    tint: .brandPrimary,
                    background: Color.brandPrimary.opacity(0.075)
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingOptions, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                BakingDropdownPopover(width: 156) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            onSelect(option)
                            showingOptions = false
                        } label: {
                            BakingDropdownRow(title: displayTitle(option), isSelected: option == value) {
                                Color.clear
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

struct CompactRecipeMetrics: View {
    let summary: RecipeSummary

    var body: some View {
        HStack(spacing: 8) {
            CompactMetricCell(title: "面团", value: BakingFormat.weight(summary.doughWeight))
            CompactMetricCell(title: "面粉", value: BakingFormat.weight(summary.flourWeight))
            CompactMetricCell(
                title: "含水",
                value: "\(BakingFormat.number(summary.hydration, precision: 1))%",
                accent: .waterText,
                background: .waterSurface
            )
        }
    }
}

private struct CompactMetricCell: View {
    let title: String
    let value: String
    var accent: Color = .brandPrimary
    var background: Color = Color.brandBackground.opacity(0.75)

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .bakingLabelStyle(.readOnlyLabel)
            Text(value)
                .font(BakingTypography.readOnlyValue)
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: BakingRadius.compactCard, style: .continuous))
    }
}
