//
//  ShakeToOpen.swift
//  IFApp
//
//  Shake reporting. SwiftUI has no shake gesture, and UIKit only delivers motion
//  events down the responder chain — so the window reports it and whoever cares
//  listens. A first-responder-based catcher would fight the text field in the plan
//  editor for the same role; the window never has to compete for it.
//
//  The shake is the fallback entry point, kept because it always works: the floating
//  button can be dragged off, switched off, or hidden on a UI-test launch, and then
//  this is the only way back in.
//
//  Compiled out entirely outside DEBUG and DEVELOPMENT.
//

#if DEBUG || DEVELOPMENT

import UIKit

extension Notification.Name {
    static let deviceDidShake = Notification.Name("com.if24.deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceDidShake, object: nil)
    }
}

#endif
