//
//  DiagnosticsLogger.swift
//  IFApp
//

#if DEBUG || DEVELOPMENT

import Foundation
import os

final class DiagnosticsLogger: DiagnosticsLoggerProtocol {
    private static let maxBytes = 4 * 1024 * 1024

    static var fileURL: URL { documents.appendingPathComponent("diagnostics.log") }
    static var previousURL: URL { documents.appendingPathComponent("diagnostics-previous.log") }

    private static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private let fileURL = DiagnosticsLogger.fileURL
    private let previousURL = DiagnosticsLogger.previousURL
    private let queue = DispatchQueue(label: "com.if24.diagnostics")
    private var handle: FileHandle?

    private let mirror = Logger(subsystem: "com.if24.app", category: "diagnostics")

    private let stamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    init() {
        rotateIfNeeded()
        openHandle()
        writeSessionHeader()
    }

    func append(_ line: String) {
        let stamped = "\(stamp.string(from: Date()))  \(line)\n"
        mirror.debug("\(line, privacy: .public)")
        queue.async { [weak self] in
            guard let data = stamped.data(using: .utf8) else { return }
            try? self?.handle?.write(contentsOf: data)
        }
    }

    // MARK: - File

    private func rotateIfNeeded() {
        let manager = FileManager.default
        let attributes = try? manager.attributesOfItem(atPath: fileURL.path)
        let size = attributes?[.size] as? Int ?? 0
        guard size >= Self.maxBytes else { return }
        try? manager.removeItem(at: previousURL)
        try? manager.moveItem(at: fileURL, to: previousURL)
    }

    private func openHandle() {
        let manager = FileManager.default
        if !manager.fileExists(atPath: fileURL.path) {
            manager.createFile(atPath: fileURL.path, contents: nil)
        }
        handle = try? FileHandle(forWritingTo: fileURL)
        try? handle?.seekToEnd()
    }

    private func writeSessionHeader() {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        let arguments = ProcessInfo.processInfo.arguments
            .filter { $0.hasPrefix("-seed") || $0.hasPrefix("-uitest") }
        let launch = arguments.isEmpty ? "none" : arguments.joined(separator: " ")
        append("=== launch \(version) (\(build))  ios=\(OSVersion.current)  args=\(launch) ===")
    }
}

private enum OSVersion {
    static var current: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion)"
    }
}

#endif
