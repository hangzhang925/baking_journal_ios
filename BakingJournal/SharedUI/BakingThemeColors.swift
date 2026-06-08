import SwiftUI
import UIKit

// MARK: - Baking Journal color foundation
//
// Source of truth: the "Baking Journal — Design System" produced in Claude Design
// (direction "Honey Gold", warm light + warm-black dark themes).
//
// Direction A · Honey Gold (bright, sunny wheat) is the signature primary. It stays
// vivid in both light and warm-black dark mode, like the saturated primaries in
// WeChat / RedNote / Instagram. Secondary is a calm water blue tied to the legacy
// `Color.water*` tokens. Surfaces follow a white-canvas → warm-cream-card model with
// no cold grey. Filled primary controls take white text on the bright gold fill.
//
// All app color routes through the semantic `Color.brand*`, `Color.water*`, semantic,
// and material tokens below — recolor here and the change propagates app-wide.

extension Color {

    // MARK: Primary scale — Honey Gold (50 → 900)
    static let goldenWheat50 = adaptiveColor(light: RGB(0.992, 0.965, 0.902), dark: RGB(0.992, 0.965, 0.902))
    static let goldenWheat100 = adaptiveColor(light: RGB(0.984, 0.914, 0.761), dark: RGB(0.984, 0.914, 0.761))
    static let goldenWheat200 = adaptiveColor(light: RGB(0.969, 0.843, 0.549), dark: RGB(0.969, 0.843, 0.549))
    static let goldenWheat300 = adaptiveColor(light: RGB(0.953, 0.757, 0.314), dark: RGB(0.953, 0.757, 0.314))
    static let goldenWheat400 = adaptiveColor(light: RGB(0.945, 0.682, 0.149), dark: RGB(0.945, 0.682, 0.149))
    static let goldenWheat500 = adaptiveColor(light: RGB(0.949, 0.635, 0.047), dark: RGB(0.949, 0.635, 0.047))
    static let goldenWheat600 = adaptiveColor(light: RGB(0.839, 0.522, 0.039), dark: RGB(0.839, 0.522, 0.039))
    static let goldenWheat700 = adaptiveColor(light: RGB(0.682, 0.400, 0.039), dark: RGB(0.682, 0.400, 0.039))
    static let goldenWheat800 = adaptiveColor(light: RGB(0.498, 0.294, 0.051), dark: RGB(0.498, 0.294, 0.051))
    static let goldenWheat900 = adaptiveColor(light: RGB(0.325, 0.192, 0.043), dark: RGB(0.325, 0.192, 0.043))

    // MARK: Secondary scale — Water Blue (50 → 900)
    static let waterBlue50 = adaptiveColor(light: RGB(0.914, 0.965, 0.980), dark: RGB(0.914, 0.965, 0.980))
    static let waterBlue100 = adaptiveColor(light: RGB(0.776, 0.914, 0.949), dark: RGB(0.776, 0.914, 0.949))
    static let waterBlue200 = adaptiveColor(light: RGB(0.561, 0.827, 0.898), dark: RGB(0.561, 0.827, 0.898))
    static let waterBlue300 = adaptiveColor(light: RGB(0.322, 0.725, 0.831), dark: RGB(0.322, 0.725, 0.831))
    static let waterBlue400 = adaptiveColor(light: RGB(0.153, 0.627, 0.761), dark: RGB(0.153, 0.627, 0.761))
    static let waterBlue500 = adaptiveColor(light: RGB(0.094, 0.533, 0.675), dark: RGB(0.094, 0.533, 0.675))
    static let waterBlue600 = adaptiveColor(light: RGB(0.075, 0.439, 0.561), dark: RGB(0.075, 0.439, 0.561))
    static let waterBlue700 = adaptiveColor(light: RGB(0.078, 0.357, 0.455), dark: RGB(0.078, 0.357, 0.455))
    static let waterBlue800 = adaptiveColor(light: RGB(0.086, 0.286, 0.361), dark: RGB(0.086, 0.286, 0.361))
    static let waterBlue900 = adaptiveColor(light: RGB(0.078, 0.227, 0.286), dark: RGB(0.078, 0.227, 0.286))

    // MARK: Semantic — success / warning / error / info
    static let semanticSuccessSoft = adaptiveColor(
        light: RGB(0.886, 0.953, 0.910),
        dark: RGB(0.114, 0.231, 0.165)
    )
    static let semanticSuccess = adaptiveColor(
        light: RGB(0.184, 0.620, 0.357),
        dark: RGB(0.498, 0.851, 0.631)
    )
    static let semanticSuccessDeep = adaptiveColor(
        light: RGB(0.118, 0.478, 0.263),
        dark: RGB(0.498, 0.851, 0.631)
    )
    static let semanticWarningSoft = adaptiveColor(
        light: RGB(0.988, 0.922, 0.831),
        dark: RGB(0.243, 0.176, 0.090)
    )
    static let semanticWarning = adaptiveColor(
        light: RGB(0.910, 0.510, 0.102),
        dark: RGB(0.961, 0.745, 0.471)
    )
    static let semanticWarningDeep = adaptiveColor(
        light: RGB(0.710, 0.380, 0.047),
        dark: RGB(0.961, 0.745, 0.471)
    )
    static let semanticErrorSoft = adaptiveColor(
        light: RGB(0.984, 0.890, 0.878),
        dark: RGB(0.243, 0.118, 0.106)
    )
    static let semanticError = adaptiveColor(
        light: RGB(0.859, 0.290, 0.239),
        dark: RGB(0.949, 0.631, 0.600)
    )
    static let semanticErrorDeep = adaptiveColor(
        light: RGB(0.682, 0.200, 0.153),
        dark: RGB(0.949, 0.631, 0.600)
    )
    static let semanticInfoSoft = adaptiveColor(
        light: RGB(0.882, 0.941, 0.965),
        dark: RGB(0.106, 0.196, 0.231)
    )
    static let semanticInfo = adaptiveColor(
        light: RGB(0.165, 0.525, 0.659),
        dark: RGB(0.525, 0.773, 0.867)
    )
    static let semanticInfoDeep = adaptiveColor(
        light: RGB(0.102, 0.408, 0.522),
        dark: RGB(0.525, 0.773, 0.867)
    )

    // MARK: Surfaces — white canvas → warm cream cards (no cold grey)
    static let brandBackground = adaptiveColor(
        light: RGB(1.0, 1.0, 1.0),                 // canvas · #FFFFFF
        dark: RGB(0.082, 0.071, 0.051)             // warm near-black · #15120D
    )
    static let brandSurface = adaptiveColor(
        light: RGB(0.984, 0.957, 0.910),           // card · #FBF4E8
        dark: RGB(0.125, 0.106, 0.078)             // #201B14
    )
    static let brandSurfaceStrong = adaptiveColor(
        light: RGB(0.965, 0.925, 0.855),           // nested cell · #F6ECDA
        dark: RGB(0.165, 0.141, 0.106)             // #2A241B
    )

    // MARK: Editable field fills — "gold = you can edit this"
    static let brandFieldSurface = adaptiveColor(
        light: RGB(0.993, 0.953, 0.876),           // field-fill (gold wash on cream)
        dark: RGB(0.216, 0.164, 0.075)
    )
    static let brandFieldSurfaceFocused = adaptiveColor(
        light: RGB(0.988, 0.922, 0.792),           // field-fill-focus · deeper gold wash
        dark: RGB(0.282, 0.208, 0.082)
    )
    static let brandFieldStroke = adaptiveColor(
        light: RGB(0.942, 0.788, 0.500),           // field-border (soft gold hairline)
        dark: RGB(0.415, 0.310, 0.120)
    )
    static let brandReadOnlySurface = adaptiveColor(
        light: RGB(0.937, 0.918, 0.878),           // warm neutral grey · read-only/computed
        dark: RGB(0.149, 0.133, 0.106)
    )

    // MARK: Primary accent
    static let brandPrimary = adaptiveColor(
        light: RGB(0.949, 0.635, 0.047),           // accent · p-500 · #F2A20C
        dark: RGB(0.949, 0.635, 0.047)
    )
    static let brandPrimaryLight = adaptiveColor(
        light: RGB(0.839, 0.522, 0.039),           // accent-hover (light → p-600)
        dark: RGB(0.945, 0.682, 0.149)             // accent-hover (dark → p-400)
    )
    static let brandPrimaryDark = adaptiveColor(
        light: RGB(0.682, 0.400, 0.039),           // accent-press (light → p-700)
        dark: RGB(0.953, 0.757, 0.314)             // accent-press (dark → p-300)
    )
    static let brandOnPrimary = adaptiveColor(
        light: RGB(1.0, 1.0, 1.0),                 // on-accent · #FFFFFF
        dark: RGB(1.0, 1.0, 1.0)
    )

    // MARK: Secondary roles
    static let brandSage = adaptiveColor(
        light: RGB(0.184, 0.620, 0.357),           // success green · #2F9E5B
        dark: RGB(0.498, 0.851, 0.631)
    )
    static let brandSea = adaptiveColor(
        light: RGB(0.094, 0.533, 0.675),           // water blue · s-500
        dark: RGB(0.322, 0.725, 0.831)             // water blue · s-300
    )

    // MARK: Text tiers (warm, no cold grey)
    static let brandText = adaptiveColor(
        light: RGB(0.165, 0.137, 0.110),           // text-1 · #2A231C
        dark: RGB(0.957, 0.925, 0.867)             // #F4ECDD
    )
    static let brandSecondaryText = adaptiveColor(
        light: RGB(0.416, 0.373, 0.314),           // text-2 · #6A5F50
        dark: RGB(0.725, 0.678, 0.596)             // #B9AD98
    )
    static let brandTertiaryText = adaptiveColor(
        light: RGB(0.612, 0.557, 0.482),           // text-3 · #9C8E7B
        dark: RGB(0.518, 0.478, 0.408)             // #847A68
    )
    static let brandDivider = adaptiveColor(
        light: RGB(0.937, 0.898, 0.827),           // border · #EFE5D3
        dark: RGB(0.227, 0.196, 0.145)             // #3A3225
    )
    static let brandBorderStrong = adaptiveColor(
        light: RGB(0.886, 0.827, 0.725),           // border-strong · #E2D3B9 (pickers, ghost buttons)
        dark: RGB(0.290, 0.251, 0.192)             // #4A4031
    )

    // MARK: Water surfaces
    static let waterSurface = adaptiveColor(
        light: RGB(0.914, 0.965, 0.980),           // s-50
        dark: RGB(0.071, 0.169, 0.184)
    )
    static let waterSurfaceStrong = adaptiveColor(
        light: RGB(0.776, 0.914, 0.949),           // s-100
        dark: RGB(0.094, 0.231, 0.267)
    )
    static let waterText = adaptiveColor(
        light: RGB(0.094, 0.533, 0.675),           // s-500
        dark: RGB(0.322, 0.725, 0.831)             // s-300
    )

    // MARK: Material chips & icon badges
    static let materialSurface = brandSurface
    static let materialChipSurface = adaptiveColor(
        light: RGB(0.965, 0.925, 0.855),           // warm cream cell · surface-2
        dark: RGB(0.165, 0.141, 0.106)
    )
    static let materialChipSurfaceSelected = adaptiveColor(
        light: RGB(0.984, 0.914, 0.761),           // soft accent gold · p-100
        dark: RGB(0.274, 0.201, 0.073)
    )
    static let selectedSurface = adaptiveColor(
        light: RGB(0.984, 0.914, 0.761),           // accent-soft fill
        dark: RGB(0.274, 0.201, 0.073)
    )
    static let selectedSurfaceStroke = adaptiveColor(
        light: RGB(0.949, 0.635, 0.047),           // accent
        dark: RGB(0.949, 0.635, 0.047)
    )
    static let materialIconSurface = adaptiveColor(
        light: RGB(0.984, 0.914, 0.761),           // accent-soft — stands apart from cream card
        dark: RGB(0.274, 0.201, 0.073)
    )

    static let flourSurface = materialChipSurface
    static let flourIconSurface = materialIconSurface
    static let starterTint = adaptiveColor(light: RGB(0.094, 0.533, 0.675), dark: RGB(0.322, 0.725, 0.831))
    static let starterSurface = waterSurface
    static let starterIconSurface = waterSurfaceStrong
    static let saltTint = adaptiveColor(light: RGB(0.44, 0.47, 0.56), dark: RGB(0.77, 0.80, 0.90))
    static let saltSurface = materialChipSurface
    static let saltIconSurface = materialIconSurface
    static let butterTint = adaptiveColor(light: RGB(0.47, 0.49, 0.29), dark: RGB(0.82, 0.78, 0.46))
    static let butterSurface = materialChipSurface
    static let butterIconSurface = materialIconSurface
    static let yeastTint = adaptiveColor(light: RGB(0.53, 0.46, 0.23), dark: RGB(0.86, 0.73, 0.40))
    static let yeastSurface = materialChipSurface
    static let yeastIconSurface = materialIconSurface
    static let eggTint = adaptiveColor(light: RGB(0.66, 0.39, 0.18), dark: RGB(0.94, 0.62, 0.34))
    static let eggSurface = materialChipSurface
    static let eggIconSurface = materialIconSurface
    static let sugarTint = adaptiveColor(light: RGB(0.39, 0.52, 0.33), dark: RGB(0.66, 0.80, 0.55))
    static let sugarSurface = materialChipSurface
    static let sugarIconSurface = materialIconSurface
    static let otherTint = adaptiveColor(light: RGB(0.43, 0.49, 0.34), dark: RGB(0.72, 0.78, 0.56))
    static let otherSurface = materialChipSurface
    static let otherIconSurface = materialIconSurface
    static let mutedSurface = brandSurfaceStrong
    static let mutedIconSurface = materialIconSurface

    private struct RGB {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat

        init(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, alpha: CGFloat = 1) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }
    }

    private static func adaptiveColor(light: RGB, dark: RGB) -> Color {
        Color(UIColor { traits in
            let color = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: color.red,
                green: color.green,
                blue: color.blue,
                alpha: color.alpha
            )
        })
    }
}
