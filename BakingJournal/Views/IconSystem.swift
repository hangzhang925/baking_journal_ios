import SwiftUI

enum BakingIcon {
    case recipe
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
    case timer
    case complete
    case edit

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

    static func step(for type: StepType) -> BakingIcon {
        switch type {
        case .prep: .prep
        case .mixing: .mixing
        case .fermentation: .fermentation
        case .rest: .rest
        case .shaping: .shaping
        case .baking: .baking
        }
    }
}

struct BakingIconView: View {
    let icon: BakingIcon
    var size: CGFloat = 24
    var color: Color = .brandPrimary

    var body: some View {
        Canvas { context, canvasSize in
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

            switch icon {
            case .recipe:
                let cover = Path(roundedRect: CGRect(x: canvasSize.width * 0.23, y: canvasSize.height * 0.16, width: canvasSize.width * 0.52, height: canvasSize.height * 0.68), cornerRadius: canvasSize.width * 0.08)
                fill(cover)
                stroke(cover)
                var binding = Path()
                binding.move(to: point(0.35, 0.23))
                binding.addLine(to: point(0.35, 0.76))
                stroke(binding, fine: true)
                for y in [0.34, 0.48, 0.62] {
                    var line = Path()
                    line.move(to: point(0.45, y))
                    line.addLine(to: point(0.64, y))
                    stroke(line, fine: true)
                }

            case .process:
                for (index, y) in [0.28, 0.50, 0.72].enumerated() {
                    var layer = Path()
                    layer.move(to: point(0.22, y))
                    layer.addLine(to: point(0.50, y - 0.13))
                    layer.addLine(to: point(0.78, y))
                    layer.addLine(to: point(0.50, y + 0.13))
                    layer.closeSubpath()
                    if index == 0 { fill(layer) }
                    stroke(layer)
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
                let sheet = Path(roundedRect: CGRect(x: canvasSize.width * 0.22, y: canvasSize.height * 0.18, width: canvasSize.width * 0.44, height: canvasSize.height * 0.62), cornerRadius: canvasSize.width * 0.06)
                fill(sheet)
                stroke(sheet)
                circle(0.68, 0.66, 0.13)
                var handle = Path()
                handle.move(to: point(0.77, 0.75))
                handle.addLine(to: point(0.86, 0.84))
                stroke(handle)

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
                let jar = Path(roundedRect: CGRect(x: canvasSize.width * 0.28, y: canvasSize.height * 0.22, width: canvasSize.width * 0.44, height: canvasSize.height * 0.58), cornerRadius: canvasSize.width * 0.08)
                fill(jar)
                stroke(jar)
                var lid = Path()
                lid.move(to: point(0.34, 0.20))
                lid.addLine(to: point(0.66, 0.20))
                stroke(lid)
                var wave = Path()
                wave.move(to: point(0.33, 0.52))
                wave.addQuadCurve(to: point(0.50, 0.52), control: point(0.41, 0.44))
                wave.addQuadCurve(to: point(0.67, 0.52), control: point(0.59, 0.60))
                stroke(wave, fine: true)
                circle(0.43, 0.64, 0.035, filled: true)
                circle(0.58, 0.64, 0.028, filled: true)

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
        ZStack {
            Circle()
                .fill(Color.brandPrimary.opacity(0.11))
            BakingIconView(icon: icon, size: 23, color: .brandPrimary)
        }
        .frame(width: 38, height: 38)
        .contentShape(Circle())
        .accessibilityLabel(accessibilityLabel)
    }
}
