//
//  DiagnosticsLoggerProtocol.swift
//  IFApp
//

#if DEBUG || DEVELOPMENT

protocol DiagnosticsLoggerProtocol {
    func append(_ line: String)
}

#endif
