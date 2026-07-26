//
//  HistorySummaryCard.swift
//  IFApp
//
//  What the history adds up to: the streak, the last seven days, and three totals.
//  The card is what makes the screen feel like something worth keeping, so its
//  numbers always come from the whole history — never from whatever slice of rows
//  happens to be on screen.
//
//  It reveals itself in stages. At zero records it isn't shown at all (a wall of
//  zeroes reads as a reproach to a beginner); the dots arrive at three records and
//  the best-streak line at seven, so nothing on screen is ever an empty promise.
//

import SwiftUI

struct HistorySummaryCard: View {
    let streak: Int
    let stats: HistoryStats
    let theme: ThemeTokens

    /// Under three records the dots would be mostly empty — hide them until there
    /// is a rhythm to show.
    private var showsDots: Bool { stats.fastsCount >= 3 }
    /// The best-streak line needs a week of history before it says anything.
    private var showsBest: Bool { stats.fastsCount >= 7 && stats.bestStreak > 0 }
    /// The first fast gets a sentence instead of statistics.
    private var showsFirstNote: Bool { stats.fastsCount <= 2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(strings.History.streakOverline.uppercased())
                        .font(.hanken(11, .semibold))
                        .overlineTracking(1.5)
                        .foregroundColor(theme.mut)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(streak)")
                            .font(.bricolage(40))
                            .monospacedDigit()
                            .foregroundColor(theme.ink)
                        Text(strings.History.daysInARow(streak))
                            .font(.hanken(14.5, .semibold))
                            .foregroundColor(theme.sec)
                    }
                }

                Spacer(minLength: 12)

                if showsDots {
                    VStack(alignment: .trailing, spacing: 9) {
                        Text(strings.History.lastSevenDays.uppercased())
                            .font(.hanken(11, .semibold))
                            .overlineTracking(1.1)
                            .foregroundColor(theme.mut)
                            .lineLimit(1)
                        StreakDots(days: stats.lastSevenDays, theme: theme)
                    }
                }
            }

            if showsFirstNote {
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
                stat(strings.History.statTotal, HistoryFormat.totalHours(stats.totalHours), theme.deep)
                divider
                stat(strings.History.statLongest, HistoryFormat.duration(stats.longest), theme.ink)
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

    /// One of the three totals. Labels truncate inside their own third rather than
    /// wrapping — German runs long here ("Am längsten") and a wrapped label would
    /// shift the row's baseline.
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

/// Seven days, oldest first. A missed day is an unfilled ring, not a cross — the
/// gap is a fact, not a verdict.
struct StreakDots: View {
    let days: [Bool]
    let theme: ThemeTokens

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, reached in
                Group {
                    if reached {
                        Circle().fill(theme.accent)
                    } else {
                        Circle().stroke(theme.faint, lineWidth: 1.5)
                    }
                }
                .frame(width: 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }
}
