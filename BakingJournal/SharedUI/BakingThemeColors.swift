import SwiftUI
import UIKit

extension Color {
    static let brandBackground = adaptiveColor(
        light: RGB(1.0, 1.0, 1.0),
        dark: RGB(0.0, 0.0, 0.0)
    )
    static let brandSurface = adaptiveColor(
        light: RGB(0.992, 0.976, 0.949),
        dark: RGB(0.0, 0.0, 0.0)
    )
    static let brandSurfaceStrong = adaptiveColor(
        light: RGB(0.976, 0.953, 0.914),
        dark: RGB(0.067, 0.067, 0.067)
    )
    static let brandFieldSurface = adaptiveColor(
        light: RGB(0.996, 0.949, 0.878),
        dark: RGB(0.165, 0.106, 0.047)
    )
    static let brandFieldStroke = adaptiveColor(
        light: RGB(0.875, 0.682, 0.424),
        dark: RGB(0.545, 0.357, 0.157)
    )
    static let brandPrimary = adaptiveColor(
        light: RGB(0.957, 0.643, 0.227),
        dark: RGB(0.957, 0.643, 0.227)
    )
    static let brandPrimaryLight = adaptiveColor(
        light: RGB(0.910, 0.584, 0.141),
        dark: RGB(0.941, 0.627, 0.184)
    )
    static let brandPrimaryDark = adaptiveColor(
        light: RGB(0.784, 0.459, 0.094),
        dark: RGB(0.827, 0.518, 0.122)
    )
    static let brandOnPrimary = adaptiveColor(
        light: RGB(1.0, 1.0, 1.0),
        dark: RGB(1.0, 1.0, 1.0)
    )
    static let brandSage = adaptiveColor(
        light: RGB(0.373, 0.498, 0.322),
        dark: RGB(0.60, 0.72, 0.50)
    )
    static let brandSea = adaptiveColor(
        light: RGB(0.247, 0.655, 0.710),
        dark: RGB(0.333, 0.718, 0.761)
    )
    static let brandText = adaptiveColor(
        light: RGB(0.067, 0.067, 0.067),
        dark: RGB(1.0, 1.0, 1.0)
    )
    static let brandSecondaryText = adaptiveColor(
        light: RGB(0.400, 0.400, 0.400),
        dark: RGB(0.722, 0.722, 0.722)
    )
    static let brandTertiaryText = adaptiveColor(
        light: RGB(0.600, 0.600, 0.600),
        dark: RGB(0.467, 0.467, 0.467)
    )
    static let brandDivider = adaptiveColor(
        light: RGB(0.886, 0.831, 0.745),
        dark: RGB(0.141, 0.141, 0.141)
    )
    static let waterSurface = adaptiveColor(
        light: RGB(0.918, 0.969, 0.976),
        dark: RGB(0.063, 0.157, 0.169)
    )
    static let waterSurfaceStrong = adaptiveColor(
        light: RGB(0.859, 0.945, 0.953),
        dark: RGB(0.086, 0.220, 0.239)
    )
    static let waterText = adaptiveColor(
        light: RGB(0.247, 0.655, 0.710),
        dark: RGB(0.333, 0.718, 0.761)
    )

    static let materialSurface = brandSurface
    static let materialChipSurface = adaptiveColor(
        light: RGB(0.969, 0.969, 0.969),
        dark: RGB(0.067, 0.067, 0.067)
    )
    static let materialChipSurfaceSelected = adaptiveColor(
        light: RGB(0.996, 0.949, 0.878),
        dark: RGB(0.165, 0.106, 0.047)
    )
    static let selectedSurface = adaptiveColor(
        light: RGB(0.996, 0.949, 0.878),
        dark: RGB(0.165, 0.106, 0.047)
    )
    static let selectedSurfaceStroke = adaptiveColor(
        light: RGB(0.957, 0.643, 0.227),
        dark: RGB(0.957, 0.643, 0.227)
    )
    static let materialIconSurface = adaptiveColor(
        light: RGB(0.996, 0.929, 0.824),
        dark: RGB(0.165, 0.106, 0.047)
    )

    static let flourSurface = materialChipSurface
    static let flourIconSurface = materialIconSurface
    static let starterTint = adaptiveColor(light: RGB(0.10, 0.42, 0.56), dark: RGB(0.42, 0.76, 0.86))
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
