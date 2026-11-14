//
//  HistoryExportRepositoryProtocol.swift
//  IFApp
//

import Foundation

protocol HistoryExportRepositoryProtocol {
    func write(csv: String, fileName: String) -> URL?
}
