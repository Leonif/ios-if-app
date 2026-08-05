//
//  HistoryExport.swift
//  IFApp
//
//  The history as a CSV file. A pure derivation over the records — no clock, no
//  file system, no locale: given the same records it returns the same bytes.
//
//  The file is machine-readable end to end, and that is a decision rather than
//  laziness (decision 14). The header is a fixed ASCII line, byte for byte the same
//  in all ten locales, because a header is a column key and not a caption: ten
//  translated headers would be ten different formats of one file. The values follow
//  the header — ISO-8601 with the local offset, whole integers, `true`/`false`, and
//  phase codes from a fixed list. Nothing here is ever localised.
//
//  Two consequences worth stating so they are not "fixed" later:
//
//  * Every byte is ASCII, so the BOM question does not exist and neither does the
//    whole class of 文字化け bugs. That holds only while no column is localised.
//  * No column carries a decimal separator, so "is it a dot or a comma" cannot
//    break an import on a de/fr/es/pl/uk machine. Not an agreement — a property.
//
//  The `plan` column is absent on purpose: `planLabel` follows entirely from
//  `goal_hours`, so it would add no information while forcing a choice between the
//  machine spelling of a custom plan and the displayed one.
//

import Foundation

enum HistoryExport {
    /// The column keys. This line is also the format's version marker — a future
    /// parser tells formats apart by it, which is why no comment line is added.
    static let header = "start,end,duration_minutes,goal_hours,goal_reached,phase"

    /// RFC 4180's terminator. Excel on Windows is the one target that still cares,
    /// and it is exactly the target the ASCII rule was written for.
    private static let newline = "\r\n"

    /// The file's whole contents.
    ///
    /// Rows run oldest first, which is not the order of the screen the button sits on
    /// (decision 92). The reader of this file is a spreadsheet or a script, and every
    /// other choice in it has already been made for the machine: descending rows give
    /// a mirrored time axis on any chart drawn from a raw import — the same class of
    /// defect as a date read right-to-left. The cost is named rather than hidden:
    /// opening the file in Numbers just to look shows the oldest fast first.
    ///
    /// No field is quoted or escaped, and that is checked rather than hoped for:
    /// every column is an ISO timestamp, an integer, `true`/`false`, or a phase code
    /// from `Phase.exportValue`. None of them can contain a comma, a quote or a
    /// newline. The day a column stops being machine-generated, this needs quoting.
    static func csv(records: [FastRecord]) -> String {
        let chronological = records.sorted { $0.startTimestamp < $1.startTimestamp }
        return ([header] + chronological.map(row)).joined(separator: newline) + newline
    }

    private static func row(_ record: FastRecord) -> String {
        [
            timestamp(record.startDate),
            timestamp(record.endDate),
            String(Int(record.duration / 60)),
            String(Int(record.goalHours.rounded())),
            record.goalReached ? "true" : "false",
            record.reachedPhase.exportValue,
        ].joined(separator: ",")
    }

    /// "2026-08-04T07:12:00+03:00" — the local offset, never `Z`.
    ///
    /// A fast that began at seven in the morning means seven in the morning; the
    /// offset keeps both readings and still sorts lexicographically. `ISO8601DateFormatter`
    /// is not a `DateFormatter` and takes no locale: it is fixed on the proleptic
    /// Gregorian calendar and Western digits by definition, which is what keeps
    /// ar_SA from writing Hijri dates in Eastern Arabic numerals into a data file.
    private static func timestamp(_ date: Date) -> String {
        isoFormatter.string(from: date)
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withColonSeparatorInTimeZone]
        f.timeZone = .current
        return f
    }()

    /// The file's name: ASCII, in every locale, like its contents.
    ///
    /// A localised name loses more than it buys. Windows and mail clients mangle
    /// non-ASCII file names, and an Arabic name additionally carries bidi ordering
    /// into a string that gets pasted into paths, headers and subject lines. The
    /// name is also the one part of the export a support conversation has to be able
    /// to say out loud.
    ///
    /// It is built from a literal rather than from `strings.History.title`: that key
    /// is the *screen title*, and sourcing the name from it would mean any later
    /// edit to the heading silently renames the file — one key doing two jobs.
    ///
    /// `dayKey` supplies the ISO date, so the files sort by name.
    static func fileName(dayKey: String) -> String {
        "IF24-history-\(dayKey).csv"
    }
}
