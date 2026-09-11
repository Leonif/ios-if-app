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
                Section(SunnahStrings.eve) {
                    Picker(SunnahStrings.hour, selection: Binding(
                        get: { state.settings.minuteOfDay / 60 },
                        set: { value in updateTime(value * 60 + state.settings.minuteOfDay % 60) })) {
                        ForEach(0..<24) { Text(String(format: "%02d", $0)).tag($0) }
                    }.accessibilityIdentifier("sunnah.hour")
                    Picker(SunnahStrings.minute, selection: Binding(
                        get: { state.settings.minuteOfDay % 60 },
                        set: { value in updateTime(state.settings.minuteOfDay / 60 * 60 + value) })) {
                        ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                    }.accessibilityIdentifier("sunnah.minute")
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
