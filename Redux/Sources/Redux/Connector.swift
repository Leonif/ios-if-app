//
//  Connector.swift
//  Redux
//
//  Created by Leonid-user on 29.08.2025.
//
import SwiftUI

public struct ReduxConnector<Props, UIState: Equatable>: ViewModifier {
    private var store: Store<UIState>

    private let mapState: (UIState) -> Props
    private let onPropsChange: (Props) -> Void
    private let areEqual: (Props, Props) -> Bool

    // Store last value for manual comparison
    @State private var lastProps: Props?

    public init(
        store: Store<UIState>,
        mapState: @escaping (UIState) -> Props,
        onPropsChange: @escaping (Props) -> Void,
        areEqual: @escaping (Props, Props) -> Bool
    ) {
        self.store = store
        self.mapState = mapState
        self.onPropsChange = onPropsChange
        self.areEqual = areEqual
    }

    public func body(content: Content) -> some View {
        content
            .onReceive(
                store.statePublisherForUI
                    .map(mapState)
            ) { props in
                if let last = lastProps {
                    let isEqual = areEqual(last, props)
                    if isEqual { return }
                }
                lastProps = props
                onPropsChange(props)
            }
    }
}

public extension View {
    func connect<Props, State>(
        to store: Store<State>,
        mapState: @escaping (State) -> Props,
        areEqual: @escaping (Props, Props) -> Bool,
        onPropsChange: @escaping (Props) -> Void
    ) -> some View {
        modifier(ReduxConnector(
            store: store,
            mapState: mapState,
            onPropsChange: onPropsChange,
            areEqual: areEqual
        ))
    }

    // Overload for Equatable Props - uses standard == comparison
    func connect<Props: Equatable, State>(
        to store: Store<State>,
        mapState: @escaping (State) -> Props,
        onPropsChange: @escaping (Props) -> Void
    ) -> some View {
        modifier(ReduxConnector(
            store: store,
            mapState: mapState,
            onPropsChange: onPropsChange
        ) { $0 == $1 })
    }
}
