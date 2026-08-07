//
//  DiagnosticsLogRepository.swift
//  IFApp
//
//  The developer-facing journal: what the app did, in order, written to a file inside
//  the app container.
//
//  It is a file rather than a stream because the two ends of diagnostics are not
//  symmetric. On the simulator a Maestro run has to be readable with no UI and no
//  human in the loop — `simctl get_app_container` and the file is right there. On a
//  real device there is no container to reach into, and the same file is the only
//  thing that can be handed out at all. A journal that only streamed to Console would
//  serve neither case; the `os.Logger` mirror below is a convenience on top, not the
//  mechanism.
//
//  Compiled out entirely outside DEBUG and DEVELOPMENT: nothing here reaches an
//  App Store build.
//

#if DEBUG || DEVELOPMENT

import Foundation
import os

protocol DiagnosticsLogRepositoryProtocol {
    func append(_ line: String)
}

final class DiagnosticsLogRepository: DiagnosticsLogRepositoryProtocol {
    /// Rotated rather than truncated: the run that explains a failure is often the one
    /// before the one you are looking at.
    private static let maxBytes = 4 * 1024 * 1024

    /// Static so the debug screen can find the journal without injecting the
    /// repository: a view taking anything out of the container would break
    /// invariant 3, and the path is the only thing it needs.
    static var fileURL: URL { documents.appendingPathComponent("diagnostics.log") }
    static var previousURL: URL { documents.appendingPathComponent("diagnostics-previous.log") }

    private static var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private let fileURL = DiagnosticsLogRepository.fileURL
    private let previousURL = DiagnosticsLogRepository.previousURL
    private let queue = DispatchQueue(label: "com.if24.diagnostics")
    private var handle: FileHandle?

    /// `%{public}` is not decoration. `os.Logger` redacts interpolated values by
    /// default, and a journal of `<private>` is worse than no journal because it looks
    /// like it worked.
    private let mirror = Logger(subsystem: "com.if24.app", category: "diagnostics")

    /// Timestamps are for machines and for reading side by side with Maestro output,
    /// so the locale is pinned. Invariant 5 (on-screen formatting) does not apply — but
    /// not because nothing here reaches a screen: `DebugScreen` renders the tail of this
    /// file in a `Text`. It does not apply because the rule guards against two digit
    /// systems meeting on one screen, and `en_US_POSIX` yields Latin digits always —
    /// the guarantee `Locale.latinDigits` exists to give, in the same shape as
    /// `Clock.dayKeyFormatter`.
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

    // MARK: File

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

    /// Every launch is marked, because the first question asked of a journal is always
    /// "is this from the run I just did".
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
