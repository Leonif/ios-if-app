//
//  MealScaleRibbon.swift
//  IFApp
//
//  The last-meal scrubber: a strip of time longer than the screen, running under a
//  fixed marker. It is a real timeline, so midnights are drawn on it — which is why
//  "I ate at ten last night" is a scroll past one marked line instead of a separate
//  date control the user has to notice.
//
//  Geometry lives in `MealScale`; this file only draws it and reads the finger.
//

import SwiftUI

struct MealScaleRibbon: View {
    let minutesAgo: Int
    /// Injected clock — the midnight rules are the one part of the ribbon that is
    /// calendar-aware, and they have to know what time it is now to be placed.
    let nowMinuteOfDay: Int
    let theme: ThemeTokens
    let a11yLabel: String
    let a11yValue: String
    let onScrub: (Int) -> Void
    let onFeedback: (MealScrubFeedback) -> Void

    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Where the marker sits on the strip, in points from "now". Continuous: the
    /// strip slides under the finger while the *value* clicks from tick to tick.
    @State private var offset: CGFloat = 0
    @State private var dragAnchor: CGFloat? = nil
    @State private var reported: Int = -1
    @State private var lastHaptic: TimeInterval = 0
    @State private var wasAtEdge = false

    // Layer geometry, from the handoff. Distances are measured up from the block's
    // bottom edge, which is where the ticks stand.
    private let tickBaseline: CGFloat = 19
    private let minorHeight: CGFloat = 10
    private let hourHeight: CGFloat = 17
    private let dayHeight: CGFloat = 22
    private let dayBreakHeight: CGFloat = 28
    private let endCapHeight: CGFloat = 26
    private let dayRowTop: CGFloat = 0
    /// 43 in the table, 40 as drawn — the mockups put the label row three points
    /// higher, which is what keeps the labels clear of the tick line.
    private let labelRowTop: CGFloat = 40
    private let fadeWidth: CGFloat = 28

    private var blockHeight: CGFloat { dynamicTypeSize.isAccessibilitySize ? 68 : 60 }
    /// +1 when the past runs left (LTR), -1 when it runs right (Arabic): the ribbon
    /// mirrors with the text, so "drag back" and "read back" are the same direction.
    private var dirSign: CGFloat { layoutDirection == .rightToLeft ? -1 : 1 }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            Canvas { ctx, size in
                draw(in: ctx, size: size)
            }
            .frame(width: width, height: blockHeight)
            .overlay(marker)
            .overlay(edgeFade)
            .contentShape(Rectangle())
            .gesture(drag)
        }
        .frame(height: blockHeight)
        // The tick labels are markings, not prose: at large text sizes they would
        // collide, and everything they say is repeated in the readout above at full
        // size. The single deliberate Dynamic Type exemption in this sheet.
        .dynamicTypeSize(.large)
        .accessibilityIdentifier("meal.ribbon")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(a11yLabel)
        .accessibilityValue(a11yValue)
        // The adjustable trait comes with the action below — VoiceOver then offers
        // swipe up/down, one snap step of the current band at a time.
        .accessibilityAdjustableAction { direction in
            let step = MealScale.step(at: minutesAgo)
            let target = direction == .increment ? minutesAgo + step : minutesAgo - step
            onScrub(MealScale.snap(max(0, min(MealScale.maxMinutes, target))))
        }
        .onAppear { offset = MealScale.position(ofMinutes: minutesAgo) }
        .onChange(of: minutesAgo) { _, new in
            // Chips and the exact-time picker move the value from outside; the strip
            // rides over to meet it. Skipped mid-drag, where the finger is in charge.
            guard dragAnchor == nil else { return }
            let target = MealScale.position(ofMinutes: new)
            guard abs(target - offset) > 0.5 else { return }
            if reduceMotion {
                offset = target
            } else {
                withAnimation(.timingCurve(0.22, 0.8, 0.3, 1, duration: 0.32)) { offset = target }
            }
        }
    }

    // MARK: Gesture

    private var drag: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let anchor = dragAnchor ?? offset
                if dragAnchor == nil {
                    dragAnchor = anchor
                    // Warm the taptic engine before the first step passes, otherwise
                    // that click arrives late and the track starts ragged.
                    onFeedback(.begin)
                }
                let raw = anchor + dirSign * value.translation.width
                offset = reduceMotion ? hardStop(raw) : rubberBand(raw)
                report(fast: abs(value.velocity.width) > 900)
            }
            .onEnded { value in
                let anchor = dragAnchor ?? offset
                dragAnchor = nil
                let projected = reduceMotion
                    ? offset
                    : anchor + dirSign * value.predictedEndTranslation.width
                let settled = MealScale.position(
                    ofMinutes: MealScale.snappedMinutes(atPosition: hardStop(projected))
                )
                if reduceMotion {
                    offset = settled
                } else {
                    withAnimation(.easeOut(duration: 0.28)) { offset = settled }
                }
                report(fast: false)
            }
    }

    private func hardStop(_ p: CGFloat) -> CGFloat { max(0, min(MealScale.length, p)) }

    /// Resistance past either end, capped at 40pt of give — enough to feel the wall
    /// without letting it read as a broken scroll.
    private func rubberBand(_ p: CGFloat) -> CGFloat {
        if p < 0 { return -min(40, -p * 0.35) }
        if p > MealScale.length { return MealScale.length + min(40, (p - MealScale.length) * 0.35) }
        return p
    }

    private func report(fast: Bool) {
        let mins = MealScale.snappedMinutes(atPosition: offset)
        let atEdge = offset <= 0 || offset >= MealScale.length
        if mins != reported {
            reported = mins
            onScrub(mins)
            // No taptic queue behind a fling: above ~900pt/s the steps arrive faster
            // than the engine can separate them, and it turns into a buzz.
            let now = Date().timeIntervalSince1970
            if !fast && now - lastHaptic > 0.045 {
                lastHaptic = now
                onFeedback(.step)
            }
        }
        if atEdge && !wasAtEdge { onFeedback(.edge) }
        wasAtEdge = atEdge
    }

    // MARK: Marker

    private var marker: some View {
        let dragging = dragAnchor != nil
        // The stem stands on the tick line and is 34 tall; the dot caps it. Measured
        // off the mockups rather than off the table in §4, which puts both 4pt lower
        // and would leave the stem floating above the ticks.
        let stemBottom = blockHeight - tickBaseline
        let stemCenterY = stemBottom - 17 - blockHeight / 2
        let dotCenterY = stemBottom - 34 - blockHeight / 2
        return ZStack {
            if dragging {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.accent.opacity(theme.isDark ? 0.12 : 0.09))
                    .frame(width: 54, height: 38)
                    .offset(y: stemCenterY)
            }
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.accent)
                .frame(width: 3, height: 34)
                .offset(y: stemCenterY)
            Circle()
                .fill(theme.accent)
                .frame(width: dragging ? 12 : 10, height: dragging ? 12 : 10)
                .overlay(
                    Circle().stroke(theme.accent.opacity(0.18), lineWidth: dragging ? 5 : 0)
                )
                .offset(y: dotCenterY)
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: dragging)
        .allowsHitTesting(false)
    }

    private var edgeFade: some View {
        HStack(spacing: 0) {
            LinearGradient(colors: [theme.sheetBg, theme.sheetBg.opacity(0)],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: fadeWidth)
            Spacer(minLength: 0)
            LinearGradient(colors: [theme.sheetBg.opacity(0), theme.sheetBg],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: fadeWidth)
        }
        .allowsHitTesting(false)
    }

    // MARK: Drawing

    private func draw(in ctx: GraphicsContext, size: CGSize) {
        let center = size.width / 2
        let baselineY = size.height - tickBaseline
        // A little past the edges so a tick never pops into view mid-slide.
        let reach = size.width / 2 + MealScale.pitch * 4

        func screenX(_ position: CGFloat) -> CGFloat {
            center - dirSign * (position - offset)
        }

        let lowIdx = max(0, Int(((offset - reach) / MealScale.pitch).rounded(.down)))
        let highIdx = min(MealScale.stepMinutes.count - 1,
                          Int(((offset + reach) / MealScale.pitch).rounded(.up)))
        guard lowIdx <= highIdx else { return }

        for idx in lowIdx...highIdx {
            let minutes = MealScale.stepMinutes[idx]
            let x = screenX(CGFloat(idx) * MealScale.pitch)
            let kind = MealScale.tick(at: minutes)
            let height: CGFloat
            let width: CGFloat
            let color: Color
            switch kind {
            case .minor: height = minorHeight; width = 1; color = theme.scaleTickMinor
            case .hour: height = hourHeight; width = 1.5; color = theme.scaleTickMajor
            case .day: height = dayHeight; width = 1.5; color = theme.scaleTickMajor
            }
            ctx.fill(Path(CGRect(x: x - width / 2, y: baselineY - height, width: width, height: height)),
                     with: .color(color))

            if let label = MealScale.labelKind(at: minutes) {
                draw(label: text(for: label), at: CGPoint(x: x, y: labelRowTop + 6),
                     in: ctx, font: .hanken(11, .semibold), color: theme.sec, anchor: .center)
            }
        }

        // The hard end of the domain, drawn as a wall rather than left to fade out.
        if highIdx == MealScale.stepMinutes.count - 1 {
            let x = screenX(MealScale.length)
            ctx.fill(Path(CGRect(x: x - 1, y: baselineY - endCapHeight, width: 2, height: endCapHeight)),
                     with: .color(theme.mut))
        }

        drawDayBreaks(in: ctx, size: size, baselineY: baselineY, screenX: screenX)
    }

    private func drawDayBreaks(in ctx: GraphicsContext, size: CGSize, baselineY: CGFloat,
                               screenX: (CGFloat) -> CGFloat) {
        var daysBack = 1
        while true {
            // Local midnight `daysBack - 1` days ago, expressed as a distance.
            let minutes = nowMinuteOfDay + (daysBack - 1) * 1440
            if minutes > MealScale.maxMinutes { break }
            guard minutes > 0 else { daysBack += 1; continue }
            let x = screenX(MealScale.position(ofMinutes: minutes))
            if x > -80 && x < size.width + 80 {
                ctx.fill(
                    Path(CGRect(x: x - 0.75, y: baselineY - dayBreakHeight, width: 1.5, height: dayBreakHeight)),
                    with: .color(theme.scaleTickDayBreak)
                )
                // The name sits on the older side of the rule — it labels the day the
                // rule opens, which in a right-to-left layout is the other side.
                draw(label: MealMath.shortDayLabel(daysAgo: daysBack),
                     at: CGPoint(x: x - dirSign * 5, y: dayRowTop + 7),
                     in: ctx, font: .hanken(10.5, .bold), color: theme.deep,
                     anchor: dirSign > 0 ? .trailing : .leading)
            }
            daysBack += 1
        }
    }

    private func text(for kind: MealScale.LabelKind) -> String {
        switch kind {
        case .now: return strings.Meal.now
        case let .hours(h): return strings.Meal.scaleTickHours(h)
        case let .days(d): return strings.Meal.scaleTickDays(d)
        }
    }

    private func draw(label: String, at point: CGPoint, in ctx: GraphicsContext,
                      font: Font, color: Color, anchor: UnitPoint) {
        var resolved = ctx.resolve(Text(label).font(font))
        resolved.shading = .color(color)
        ctx.draw(resolved, at: point, anchor: anchor)
    }
}
