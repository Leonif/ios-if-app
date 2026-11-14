//
//  HistoryFlowView+InteractivePopGesture.swift
//  IFApp
//

import SwiftUI
import UIKit

extension HistoryFlowView {
    struct InteractivePopGesture: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> UIViewController { Host() }
        func updateUIViewController(_ controller: UIViewController, context: Context) {}

        private final class Host: UIViewController, UIGestureRecognizerDelegate {
            private weak var borrowed: UIGestureRecognizer?
            private weak var previousDelegate: (any UIGestureRecognizerDelegate)?
            private var previousEnabled: Bool?

            override func viewDidAppear(_ animated: Bool) {
                super.viewDidAppear(animated)
                guard let gesture = navigationController?.interactivePopGestureRecognizer,
                      gesture.delegate !== self else { return }
                borrowed = gesture
                previousDelegate = gesture.delegate
                previousEnabled = gesture.isEnabled
                gesture.delegate = self
                gesture.isEnabled = true
            }

            override func viewWillDisappear(_ animated: Bool) {
                super.viewWillDisappear(animated)
                guard borrowed?.delegate === self else { return }
                borrowed?.delegate = previousDelegate
                if let previousEnabled { borrowed?.isEnabled = previousEnabled }
            }

            func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
                (navigationController?.viewControllers.count ?? 0) > 1
            }

            func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                   shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
                false
            }
        }
    }
}
