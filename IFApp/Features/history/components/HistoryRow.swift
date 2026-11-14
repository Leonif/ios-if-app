//
//  HistoryRow.swift
//  IFApp
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
                        Text(HistoryFormat.duration(record.duration))
                            .font(.bricolage(19.5))
                            .monospacedDigit()
                            .foregroundColor(theme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .layoutPriority(1)
                        tag
                    }
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
