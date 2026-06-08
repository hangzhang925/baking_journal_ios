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
                .foregroundStyle(Color.brandSecondaryText)
            BakingNumericValue(
                value: value,
                unit: unit,
                kind: .readOnly,
                role: .secondary,
                valueColor: .brandText
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CompactTextRow: View {
    let title: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            BakingLabel(text: title, role: .fieldLabel)
            Spacer()
            TextField(title, text: $text)
                .font(BakingTypography.rowValue)
                .foregroundStyle(Color.brandText)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .bakingFittedInputField(.long, alignment: .trailing, kind: isFocused ? .focused : .field)
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
                .font(BakingTypography.rowMeta)
                .foregroundStyle(Color.brandSecondaryText)
        }
        .padding(.vertical, 6)
    }
}

struct InlineNameField: View {
    @Binding var text: String
    let placeholder: String
    var font: Font = BakingTypography.appPrimaryText
    var isWaterStyle = false
    var fieldWidth: CGFloat = 132
    var height: CGFloat = 40
    @State private var isFocused = false

    var body: some View {
        BakingInlineTextField(
            text: $text,
            placeholder: placeholder,
            isFocused: $isFocused,
            color: UIColor(Color.brandText),
            font: uiFont
        )
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .frame(width: fieldWidth, alignment: .leading)
            .frame(height: height)
            .bakingSurface(isFocused ? .focused : .field)
    }

    private var editableFieldBackground: Color {
        isWaterStyle ? BakingSurfaceTheme.theme(for: .waterSurface).background : BakingSurfaceTheme.theme(for: .inputSurface).background
    }

    private var uiFont: UIFont {
        switch font {
        case .caption:
            return .systemFont(ofSize: 12, weight: .semibold)
        case .subheadline:
            return .systemFont(ofSize: 15, weight: .semibold)
        default:
            return .systemFont(ofSize: 15, weight: .semibold)
        }
    }
}

struct InlineNumberField: View {
    @Binding var value: Double
    let unit: String
    var font: Font = BakingTypography.appPrimaryText
    var color: Color = .primary
    var fieldWidth: CGFloat = 64
    var totalWidth: CGFloat? = nil
    var isWaterStyle = false
    var fractionDigits: ClosedRange<Int> = 0...0
    var height: CGFloat = 40
    @State private var isFocused = false

    var body: some View {
        HStack(spacing: 4) {
            BakingNumericTextField(
                value: $value,
                fractionDigits: fractionDigits,
                isFocused: $isFocused,
                color: UIColor(color),
                font: uiFont
            )
                .frame(width: fieldWidth)
            Text(unit)
                .font(BakingTypography.rowMeta)
                .foregroundStyle(Color.brandSecondaryText)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .frame(width: totalWidth, alignment: .trailing)
        .frame(height: height)
        .bakingSurface(isFocused ? .focused : .field)
    }

    private var uiFont: UIFont {
        switch font {
        case .subheadline:
            return .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        case .callout:
            return .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        default:
            return .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        }
    }
}

struct ReadOnlyInlineMetric: View {
    let value: String
    let unit: String
    var font: Font = BakingTypography.appPrimaryText
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
                unitColor: color
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
            return BakingTypography.tableNumber
        default:
            return BakingTypography.tableNumber
        }
    }

    private var editableFieldBackground: Color {
        if isWaterStyle {
            return BakingSurfaceTheme.theme(for: .waterSurface).background
        }
        return BakingSurfaceTheme.theme(for: .inputSurface).background
    }

    private var fieldStroke: Color {
        if isWaterStyle {
            return BakingSurfaceTheme.theme(for: .waterSurface).stroke
        }
        return BakingSurfaceTheme.theme(for: .inputSurface).stroke
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
                    tint: .brandPrimary
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
    var items: [RecipeItem] = []
    var flourContribution: ((RecipeItem) -> Double)?
    var waterContribution: ((RecipeItem) -> Double)?

    var body: some View {
        HStack(spacing: 8) {
            CompactMetricCell(title: BakingTerms.formulaMetricDough, value: BakingFormat.weight(summary.doughWeight))
            CompactMetricCell(title: BakingTerms.formulaMetricFlour, value: BakingFormat.weight(summary.flourWeight))
            CompactMetricCell(
                title: BakingTerms.formulaMetricHydration,
                value: "\(BakingFormat.number(summary.hydration, precision: 1))%",
                background: .waterSurface,
                hydrationReceipt: hydrationReceipt
            )
        }
    }

    private var hydrationReceipt: HydrationReceipt? {
        HydrationReceipt(
            items: items,
            summary: summary,
            flourContribution: flourContribution,
            waterContribution: waterContribution
        )
    }
}

private struct CompactMetricCell: View {
    let title: String
    let value: String
    var accent: Color = .brandText
    var background: Color = BakingSurfaceTheme.theme(for: .readOnly).background
    var hydrationReceipt: HydrationReceipt?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                Text(title)
                    .bakingLabelStyle(.readOnlyLabel)

                if let hydrationReceipt {
                    HydrationReceiptInfoButton(receipt: hydrationReceipt, iconSize: 15)
                }
            }
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
