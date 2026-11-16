//
//  LaunchSplash.swift
//  IFApp
//

import SwiftUI

struct LaunchSplash: View {
    let target: CGRect?
    let onFinish: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var time: Double = 0

    var body: some View {
        let timing = reduceMotion ? SplashTiming.still : SplashTiming.drawn
        SplashFrame(time: time, timing: timing, target: target, palette: SplashPalette(colorScheme))
            .ignoresSafeArea()
            .environment(\.layoutDirection, .leftToRight)
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(.linear(duration: timing.total)) {
                    time = timing.total
                } completion: {
                    onFinish()
                }
            }
    }
}

private struct SplashTiming {
    let isDrawn: Bool
    let draw: Double
    let hold: Double
    let exit: Double

    var total: Double { draw + hold + exit }

    static let drawn = SplashTiming(isDrawn: true, draw: 2.0, hold: 0.4, exit: 0.4)
    static let still = SplashTiming(isDrawn: false, draw: 0.3, hold: 0.4, exit: 0.3)
}

private struct SplashPalette {
    let duskTop: Color
    let duskBottom: Color

    init(_ scheme: ColorScheme) {
        if scheme == .dark {
            duskTop = Color(hex: "#18202D")
            duskBottom = Color(hex: "#262431")
        } else {
            duskTop = Color(hex: "#C9CFD8")
            duskBottom = Color(hex: "#EFE6D6")
        }
    }

    let launch = Color("LaunchDusk")
    let day = Color("LaunchBackground")
    let dot = Color(hex: "#CEDB6B")

    static let ring = Gradient(colors: [
        "#F8F3D3", "#FBF5D6", "#FCF4D7", "#FBF4D6", "#FAF0CF", "#F9ECBB", "#F8E8A1", "#F7E48A", "#F6E17D",
        "#F6E17A", "#F5E07D", "#EEE07C", "#E5DE7D", "#DBDE7D", "#D2DD7E", "#C8DD7E", "#BFDC7F", "#BCDD95",
        "#B7E3B9", "#AFE8D6", "#A6ECE4", "#A3EFE8", "#A3EDE5", "#A7EDDF", "#B1EBD2", "#BBE8C2", "#C3E7B3",
        "#C7E6AA", "#C7E5A9", "#C8E5A8", "#C8E5A8", "#C7E5A9", "#CCE6AD", "#D6E9B5", "#E4EDC2", "#F0F1CD",
        "#F8F3D3",
    ].map { Color(hex: $0) })
}

private struct SplashFrame: View, Animatable {
    var time: Double
    let timing: SplashTiming
    let target: CGRect?
    let palette: SplashPalette

    var animatableData: Double {
        get { time }
        set { time = newValue }
    }

    private static let innerRadius = 115.8
    private static let outerRadius = 145.2
    private static let midRadius = (innerRadius + outerRadius) / 2
    private static let dotRadius = 28.2
    private static let gapRadius = dotRadius * 1.42
    private static let dotOrbit = 127.0
    private static let screenShare = 150.0 / 720.0
    private static let launchDuskFade = 0.25
    private static let startAngle = -Double.pi / 2
    private static let endAngle = atan2(61.67 - 148, 241.17 - 148)
    private static let sweep = endAngle - startAngle + 2 * .pi

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let drawProgress = min(time / timing.draw, 1)
        let exitProgress = ease(min(max((time - timing.draw - timing.hold) / timing.exit, 0), 1))

        let headAngle: Double
        let traveled: Double
        let dayShare: Double
        let logoOpacity: Double
        let dotOpacity: Double
        if timing.isDrawn {
            let eased = ease(drawProgress)
            headAngle = Self.startAngle + Self.sweep * eased
            traveled = min(Self.sweep * eased, 2 * .pi - 0.001)
            dayShare = min(1, drawProgress * 1.15)
            logoOpacity = 1
            dotOpacity = min(1, drawProgress / 0.08)
        } else {
            headAngle = Self.endAngle
            traveled = 2 * .pi
            dayShare = drawProgress
            logoOpacity = drawProgress
            dotOpacity = 1
        }

        let bounds = CGRect(origin: .zero, size: size)
        var background = context
        background.opacity = 1 - exitProgress
        background.fill(Path(bounds), with: .linearGradient(
            Gradient(colors: [palette.duskTop, palette.duskBottom]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        background.fill(Path(bounds), with: .color(palette.day.opacity(dayShare)))
        background.fill(Path(bounds), with: .color(palette.launch.opacity(1 - min(1, time / Self.launchDuskFade))))

        let unit = size.width * Self.screenShare / Self.outerRadius
        var center = CGPoint(x: size.width / 2, y: size.height / 2)
        var scale = unit
        if timing.isDrawn, let target {
            let targetScale = target.width / 2 / Self.midRadius
            center.x += (target.midX - center.x) * exitProgress
            center.y += (target.midY - center.y) * exitProgress
            scale += (targetScale - unit) * exitProgress
        }

        var logo = context
        logo.opacity = logoOpacity * (1 - exitProgress * exitProgress)
        logo.translateBy(x: center.x, y: center.y)
        logo.scaleBy(x: scale, y: scale)

        let head = CGPoint(x: Self.dotOrbit * cos(headAngle), y: Self.dotOrbit * sin(headAngle))

        var ring = logo
        var cutout = Path(CGRect(x: -1000, y: -1000, width: 2000, height: 2000))
        cutout.addEllipse(in: circle(at: head, radius: Self.gapRadius))
        ring.clip(to: cutout, style: FillStyle(eoFill: true))
        ring.fill(band(from: headAngle - traveled, to: headAngle),
                  with: .conicGradient(SplashPalette.ring, center: .zero, angle: .degrees(180)),
                  style: FillStyle(eoFill: true))

        logo.opacity *= dotOpacity
        logo.fill(Path(ellipseIn: circle(at: head, radius: Self.dotRadius)), with: .color(palette.dot))
    }

    private func band(from start: Double, to end: Double) -> Path {
        var path = Path()
        if end - start >= 2 * .pi {
            path.addEllipse(in: circle(at: .zero, radius: Self.outerRadius))
            path.addEllipse(in: circle(at: .zero, radius: Self.innerRadius))
            return path
        }
        let steps = max(2, Int((end - start) / (.pi / 180)) + 1)
        let angles = (0...steps).map { start + (end - start) * Double($0) / Double(steps) }
        let outer = angles.map { point(at: $0, radius: Self.outerRadius) }
        let inner = angles.reversed().map { point(at: $0, radius: Self.innerRadius) }
        path.addLines(outer + inner)
        path.closeSubpath()
        return path
    }

    private func point(at angle: Double, radius: Double) -> CGPoint {
        CGPoint(x: radius * cos(angle), y: radius * sin(angle))
    }

    private func circle(at center: CGPoint, radius: Double) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }

    private func ease(_ t: Double) -> Double {
        0.5 - 0.5 * cos(.pi * t)
    }
}
