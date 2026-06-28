//
//  ThunkExecutionError.swift
//  DataLayer
//

import Foundation

/// Shared error for thunk execution failures when state or context is invalid.
/// Use `origin` to identify which thunk (or feature) reported the error.
public enum ThunkExecutionError: Error, LocalizedError {
    /// State could not be cast to expected type (e.g. AppState). `origin` identifies the thunk.
    case invalidState(origin: String)

    public var errorDescription: String? {
        switch self {
        case let .invalidState(origin):
            return "Thunk invalid state at origin: \(origin)"
        }
    }
}
