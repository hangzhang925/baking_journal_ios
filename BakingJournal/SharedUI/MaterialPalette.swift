import SwiftUI

struct MaterialPalette {
    let tint: Color
    let text: Color
    let surface: Color
    let chipSurface: Color
    let selectedChipSurface: Color
    let iconSurface: Color
    let stroke: Color
    let chipStroke: Color
    let mutedSurface: Color
    let mutedIconSurface: Color
}

extension RecipeItem {
    var materialPalette: MaterialPalette {
        MaterialPalette(
            tint: .brandPrimary,
            text: .brandText,
            surface: .materialSurface,
            chipSurface: .materialChipSurface,
            selectedChipSurface: .materialChipSurfaceSelected,
            iconSurface: .materialIconSurface,
            stroke: BakingSurface.cardStroke,
            chipStroke: BakingSurface.warmHairline,
            mutedSurface: .mutedSurface,
            mutedIconSurface: .mutedIconSurface
        )
    }
}
