//
//  HistorySummaryCard.swift
//  IFApp
//

import SwiftUI

struct HistorySummaryCard: View {
    let display: StreakDisplay
    let stats: HistoryStats
    let showsFirstNote: Bool
    let theme: ThemeTokens

    @Environment(\.locale) private var locale

    private var streak: Int { display.count }
    private var hasEnded: Bool { display.hasEnded }

    private var counterSpacing: CGFloat {
        switch locale.language.languageCode?.identifier {
        case "ja", "ko", "zh": return 0
        default: return 8
        }
    }

    private var showsDots: Bool { stats.fastsCount >= 3 }
    private var showsBest: Bool {
        stats.fastsCount >= 7 && stats.bestStreak > 0 && stats.bestStreak >= streak
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text((hasEnded ? strings.History.lastStreakOverline
                                   : strings.History.streakOverline).uppercased())
                        .font(.hanken(11, .semibold))
                        .overlineTracking(1.5)
                        .foregroundColor(theme.mut)

                    HStack(alignment: .firstTextBaseline, spacing: counterSpacing) {
                        Text(verbatim: String(streak))
                            .font(.bricolage(40))
                            .monospacedDigit()
                            .foregroundColor(hasEnded ? theme.mut : theme.ink)
                        Text(strings.History.daysInARow(streak))
                            .font(.hanken(14.5, .semibold))
                            .foregroundColor(theme.sec)
                    }
                }

                Spacer(minLength: 12)

                if showsDots {
                    VStack(alignment: .trailing, spacing: 9) {
                        Text(strings.History.goalDays.uppercased())
                            .font(.hanken(11, .semibold))
                            .overlineTracking(1.1)
                            .foregroundColor(theme.mut)
                            .lineLimit(1)
                        StreakDots(days: stats.lastSevenDays, theme: theme)
                    }
                }
            }

            if hasEnded {
                Text(strings.History.streakEnded(streak, lastGoalDate: display.lastGoalDate))
                    .font(.hanken(14, .medium))
                    .foregroundColor(theme.sec)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 9)
            } else if showsFirstNote {
                Text(strings.History.firstNote)
                    .font(.hanken(14, .medium))
                    .foregroundColor(theme.deep)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 9)
            } else if showsBest, let since = stats.since {
                Text(strings.History.best(stats.bestStreak, HistoryFormat.sinceDate(since)))
                    .font(.hanken(13, .medium))
                    .foregroundColor(theme.mut)
                    .lineLimit(1)
                    .padding(.top, 9)
            }

            Rectangle()
                .fill(theme.surfaceLine)
                .frame(height: 1)
                .padding(.top, 16)

            HStack(spacing: 0) {
                stat(strings.History.statFasts, "\(stats.fastsCount)", theme.ink)
                divider
                stat(strings.History.statTotal, HistoryFormat.summaryDuration(stats.total), theme.deep)
                divider
                stat(strings.History.statLongest, HistoryFormat.summaryDuration(stats.longest), theme.ink)
            }
            .padding(.vertical, 14)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(theme.surfaceLine, lineWidth: 1))
                .shadow(color: theme.cardShadow, radius: 30, x: 0, y: 12)
        )
        .accessibilityIdentifier("history.summary")
    }

    private func stat(_ label: String, _ value: String, _ valueColor: Color) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.hanken(10.5, .semibold))
                .overlineTracking(1.4)
                .foregroundColor(theme.mut)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.hanken(15.5, .bold))
                .monospacedDigit()
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle().fill(theme.surfaceLine).frame(width: 1, height: 30)
    }
}

struct StreakDots: View {
    let days: [HistoryDay]
    let theme: ThemeTokens

    var body: some View {
        HStack(spacing: 5) {
            ForEach(days) { day in
                VStack(spacing: 4) {
                    Group {
                        if day.reachedGoal {
                            Circle().fill(theme.accent)
                        } else {
                            Circle().stroke(theme.faint, lineWidth: 1.5)
                        }
                    }
                    .frame(width: 8, height: 8)

                    Text(HistoryFormat.weekdayNarrow(day.date).uppercased())
                        .font(.hanken(9, .semibold))
                        .foregroundColor(theme.mut)
                        .frame(width: 10)
                }
            }
        }
        .accessibilityHidden(true)
    }
}
