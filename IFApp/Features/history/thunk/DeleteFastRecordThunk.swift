//
//  DeleteFastRecordThunk.swift
//  IFApp
//

import Foundation
import Redux

struct DeleteFastRecordThunk: Thunk {
    let id: UUID
    private let repo: FastHistoryRepositoryProtocol

    init(id: UUID, repo: FastHistoryRepositoryProtocol = container.inject()) {
        self.id = id
        self.repo = repo
    }

    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        repo.delete(id: id)
    }
}
