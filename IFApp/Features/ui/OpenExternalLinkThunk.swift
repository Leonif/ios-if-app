import Foundation
import Redux

struct OpenExternalLinkThunk: Thunk {
    private let url: URL
    private let links: ExternalLinkRepositoryProtocol

    init(url: URL, links: ExternalLinkRepositoryProtocol = container.inject()) {
        self.url = url
        self.links = links
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        await links.open(url)
    }
}
