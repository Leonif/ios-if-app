import UIKit

protocol ExternalLinkRepositoryProtocol {
    @MainActor func open(_ url: URL) async
}

struct ExternalLinkRepository: ExternalLinkRepositoryProtocol {
    @MainActor func open(_ url: URL) async {
        await UIApplication.shared.open(url)
    }
}
