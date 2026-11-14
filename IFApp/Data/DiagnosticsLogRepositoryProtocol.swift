//
//  DiagnosticsLogRepositoryProtocol.swift
//  IFApp
//

#if DEBUG || DEVELOPMENT

protocol DiagnosticsLogRepositoryProtocol {
    func append(_ line: String)
}

#endif
