//
//  SourcesMiddlewareTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class SourcesMiddlewareTests: XCTestCase {
    private final class Box { var thunks: [Thunk] = [] }

    private func thunks(after action: Action) -> [Thunk] {
        let box = Box()
        SourcesMiddleware().handle(
            action: action, state: AppState(),
            dispatch: DispatchFunction(dispatchAction: { _ in }, dispatchThunk: { box.thunks.append($0) }))
        return box.thunks
    }

    func testReadTheOriginalOpensThePapersURL() throws {
        let url = SourceArticle.all[2].url
        let thunks = thunks(after: AppLifecycleAction.sourceOriginalOpened(articleID: 2, url: url))
        XCTAssertEqual(thunks.count, 1)
        let link = try XCTUnwrap(thunks.first as? OpenExternalLinkThunk)
        XCTAssertEqual(Mirror(reflecting: link).descendant("url") as? URL, url)
    }

    func testTheReadersOtherActionsOpenNothing() {
        let actions: [AppLifecycleAction] = [.sourcesOpened, .sourceArticleOpened(articleID: 2),
                                             .sourceArticleClosed(articleID: 2, reachedEnd: true)]
        for action in actions {
            XCTAssertTrue(thunks(after: action).isEmpty)
        }
    }
}
