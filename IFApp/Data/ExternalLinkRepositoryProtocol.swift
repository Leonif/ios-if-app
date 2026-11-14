//
//  ExternalLinkRepositoryProtocol.swift
//  IFApp
//

import Foundation

protocol ExternalLinkRepositoryProtocol {
    @MainActor func open(_ url: URL) async
}
