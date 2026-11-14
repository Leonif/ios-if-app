//
//  HistoryExportRepository.swift
//  IFApp
//

import Foundation

struct HistoryExportRepository: HistoryExportRepositoryProtocol {
    func write(csv: String, fileName: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        guard let data = csv.data(using: .utf8) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
