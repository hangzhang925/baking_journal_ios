import SwiftUI

struct MaterialPalette {
    let tint: Color
    let text: Color
    let surface: Color
    let iconSurface: Color
    let stroke: Color
    let mutedSurface: Color
    let mutedIconSurface: Color
}

extension RecipeItem {
    var materialPalette: MaterialPalette {
        MaterialPalette(
            tint: .brandPrimary,
            text: .brandText,
            surface: .materialSurface,
            iconSurface: .materialIconSurface,
            stroke: BakingSurface.cardStroke,
            mutedSurface: .mutedSurface,
            mutedIconSurface: .mutedIconSurface
        )
    }
}
