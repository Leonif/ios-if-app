//
//  SaveFastRecordThunk.swift
//  IFApp
//

import Foundation
import Redux

struct SaveFastRecordThunk: Thunk {
    let record: FastRecord
    private let repo: FastHistoryRepositoryProtocol

    init(record: FastRecord, repo: FastHistoryRepositoryProtocol = container.inject()) {
        self.record = record
        self.repo = repo
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        repo.append(record)
        dispatch(HistoryAction.recorded(record))
    }
}
