//
//  HistoryFlowView.swift
//  IFApp
//

import SwiftUI
import UIKit
import Redux

struct HistoryProps: Equatable {
    let records: [FastRecord]
    let streak: StreakStatus
    let isRunning: Bool
    let isPro: Bool
    let exportFile: URL?
    let isExporting: Bool
    let isExportBusy: Bool

    init(state: AppState) {
        records = state.historyState.records
        streak = state.streak
        isRunning = state.timerState.isRunning
        isPro = state.proState.isPro
        exportFile = state.historyState.exportFile
        isExporting = state.historyState.isExporting
        isExportBusy = state.historyState.isExportBusy
    }
}

struct HistoryFlowView: View {
    private let store: Store<AppState>
    let source: HistoryEntrySource
    let focusRecordID: UUID?
    let onStartFast: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @State private var props: HistoryProps
    @State private var expandedID: UUID?
    @State private var pendingDelete: FastRecord?

    init(store: Store<AppState>, source: HistoryEntrySource, focusRecordID: UUID? = nil,
         onStartFast: @escaping () -> Void) {
        self.store = store
        self.source = source
        self.focusRecordID = focusRecordID
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
        .toolbar(.hidden, for: .navigationBar)
        .background(InteractivePopGesture().frame(width: 0, height: 0))
        .connect(to: store, mapState: { HistoryProps(state: $0) }, onPropsChange: { props = $0 })
        .onAppear {
            store.dispatch(AppLifecycleAction.historyOpened(source: source))
            if let focusRecordID {
                expandedID = focusRecordID
            } else if source == .eatingWindow {
                expandedID = HistoryStats.monthGroups(records: props.records).first?.records.first?.id
            }
        }
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

    // MARK: - Nav row

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

    private func exportButton(theme: ThemeTokens) -> some View {
        Button(action: {
            if props.isPro {
                store.dispatch(ExportHistoryThunk())
            } else {
                store.dispatch(ProAction.offerOpened(trigger: .historyExport))
            }
        }) {
            LabeledActionRow(title: strings.History.exportTitle,
                             caption: strings.History.exportCaption,
                             theme: theme) {
                Group {
                    if props.isExporting {
                        ProgressView().tint(theme.deep)
                    } else if props.isPro {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.ink)
                            .offset(y: -1)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle().fill(theme.secBg)
                                    .overlay(Circle().stroke(theme.secLine, lineWidth: 1))
                            )
                    } else {
                        HStack(spacing: 6) {
                            Image("pro-lock").renderingMode(.template)
                            Text(verbatim: "PRO")
                                .font(.hanken(12, .semibold))
                                .tracking(0.48)
                                .environment(\.layoutDirection, .leftToRight)
                        }
                        .foregroundColor(theme.deep)
                        .padding(.leading, 9)
                        .padding(.trailing, 11)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(theme.accent.opacity(0.14))
                                .overlay(Capsule().stroke(theme.accent.opacity(0.34), lineWidth: 1))
                        )
                    }
                }
                .frame(width: props.isPro ? 44 : 76)
                .accessibilityHidden(true)
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.surfaceLine, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(strings.History.export)
        .accessibilityValue(props.isPro ? "" : strings.Pro.productName)
        .accessibilityHint(props.isPro ? "" : strings.Pro.lockedDestinationHint)
        .accessibilityIdentifier("history.export")
        .disabled(props.isExportBusy)
    }

    // MARK: - List

    private func content(stats: HistoryStats, theme: ThemeTokens) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 20) {
                HistorySummaryCard(
                    display: props.streak.display(at: Clock.now()),
                    stats: stats,
                    showsFirstNote: HistoryStats.showsFirstNote(fastsCount: stats.fastsCount,
                                                                streakCount: props.streak.count),
                    theme: theme
                )
                .padding(.bottom, 2)

                exportButton(theme: theme)

                ForEach(HistoryStats.monthGroups(records: props.records)) { group in
                    monthGroup(group, theme: theme)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func monthGroup(_ group: HistoryMonthGroup, theme: ThemeTokens) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(HistoryFormat.monthTitle(group.month).uppercased())
                    .font(.hanken(11.5, .bold))
                    .overlineTracking(1.6)
                    .foregroundColor(theme.mut)
                Spacer(minLength: 8)
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

private struct InteractivePopGesture: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { Host() }
    func updateUIViewController(_ controller: UIViewController, context: Context) {}

    private final class Host: UIViewController, UIGestureRecognizerDelegate {
        private weak var borrowed: UIGestureRecognizer?
        private weak var previousDelegate: (any UIGestureRecognizerDelegate)?
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

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            false
        }
    }
}

private struct SwipeToDeleteRow<Content: View>: View {
    let theme: ThemeTokens
    let onDelete: () -> Void
    let onTap: () -> Void
    @ViewBuilder let content: Content

    @Environment(\.layoutDirection) private var layoutDirection
    @State private var offset: CGFloat = 0
    @State private var revealed = false

    private let actionWidth: CGFloat = 92
    private var direction: CGFloat { layoutDirection == .rightToLeft ? 1 : -1 }

    var body: some View {
        ZStack {
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

            swipeableContent
        }
        .accessibilityAction(named: Text(strings.History.delete), onDelete)
    }

    @ViewBuilder
    private var swipeableContent: some View {
        let row = content
            .offset(x: offset)
            .onTapGesture {
                if revealed { close() } else { onTap() }
            }

        if #available(iOS 18.0, *) {
            row.gesture(HorizontalRowPan(
                onChanged: updateOffset,
                onEnded: settleOffset
            ))
        } else {
            row.gesture(
                DragGesture(minimumDistance: 14)
                    .onChanged { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        updateOffset(value.translation.width)
                    }
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        settleOffset(value.translation.width)
                    }
            )
        }
    }

    private func updateOffset(_ horizontalTranslation: CGFloat) {
        let travel = horizontalTranslation * direction
        offset = direction * min(actionWidth, max(0, travel))
    }

    private func settleOffset(_ horizontalTranslation: CGFloat) {
        let travel = horizontalTranslation * direction
        withAnimation(.easeOut(duration: 0.2)) {
            revealed = travel > actionWidth / 2
            offset = revealed ? direction * actionWidth : 0
        }
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.2)) {
            revealed = false
            offset = 0
        }
    }
}

@available(iOS 18.0, *)
private struct HorizontalRowPan: UIGestureRecognizerRepresentable {
    let onChanged: (CGFloat) -> Void
    let onEnded: (CGFloat) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.minimumNumberOfTouches = 1
        recognizer.maximumNumberOfTouches = 1
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        let horizontal = context.converter.translation(in: .local)?.x
            ?? recognizer.translation(in: recognizer.view).x
        switch recognizer.state {
        case .began, .changed:
            onChanged(horizontal)
        case .ended, .cancelled, .failed:
            onEnded(horizontal)
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
