//
//  SourceAnalyticsTests.swift
//  IFAppTests
//
//  The reading funnel. Before these three events the Sources screen reported only
//  that the list had been opened: which paper was read, whether anybody went on to
//  the paper itself, and whether the reader was closed at the end or at the top were
//  all invisible, and the four titles could not be told apart at all.
//
//  Two things here are worth a test rather than a reading of the middleware.
//
//  The identifier has to be the catalog index, and it has to survive as text: the
//  four papers are read as a distribution, which means sorting by the dimension, and
//  a number logged as a number arrives in GA4's numeric field with the dimension left
//  `(not set)`. Same trap that cost `goal_hours` a month.
//
//  And `source_original_opened` must fire for the paper's own link and for nothing
//  else. `OpenExternalLinkThunk` — the mechanism behind the button — also opens the
//  privacy policy and the system Settings, so the event hangs off a lifecycle action
//  dispatched at the one call site, not off the thunk. The last test states that as a
//  rule: a thunk passing through the analytics middleware leaves no event behind.
//

import XCTest
import Redux
@testable import IFApp

final class SourceAnalyticsTests: XCTestCase {

    private final class RepoSpy: AnalyticsRepositoryProtocol {
        var events: [AnalyticsEvent] = []
        func log(_ event: AnalyticsEvent) { events.append(event) }
        func setUserProperty(_ value: String?, forName name: String) {}

        func named(_ name: String) -> [AnalyticsEvent] { events.filter { $0.name == name } }
        func articles(of name: String) -> [String] {
            named(name).compactMap { $0.parameters["article"] as? String }
        }
    }

    /// The thunk takes its repository from the container, which is registered at app
    /// launch and not in a test bundle. Handed one explicitly, it can be built here
    /// without the launch path.
    private struct LinksStub: ExternalLinkRepositoryProtocol {
        @MainActor func open(_ url: URL) async {}
    }

    private let noDispatch = DispatchFunction(dispatchAction: { _ in }, dispatchThunk: { _ in })

    private func send(_ action: Action, to middleware: AnalyticsMiddleware) {
        middleware.handle(action: action, state: AppState(), dispatch: noDispatch)
    }

    // MARK: The funnel

    /// List opened, article opened, original followed — the three steps, in order, and
    /// the two that name a paper naming the same one.
    func testTheWholeFunnelIsCountableEndToEnd() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        send(AppLifecycleAction.sourcesOpened, to: middleware)
        send(AppLifecycleAction.sourceArticleOpened(articleID: 1), to: middleware)
        send(AppLifecycleAction.sourceOriginalOpened(articleID: 1), to: middleware)

        XCTAssertEqual(repo.events.map(\.name),
                       ["sources_opened", "source_article_opened", "source_original_opened"])
        XCTAssertEqual(repo.articles(of: "source_article_opened"), ["01"])
        XCTAssertEqual(repo.articles(of: "source_original_opened"), ["01"])
    }

    /// One event per opening, and each one carrying its own paper: with four titles in
    /// the list, an event that could not tell them apart would answer none of the
    /// questions it exists for.
    func testEachArticleReportsItself() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        for id in 0..<4 {
            send(AppLifecycleAction.sourceArticleOpened(articleID: id), to: middleware)
        }

        XCTAssertEqual(repo.articles(of: "source_article_opened"), ["00", "01", "02", "03"])
    }

    // MARK: Closing the reader

    func testClosingReportsWhetherTheEndWasReached() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        send(AppLifecycleAction.sourceArticleClosed(articleID: 2, reachedEnd: true),
             to: middleware)
        send(AppLifecycleAction.sourceArticleClosed(articleID: 3, reachedEnd: false),
             to: middleware)

        let closed = repo.named("source_article_closed")
        XCTAssertEqual(closed.count, 2)
        XCTAssertEqual(closed.map { $0.parameters["article"] as? String }, ["02", "03"])
        XCTAssertEqual(closed.map { $0.parameters["reached_end"] as? String }, ["true", "false"])
    }

    /// The flag is text. It is a `Bool` at the call site, and a `Bool` bridges to
    /// `NSNumber` — logged as it stands, the breakdown comes back empty.
    func testReachedEndTravelsAsTextNotAsABool() {
        let parameters = AnalyticsEvent
            .sourceArticleClosed(articleID: 0, reachedEnd: true).parameters
        XCTAssertTrue(parameters["reached_end"] is String)
        XCTAssertTrue(parameters["article"] is String)
    }

    /// No parameter carries a title or a URL. The titles are localized — ten
    /// vocabularies in one dimension — and the URL is the one value the event is
    /// required not to carry.
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

    // MARK: The other users of the external-link thunk

    /// The privacy policy and the system Settings go out through the same thunk as the
    /// paper's link. Nothing about that thunk produces an event — which is what keeps
    /// `source_original_opened` counting papers and only papers.
    func testOpeningAnExternalLinkOnItsOwnReportsNothing() {
        let repo = RepoSpy()
        let middleware = AnalyticsMiddleware(repo: repo)

        middleware.handle(
            thunk: OpenExternalLinkThunk(url: SiteLinks.privacyPolicy, links: LinksStub()),
            state: AppState()
        )

        XCTAssertTrue(repo.events.isEmpty)
    }
}
