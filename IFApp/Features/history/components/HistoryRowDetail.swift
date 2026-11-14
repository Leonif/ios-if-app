//
//  HistoryRowDetail.swift
//  IFApp
//

import SwiftUI

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
