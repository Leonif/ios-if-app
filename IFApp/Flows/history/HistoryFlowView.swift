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
    let streak: StreakStatus
    /// Whether a fast is in flight. Picks which action the empty state offers — see
    /// `HistoryEmptyAction`.
    let isRunning: Bool
    /// Whether the export is unlocked. `unknown` locks exactly like `free` — Pro is
    /// never handed out on a guess.
    let isPro: Bool
    /// The written CSV waiting to be shared; the share sheet is up while it exists.
    let exportFile: URL?

    init(state: AppState) {
        records = state.historyState.records
        streak = state.streak
        isRunning = state.timerState.isRunning
        isPro = state.proState.isPro
        exportFile = state.historyState.exportFile
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

    var body: some View {
        let theme = ThemeTokens.resolve(colorScheme)
        let stats = HistoryStats.compute(records: props.records)

        VStack(spacing: 0) {
            navRow(theme: theme)

            if props.records.isEmpty {
                ScrollView {
                    HistoryEmptyState(theme: theme,
                                      action: props.isRunning ? .backToFast : .startFast) {
                        // Both leave the screen; only the invitation also has a fast
                        // to start on the way out.
                        if !props.isRunning { onStartFast() }
                        dismiss()
                    }
                    .padding(.top, 90)
                }
            } else {
                content(stats: stats, theme: theme)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.historyBackground.ignoresSafeArea())
        // The bar is hidden, and the back button is *not* separately hidden: that
        // modifier switches the pop gesture off outright. Hiding the bar turns out to
        // suppress it too, so the gesture is put back by hand below (F-9).
        .toolbar(.hidden, for: .navigationBar)
        .background(InteractivePopGesture().frame(width: 0, height: 0))
        .connect(to: store, mapState: { HistoryProps(state: $0) }, onPropsChange: { props = $0 })
        .onAppear {
            store.dispatch(AppLifecycleAction.historyOpened(source: source))
            if source == .eatingWindow {
                expandedID = HistoryStats.monthGroups(records: props.records).first?.records.first?.id
            }
            // Drives the entry animation: rows rise into place on the first frame only.
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : nil) { appeared = true }
        }
        // Apple's sheet, so it is presented the system way rather than as an overlay
        // with our own motion numbers.
        .sheet(isPresented: Binding(
            get: { props.exportFile != nil },
            set: { if !$0 { store.dispatch(HistoryAction.exportFinished(shared: false)) } }
        )) {
            if let file = props.exportFile {
                ShareSheet(file: file) { completed in
                    store.dispatch(HistoryAction.exportFinished(shared: completed))
                }
            }
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

            // No records, no export: the empty branch below already says what this
            // screen is for, and a control that can only produce an empty file would
            // be a dead end needing its own explanation.
            if !props.records.isEmpty {
                exportButton(theme: theme)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    /// The system share affordance, in the same 34pt circle the back button uses —
    /// the screen's own pattern for a nav control, since the offer handoff draws no
    /// mockup for this one. Locked, it carries the lock glyph from that handoff.
    private func exportButton(theme: ThemeTokens) -> some View {
        Button(action: {
            // Locked, the control is a door rather than a statement (decision 93).
            // The trigger is the existing `manual` — by its own definition that value
            // means "the offer was opened from a permanent entry", and a lock that
            // sits on the history screen for as long as Pro is not owned is exactly
            // that. A trigger of its own would split 20-35 monthly impressions into
            // two columns of noise instead of a distribution.
            if props.isPro {
                store.dispatch(ExportHistoryThunk())
            } else {
                store.dispatch(ProAction.offerOpened(trigger: .manual))
            }
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(props.isPro ? theme.ink : theme.mut)
                // The glyph's own baseline sits low inside its box; the nudge puts
                // the arrow, not the box, in the middle of the circle.
                .offset(y: -1)
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(theme.secBg)
                        .overlay(Circle().stroke(theme.secLine, lineWidth: 1))
                )
                .overlay(alignment: .bottomTrailing) {
                    if !props.isPro {
                        Image("pro-lock")
                            .renderingMode(.template)
                            .foregroundColor(theme.deep)
                            .padding(3)
                            .background(
                                Circle().fill(theme.accent.opacity(0.14))
                                    .overlay(Circle().stroke(theme.accent.opacity(0.34), lineWidth: 1))
                            )
                            .background(Circle().fill(theme.historyBackground))
                            .offset(x: 2, y: 2)
                    }
                }
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(strings.History.export)
        // The lock badge is decorative to the accessibility tree and the label above
        // overrides whatever the glyph would have contributed, so without these two the
        // locked and unlocked states of the control are indistinguishable to VoiceOver.
        // The tier goes in the value rather than the hint alone because hints are
        // switchable and delayed: a gate needs one channel the user cannot turn off.
        .accessibilityValue(props.isPro ? "" : strings.Pro.productName)
        .accessibilityHint(props.isPro ? "" : strings.Pro.lockedDestinationHint)
        .accessibilityIdentifier("history.export")
    }

    // MARK: List

    private func content(stats: HistoryStats, theme: ThemeTokens) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 20) {
                // Same projection the main screen shows — one rule, one number.
                HistorySummaryCard(
                    streak: props.streak.displayed(at: Clock.now()),
                    stats: stats,
                    // The raw counter, not the projection above it: whether the reader
                    // is a beginner is a fact about their past, and a streak that
                    // lapsed yesterday displays as 0 without making them one.
                    showsFirstNote: HistoryStats.showsFirstNote(fastsCount: stats.fastsCount,
                                                                streakCount: props.streak.count),
                    theme: theme
                )
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

/// Puts the system's edge-swipe back on a screen that hides the navigation bar.
///
/// Hiding the bar takes the interactive pop gesture with it, and the recogniser is not
/// merely disabled — the navigation controller's own delegate vetoes it in
/// `gestureRecognizerShouldBegin`, so flipping `isEnabled` changes nothing on its own.
/// Both are done here: the flag, and a delegate that allows the pop whenever there is
/// something to pop back to.
///
/// Why not a `DragGesture`: a hand-rolled one is not the system gesture. It does not
/// track interactively, it does not mirror itself to the trailing edge in RTL, and it
/// would compete with the horizontal drag `SwipeToDeleteRow` already owns.
///
/// Nothing is drawn — the controller exists only to reach the navigation controller —
/// so the header is untouched and no system back button can appear: the bar is still
/// hidden, and hiding it is what hid the button.
private struct InteractivePopGesture: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { Host() }
    func updateUIViewController(_ controller: UIViewController, context: Context) {}

    private final class Host: UIViewController, UIGestureRecognizerDelegate {
        /// The recogniser belongs to the navigation controller, which outlives this
        /// screen, so what was borrowed is given back on the way out. A delegate left
        /// behind on the root is the classic way to wedge navigation for good.
        private weak var borrowed: UIGestureRecognizer?
        private weak var previousDelegate: (any UIGestureRecognizerDelegate)?
        /// Both borrowed properties are given back, not just the delegate: an
        /// `isEnabled` that was deliberately false somewhere else would otherwise stay
        /// on after this screen, and that misfires far from here.
        private var previousEnabled: Bool?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard let gesture = navigationController?.interactivePopGestureRecognizer,
                  gesture.delegate !== self else { return }
            borrowed = gesture
            previousDelegate = gesture.delegate
            previousEnabled = gesture.isEnabled
            gesture.delegate = self
            gesture.isEnabled = true
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            guard borrowed?.delegate === self else { return }
            borrowed?.delegate = previousDelegate
            if let previousEnabled { borrowed?.isEnabled = previousEnabled }
        }

        /// The depth check is not ceremony: allowing the gesture on the root view
        /// controller is what makes a navigation controller stop responding to pushes
        /// afterwards.
        ///
        /// Note the delegate is replaced wholesale, not proxied: this type answers two
        /// of the five methods and the original is no longer asked any of them — the
        /// rest fall back to the protocol defaults. That holds today only because the
        /// one behaviour we know it had (simultaneous recognition) is reproduced below.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }

        /// The rows own a horizontal drag of their own; the two must not run together.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            false
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
