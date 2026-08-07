//
//  DebugOverlay.swift
//  IFApp
//
//  The two ways into the debug screen, and the single place that owns its sheet:
//  a draggable button for everyday use, a shake for when the button is not there.
//
//  The button hides itself on any UI-test launch. Every Maestro flow and every
//  loc-matrix screenshot launches with a `-seed…` / `-uitest…` / `-show…` argument,
//  so the check is exact rather than a guess — and without it a floating circle would
//  sit in all 70 screenshots of the locale matrix and over whatever the visual-diff
//  mode is comparing.
//
//  Compiled out entirely outside DEBUG and DEVELOPMENT.
//

#if DEBUG || DEVELOPMENT

import SwiftUI

extension View {
    func debugOverlay() -> some View {
        modifier(DebugOverlay())
    }
}

private struct DebugOverlay: ViewModifier {
    private static let size: CGFloat = 44
    /// Keeps the button off the very edge, where a drag would be competing with the
    /// system's own edge gestures.
    private static let margin: CGFloat = 8

    @State private var isPresented = false
    @State private var location: CGPoint?

    @AppStorage("debug.buttonHidden") private var isHidden = false
    @AppStorage("debug.buttonX") private var storedX: Double = -1
    @AppStorage("debug.buttonY") private var storedY: Double = -1

    func body(content: Content) -> some View {
        content
            .overlay { button }
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                isPresented = true
            }
            .sheet(isPresented: $isPresented) { DebugScreen() }
    }

    @ViewBuilder
    private var button: some View {
        if !isHidden, !Self.isUITestLaunch {
            GeometryReader { proxy in
                Circle()
                    .fill(.black.opacity(0.5))
                    .overlay {
                        Image(systemName: "ladybug.fill")
                            .foregroundStyle(.white)
                    }
                    .frame(width: Self.size, height: Self.size)
                    .position(resolved(in: proxy.size))
                    .onTapGesture { isPresented = true }
                    .gesture(drag(in: proxy.size))
            }
            .ignoresSafeArea()
        }
    }

    private func drag(in bounds: CGSize) -> some Gesture {
        // `minimumDistance: 1` so a plain tap still reaches `onTapGesture` above.
        DragGesture(minimumDistance: 1)
            .onChanged { location = clamped($0.location, in: bounds) }
            .onEnded { value in
                let point = clamped(value.location, in: bounds)
                location = point
                storedX = point.x
                storedY = point.y
            }
    }

    /// Live drag first, then the remembered spot, then a default that sits clear of
    /// the primary button at the bottom of the timer screen.
    private func resolved(in bounds: CGSize) -> CGPoint {
        if let location { return location }
        if storedX >= 0, storedY >= 0 { return clamped(CGPoint(x: storedX, y: storedY), in: bounds) }
        return CGPoint(x: bounds.width - Self.size, y: bounds.height / 2)
    }

    /// Clamped on every read, not just on drop: rotating the device or switching to a
    /// smaller one would otherwise strand the button off-screen with no way back.
    private func clamped(_ point: CGPoint, in bounds: CGSize) -> CGPoint {
        let inset = Self.size / 2 + Self.margin
        return CGPoint(
            x: min(max(point.x, inset), max(bounds.width - inset, inset)),
            y: min(max(point.y, inset), max(bounds.height - inset, inset))
        )
    }

    private static var isUITestLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains {
            $0.hasPrefix("-seed") || $0.hasPrefix("-uitest") || $0.hasPrefix("-show")
        }
    }
}

#endif
