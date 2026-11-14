//
//  ThunkExecutionError.swift
//  Redux
//

import Foundation

public enum ThunkExecutionError: Error, LocalizedError {
    case invalidState(origin: String)

    public var errorDescription: String? {
        switch self {
        case let .invalidState(origin):
            return "Thunk invalid state at origin: \(origin)"
        }
    }
}
