//
//  HistoryFlowView+SwipeToDeleteRow.swift
//  IFApp
//

import SwiftUI

extension HistoryFlowView {
    struct SwipeToDeleteRow<Content: View>: View {
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
}
