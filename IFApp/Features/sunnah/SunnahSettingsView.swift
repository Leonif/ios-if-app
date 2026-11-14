//
//  SunnahSettingsView.swift
//  IFApp
//

import SwiftUI

struct SunnahSettingsView: View {
    let state: SunnahState
    let onChange: (SunnahSettings) -> Void
    let onRetry: () -> Void
    let onSettings: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = ThemeTokens.resolve(colorScheme)

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header(theme)

                if isDenied {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(SunnahStrings.denied)
                            .font(.hanken(15, .medium))
                            .foregroundColor(theme.sec)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("sunnah.status")
                        PrimaryButton(title: SunnahStrings.settings, theme: theme,
                                      action: onSettings)
                            .accessibilityIdentifier("sunnah.settings")
                    }
                    .padding(18)
                    .card(theme)
                    .padding(.bottom, 18)
                }

                VStack(spacing: 0) {
                    toggleRow(SunnahStrings.weekly, binding(\.weekly), theme,
                              identifier: "sunnah.weekly")
                    divider(theme)
                    toggleRow(SunnahStrings.whiteDays, binding(\.whiteDays), theme,
                              identifier: "sunnah.whiteDays")
                }
                .card(theme)
                .tint(isDenied ? theme.mut : theme.accent)

                Text(SunnahStrings.note)
                    .font(.hanken(12.5))
                    .lineSpacing(4)
                    .foregroundColor(theme.mut)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .padding(.bottom, 18)

                HStack(spacing: 12) {
                    Text(SunnahStrings.eve)
                        .font(.hanken(15, .medium))
                        .foregroundColor(theme.ink)
                    Spacer(minLength: 8)
                    DatePicker(SunnahStrings.eve, selection: reminderTime,
                               displayedComponents: .hourAndMinute)
                        .environment(\.locale, .latinDigits)
                        .labelsHidden()
                        .tint(theme.accent)
                        .accessibilityIdentifier("sunnah.time")
                        .disabled(!state.settings.enabled)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 58)
                .card(theme)
                .opacity(state.settings.enabled ? 1 : 0.62)

                if !isDenied {
                    HStack(alignment: .top, spacing: 11) {
                        Circle()
                            .fill(statusColor(theme))
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)
                        Text(statusText)
                            .font(.hanken(13.5, .medium))
                            .foregroundColor(theme.sec)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("sunnah.status")
                        Spacer(minLength: 0)
                        if state.delivery == .failed {
                            Button(SunnahStrings.retry, action: onRetry)
                                .font(.hanken(13.5, .semibold))
                                .foregroundColor(theme.deep)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .card(theme)
                    .padding(.top, 12)
                }

                if !isDenied && state.settings.enabled && !state.upcoming.isEmpty {
                    Text(SunnahStrings.upcoming.uppercased())
                        .font(.hanken(11.5, .semibold))
                        .overlineTracking(1.4)
                        .foregroundColor(theme.mut)
                        .padding(.top, 22)
                        .padding(.bottom, 9)
                    VStack(spacing: 0) {
                        ForEach(state.upcoming, id: \.self) { date in
                            Text(date.formatted(Date.FormatStyle.latinDigits.day().month().year()))
                                .font(.hanken(15, .medium))
                                .foregroundColor(theme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .frame(minHeight: 48)
                        }
                    }
                    .card(theme)
                }

                Text(SunnahStrings.calendar)
                    .font(.hanken(12))
                    .lineSpacing(4)
                    .foregroundColor(theme.mut)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 18)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .background(theme.sheetBg.ignoresSafeArea())
    }

    private var isDenied: Bool { state.delivery == .denied }

    private func header(_ theme: ThemeTokens) -> some View {
        HStack(spacing: 12) {
            Text(SunnahStrings.title)
                .font(.bricolage(22, .semibold))
                .displayTracking(22, -0.01)
                .foregroundColor(theme.ink)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.ink)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle().fill(theme.secBg)
                            .overlay(Circle().stroke(theme.secLine, lineWidth: 1))
                    )
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(strings.Pro.close)
            .accessibilityIdentifier("sunnah.close")
        }
        .padding(.bottom, 22)
    }

    private func toggleRow(_ title: String, _ value: Binding<Bool>, _ theme: ThemeTokens,
                           identifier: String) -> some View {
        Toggle(isOn: value) {
            Text(title)
                .font(.hanken(15.5, .medium))
                .foregroundColor(theme.ink)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 58)
        .accessibilityIdentifier(identifier)
    }

    private func divider(_ theme: ThemeTokens) -> some View {
        Rectangle().fill(theme.surfaceLine).frame(height: 1).padding(.horizontal, 16)
    }

    private func statusColor(_ theme: ThemeTokens) -> Color {
        switch state.delivery {
        case .scheduled: return theme.accent
        case .failed: return .red
        default: return theme.faint
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
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                let calendar = Calendar.current
                let minute = SunnahSettings.clamped(minuteOfDay: state.settings.minuteOfDay)
                let day = calendar.startOfDay(for: Clock.now())
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

private extension View {
    func card(_ theme: ThemeTokens) -> some View {
        background(RoundedRectangle(cornerRadius: 16).fill(theme.backgroundBase))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.surfaceLine, lineWidth: 1))
    }
}
