import SwiftUI

/// Shared label/caption geometry for actions in the plan editor and history.
/// The caller owns its button, background, state and trailing affordance.
struct LabeledActionRow<Trailing: View>: View {
    let title: String
    let caption: String
    let theme: ThemeTokens
    var isEmphasized = false
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.hanken(16, isEmphasized ? .semibold : .medium))
                    .foregroundColor(isEmphasized ? theme.deep : theme.ink)
                Text(caption)
                    .font(.hanken(13))
                    .lineSpacing(2.6)
                    .foregroundColor(theme.mut)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing()
        }
        .frame(minHeight: 56)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
