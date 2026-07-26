//
//  HistoryState.swift
//  IFApp
//
//  Finished fasts, newest first. The whole array lives in state so the screen's
//  aggregates recompute themselves after a delete without any bookkeeping.
//

struct HistoryState: Equatable, Sendable {
    var records: [FastRecord] = []
}
