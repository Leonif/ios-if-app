//
//  StreakDots.swift
//  IFApp
//

import SwiftUI

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
