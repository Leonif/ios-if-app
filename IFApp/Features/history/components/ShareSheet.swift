//
//  ShareSheet.swift
//  IFApp
//
//  The system share sheet over a file. Apple's surface, presented and not styled —
//  the handoff leaves it out of the mockup on purpose so nobody starts dressing it.
//
//  It exists as a bridge rather than as `ShareLink` for one reason: the export event
//  fires on a share that happened, and a cancelled sheet is not one. `ShareLink` has
//  no completion, `UIActivityViewController` does.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let file: URL
    /// true only when an activity actually ran; backing out reports false.
    let onFinish: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [file], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onFinish(completed)
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
