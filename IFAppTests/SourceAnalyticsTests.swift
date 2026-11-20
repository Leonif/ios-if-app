//
//  SourceAnalyticsTests.swift
//  IFAppTests
//

import XCTest
import Redux
@testable import IFApp

final class SourceAnalyticsTests: XCTestCase {

    private final class TrackerSpy: AnalyticsTrackerProtocol {
        var events: [AnalyticsEvent] = []
        func log(_ event: AnalyticsEvent) { events.append(event) }
        func setUserProperty(_ value: String?, forName name: String) {}

        func named(_ name: String) -> [AnalyticsEvent] { events.filter { $0.name == name } }
        func articles(of name: String) -> [String] {
            named(name).compactMap { $0.parameters["article"] as? String }
        }
    }

    private struct LinksStub: ExternalLinkRepositoryProtocol {
        @MainActor func open(_ url: URL) async {}
    }

    private let noDispatch = DispatchFunction(dispatchAction: { _ in }, dispatchThunk: { _ in })

    private func send(_ action: Action, to middleware: AnalyticsMiddleware) {
        middleware.handle(action: action, state: AppState(), dispatch: noDispatch)
    }

    // MARK: - The funnel

    func testTheWholeFunnelIsCountableEndToEnd() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        send(AppLifecycleAction.sourcesOpened, to: middleware)
        send(AppLifecycleAction.sourceArticleOpened(articleID: 1), to: middleware)
        send(AppLifecycleAction.sourceOriginalOpened(articleID: 1, url: SourceArticle.all[1].url), to: middleware)

        XCTAssertEqual(tracker.events.map(\.name),
                       ["sources_opened", "source_article_opened", "source_original_opened"])
        XCTAssertEqual(tracker.articles(of: "source_article_opened"), ["01"])
        XCTAssertEqual(tracker.articles(of: "source_original_opened"), ["01"])
    }

    func testEachArticleReportsItself() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        for id in 0..<4 {
            send(AppLifecycleAction.sourceArticleOpened(articleID: id), to: middleware)
        }

        XCTAssertEqual(tracker.articles(of: "source_article_opened"), ["00", "01", "02", "03"])
    }

    // MARK: - Closing the reader

    func testClosingReportsWhetherTheEndWasReached() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        send(AppLifecycleAction.sourceArticleClosed(articleID: 2, reachedEnd: true),
             to: middleware)
        send(AppLifecycleAction.sourceArticleClosed(articleID: 3, reachedEnd: false),
             to: middleware)

        let closed = tracker.named("source_article_closed")
        XCTAssertEqual(closed.count, 2)
        XCTAssertEqual(closed.map { $0.parameters["article"] as? String }, ["02", "03"])
        XCTAssertEqual(closed.map { $0.parameters["reached_end"] as? String }, ["true", "false"])
    }

    func testReachedEndTravelsAsTextNotAsABool() {
        let parameters = AnalyticsEvent
            .sourceArticleClosed(articleID: 0, reachedEnd: true).parameters
        XCTAssertTrue(parameters["reached_end"] is String)
        XCTAssertTrue(parameters["article"] is String)
    }

    func testNoEventCarriesATitleOrAURL() {
        let values = [
            AnalyticsEvent.sourceArticleOpened(articleID: 0),
            AnalyticsEvent.sourceOriginalOpened(articleID: 0),
            AnalyticsEvent.sourceArticleClosed(articleID: 0, reachedEnd: false),
        ].flatMap { $0.parameters.values.compactMap { $0 as? String } }

        for value in values {
            XCTAssertFalse(value.contains("://"), "\(value) looks like a URL")
            XCTAssertTrue(value.allSatisfy(\.isASCII), "\(value) is not fixed ASCII")
        }
        let article = SourceArticle.all[0]
        XCTAssertFalse(values.contains(article.title))
        XCTAssertFalse(values.contains(article.url.absoluteString))
    }

    // MARK: - The other users of the external-link thunk

    func testOpeningAnExternalLinkOnItsOwnReportsNothing() {
        let tracker = TrackerSpy()
        let middleware = AnalyticsMiddleware(tracker: tracker)

        middleware.handle(
            thunk: OpenExternalLinkThunk(url: SiteLinks.privacyPolicy, links: LinksStub()),
            state: AppState()
        )

        XCTAssertTrue(tracker.events.isEmpty)
    }
}
