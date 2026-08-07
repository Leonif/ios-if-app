//
//  DebugScreen.swift
//  IFApp
//
//  The device end of diagnostics. On the simulator the journal is read straight off
//  disk and this screen is unnecessary; on a real device there is no container to
//  reach into, and Copy / Share are the only ways anything gets out at all.
//
//  Not localised and not designed on purpose: it has no reference screen, it is never
//  seen by a user, and every string here is meant to be read by whoever is debugging.
//
//  Compiled out entirely outside DEBUG and DEVELOPMENT.
//

#if DEBUG || DEVELOPMENT

import SwiftUI
import UIKit

struct DebugScreen: View {
    /// Enough to see how a flow ended without loading a multi-megabyte file into a
    /// view. The whole journal still goes out through Share.
    private static let tailLines = 120

    @Environment(\.dismiss) private var dismiss
    @State private var items: [DiagnosticsSnapshot.Item] = []
    @State private var tail = "reading…"
    @AppStorage("debug.buttonHidden") private var isButtonHidden = false

    var body: some View {
        NavigationStack {
            List {
                Section("Environment") {
                    ForEach(items) { item in
                        HStack(alignment: .top) {
                            Text(item.label)
                                .foregroundStyle(.secondary)
                                .frame(width: 110, alignment: .leading)
                            Text(item.value)
                                .textSelection(.enabled)
                        }
                        .font(.system(.caption, design: .monospaced))
                    }
                }
                Section {
                    Button("Copy report") { UIPasteboard.general.string = report }
                    Toggle("Floating button", isOn: Binding(
                        get: { !isButtonHidden },
                        set: { isButtonHidden = !$0 }
                    ))
                    .font(.system(.caption, design: .monospaced))
                } footer: {
                    Text("Off leaves the shake as the only way in. Always hidden on UI-test launches.")
                }
                Section("Journal — last \(Self.tailLines) lines") {
                    Text(tail)
                        .font(.system(size: 9, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .navigationTitle("Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: DiagnosticsLogRepository.fileURL)
                }
            }
            .task {
                items = await DiagnosticsSnapshot.collect()
                tail = Self.readTail()
            }
        }
    }

    private var report: String {
        "\(DiagnosticsSnapshot.text(items))\n\n--- journal ---\n\(tail)"
    }

    private static func readTail() -> String {
        guard let contents = try? String(contentsOf: DiagnosticsLogRepository.fileURL, encoding: .utf8)
        else { return "no journal yet" }
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.suffix(tailLines).joined(separator: "\n")
    }
}

#endif
