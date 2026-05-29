import SwiftUI
import UIKit

extension Color {
    static let brandBackground = adaptiveColor(
        light: RGB(0.99, 0.96, 0.90),
        dark: RGB(0.075, 0.062, 0.050)
    )
    static let brandSurface = adaptiveColor(
        light: RGB(1.0, 0.985, 0.955),
        dark: RGB(0.125, 0.105, 0.088)
    )
    static let brandPrimary = adaptiveColor(
        light: RGB(0.70, 0.26, 0.18),
        dark: RGB(0.94, 0.43, 0.32)
    )
    static let brandSage = adaptiveColor(
        light: RGB(0.34, 0.44, 0.30),
        dark: RGB(0.60, 0.72, 0.50)
    )
    static let brandSea = adaptiveColor(
        light: RGB(0.09, 0.46, 0.62),
        dark: RGB(0.34, 0.70, 0.82)
    )
    static let brandText = adaptiveColor(
        light: RGB(0.08, 0.07, 0.055),
        dark: RGB(0.96, 0.91, 0.84)
    )
    static let brandSecondaryText = adaptiveColor(
        light: RGB(0.46, 0.43, 0.38),
        dark: RGB(0.72, 0.67, 0.59)
    )
    static let waterSurface = adaptiveColor(
        light: RGB(0.86, 0.96, 0.98),
        dark: RGB(0.08, 0.18, 0.22)
    )
    static let waterSurfaceStrong = adaptiveColor(
        light: RGB(0.74, 0.91, 0.96),
        dark: RGB(0.11, 0.28, 0.34)
    )
    static let waterText = adaptiveColor(
        light: RGB(0.04, 0.34, 0.49),
        dark: RGB(0.46, 0.80, 0.90)
    )

    static let materialSurface = brandSurface
    static let materialIconSurface = adaptiveColor(
        light: RGB(0.96, 0.925, 0.855),
        dark: RGB(0.18, 0.145, 0.115)
    )

    static let flourSurface = adaptiveColor(light: RGB(0.95, 0.97, 0.91), dark: RGB(0.12, 0.16, 0.105))
    static let flourIconSurface = adaptiveColor(light: RGB(0.89, 0.94, 0.84), dark: RGB(0.18, 0.25, 0.15))
    static let starterTint = adaptiveColor(light: RGB(0.10, 0.42, 0.56), dark: RGB(0.42, 0.76, 0.86))
    static let starterSurface = adaptiveColor(light: RGB(0.89, 0.96, 0.98), dark: RGB(0.08, 0.17, 0.21))
    static let starterIconSurface = adaptiveColor(light: RGB(0.79, 0.91, 0.95), dark: RGB(0.11, 0.28, 0.34))
    static let saltTint = adaptiveColor(light: RGB(0.44, 0.47, 0.56), dark: RGB(0.77, 0.80, 0.90))
    static let saltSurface = adaptiveColor(light: RGB(0.95, 0.96, 0.99), dark: RGB(0.12, 0.13, 0.17))
    static let saltIconSurface = adaptiveColor(light: RGB(0.88, 0.90, 0.96), dark: RGB(0.18, 0.20, 0.27))
    static let butterTint = adaptiveColor(light: RGB(0.47, 0.49, 0.29), dark: RGB(0.82, 0.78, 0.46))
    static let butterSurface = adaptiveColor(light: RGB(0.99, 0.96, 0.87), dark: RGB(0.18, 0.15, 0.09))
    static let butterIconSurface = adaptiveColor(light: RGB(0.97, 0.92, 0.72), dark: RGB(0.27, 0.22, 0.10))
    static let yeastTint = adaptiveColor(light: RGB(0.53, 0.46, 0.23), dark: RGB(0.86, 0.73, 0.40))
    static let yeastSurface = adaptiveColor(light: RGB(0.98, 0.94, 0.86), dark: RGB(0.18, 0.13, 0.08))
    static let yeastIconSurface = adaptiveColor(light: RGB(0.96, 0.89, 0.74), dark: RGB(0.27, 0.20, 0.11))
    static let eggTint = adaptiveColor(light: RGB(0.66, 0.39, 0.18), dark: RGB(0.94, 0.62, 0.34))
    static let eggSurface = adaptiveColor(light: RGB(0.99, 0.92, 0.84), dark: RGB(0.20, 0.12, 0.075))
    static let eggIconSurface = adaptiveColor(light: RGB(0.98, 0.86, 0.73), dark: RGB(0.31, 0.18, 0.10))
    static let sugarTint = adaptiveColor(light: RGB(0.39, 0.52, 0.33), dark: RGB(0.66, 0.80, 0.55))
    static let sugarSurface = adaptiveColor(light: RGB(0.94, 0.97, 0.91), dark: RGB(0.12, 0.16, 0.10))
    static let sugarIconSurface = adaptiveColor(light: RGB(0.88, 0.93, 0.83), dark: RGB(0.18, 0.25, 0.14))
    static let otherTint = adaptiveColor(light: RGB(0.43, 0.49, 0.34), dark: RGB(0.72, 0.78, 0.56))
    static let otherSurface = adaptiveColor(light: RGB(0.95, 0.96, 0.89), dark: RGB(0.15, 0.16, 0.10))
    static let otherIconSurface = adaptiveColor(light: RGB(0.89, 0.92, 0.82), dark: RGB(0.22, 0.24, 0.14))
    static let mutedSurface = adaptiveColor(light: RGB(0.0, 0.0, 0.0, alpha: 0.06), dark: RGB(1.0, 1.0, 1.0, alpha: 0.08))
    static let mutedIconSurface = adaptiveColor(light: RGB(1.0, 1.0, 1.0, alpha: 0.65), dark: RGB(1.0, 1.0, 1.0, alpha: 0.10))

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
