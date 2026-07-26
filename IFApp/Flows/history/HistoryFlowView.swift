//
//  HistoryFlowView.swift
//  IFApp
//
//  The history screen: what the fasts add up to, then the fasts themselves grouped
//  by month. Pushed from the main screen — history is deeper into the app, not a
//  dialog over it.
//
//  Months, not weeks: a month is the unit people think "how am I doing" in, and it
//  gives the group header a meaningful aggregate. Weekly headers would turn a long
//  history into a picket fence of titles.
//

import SwiftUI
import Redux

struct HistoryProps: Equatable {
    let records: [FastRecord]
    let streak: Int

    init(state: AppState) {
        records = state.historyState.records
        streak = state.timerState.streakCount
    }
}

struct HistoryFlowView: View {
    private let store: Store<AppState>
    /// Which entry point led here. Logged with the open, and the eating-window one
    /// arrives with the fast that just closed already open — it is what the link
    /// named ("Last fast · 16h 24m"), so the screen should not make it be hunted for.
    let source: HistoryEntrySource
    let onStartFast: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var props: HistoryProps
    @State private var expandedID: UUID?
    @State private var pendingDelete: FastRecord?
    @State private var appeared = false

    init(store: Store<AppState>, source: HistoryEntrySource, onStartFast: @escaping () -> Void) {
        self.store = store
        self.source = source
        self.onStartFast = onStartFast
        _props = State(initialValue: HistoryProps(state: store.getCurrentState()))
    }

    /// The streak the card shows: 0 once a day was missed, matching the main screen.
    private var displayedStreak: Int {
        let stats = HistoryStats.compute(records: props.records)
        guard stats.fastsCount > 0 else { return props.streak }
        return props.streak
    }

    var body: some View {
        let theme = ThemeTokens.resolve(colorScheme)
        let stats = HistoryStats.compute(records: props.records)

        VStack(spacing: 0) {
            navRow(theme: theme)

            if props.records.isEmpty {
                ScrollView {
                    HistoryEmptyState(theme: theme, onStart: {
                        onStartFast()
                        dismiss()
                    })
                    .padding(.top, 90)
                }
            } else {
                content(stats: stats, theme: theme)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.historyBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .connect(to: store, mapState: { HistoryProps(state: $0) }, onPropsChange: { props = $0 })
        .onAppear {
            store.dispatch(AppLifecycleAction.historyOpened(source: source))
            if source == .eatingWindow {
                expandedID = HistoryStats.monthGroups(records: props.records).first?.records.first?.id
            }
            // Drives the entry animation: rows rise into place on the first frame only.
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : nil) { appeared = true }
        }
        .overlay {
            DeleteFastSheet(
                isOpen: pendingDelete != nil,
                theme: theme,
                onConfirm: {
                    if let record = pendingDelete {
                        if expandedID == record.id { expandedID = nil }
                        withAnimation(.easeOut(duration: 0.25)) {
                            store.dispatch(HistoryAction.deleted(id: record.id))
                        }
                    }
                    pendingDelete = nil
                },
                onDismiss: { pendingDelete = nil }
            )
            .animation(.easeOut(duration: 0.3), value: pendingDelete?.id)
        }
    }

    // MARK: Nav row

    private func navRow(theme: ThemeTokens) -> some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.ink)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle().fill(theme.secBg)
                            .overlay(Circle().stroke(theme.secLine, lineWidth: 1))
                    )
            }
            .buttonStyle(.pressable)
            .accessibilityIdentifier("history.back")

            Text(strings.History.title)
                .font(.bricolage(28))
                .tracking(-0.28)
                .foregroundColor(theme.ink)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    // MARK: List

    private func content(stats: HistoryStats, theme: ThemeTokens) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 20) {
                HistorySummaryCard(streak: displayedStreak, stats: stats, theme: theme)
                    .padding(.bottom, 2)

                // Charts land here in a later release — between the totals and the
                // first group, so adding them shifts nothing above or below.

                ForEach(Array(HistoryStats.monthGroups(records: props.records).enumerated()), id: \.element.id) { groupIndex, group in
                    monthGroup(group, groupIndex: groupIndex, theme: theme)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func monthGroup(_ group: HistoryMonthGroup, groupIndex: Int, theme: ThemeTokens) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(HistoryFormat.monthTitle(group.month).uppercased())
                    .font(.hanken(11.5, .bold))
                    .overlineTracking(1.6)
                    .foregroundColor(theme.mut)
                Spacer(minLength: 8)
                // On a long history the aggregate carries the value, not the rows.
                Text(strings.History.groupMeta(group.records.count,
                                               HistoryFormat.totalHours(group.totalHours)))
                    .font(.hanken(12, .semibold))
                    .foregroundColor(theme.faint)
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)

            VStack(spacing: 0) {
                ForEach(Array(group.records.enumerated()), id: \.element.id) { index, record in
                    if index > 0 {
                        Rectangle().fill(theme.surfaceLine).frame(height: 1)
                    }
                    SwipeToDeleteRow(
                        theme: theme,
                        onDelete: { pendingDelete = record },
                        onTap: { toggle(record) }
                    ) {
                        HistoryRow(record: record, isExpanded: expandedID == record.id, theme: theme)
                    }
                    .modifier(RowEntrance(index: groupIndex == 0 ? index : 8,
                                          appeared: appeared,
                                          reduceMotion: reduceMotion))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(theme.surfaceLine, lineWidth: 1))
                    .shadow(color: theme.cardShadow, radius: 30, x: 0, y: 12)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }

    /// Accordion: at most one record open, so the screen never becomes a wall of detail.
    private func toggle(_ record: FastRecord) {
        let animation: Animation? = reduceMotion
            ? nil
            : .timingCurve(0.22, 0.8, 0.3, 1, duration: 0.28)
        withAnimation(animation) {
            expandedID = expandedID == record.id ? nil : record.id
        }
        if !reduceMotion {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

/// Rows on the first screen fade and rise into place, staggered. Reduce Motion gets
/// a plain crossfade — no movement, no stagger.
private struct RowEntrance: ViewModifier {
    let index: Int
    let appeared: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        if reduceMotion {
            content.opacity(appeared ? 1 : 0)
        } else {
            content
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 6)
                .animation(
                    .timingCurve(0.22, 0.8, 0.3, 1, duration: 0.32)
                        .delay(Double(min(index, 8)) * 0.03),
                    value: appeared
                )
        }
    }
}

/// Trailing swipe reveals Delete. A full swipe never deletes on its own: the
/// confirmation is the point, since there is no undo.
private struct SwipeToDeleteRow<Content: View>: View {
    let theme: ThemeTokens
    let onDelete: () -> Void
    let onTap: () -> Void
    @ViewBuilder let content: Content

    @Environment(\.layoutDirection) private var layoutDirection
    @State private var offset: CGFloat = 0
    @State private var revealed = false

    private let actionWidth: CGFloat = 92
    /// Which way the row travels: toward the trailing edge, whichever side that is.
    private var direction: CGFloat { layoutDirection == .rightToLeft ? 1 : -1 }

    var body: some View {
        ZStack {
            // The action fills exactly the strip the row has been pulled aside by, so
            // it never sits under the (translucent) row content at rest.
            HStack {
                Spacer(minLength: 0)
                Button(action: {
                    close()
                    onDelete()
                }) {
                    Text(strings.History.delete)
                        .font(.hanken(14.5, .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .frame(width: abs(offset))
                        .frame(maxHeight: .infinity)
                        .background(Color.red)
                        .clipped()
                }
                .accessibilityIdentifier("history.row.delete")
                .disabled(!revealed)
            }

            content
                .offset(x: offset)
                .onTapGesture {
                    if revealed { close() } else { onTap() }
                }
                .gesture(
                    DragGesture(minimumDistance: 14)
                        .onChanged { value in
                            // Ignore a drag that is mostly vertical — that belongs to
                            // the scroll view.
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            let travel = value.translation.width * direction
                            offset = direction * min(actionWidth, max(0, travel))
                        }
                        .onEnded { value in
                            let travel = value.translation.width * direction
                            withAnimation(.easeOut(duration: 0.2)) {
                                revealed = travel > actionWidth / 2
                                offset = revealed ? direction * actionWidth : 0
                            }
                        }
                )
        }
        .accessibilityAction(named: Text(strings.History.delete), onDelete)
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.2)) {
            revealed = false
            offset = 0
        }
    }
}
