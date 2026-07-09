//
//  LeaveReviewThunk.swift
//  IFApp
//
//  Positive tap on the "Enjoying IF24?" pre-prompt: open the App Store
//  write-review form and close the sheet.
//

import Redux

struct LeaveReviewThunk: Thunk {
    func execute<State: Equatable>(state: State, dispatch: @escaping (Action) -> Void) async {
        let repo: ReviewRepositoryProtocol = container.inject()
        dispatch(AppLifecycleAction.reviewCtaTapped)
        repo.openWriteReview()
        dispatch(UIAction.reviewPromptClosed)
    }
}
