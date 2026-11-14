//
//  DebugScreen.swift
//  IFApp
//

#if DEBUG || DEVELOPMENT

import SwiftUI
import UIKit

struct DebugScreen: View {
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
