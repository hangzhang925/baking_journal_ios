import SwiftUI

enum BakingIcon {
    case back
    case add
    case copy
    case save
    case share
    case home
    case settings
    case toolbox
    case recipe
    case recipeToast
    case recipeCake
    case recipeCountryBread
    case recipeCustom
    case filterAll
    case modifiedSort
    case sortNewest
    case sortOldest
    case process
    case start
    case preview
    case flour
    case starter
    case water
    case salt
    case sugar
    case butter
    case yeast
    case egg
    case other
    case prep
    case mixing
    case fermentation
    case rest
    case shaping
    case baking
    case bakes
    case bakeHistory
    case timer
    case complete
    case edit
    case delete

    static func material(for item: RecipeItem) -> BakingIcon {
        switch item.tag {
        case .flour: .flour
        case .starter: .starter
        case .water: .water
        case .salt: .salt
        case .sugar: .sugar
        case .butter: .butter
        case .yeast: .yeast
        case .egg: .egg
        case .other: .other
        }
    }

    static func recipeKind(_ kind: RecipeKind) -> BakingIcon {
        switch kind {
        case .toast:
            return .recipeToast
        case .chiffon:
            return .recipeCake
        case .countryBread:
            return .recipeCountryBread
        case .custom:
            return .recipeCustom
        }
    }

    static func step(for type: StepType) -> BakingIcon {
        switch type {
        case .prep: .prep
        case .mixing: .mixing
        case .fermentation: .fermentation
        case .rest: .rest
        case .shaping: .shaping
        case .baking: .baking
        case .other: .other
        }
    }
}

enum BakingIconVariant {
    case outline
    case selected
}

struct BakingIconView: View {
    let icon: BakingIcon
    var size: CGFloat = 24
    var color: Color = .brandPrimary
    var variant: BakingIconVariant = .outline

    var body: some View {
        Canvas { context, canvasSize in
            // Selection is expressed by the parent tint and navigation indicator;
            // the icon drawing itself must stay identical across states.
            let isSelected = false
            let style = StrokeStyle(
                lineWidth: max(1.6, canvasSize.width * 0.075),
                lineCap: .round,
                lineJoin: .round
            )
            let fineStyle = StrokeStyle(
                lineWidth: max(1.2, canvasSize.width * 0.055),
                lineCap: .round,
                lineJoin: .round
            )

            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: canvasSize.width * x, y: canvasSize.height * y)
            }

            func stroke(_ path: Path, fine: Bool = false) {
                context.stroke(path, with: .color(color), style: fine ? fineStyle : style)
            }

            func fill(_ path: Path, opacity: Double = 0.12) {
                context.fill(path, with: .color(color.opacity(opacity)))
            }

            func solid(_ path: Path) {
                context.fill(path, with: .color(color))
            }

            func cut(_ path: Path, fine: Bool = false) {
                context.stroke(path, with: .color(Color.brandBackground), style: fine ? fineStyle : style)
            }

            func cutFill(_ path: Path) {
                context.fill(path, with: .color(Color.brandBackground))
            }

            func circle(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, filled: Bool = false) {
                let rect = CGRect(
                    x: canvasSize.width * (x - radius),
                    y: canvasSize.height * (y - radius),
                    width: canvasSize.width * radius * 2,
                    height: canvasSize.height * radius * 2
                )
                let path = Path(ellipseIn: rect)
                filled ? fill(path, opacity: 0.18) : stroke(path, fine: true)
            }

            func cutCircle(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat) {
                let rect = CGRect(
                    x: canvasSize.width * (x - radius),
                    y: canvasSize.height * (y - radius),
                    width: canvasSize.width * radius * 2,
                    height: canvasSize.height * radius * 2
                )
                cutFill(Path(ellipseIn: rect))
            }

            switch icon {
            case .back:
                var arrow = Path()
                arrow.move(to: point(0.66, 0.20))
                arrow.addLine(to: point(0.34, 0.50))
                arrow.addLine(to: point(0.66, 0.80))
                stroke(arrow)

            case .add:
                var plus = Path()
                plus.move(to: point(0.50, 0.22))
                plus.addLine(to: point(0.50, 0.78))
                plus.move(to: point(0.22, 0.50))
                plus.addLine(to: point(0.78, 0.50))
                stroke(plus)

            case .copy:
                var back = Path()
                back.move(to: point(0.31, 0.35))
                back.addLine(to: point(0.26, 0.35))
                back.addCurve(to: point(0.20, 0.40), control1: point(0.23, 0.35), control2: point(0.20, 0.37))
                back.addLine(to: point(0.20, 0.75))
                back.addCurve(to: point(0.26, 0.81), control1: point(0.20, 0.78), control2: point(0.23, 0.81))
                back.addLine(to: point(0.61, 0.81))
                back.addCurve(to: point(0.67, 0.75), control1: point(0.64, 0.81), control2: point(0.67, 0.78))
                back.addLine(to: point(0.67, 0.70))
                stroke(back)

                let front = Path(roundedRect: CGRect(
                    x: canvasSize.width * 0.35,
                    y: canvasSize.height * 0.19,
                    width: canvasSize.width * 0.45,
                    height: canvasSize.height * 0.45
                ), cornerRadius: canvasSize.width * 0.06)
                stroke(front)

            case .save:
                let ring = Path(ellipseIn: CGRect(
                    x: canvasSize.width * 0.18,
                    y: canvasSize.height * 0.18,
                    width: canvasSize.width * 0.64,
                    height: canvasSize.height * 0.64
                ))
                fill(ring, opacity: 0.06)
                stroke(ring)
                var check = Path()
                check.move(to: point(0.34, 0.52))
                check.addLine(to: point(0.46, 0.64))
                check.addLine(to: point(0.68, 0.40))
                stroke(check, fine: true)

            case .share:
                var tray = Path()
                tray.move(to: point(0.24, 0.56))
                tray.addLine(to: point(0.24, 0.78))
                tray.addLine(to: point(0.76, 0.78))
                tray.addLine(to: point(0.76, 0.56))
                stroke(tray)
                var arrow = Path()
                arrow.move(to: point(0.50, 0.64))
                arrow.addLine(to: point(0.50, 0.20))
                arrow.move(to: point(0.34, 0.36))
                arrow.addLine(to: point(0.50, 0.20))
                arrow.addLine(to: point(0.66, 0.36))
                stroke(arrow)

            case .home:
                var roof = Path()
                roof.move(to: point(0.18, 0.48))
                roof.addLine(to: point(0.50, 0.20))
                roof.addLine(to: point(0.82, 0.48))
                stroke(roof)

                let body = Path(roundedRect: CGRect(
                    x: canvasSize.width * 0.28,
                    y: canvasSize.height * 0.44,
                    width: canvasSize.width * 0.44,
                    height: canvasSize.height * 0.38
                ), cornerRadius: canvasSize.width * 0.06)
                fill(body)
                stroke(body)

                var door = Path()
                door.move(to: point(0.50, 0.82))
                door.addLine(to: point(0.50, 0.64))
                stroke(door, fine: true)

            case .settings:
                let center = Path(ellipseIn: CGRect(
                    x: canvasSize.width * 0.30,
                    y: canvasSize.height * 0.30,
                    width: canvasSize.width * 0.40,
                    height: canvasSize.height * 0.40
                ))
                if isSelected {
                    let outer = Path(ellipseIn: CGRect(
                        x: canvasSize.width * 0.21,
                        y: canvasSize.height * 0.21,
                        width: canvasSize.width * 0.58,
                        height: canvasSize.height * 0.58
                    ))
                    solid(outer)
                    for (x, y) in [(0.50, 0.16), (0.50, 0.84), (0.16, 0.50), (0.84, 0.50)] {
                        cutCircle(x, y, 0.055)
                    }
                    cutFill(center)
                } else {
                    let outer = Path(ellipseIn: CGRect(
                        x: canvasSize.width * 0.22,
                        y: canvasSize.height * 0.22,
                        width: canvasSize.width * 0.56,
                        height: canvasSize.height * 0.56
                    ))
                    stroke(outer)
                    stroke(center)
                    for (start, end) in [
                        (point(0.50, 0.14), point(0.50, 0.22)),
                        (point(0.50, 0.78), point(0.50, 0.86)),
                        (point(0.14, 0.50), point(0.22, 0.50)),
                        (point(0.78, 0.50), point(0.86, 0.50))
                    ] {
                        var tooth = Path()
                        tooth.move(to: start)
                        tooth.addLine(to: end)
                        stroke(tooth)
                    }
                }

            case .toolbox:
                let box = Path(roundedRect: CGRect(
                    x: canvasSize.width * 0.18,
                    y: canvasSize.height * 0.34,
                    width: canvasSize.width * 0.64,
                    height: canvasSize.height * 0.42
                ), cornerRadius: canvasSize.width * 0.07)
                fill(box)
                stroke(box)

                var handle = Path()
                handle.move(to: point(0.38, 0.34))
                handle.addLine(to: point(0.38, 0.24))
                handle.addLine(to: point(0.62, 0.24))
                handle.addLine(to: point(0.62, 0.34))
                stroke(handle, fine: true)

                var seam = Path()
                seam.move(to: point(0.18, 0.52))
                seam.addLine(to: point(0.82, 0.52))
                stroke(seam, fine: true)

                var loaf = Path()
                loaf.move(to: point(0.40, 0.66))
                loaf.addCurve(to: point(0.60, 0.66), control1: point(0.42, 0.55), control2: point(0.58, 0.55))
                loaf.addQuadCurve(to: point(0.50, 0.72), control: point(0.57, 0.75))
                loaf.addQuadCurve(to: point(0.40, 0.66), control: point(0.43, 0.75))
                fill(loaf, opacity: 0.12)
                stroke(loaf, fine: true)

            case .recipe:
                let cover = Path(roundedRect: CGRect(x: canvasSize.width * 0.28, y: canvasSize.height * 0.18, width: canvasSize.width * 0.48, height: canvasSize.height * 0.64), cornerRadius: canvasSize.width * 0.07)
                if isSelected {
                    solid(cover)
                } else {
                    stroke(cover)
                }
                var binding = Path()
                binding.move(to: point(0.41, 0.28))
                binding.addLine(to: point(0.41, 0.72))
                if isSelected {
                    cut(binding)
                } else {
                    stroke(binding)
                }

                var line = Path()
                line.move(to: point(0.53, 0.45))
                line.addLine(to: point(0.64, 0.45))
                if isSelected {
                    cut(line, fine: true)
                } else {
                    stroke(line, fine: true)
                }

            case .recipeToast:
                var toast = Path()
                toast.move(to: point(0.28, 0.78))
                toast.addLine(to: point(0.28, 0.40))
                toast.addCurve(to: point(0.50, 0.22), control1: point(0.28, 0.28), control2: point(0.38, 0.22))
                toast.addCurve(to: point(0.72, 0.40), control1: point(0.62, 0.22), control2: point(0.72, 0.28))
                toast.addLine(to: point(0.72, 0.78))
                toast.closeSubpath()
                stroke(toast)

                var crumb = Path()
                crumb.move(to: point(0.42, 0.50))
                crumb.addLine(to: point(0.58, 0.50))
                crumb.move(to: point(0.42, 0.62))
                crumb.addLine(to: point(0.54, 0.62))
                stroke(crumb, fine: true)

            case .recipeCake:
                let cake = Path(roundedRect: CGRect(
                    x: canvasSize.width * 0.24,
                    y: canvasSize.height * 0.42,
                    width: canvasSize.width * 0.52,
                    height: canvasSize.height * 0.34
                ), cornerRadius: canvasSize.width * 0.055)
                stroke(cake)

                var top = Path()
                top.move(to: point(0.28, 0.42))
                top.addCurve(to: point(0.50, 0.33), control1: point(0.34, 0.36), control2: point(0.42, 0.33))
                top.addCurve(to: point(0.72, 0.42), control1: point(0.58, 0.33), control2: point(0.66, 0.36))
                stroke(top)

                var candle = Path()
                candle.move(to: point(0.50, 0.24))
                candle.addLine(to: point(0.50, 0.32))
                candle.move(to: point(0.46, 0.24))
                candle.addQuadCurve(to: point(0.50, 0.17), control: point(0.49, 0.20))
                candle.addQuadCurve(to: point(0.54, 0.24), control: point(0.53, 0.20))
                stroke(candle, fine: true)

                var layer = Path()
                layer.move(to: point(0.31, 0.58))
                layer.addLine(to: point(0.69, 0.58))
                stroke(layer, fine: true)

            case .recipeCountryBread:
                var boule = Path()
                boule.move(to: point(0.22, 0.64))
                boule.addCurve(to: point(0.78, 0.64), control1: point(0.26, 0.27), control2: point(0.74, 0.27))
                boule.addCurve(to: point(0.50, 0.79), control1: point(0.75, 0.77), control2: point(0.62, 0.82))
                boule.addCurve(to: point(0.22, 0.64), control1: point(0.38, 0.82), control2: point(0.25, 0.77))
                stroke(boule)

                var score = Path()
                score.move(to: point(0.38, 0.55))
                score.addQuadCurve(to: point(0.50, 0.42), control: point(0.43, 0.45))
                score.move(to: point(0.52, 0.56))
                score.addQuadCurve(to: point(0.64, 0.44), control: point(0.57, 0.46))
                stroke(score, fine: true)

            case .recipeCustom:
                let card = Path(roundedRect: CGRect(x: canvasSize.width * 0.22, y: canvasSize.height * 0.18, width: canvasSize.width * 0.56, height: canvasSize.height * 0.64), cornerRadius: canvasSize.width * 0.08)
                fill(card)
                stroke(card)
                var sparkle = Path()
                sparkle.move(to: point(0.50, 0.30))
                sparkle.addLine(to: point(0.50, 0.50))
                sparkle.move(to: point(0.40, 0.40))
                sparkle.addLine(to: point(0.60, 0.40))
                stroke(sparkle, fine: true)
                var line = Path()
                line.move(to: point(0.36, 0.62))
                line.addLine(to: point(0.64, 0.62))
                stroke(line, fine: true)

            case .filterAll:
                for (x, y) in [(0.34, 0.34), (0.66, 0.34), (0.34, 0.66), (0.66, 0.66)] {
                    let tile = Path(roundedRect: CGRect(
                        x: canvasSize.width * (x - 0.09),
                        y: canvasSize.height * (y - 0.09),
                        width: canvasSize.width * 0.18,
                        height: canvasSize.height * 0.18
                    ), cornerRadius: canvasSize.width * 0.04)
                    fill(tile, opacity: 0.10)
                    stroke(tile, fine: true)
                }

            case .modifiedSort:
                var up = Path()
                up.move(to: point(0.36, 0.72))
                up.addLine(to: point(0.36, 0.28))
                up.move(to: point(0.24, 0.40))
                up.addLine(to: point(0.36, 0.28))
                up.addLine(to: point(0.48, 0.40))
                stroke(up, fine: true)

                var down = Path()
                down.move(to: point(0.64, 0.28))
                down.addLine(to: point(0.64, 0.72))
                down.move(to: point(0.52, 0.60))
                down.addLine(to: point(0.64, 0.72))
                down.addLine(to: point(0.76, 0.60))
                stroke(down, fine: true)

            case .sortNewest:
                var arrow = Path()
                arrow.move(to: point(0.50, 0.22))
                arrow.addLine(to: point(0.50, 0.78))
                arrow.move(to: point(0.34, 0.62))
                arrow.addLine(to: point(0.50, 0.78))
                arrow.addLine(to: point(0.66, 0.62))
                stroke(arrow)
                for (index, width) in [0.44, 0.32, 0.20].enumerated() {
                    let y = 0.28 + CGFloat(index) * 0.12
                    var line = Path()
                    line.move(to: point(0.28, y))
                    line.addLine(to: point(0.28 + width, y))
                    stroke(line, fine: true)
                }

            case .sortOldest:
                var arrow = Path()
                arrow.move(to: point(0.50, 0.78))
                arrow.addLine(to: point(0.50, 0.22))
                arrow.move(to: point(0.34, 0.38))
                arrow.addLine(to: point(0.50, 0.22))
                arrow.addLine(to: point(0.66, 0.38))
                stroke(arrow)
                for (index, width) in [0.20, 0.32, 0.44].enumerated() {
                    let y = 0.48 + CGFloat(index) * 0.12
                    var line = Path()
                    line.move(to: point(0.28, y))
                    line.addLine(to: point(0.28 + width, y))
                    stroke(line, fine: true)
                }

            case .process:
                for (index, y) in [0.32, 0.50, 0.68].enumerated() {
                    var layer = Path()
                    layer.move(to: point(0.24, y))
                    layer.addLine(to: point(0.50, y - 0.11))
                    layer.addLine(to: point(0.76, y))
                    layer.addLine(to: point(0.50, y + 0.11))
                    layer.closeSubpath()
                    if isSelected {
                        if index == 1 {
                            solid(layer)
                        } else {
                            fill(layer, opacity: 0.58)
                        }
                    } else {
                        stroke(layer)
                    }
                }

            case .start:
                let ring = Path(ellipseIn: CGRect(x: canvasSize.width * 0.16, y: canvasSize.height * 0.16, width: canvasSize.width * 0.68, height: canvasSize.height * 0.68))
                fill(ring)
                stroke(ring)
                var play = Path()
                play.move(to: point(0.43, 0.36))
                play.addLine(to: point(0.67, 0.50))
                play.addLine(to: point(0.43, 0.64))
                play.closeSubpath()
                context.fill(play, with: .color(color))

            case .preview:
                if isSelected {
                    let lens = Path(ellipseIn: CGRect(
                        x: canvasSize.width * 0.24,
                        y: canvasSize.height * 0.22,
                        width: canvasSize.width * 0.42,
                        height: canvasSize.height * 0.42
                    ))
                    solid(lens)
                    var handle = Path()
                    handle.move(to: point(0.62, 0.62))
                    handle.addLine(to: point(0.78, 0.78))
                    stroke(handle)
                } else {
                    let sheet = Path(roundedRect: CGRect(x: canvasSize.width * 0.22, y: canvasSize.height * 0.18, width: canvasSize.width * 0.40, height: canvasSize.height * 0.58), cornerRadius: canvasSize.width * 0.06)
                    fill(sheet, opacity: 0.12)
                    stroke(sheet)
                    circle(0.66, 0.64, 0.14)
                    var handle = Path()
                    handle.move(to: point(0.76, 0.74))
                    handle.addLine(to: point(0.84, 0.82))
                    stroke(handle)
                }

            case .flour:
                var stem = Path()
                stem.move(to: point(0.5, 0.82))
                stem.addLine(to: point(0.5, 0.22))
                stroke(stem)
                for (x1, y1, x2, y2) in [(0.50, 0.34, 0.28, 0.24), (0.50, 0.46, 0.73, 0.36), (0.50, 0.58, 0.29, 0.50), (0.50, 0.70, 0.72, 0.62)] {
                    var leaf = Path()
                    leaf.move(to: point(x1, y1))
                    leaf.addQuadCurve(to: point(x2, y2), control: point((x1 + x2) / 2, y2 - 0.13))
                    leaf.addQuadCurve(to: point(x1, y1), control: point((x1 + x2) / 2, y1 + 0.10))
                    fill(leaf)
                    stroke(leaf, fine: true)
                }

            case .starter:
                let jar = Path(roundedRect: CGRect(
                    x: canvasSize.width * 0.29,
                    y: canvasSize.height * 0.22,
                    width: canvasSize.width * 0.46,
                    height: canvasSize.height * 0.60
                ), cornerRadius: canvasSize.width * 0.09)
                if isSelected {
                    solid(jar)
                } else {
                    fill(jar, opacity: 0.08)
                    stroke(jar)
                }

                var rim = Path()
                rim.move(to: point(0.36, 0.32))
                rim.addLine(to: point(0.68, 0.32))
                if isSelected {
                    cut(rim)
                } else {
                    stroke(rim)
                }

                var fillLine = Path()
                fillLine.move(to: point(0.37, 0.58))
                fillLine.addLine(to: point(0.67, 0.58))
                if isSelected {
                    cut(fillLine)
                } else {
                    stroke(fillLine)
                    circle(0.50, 0.45, 0.04)
                }

            case .water:
                var drop = Path()
                drop.move(to: point(0.50, 0.15))
                drop.addCurve(to: point(0.25, 0.56), control1: point(0.37, 0.30), control2: point(0.25, 0.42))
                drop.addCurve(to: point(0.50, 0.84), control1: point(0.25, 0.74), control2: point(0.38, 0.84))
                drop.addCurve(to: point(0.75, 0.56), control1: point(0.62, 0.84), control2: point(0.75, 0.74))
                drop.addCurve(to: point(0.50, 0.15), control1: point(0.75, 0.42), control2: point(0.63, 0.30))
                fill(drop)
                stroke(drop)

            case .salt:
                var crystalA = Path()
                crystalA.move(to: point(0.50, 0.20))
                crystalA.addLine(to: point(0.70, 0.40))
                crystalA.addLine(to: point(0.50, 0.60))
                crystalA.addLine(to: point(0.30, 0.40))
                crystalA.closeSubpath()
                fill(crystalA)
                stroke(crystalA, fine: true)

                var crystalB = Path()
                crystalB.move(to: point(0.33, 0.54))
                crystalB.addLine(to: point(0.46, 0.67))
                crystalB.addLine(to: point(0.33, 0.80))
                crystalB.addLine(to: point(0.20, 0.67))
                crystalB.closeSubpath()
                fill(crystalB)
                stroke(crystalB, fine: true)

                var crystalC = Path()
                crystalC.move(to: point(0.67, 0.54))
                crystalC.addLine(to: point(0.80, 0.67))
                crystalC.addLine(to: point(0.67, 0.80))
                crystalC.addLine(to: point(0.54, 0.67))
                crystalC.closeSubpath()
                fill(crystalC)
                stroke(crystalC, fine: true)

            case .sugar:
                for point in [(0.34, 0.35), (0.52, 0.30), (0.67, 0.43), (0.43, 0.55), (0.62, 0.66), (0.30, 0.70)] {
                    circle(point.0, point.1, 0.055)
                }

            case .butter:
                let block = Path(roundedRect: CGRect(x: canvasSize.width * 0.23, y: canvasSize.height * 0.32, width: canvasSize.width * 0.56, height: canvasSize.height * 0.38), cornerRadius: canvasSize.width * 0.06)
                fill(block)
                stroke(block)
                var cut = Path()
                cut.move(to: point(0.36, 0.33))
                cut.addLine(to: point(0.52, 0.69))
                stroke(cut, fine: true)

            case .yeast:
                circle(0.38, 0.40, 0.12)
                circle(0.60, 0.43, 0.10)
                circle(0.50, 0.63, 0.13)
                circle(0.70, 0.66, 0.055, filled: true)
                circle(0.28, 0.65, 0.045, filled: true)

            case .egg:
                var egg = Path()
                egg.move(to: point(0.50, 0.17))
                egg.addCurve(to: point(0.25, 0.58), control1: point(0.34, 0.22), control2: point(0.25, 0.40))
                egg.addCurve(to: point(0.50, 0.85), control1: point(0.25, 0.76), control2: point(0.37, 0.85))
                egg.addCurve(to: point(0.75, 0.58), control1: point(0.63, 0.85), control2: point(0.75, 0.76))
                egg.addCurve(to: point(0.50, 0.17), control1: point(0.75, 0.40), control2: point(0.66, 0.22))
                fill(egg)
                stroke(egg)

            case .other:
                var seal = Path()
                seal.move(to: point(0.50, 0.16))
                for index in 0..<8 {
                    let angle = CGFloat(index) * .pi / 4
                    let radius: CGFloat = index.isMultiple(of: 2) ? 0.34 : 0.24
                    seal.addLine(to: point(0.50 + cos(angle) * radius, 0.50 + sin(angle) * radius))
                }
                seal.closeSubpath()
                fill(seal)
                stroke(seal, fine: true)

            case .prep:
                var bowl = Path()
                bowl.move(to: point(0.22, 0.44))
                bowl.addQuadCurve(to: point(0.78, 0.44), control: point(0.50, 0.54))
                bowl.addQuadCurve(to: point(0.50, 0.78), control: point(0.70, 0.78))
                bowl.addQuadCurve(to: point(0.22, 0.44), control: point(0.30, 0.78))
                fill(bowl)
                stroke(bowl)
                var spoon = Path()
                spoon.move(to: point(0.64, 0.20))
                spoon.addLine(to: point(0.44, 0.56))
                stroke(spoon)

            case .mixing:
                var whisk = Path()
                whisk.move(to: point(0.50, 0.18))
                whisk.addLine(to: point(0.50, 0.82))
                whisk.move(to: point(0.50, 0.30))
                whisk.addCurve(to: point(0.32, 0.56), control1: point(0.32, 0.34), control2: point(0.28, 0.47))
                whisk.addCurve(to: point(0.50, 0.68), control1: point(0.36, 0.64), control2: point(0.44, 0.68))
                whisk.addCurve(to: point(0.68, 0.56), control1: point(0.56, 0.68), control2: point(0.64, 0.64))
                whisk.addCurve(to: point(0.50, 0.30), control1: point(0.72, 0.47), control2: point(0.68, 0.34))
                stroke(whisk)

            case .fermentation:
                var dome = Path()
                dome.move(to: point(0.20, 0.68))
                dome.addCurve(to: point(0.80, 0.68), control1: point(0.28, 0.30), control2: point(0.72, 0.30))
                dome.addLine(to: point(0.20, 0.68))
                fill(dome)
                stroke(dome)
                circle(0.40, 0.52, 0.035, filled: true)
                circle(0.56, 0.45, 0.03, filled: true)
                circle(0.61, 0.58, 0.025, filled: true)

            case .rest:
                var pause = Path()
                pause.move(to: point(0.40, 0.28))
                pause.addLine(to: point(0.40, 0.72))
                pause.move(to: point(0.60, 0.28))
                pause.addLine(to: point(0.60, 0.72))
                stroke(pause)
                var plate = Path()
                plate.move(to: point(0.24, 0.78))
                plate.addLine(to: point(0.76, 0.78))
                stroke(plate, fine: true)

            case .shaping:
                var hand = Path()
                hand.move(to: point(0.26, 0.58))
                hand.addCurve(to: point(0.49, 0.75), control1: point(0.34, 0.76), control2: point(0.42, 0.78))
                hand.addCurve(to: point(0.74, 0.48), control1: point(0.60, 0.70), control2: point(0.70, 0.60))
                hand.addLine(to: point(0.64, 0.38))
                hand.addLine(to: point(0.50, 0.54))
                hand.addLine(to: point(0.40, 0.42))
                hand.addLine(to: point(0.26, 0.58))
                fill(hand)
                stroke(hand)

            case .baking:
                let oven = Path(roundedRect: CGRect(x: canvasSize.width * 0.20, y: canvasSize.height * 0.24, width: canvasSize.width * 0.60, height: canvasSize.height * 0.52), cornerRadius: canvasSize.width * 0.07)
                fill(oven)
                stroke(oven)
                var rack = Path()
                rack.move(to: point(0.30, 0.53))
                rack.addLine(to: point(0.70, 0.53))
                rack.move(to: point(0.33, 0.63))
                rack.addLine(to: point(0.67, 0.63))
                stroke(rack, fine: true)
                circle(0.66, 0.34, 0.035, filled: true)

            case .bakes:
                let oven = Path(roundedRect: CGRect(x: canvasSize.width * 0.20, y: canvasSize.height * 0.28, width: canvasSize.width * 0.60, height: canvasSize.height * 0.42), cornerRadius: canvasSize.width * 0.09)
                if isSelected {
                    solid(oven)
                } else {
                    stroke(oven)
                }

                var window = Path()
                window.move(to: point(0.32, 0.56))
                window.addLine(to: point(0.68, 0.56))
                if isSelected {
                    cut(window)
                } else {
                    stroke(window)
                }

            case .bakeHistory:
                let backCard = Path(roundedRect: CGRect(x: canvasSize.width * 0.30, y: canvasSize.height * 0.18, width: canvasSize.width * 0.44, height: canvasSize.height * 0.56), cornerRadius: canvasSize.width * 0.07)
                stroke(backCard, fine: true)

                let card = Path(roundedRect: CGRect(x: canvasSize.width * 0.22, y: canvasSize.height * 0.26, width: canvasSize.width * 0.52, height: canvasSize.height * 0.56), cornerRadius: canvasSize.width * 0.08)
                fill(card)
                stroke(card)

                var loaf = Path()
                loaf.move(to: point(0.32, 0.54))
                loaf.addCurve(to: point(0.64, 0.54), control1: point(0.35, 0.34), control2: point(0.61, 0.34))
                loaf.addQuadCurve(to: point(0.48, 0.62), control: point(0.58, 0.66))
                loaf.addQuadCurve(to: point(0.32, 0.54), control: point(0.38, 0.66))
                fill(loaf, opacity: 0.10)
                stroke(loaf, fine: true)

                var score = Path()
                score.move(to: point(0.44, 0.50))
                score.addQuadCurve(to: point(0.54, 0.42), control: point(0.48, 0.43))
                stroke(score, fine: true)

                for y in [0.68, 0.76] {
                    var line = Path()
                    line.move(to: point(0.34, y))
                    line.addLine(to: point(0.62, y))
                    stroke(line, fine: true)
                }

            case .timer:
                let timer = Path(ellipseIn: CGRect(x: canvasSize.width * 0.22, y: canvasSize.height * 0.25, width: canvasSize.width * 0.56, height: canvasSize.height * 0.56))
                fill(timer)
                stroke(timer)
                var hand = Path()
                hand.move(to: point(0.50, 0.53))
                hand.addLine(to: point(0.50, 0.38))
                hand.addLine(to: point(0.62, 0.58))
                stroke(hand, fine: true)
                var top = Path()
                top.move(to: point(0.42, 0.16))
                top.addLine(to: point(0.58, 0.16))
                stroke(top)

            case .complete:
                let badge = Path(ellipseIn: CGRect(x: canvasSize.width * 0.18, y: canvasSize.height * 0.18, width: canvasSize.width * 0.64, height: canvasSize.height * 0.64))
                fill(badge)
                stroke(badge)
                var check = Path()
                check.move(to: point(0.34, 0.52))
                check.addLine(to: point(0.46, 0.64))
                check.addLine(to: point(0.68, 0.38))
                stroke(check)

            case .edit:
                let page = Path(roundedRect: CGRect(x: canvasSize.width * 0.24, y: canvasSize.height * 0.18, width: canvasSize.width * 0.44, height: canvasSize.height * 0.58), cornerRadius: canvasSize.width * 0.06)
                fill(page)
                stroke(page)
                var pencil = Path()
                pencil.move(to: point(0.43, 0.64))
                pencil.addLine(to: point(0.73, 0.34))
                pencil.addLine(to: point(0.80, 0.41))
                pencil.addLine(to: point(0.50, 0.71))
                pencil.addLine(to: point(0.38, 0.75))
                pencil.closeSubpath()
                context.fill(pencil, with: .color(color.opacity(0.16)))
                stroke(pencil, fine: true)
                var line = Path()
                line.move(to: point(0.34, 0.35))
                line.addLine(to: point(0.52, 0.35))
                line.move(to: point(0.34, 0.48))
                line.addLine(to: point(0.46, 0.48))
                stroke(line, fine: true)

            case .delete:
                let bin = Path(roundedRect: CGRect(
                    x: canvasSize.width * 0.28,
                    y: canvasSize.height * 0.32,
                    width: canvasSize.width * 0.44,
                    height: canvasSize.height * 0.52
                ), cornerRadius: canvasSize.width * 0.05)
                fill(bin)
                stroke(bin)

                var lid = Path()
                lid.move(to: point(0.22, 0.28))
                lid.addLine(to: point(0.78, 0.28))
                lid.move(to: point(0.40, 0.20))
                lid.addLine(to: point(0.60, 0.20))
                lid.move(to: point(0.44, 0.20))
                lid.addLine(to: point(0.40, 0.28))
                lid.move(to: point(0.56, 0.20))
                lid.addLine(to: point(0.60, 0.28))
                stroke(lid)

                var slats = Path()
                slats.move(to: point(0.42, 0.43))
                slats.addLine(to: point(0.42, 0.74))
                slats.move(to: point(0.58, 0.43))
                slats.addLine(to: point(0.58, 0.74))
                stroke(slats, fine: true)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct BakingToolbarIconButton: View {
    let icon: BakingIcon
    let accessibilityLabel: String

    var body: some View {
        BakingIconButtonLabel(icon: icon, role: .primary, size: .primary)
            .accessibilityLabel(accessibilityLabel)
    }
}
