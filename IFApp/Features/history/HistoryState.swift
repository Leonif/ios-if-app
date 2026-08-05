//
//  HistoryState.swift
//  IFApp
//
//  Finished fasts, newest first. The whole array lives in state so the screen's
//  aggregates recompute themselves after a delete without any bookkeeping.
//

import Foundation

struct HistoryState: Equatable, Sendable {
    var records: [FastRecord] = []

    /// The CSV file waiting to be handed to the share sheet, once a thunk has
    /// written one. nil the rest of the time — the sheet is up exactly while this
    /// has a value, so the screen cannot be showing a share of a file that no
    /// longer exists. Not persisted: the file lives in the temporary directory and
    /// an export is finished the moment the sheet closes.
    var exportFile: URL? = nil
}
