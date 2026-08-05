//
//  HistoryExportRepository.swift
//  IFApp
//
//  Puts the exported CSV on disk so the system share sheet has a real file to hand
//  over. The mechanism only — what goes in the file is `HistoryExport`, and the
//  decision to write one is the thunk's.
//
//  Temporary directory, not Documents: the file is a copy made for one share and
//  the app is not its owner. The history itself already lives in
//  `fast-history.json`, and a second copy in Documents would show up in the user's
//  backups as a stale duplicate of it.
//

import Foundation

protocol HistoryExportRepositoryProtocol {
    /// Writes `csv` under `fileName` and returns where it landed, or nil if the
    /// write failed. Overwrites any earlier export of the same day.
    func write(csv: String, fileName: String) -> URL?
}

struct HistoryExportRepository: HistoryExportRepositoryProtocol {
    func write(csv: String, fileName: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        // ASCII by construction (see `HistoryExport`), so UTF-8 writes the same bytes
        // and no BOM question arises.
        guard let data = csv.data(using: .utf8) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
