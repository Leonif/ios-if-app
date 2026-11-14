import UIKit

struct ExternalLinkRepository: ExternalLinkRepositoryProtocol {
    @MainActor func open(_ url: URL) async {
        await UIApplication.shared.open(url)
    }
}
