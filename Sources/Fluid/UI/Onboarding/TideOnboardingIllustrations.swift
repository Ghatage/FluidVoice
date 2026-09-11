import SwiftUI

struct TideWelcomeIllustration: View {
    let theme: AppTheme

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 260, y: size.height / 300)

            context.stroke(
                Self.topBubble,
                with: .color(self.theme.tide.accent),
                style: StrokeStyle(lineWidth: 7, lineJoin: .round)
            )
            context.stroke(
                Self.topSquiggleOne,
                with: .color(self.theme.tide.text),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
            context.stroke(
                Self.topSquiggleTwo,
                with: .color(self.theme.tide.text),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
            context.stroke(
                Self.bottomBubble,
                with: .color(self.theme.tide.accent2),
                style: StrokeStyle(lineWidth: 7, lineJoin: .round)
            )
            context.stroke(
                Self.bottomSquiggleOne,
                with: .color(self.theme.tide.text),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
            context.stroke(
                Self.bottomSquiggleTwo,
                with: .color(self.theme.tide.text),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
        }
        .frame(width: 190, height: 220)
        .accessibilityHidden(true)
    }

    private static let topBubble: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 34, y: 60))
        path.addCurve(to: CGPoint(x: 70, y: 24), control1: CGPoint(x: 34, y: 40), control2: CGPoint(x: 50, y: 24))
        path.addLine(to: CGPoint(x: 190, y: 24))
        path.addCurve(to: CGPoint(x: 226, y: 60), control1: CGPoint(x: 210, y: 24), control2: CGPoint(x: 226, y: 40))
        path.addLine(to: CGPoint(x: 226, y: 104))
        path.addCurve(to: CGPoint(x: 190, y: 140), control1: CGPoint(x: 226, y: 124), control2: CGPoint(x: 210, y: 140))
        path.addLine(to: CGPoint(x: 104, y: 140))
        path.addLine(to: CGPoint(x: 74, y: 168))
        path.addLine(to: CGPoint(x: 80, y: 140))
        path.addCurve(to: CGPoint(x: 34, y: 104), control1: CGPoint(x: 52, y: 140), control2: CGPoint(x: 34, y: 124))
        path.closeSubpath()
        return path
    }()

    private static let bottomBubble: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 226, y: 186))
        path.addCurve(to: CGPoint(x: 190, y: 150), control1: CGPoint(x: 226, y: 166), control2: CGPoint(x: 210, y: 150))
        path.addLine(to: CGPoint(x: 70, y: 150))
        path.addCurve(to: CGPoint(x: 34, y: 186), control1: CGPoint(x: 50, y: 150), control2: CGPoint(x: 34, y: 166))
        path.addLine(to: CGPoint(x: 34, y: 230))
        path.addCurve(to: CGPoint(x: 70, y: 266), control1: CGPoint(x: 34, y: 250), control2: CGPoint(x: 50, y: 266))
        path.addLine(to: CGPoint(x: 156, y: 266))
        path.addLine(to: CGPoint(x: 186, y: 294))
        path.addLine(to: CGPoint(x: 180, y: 266))
        path.addCurve(to: CGPoint(x: 226, y: 230), control1: CGPoint(x: 208, y: 266), control2: CGPoint(x: 226, y: 250))
        path.closeSubpath()
        return path
    }()

    private static let topSquiggleOne = squiggle(start: CGPoint(x: 64, y: 66), waves: 5, amplitude: 12)
    private static let topSquiggleTwo = squiggle(start: CGPoint(x: 70, y: 90), waves: 4, amplitude: 12)
    private static let bottomSquiggleOne = squiggle(start: CGPoint(x: 60, y: 192), waves: 5, amplitude: 12)
    private static let bottomSquiggleTwo = squiggle(start: CGPoint(x: 66, y: 216), waves: 4, amplitude: 12)
}

struct TideAccessibilityIllustration: View {
    let theme: AppTheme

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 260, y: size.height / 300)

            context.stroke(
                Self.bubble,
                with: .color(self.theme.tide.accent),
                style: StrokeStyle(lineWidth: 7, lineJoin: .round)
            )
            context.stroke(Self.squiggleOne, with: .color(self.theme.tide.text), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            context.stroke(Self.squiggleTwo, with: .color(self.theme.tide.text), style: StrokeStyle(lineWidth: 5, lineCap: .round))

            let terminal = Path(roundedRect: CGRect(x: 96, y: 150, width: 150, height: 120), cornerRadius: 18)
            context.fill(terminal, with: .color(self.theme.tide.card))
            context.stroke(terminal, with: .color(self.theme.tide.line), lineWidth: 2)

            for x in [114.0, 128.0, 142.0] {
                context.fill(Path(ellipseIn: CGRect(x: x - 4, y: 164, width: 8, height: 8)), with: .color(self.theme.tide.muted))
            }
            for bar in Self.terminalBars {
                context.fill(Path(roundedRect: bar, cornerRadius: 4), with: .color(self.theme.tide.accent2))
            }
            context.fill(Path(CGRect(x: 148, y: 243, width: 3, height: 14)), with: .color(self.theme.tide.accent))
            context.stroke(
                Self.dottedArc,
                with: .color(self.theme.tide.accent2),
                style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [1, 12])
            )
        }
        .frame(width: 240, height: 280)
        .accessibilityHidden(true)
    }

    private static let bubble: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 20, y: 90))
        path.addCurve(to: CGPoint(x: 56, y: 54), control1: CGPoint(x: 20, y: 70), control2: CGPoint(x: 36, y: 54))
        path.addLine(to: CGPoint(x: 116, y: 54))
        path.addCurve(to: CGPoint(x: 152, y: 90), control1: CGPoint(x: 136, y: 54), control2: CGPoint(x: 152, y: 70))
        path.addLine(to: CGPoint(x: 152, y: 120))
        path.addCurve(to: CGPoint(x: 116, y: 156), control1: CGPoint(x: 152, y: 140), control2: CGPoint(x: 136, y: 156))
        path.addLine(to: CGPoint(x: 76, y: 156))
        path.addLine(to: CGPoint(x: 50, y: 180))
        path.addLine(to: CGPoint(x: 54, y: 156))
        path.addCurve(to: CGPoint(x: 20, y: 120), control1: CGPoint(x: 34, y: 154), control2: CGPoint(x: 20, y: 140))
        path.closeSubpath()
        return path
    }()

    private static let squiggleOne = squiggle(start: CGPoint(x: 46, y: 96), waves: 4, amplitude: 11, halfWidth: 9)
    private static let squiggleTwo = squiggle(start: CGPoint(x: 50, y: 118), waves: 3, amplitude: 11, halfWidth: 9)
    private static let terminalBars = [
        CGRect(x: 114, y: 192, width: 100, height: 8),
        CGRect(x: 114, y: 210, width: 74, height: 8),
        CGRect(x: 114, y: 228, width: 88, height: 8),
        CGRect(x: 114, y: 246, width: 30, height: 8),
    ]
    private static let dottedArc: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 150, y: 128))
        path.addCurve(to: CGPoint(x: 174, y: 170), control1: CGPoint(x: 170, y: 138), control2: CGPoint(x: 178, y: 150))
        return path
    }()
}

struct TideTryoutIllustration: View {
    let theme: AppTheme

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 260, y: size.height / 300)

            context.stroke(Self.topBubble, with: .color(self.theme.tide.accent), style: StrokeStyle(lineWidth: 7, lineJoin: .round))
            context.stroke(Self.squiggleOne, with: .color(self.theme.tide.text), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            context.stroke(Self.squiggleTwo, with: .color(self.theme.tide.text), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            context.stroke(Self.bottomBubble, with: .color(self.theme.tide.accent2), style: StrokeStyle(lineWidth: 7, lineJoin: .round))

            for bar in Self.typedBars {
                context.fill(Path(roundedRect: bar, cornerRadius: 4), with: .color(self.theme.tide.text))
            }
            context.stroke(Self.arrowStem, with: .color(self.theme.tide.muted), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            context.stroke(Self.arrowHead, with: .color(self.theme.tide.muted), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 240, height: 280)
        .accessibilityHidden(true)
    }

    private static let topBubble = bubble(originY: 12)
    private static let bottomBubble = bubble(originY: 160)
    private static let squiggleOne = squiggle(start: CGPoint(x: 64, y: 58), waves: 5, amplitude: 12)
    private static let squiggleTwo = squiggle(start: CGPoint(x: 70, y: 84), waves: 4, amplitude: 12)
    private static let typedBars = [
        CGRect(x: 64, y: 182, width: 112, height: 8),
        CGRect(x: 64, y: 202, width: 84, height: 8),
        CGRect(x: 64, y: 222, width: 96, height: 8),
        CGRect(x: 64, y: 242, width: 40, height: 8),
    ]
    private static let arrowStem: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 128, y: 130))
        path.addLine(to: CGPoint(x: 128, y: 154))
        return path
    }()
    private static let arrowHead: Path = {
        var path = Path()
        path.move(to: CGPoint(x: 118, y: 146))
        path.addLine(to: CGPoint(x: 128, y: 156))
        path.addLine(to: CGPoint(x: 138, y: 146))
        return path
    }()

    private static func bubble(originY: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 40, y: originY + 28))
        path.addCurve(to: CGPoint(x: 68, y: originY), control1: CGPoint(x: 40, y: originY + 12), control2: CGPoint(x: 52, y: originY))
        path.addLine(to: CGPoint(x: 188, y: originY))
        path.addCurve(to: CGPoint(x: 216, y: originY + 28), control1: CGPoint(x: 204, y: originY), control2: CGPoint(x: 216, y: originY + 12))
        path.addLine(to: CGPoint(x: 216, y: originY + 88))
        path.addCurve(to: CGPoint(x: 188, y: originY + 116), control1: CGPoint(x: 216, y: originY + 104), control2: CGPoint(x: 204, y: originY + 116))
        path.addLine(to: CGPoint(x: 100, y: originY + 116))
        path.addLine(to: CGPoint(x: 70, y: originY + 142))
        path.addLine(to: CGPoint(x: 74, y: originY + 116))
        path.addCurve(to: CGPoint(x: 40, y: originY + 88), control1: CGPoint(x: 54, y: originY + 116), control2: CGPoint(x: 40, y: originY + 104))
        path.closeSubpath()
        return path
    }
}

private func squiggle(
    start: CGPoint,
    waves: Int,
    amplitude: CGFloat,
    halfWidth: CGFloat = 10
) -> Path {
    var path = Path()
    path.move(to: start)
    var x = start.x
    for _ in 0..<waves {
        path.addQuadCurve(
            to: CGPoint(x: x + (halfWidth * 2), y: start.y),
            control: CGPoint(x: x + halfWidth, y: start.y - amplitude)
        )
        x += halfWidth * 2
    }
    return path
}
