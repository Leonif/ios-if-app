//
//  ReviewRepository.swift
//  IFApp
//
//  Wraps StoreKit's review prompt. The gating logic lives in ReviewMiddleware.
//

import StoreKit
import UIKit

protocol ReviewRepositoryProtocol {
    func requestReview()
}

struct ReviewRepository: ReviewRepositoryProtocol {
    func requestReview() {
        Task { @MainActor in
            guard let scene = UIApplication.shared.connectedScenes.first(where: {
                $0.activationState == .foregroundActive
            }) as? UIWindowScene else {
                return
            }
            AppStore.requestReview(in: scene)
        }
    }
}
