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
                Section {
                    Toggle(SunnahStrings.weekly, isOn: binding(\.weekly))
                        .accessibilityIdentifier("sunnah.weekly")
                    Toggle(SunnahStrings.whiteDays, isOn: binding(\.whiteDays))
                        .accessibilityIdentifier("sunnah.whiteDays")
                } footer: { Text(SunnahStrings.note) }
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
                Section {
                    Text(statusText).accessibilityIdentifier("sunnah.status")
                    if state.delivery == .denied {
                        Button(SunnahStrings.settings, action: onSettings)
                    }
                    if state.delivery == .failed {
                        Button(SunnahStrings.retry, action: onRetry)
                    }
                }
                if state.settings.enabled && !state.upcoming.isEmpty {
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
