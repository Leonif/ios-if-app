//
//  HistoryFlowView+HorizontalRowPan.swift
//  IFApp
//

import SwiftUI
import UIKit

extension HistoryFlowView {
    @available(iOS 18.0, *)
    struct HorizontalRowPan: UIGestureRecognizerRepresentable {
        let onChanged: (CGFloat) -> Void
        let onEnded: (CGFloat) -> Void

        func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
            Coordinator()
        }

        func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
            let recognizer = UIPanGestureRecognizer()
            recognizer.minimumNumberOfTouches = 1
            recognizer.maximumNumberOfTouches = 1
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = context.coordinator
            return recognizer
        }

        func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
            let horizontal = context.converter.translation(in: .local)?.x
                ?? recognizer.translation(in: recognizer.view).x
            switch recognizer.state {
            case .began, .changed:
                onChanged(horizontal)
            case .ended, .cancelled, .failed:
                onEnded(horizontal)
            default:
                break
            }
        }

        final class Coordinator: NSObject, UIGestureRecognizerDelegate {
            func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
                guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
                let velocity = pan.velocity(in: pan.view)
                return abs(velocity.x) > abs(velocity.y)
            }

            func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                   shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
                true
            }
        }
    }
}
