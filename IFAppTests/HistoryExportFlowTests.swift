import XCTest
import Redux
@testable import IFApp

final class HistoryExportFlowTests: XCTestCase {
    private final class Files: HistoryExportRepositoryProtocol {
        var result: URL?
        var calls = 0
        func write(csv: String, fileName: String) -> URL? {
            calls += 1
            return result
        }
    }
    private final class Box {
        var state = HistoryState()
        var busyStates: [Bool] = []
    }
    private func state() -> AppState {
        var state = AppState()
        state.historyState.records = [FastRecord(id: UUID(), startTimestamp: 100,
                                                endTimestamp: 57_700, goalHours: 16,
                                                planLabel: "16:8")]
        return state
    }

    func testFailedWriteAllowsRetryWithoutChangingHistory() async {
        let files = Files()
        let initial = state()
        let box = Box()
        box.state = initial.historyState
        await ExportHistoryThunk(files: files).execute(state: initial) { action in
            box.state = historyReducer(state: box.state, action: action)
            box.busyStates.append(box.state.isExporting)
        }
        XCTAssertEqual(box.busyStates, [true, false])
        XCTAssertNil(box.state.exportFile)
        XCTAssertEqual(box.state.records, initial.historyState.records)
        var retry = initial
        retry.historyState = box.state
        files.result = URL(fileURLWithPath: "/tmp/history-test.csv")
        await ExportHistoryThunk(files: files).execute(state: retry) { action in
            box.state = historyReducer(state: box.state, action: action)
        }
        XCTAssertEqual(files.calls, 2)
        XCTAssertEqual(box.state.exportFile, files.result)
        XCTAssertFalse(box.state.isExporting)
    }

    func testDoesNotRewriteFileWhileShareSheetIsOpen() async {
        let files = Files()
        var initial = state()
        initial.historyState.exportFile = URL(fileURLWithPath: "/tmp/history-test.csv")
        await ExportHistoryThunk(files: files).execute(state: initial) { _ in
            XCTFail("An active share must not be replaced")
        }
        XCTAssertEqual(files.calls, 0)
    }
}
