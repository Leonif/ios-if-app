//
//  SunnahSettingsView.swift
//  IFApp
//
//  The opt-in for voluntary Sunnah reminders. One state on this screen is not a
//  variant of the others: with notifications refused in iOS Settings nothing here
//  can ever be delivered, and until SU-1 the screen said the opposite — a green
//  switch on top, a list of upcoming fasting dates below, and the refusal itself a
//  grey line between them. So `denied` reorders the screen rather than annotating
//  it: the refusal and the way out of it come first, the switches stop reading as a
//  running schedule, and the upcoming list is gone (the middleware stops sending
//  dates it did not schedule).
//

import SwiftUI

struct SunnahSettingsView: View {
    let state: SunnahState
    let onChange: (SunnahSettings) -> Void
    let onRetry: () -> Void
    let onSettings: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if isDenied {
                    Section {
                        Text(SunnahStrings.denied)
                            .accessibilityIdentifier("sunnah.status")
                        Button(SunnahStrings.settings, action: onSettings)
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("sunnah.settings")
                    }
                }
                // The switches stay operable while denied — they are how someone turns
                // the opt-in back off — but they lose the on-tint, which is the part
                // that claimed a schedule exists.
                Section {
                    Toggle(SunnahStrings.weekly, isOn: binding(\.weekly))
                        .accessibilityIdentifier("sunnah.weekly")
                    Toggle(SunnahStrings.whiteDays, isOn: binding(\.whiteDays))
                        .accessibilityIdentifier("sunnah.whiteDays")
                } footer: { Text(SunnahStrings.note) }
                    .tint(isDenied ? Color.secondary : nil)
                // One control for one fact. Two wheels — an hour and a minute picked
                // apart — asked the user to assemble a time the system already knows
                // how to ask for, in their own clock convention (12h/24h) and their own
                // digits, which the pair of number lists did not honour. It also cost
                // two strings of its own for labels the system picker does not need.
                //
                // Disabled while both switches are off: with nothing scheduled there is
                // no reminder for a time to belong to, and a live control there invited
                // someone to set an hour for a schedule that does not exist.
                Section {
                    DatePicker(SunnahStrings.eve, selection: reminderTime,
                               displayedComponents: .hourAndMinute)
                        // Latin digits, like every other number the app draws — and
                        // this control had to be told, because it formats its own. The
                        // language is untouched, so the clock convention is still the
                        // locale's own (24h in de, 12h in en). Without it Arabic read
                        // "٨:٠٠ م" above an upcoming-dates list pinned to Latin, which
                        // is the exact pair of numbering systems on one screen that
                        // `Locale.latinDigits` exists to prevent.
                        .environment(\.locale, .latinDigits)
                        .accessibilityIdentifier("sunnah.time")
                        .disabled(!state.settings.enabled)
                }
                if !isDenied {
                    Section {
                        Text(statusText).accessibilityIdentifier("sunnah.status")
                        if state.delivery == .failed {
                            Button(SunnahStrings.retry, action: onRetry)
                        }
                    }
                }
                // Never a list of dates under a refusal, whatever the state still holds
                // from before the permission changed.
                if !isDenied && state.settings.enabled && !state.upcoming.isEmpty {
                    Section(SunnahStrings.upcoming) {
                        ForEach(state.upcoming, id: \.self) { date in
                            Text(date.formatted(Date.FormatStyle.latinDigits.day().month().year()))
                        }
                    }
                }
                Section { Text(SunnahStrings.calendar) }
            }
            .navigationTitle(SunnahStrings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(strings.Pro.close)
                        .accessibilityIdentifier("sunnah.close")
                }
            }
        }
    }

    /// `denied` is the one delivery state the layout itself answers to.
    private var isDenied: Bool { state.delivery == .denied }

    /// `.denied` no longer reaches this text — the refusal owns a section of its own
    /// above, and this one is hidden while it does. The case stays because the switch
    /// is exhaustive over the states, not over the ones this row happens to render.
    private var statusText: String {
        switch state.delivery {
        case .off: return SunnahStrings.off
        case .checking: return SunnahStrings.checking
        case .scheduled: return SunnahStrings.scheduled
        case .denied: return SunnahStrings.denied
        case .failed: return SunnahStrings.failed
        }
    }
    /// The stored minute of a civil day, as the clock value the system picker takes.
    /// The date carried is today's — only the time components are read back — so the
    /// value stays a minute of a day and never becomes a calendar moment.
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                let calendar = Calendar.current
                let minute = SunnahSettings.clamped(minuteOfDay: state.settings.minuteOfDay)
                let day = calendar.startOfDay(for: Clock.now())
                // `bySettingHour` first because it is the one that survives a clock
                // change: on a spring-forward day, adding 20 hours to midnight lands
                // at 21:00. The fallback adds them anyway rather than handing back the
                // current time — a control that cannot resolve the stored setting must
                // not answer with "now", which is a different value stated as if it
                // were the one saved.
                return calendar.date(bySettingHour: minute / 60, minute: minute % 60,
                                     second: 0, of: day)
                    ?? day.addingTimeInterval(TimeInterval(minute * 60))
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                updateTime((parts.hour ?? 0) * 60 + (parts.minute ?? 0))
            }
        )
    }

    private func binding(_ key: WritableKeyPath<SunnahSettings, Bool>) -> Binding<Bool> {
        Binding(get: { state.settings[keyPath: key] }, set: { value in
            var settings = state.settings
            settings[keyPath: key] = value
            onChange(settings)
        })
    }
    private func updateTime(_ minute: Int) {
        var settings = state.settings
        settings.minuteOfDay = minute
        onChange(settings)
    }
}
