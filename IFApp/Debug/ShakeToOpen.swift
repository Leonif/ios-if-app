//
//  ShakeToOpen.swift
//  IFApp
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
