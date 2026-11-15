//
//  ReviewRepositoryProtocol.swift
//  IFApp
//

import Foundation

protocol ReviewRepositoryProtocol {
    func canPrompt() -> Bool
    func markPromptShown()
    func requestReview(completion: @escaping (Bool) -> Void)
}
