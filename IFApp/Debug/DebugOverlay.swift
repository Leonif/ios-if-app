//
//  DebugOverlay.swift
//  IFApp
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
        DragGesture(minimumDistance: 1)
            .onChanged { location = clamped($0.location, in: bounds) }
            .onEnded { value in
                let point = clamped(value.location, in: bounds)
                location = point
                storedX = point.x
                storedY = point.y
            }
    }

    private func resolved(in bounds: CGSize) -> CGPoint {
        if let location { return location }
        if storedX >= 0, storedY >= 0 { return clamped(CGPoint(x: storedX, y: storedY), in: bounds) }
        return CGPoint(x: bounds.width - Self.size, y: bounds.height / 2)
    }

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
