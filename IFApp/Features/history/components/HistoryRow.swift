//
//  HistoryRow.swift
//  IFApp
//
//  One finished fast: ring, duration, when it ran, which plan and how deep it got.
//  A fast that fell short is coloured, not flagged — an open arc, the goal quietly
//  beside the duration and the phase it honestly reached. Nothing here says "failed",
//  because a user who feels judged stops recording the bad days.
//

import SwiftUI

struct HistoryRow: View {
    let record: FastRecord
    let isExpanded: Bool
    let theme: ThemeTokens

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                PhaseRingMini(record: record, theme: theme)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        // "41 Std 12 Min" beside the Extended chip is the widest this
                        // line ever gets; it shrinks rather than losing its minutes.
                        Text(HistoryFormat.duration(record.duration))
                            .font(.bricolage(19.5))
                            .monospacedDigit()
                            .foregroundColor(theme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .layoutPriority(1)
                        tag
                    }
                    // One line, always. Arabic and German run past the width on the
                    // longest rows (a 40h fast spelling out two dates), so the line
                    // gives up a little size before it gives up characters.
                    Text(HistoryFormat.rowSubline(record, isRTL: isRTL))
                        .font(.hanken(12.5, .medium))
                        .foregroundColor(theme.mut)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 5) {
                    Text(record.planLabel)
                        .font(.hanken(12, .bold))
                        .monospacedDigit()
                        .foregroundColor(theme.ink)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 9)
                        .background(
                            Capsule().fill(theme.secBg)
                                .overlay(Capsule().stroke(theme.secLine, lineWidth: 1))
                        )
                    Text(record.reachedPhase.label)
                        .font(.hanken(11.5, .semibold))
                        .foregroundColor(theme.historyPhaseLabel(record.reachedPhase.color))
                        .lineLimit(1)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 16)

            if isExpanded {
                HistoryRowDetail(record: record, theme: theme)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("history.row")
        .accessibilityLabel(accessibilityLabel)
    }

    @Environment(\.layoutDirection) private var layoutDirection
    private var isRTL: Bool { layoutDirection == .rightToLeft }

    /// Either the goal a short fast fell short of, or the Extended chip past 24h.
    @ViewBuilder
    private var tag: some View {
        if record.isExtended {
            let phase = record.reachedPhase.color
            Text(strings.History.extended)
                .font(.hanken(11.5, .semibold))
                .foregroundColor(theme.historyPhaseLabel(phase))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.vertical, 2)
                .padding(.horizontal, 8)
                .background(
                    Capsule().fill(phase.opacity(0.14))
                        .overlay(Capsule().stroke(phase.opacity(0.32), lineWidth: 1))
                )
        } else if !record.goalReached {
            Text(strings.History.ofGoal(strings.Duration.goalHours(Int(record.goalHours))))
                .font(.hanken(11.5, .semibold))
                .foregroundColor(theme.mut)
                .lineLimit(1)
        }
    }

    /// One spoken sentence per row; the ring is decorative and stays hidden.
    ///
    /// The plan is spelled out rather than read off the pill: `planLabel` is a ratio
    /// ("17:7"), and a colon between two numerals is announced as a time of day — a
    /// row that already speaks the real start and end times would gain a third,
    /// invented one. Caption plus length, comma-separated like the fields beside it.
    private var accessibilityLabel: String {
        [
            HistoryFormat.duration(record.duration),
            record.goalReached ? strings.History.reached(record.reachedPhase.label)
                               : strings.History.ofGoal(strings.Duration.goalHours(Int(record.goalHours))),
            HistoryFormat.rowSubline(record, isRTL: false),
            strings.Sheet.fastingPlan,
            strings.Duration.hoursSpelled(Int(record.goalHours)),
        ].joined(separator: ", ")
    }
}

/// The expanded panel. Read-only by design: the one destructive path is an explicit
/// swipe with a confirmation, so an accordion that opens on a tap can never delete
/// anything, and the screen owes no undo.
struct HistoryRowDetail: View {
    let record: FastRecord
    let theme: ThemeTokens

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhaseTimeline(
                currentPhase: record.reachedPhase,
                currentFill: record.goalFraction * 4 - Double(record.reachedPhase.rawValue),
                isComplete: record.goalReached,
                theme: theme,
                showsLabels: false
            )

            HStack(spacing: 8) {
                Circle()
                    .fill(record.reachedPhase.color)
                    .frame(width: 8, height: 8)
                Text(strings.History.reached(record.reachedPhase.label))
                    .font(.hanken(13.5, .semibold))
                    .foregroundColor(theme.ink)
            }

            VStack(spacing: 6) {
                detailRow(strings.History.started, HistoryFormat.dateTime(record.startDate))
                detailRow(strings.History.ended, HistoryFormat.dateTime(record.endDate))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 15)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.historyDetailBg)
        .overlay(alignment: .top) {
            Rectangle().fill(theme.surfaceLine).frame(height: 1)
        }
    }

    /// The only place both calendar dates of a fast are spelled out — the row itself
    /// shows the start date, which is what the user recognises it by.
    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label.uppercased())
                .font(.hanken(11, .semibold))
                .overlineTracking(1.3)
                .foregroundColor(theme.mut)
            Spacer(minLength: 8)
            Text(value)
                .font(.hanken(13.5, .semibold))
                .monospacedDigit()
                .foregroundColor(theme.sec)
                .lineLimit(1)
        }
    }
}
