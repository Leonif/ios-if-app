//
//  AnalyticsMiddleware.swift
//  IFApp
//
//  Central analytics: translates Redux actions into funnel events. This is the
//  single place that decides what gets tracked, so the user journey is auditable.
//

import Foundation
import Redux

final class AnalyticsMiddleware: Middleware {
    private let repo: AnalyticsRepositoryProtocol
    /// The plan last reported as the `current_plan` user property. Tapping the
    /// plan that is already selected is not a selection, so it must not re-fire.
    private var reportedPlan: Plan?
    /// The entitlement last written to `pro_status`, so the property is set once per
    /// actual change rather than on every action that carries the state along.
    private var reportedEntitlement: Entitlement?
    /// Pro substate as of the previous action — i.e. before the one being handled.
    /// Middleware sees state *after* the reducer, and the dismissal event needs the
    /// trigger the reducer has just cleared; this snapshot is where it still exists.
    /// Same device as `HistoryMiddleware.previousTimer`, for the same reason.
    private var previousPro: ProState?
    /// Sunnah substate as of the previous action, for the same reason and by the same
    /// device as `previousPro`: the one fact `sunnah_enabled` hangs off — that nothing
    /// was scheduled until this write — exists only *before* the write, and middleware
    /// is handed the state after it.
    private var previousSunnah: SunnahState?
    /// A `settingsChanged` armed a schedule that was not armed before, and the answer
    /// that says whether it can be delivered has not arrived yet.
    ///
    /// It exists because "the reminders were switched on" is an *edge*, and every
    /// control on that screen writes through the same action: the two switches and the
    /// reminder time all emit `settingsChanged`, and the time control is a wheel that
    /// emits one per detent. Read as "a write landed on an enabled schedule", the
    /// event would count a schedule armed once and then nudged by an hour as a dozen
    /// armings — and, worse, would count switching *off* one of two schedules as
    /// arming the other. The edge lives in `previousSunnah`, which is the settings as
    /// they stood before the write, and nowhere else.
    private var armingAwaitingAnswer = false

    init(repo: AnalyticsRepositoryProtocol = container.inject()) {
        self.repo = repo
    }

    func handle<State: Equatable>(thunk: Thunk, state: State) {}

    func handle<State: Equatable>(action: Action, state: State, dispatch: DispatchFunction) {
        let app = state as? AppState
        defer {
            if let app {
                previousPro = app.proState
                previousSunnah = app.sunnahState
            }
        }
        switch action {
        case let lifecycle as AppLifecycleAction:
            if case .appOpened = lifecycle, let app { reportCurrentPlan(app.planState.plan) }
            handle(lifecycle)
        case let timer as TimerAction:
            handle(timer, goalHours: app?.activeGoalHours ?? Plan.default.fastHours)
        case is PlanAction:
            // State here is post-reduce, so `plan` is already the saved choice.
            if let app { handlePlanSelected(app.planState.plan) }
        case let ui as UIAction:
            if case .planEditorClosed = ui, let app {
                let plan = app.planState.plan
                repo.log(.planConfirmed(plan: plan.analyticsLabel, goalHours: plan.hours))
            }
        case let history as HistoryAction:
            handle(history)
        case let pro as ProAction:
            handle(pro, trigger: trigger(after: app))
            if let app { reportProStatus(app.proState.entitlement) }
        case let endFast as EndFastAction:
            handle(endFast)
        case let sunnah as SunnahAction:
            if let app { handle(sunnah, settings: app.sunnahState.settings) }
        default:
            break
        }
    }

    /// The Sunnah opt-in. One event per switching-on, split across the two actions it
    /// takes to know both halves of it: which schedule was armed, and whether a
    /// reminder can be delivered at all.
    ///
    /// The subject is an edge, and the screen offers no action that states it. Both
    /// switches and the reminder time write through `settingsChanged`, and the reducer
    /// answers every one of them with `.checking` while the middleware goes and asks —
    /// so "a write landed on an enabled schedule" is true of a time nudged by an hour
    /// and of one of two switches being turned *off*, neither of which is anybody
    /// switching anything on. The edge is read from `previousSunnah` instead, and the
    /// note it leaves is spent by the delivery answer that follows.
    private func handle(_ action: SunnahAction, settings: SunnahSettings) {
        switch action {
        case .settingsChanged:
            if !settings.enabled {
                // Switched off before the answer came back: there is no longer a
                // schedule for the note to describe.
                armingAwaitingAnswer = false
            } else if previousSunnah?.settings.enabled == false {
                // The edge, and the only place it is visible: nothing was scheduled
                // before this write and something is scheduled after it.
                armingAwaitingAnswer = true
            }
            // A write on a schedule that was already armed — a time moved, a second
            // schedule added, one of two switched off — is left alone deliberately,
            // rather than assigned `false`. Assignment looked equivalent and was not:
            // flipping the second switch before the first one's answer arrives is one
            // switching-on, and the second write would have swallowed the note the
            // first one left. The window is the length of a scheduling round trip,
            // and the length of the permission dialog when that is up.
        case let .deliveryUpdated(delivery, _):
            // Raised on the answer rather than on the tap: half of what the event
            // reports is whether a reminder can be delivered at all, and the
            // permission is only known once it has been read. A `deliveryUpdated` from
            // a refresh, a cold start, a day change or a time-zone change finds no
            // note here and is silent.
            guard armingAwaitingAnswer else { return }
            armingAwaitingAnswer = false
            // Denied is the one delivery state that means nothing was written.
            // `.failed` is a permission that exists and a schedule that did not take —
            // a different fact, and not this parameter's.
            repo.log(.sunnahEnabled(mode: settings.analyticsMode,
                                    pushAllowed: delivery != .denied))
        case .refresh:
            break
        }
    }

    private func handle(_ action: EndFastAction) {
        // Only the refusal is worth a line — how often a real end runs into a saved
        // fast, and how often it is the start-clash kind that has no re-pick out of it.
        if case let .refused(_, unavoidable) = action {
            repo.log(.endFastRefused(unavoidable: unavoidable))
        }
    }

    private func handle(_ action: HistoryAction) {
        switch action {
        case .deleted:
            repo.log(.historyRecordDeleted)
        case let .exportFinished(shared):
            // Only a share that went through. Opening the sheet and backing out is
            // not an export, and counting it would inflate the one number the
            // import decision will be read off.
            if shared { repo.log(.historyExported) }
        case .recorded, .exportStarted, .exportFailed, .exportPrepared:
            // Saving a fast is already covered by `fast_stopped`; writing the file is
            // a step on the way, not the act.
            break
        }
    }

    /// The offer and the purchase. Every event here carries `trigger`, because at
    /// 20-35 shows a month the distribution over entry points is the only thing this
    /// release can actually read; a conversion rate off 0-1 purchases cannot be.
    private func handle(_ action: ProAction, trigger: String) {
        switch action {
        case .offerOpened:
            repo.log(.paywallShown(trigger: trigger))
        case .offerClosed:
            repo.log(.paywallDismissed(trigger: trigger))
        case .purchaseStarted:
            repo.log(.purchaseStarted(trigger: trigger, product: ProCatalog.productID))
        case .purchaseCompleted:
            repo.log(.purchaseCompleted(trigger: trigger, product: ProCatalog.productID))
        case .purchasePending:
            // Ask to Buy is not a purchase and not yet a loss — it is logged as the
            // reason the attempt did not end in Pro, and may still be approved later.
            repo.log(.purchaseFailed(trigger: trigger, reason: PurchaseFailure.pending.rawValue))
        case let .purchaseFailed(reason), let .restoreFailed(reason):
            repo.log(.purchaseFailed(trigger: trigger, reason: reason.rawValue))
        case .restoreCompleted:
            repo.log(.restoreCompleted)
        case .restoreStarted, .restoreFoundNothing, .storeResolved, .entitlementChanged,
             .nothingToRestoreExpired, .noticeShown, .noticeDismissed,
             .autoOfferArmed, .autoOfferCancelled:
            // Reading the entitlement is not a funnel step; the property below carries
            // the outcome. Restore that finds nothing is the same non-event, and the
            // two notices report something the user did not do.
            //
            // Arming and cancelling the automatic offer are deliberately silent: the
            // funnel counts shows, and a show is `offerOpened` above. An armed plan
            // that never fires is not a paywall the user saw, and logging it would put
            // the one readable number of this release — the distribution over
            // triggers — out by the whole suppression rate.
            break
        }
    }

    /// The entry point to report. The state holds it while the offer is up; on the
    /// dismissal the reducer has already cleared it, so the pre-reduce snapshot
    /// answers. Restore can also be run from the About sheet's own button with no
    /// offer open at all, and then neither snapshot holds a door — the trigger is
    /// `unknown`, not `manual`.
    ///
    /// It used to be `manual`, and that put two different things in one column: the
    /// permanent entries the user went looking for, and every event that simply had
    /// no entry point to report. The distribution over triggers is what 1.5.1's new
    /// doors are measured by, and they are measured against `manual` — so this
    /// fallback has to sit outside it.
    private func trigger(after app: AppState?) -> String {
        (app?.proState.trigger ?? previousPro?.trigger ?? .unknown).rawValue
    }

    private func reportProStatus(_ entitlement: Entitlement) {
        guard entitlement != reportedEntitlement else { return }
        reportedEntitlement = entitlement
        repo.setUserProperty(entitlement.analyticsValue, forName: "pro_status")
    }

    private func handle(_ action: AppLifecycleAction) {
        switch action {
        case .appOpened: repo.log(.appOpened)
        case .sourcesOpened: repo.log(.sourcesOpened)
        case let .sourceArticleOpened(articleID):
            repo.log(.sourceArticleOpened(articleID: articleID))
        case let .sourceOriginalOpened(articleID):
            repo.log(.sourceOriginalOpened(articleID: articleID))
        case let .sourceArticleClosed(articleID, reachedEnd):
            repo.log(.sourceArticleClosed(articleID: articleID, reachedEnd: reachedEnd))
        case let .sunnahOpened(source): repo.log(.sunnahOpened(source: source.rawValue))
        case let .historyOpened(source): repo.log(.historyOpened(source: source.rawValue))
        case let .reviewPrompted(trigger): repo.log(.reviewPrompted(trigger: trigger.rawValue))
        case let .streakMilestone(days): repo.log(.streakMilestone(days: days))
        case .appBecameActive: break     // internal gate signal, not a funnel event
        case .goalScreenSettled: break   // internal gate signal, not a funnel event
        case .pushAuthorizationResolved: break // re-schedule signal, not a funnel event
        case let .lastMealLogged(backdated, minutesAgo, inputMethod):
            repo.log(.lastMealLogged(backdated: backdated, minutesAgo: minutesAgo,
                                     inputMethod: inputMethod))
        case .fastChained:
            repo.log(.fastChained)
        case let .themeActive(dark):
            repo.log(.themeActive(dark: dark))
        }
    }

    private func handle(_ action: TimerAction, goalHours: Double) {
        switch action {
        case .started:
            repo.log(.fastStarted(goalHours: goalHours))
        case let .stopped(elapsed, qualifies, backdatedMinutes):
            let phase = PhaseProgress.compute(elapsed: elapsed, goalHours: goalHours).phase
            repo.log(.fastStopped(
                durationSeconds: Int(elapsed),
                completed: qualifies,
                stage: phase.analyticsValue,
                backdatedMinutes: backdatedMinutes
            ))
        case .stopUndone:
            repo.log(.fastStopUndone)
        case let .reset(elapsed):
            repo.log(.fastReset(elapsedMinutes: Int(elapsed / 60)))
        case .eatingStarted:
            repo.log(.eatingWindowStarted)
        case .eatingEnded:
            break
        case .timeAdjusted:
            repo.log(.timeAdjusted)
        case .goalCelebrated:
            repo.log(.goalReached(goalHours: goalHours))
        }
    }

    /// The plan editor saved a choice: one event plus the persistent property.
    private func handlePlanSelected(_ plan: Plan) {
        guard plan != reportedPlan else { return }
        repo.log(.planSelected(plan: plan.analyticsLabel, goalHours: plan.hours))
        reportCurrentPlan(plan)
    }

    /// Keeps `current_plan` on the user. Set on cold start too, so reports can be
    /// segmented by plan for the majority who never open the editor.
    private func reportCurrentPlan(_ plan: Plan) {
        reportedPlan = plan
        repo.setUserProperty(plan.analyticsLabel, forName: "current_plan")
    }
}
