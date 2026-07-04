//
//  ImprovedStoreV2.swift
//  Redux
//
//  Created by Leonid-user on 14.09.2025.
//
import Combine
import Foundation
import os

public final class ImprovedStoreV2<State: Equatable & Sendable>: @unchecked Sendable {
    private let stateSubject: CurrentValueSubject<State, Never>
    private let actionSubject = PassthroughSubject<Action, Never>()
    private let reducer: (State, Action) -> State

    // 1. Single recursive lock for the entire store
    private let storeLock = NSRecursiveLock()
    
    // 2. Store data directly (protected by the lock)
    private var internalState: State
    private var internalMiddlewares: [Middleware]

    public var statePublisher: AnyPublisher<State, Never> {
        stateSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public var statePublisherForUI: AnyPublisher<State, Never> {
        statePublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    public var actionsPublisherForUI: AnyPublisher<Action, Never> {
        actionsPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    public var actionsPublisher: AnyPublisher<Action, Never> {
        actionSubject.eraseToAnyPublisher()
    }

    public init(
        state: State,
        reducer: @escaping (State, Action) -> State,
        middlewares: [Middleware] = []
    ) {
        self.stateSubject = CurrentValueSubject(state)
        self.internalState = state
        self.reducer = reducer
        self.internalMiddlewares = middlewares
    }

    public func getCurrentState() -> State {
        return storeLock.withLock { internalState }
    }

    public func set(middlewares: [Middleware]) {
        storeLock.withLock { internalMiddlewares = middlewares }
    }

    public var middlewares: [Middleware] {
        storeLock.withLock { internalMiddlewares }
    }

    public func dispatch(_ action: Action) {
        processActionDirectly(action)
    }

    public func dispatch(_ thunk: Thunk) {
        Task { [weak self] in
            guard let self else { return }
            
            // Snapshot + notify middlewares atomically
            let currentState = storeLock.withLock {
                let state = self.internalState
                let middlewares = self.internalMiddlewares
                for middleware in middlewares {
                    middleware.handle(thunk: thunk, state: state)
                }
                return state
            }
            
            let sendableDispatch: @Sendable (Action) -> Void = { [weak self] action in
                self?.dispatch(action)
            }
            await thunk.execute(state: currentState, dispatch: sendableDispatch)
        }
    }

    private func processActionDirectly(_ action: Action) {
        let dispatchFunction = DispatchFunction(
            dispatchAction: { [weak self] action in self?.dispatch(action) },
            dispatchThunk: { [weak self] thunk in self?.dispatch(thunk) }
        )

        // Lock only for state mutation — holding lock during send/middleware
        // can cause deadlock if a subscriber or middleware dispatches back
        // on a thread that is already waiting for this lock.
        let (stateToSend, isChanged, capturedMiddlewares): (State, Bool, [Middleware]) = storeLock.withLock {
            let oldState = internalState
            let newState = reducer(oldState, action)
            let changed = newState != oldState
            if changed { internalState = newState }
            return (changed ? newState : oldState, changed, internalMiddlewares)
        }

        // Notifications and middleware run outside the lock
        if isChanged { stateSubject.send(stateToSend) }
        actionSubject.send(action)

        for middleware in capturedMiddlewares {
            middleware.handle(
                action: action,
                state: stateToSend,
                dispatch: dispatchFunction
            )
        }
    }
}

public final class Store<State: Equatable & Sendable>: ObservableObject {
    @Published public private(set) var state: State

    // Forward publishers from ImprovedStoreV2
    public var statePublisher: AnyPublisher<State, Never> {
        store.statePublisher
    }

    public var statePublisherForUI: AnyPublisher<State, Never> {
        store.statePublisherForUI
    }
    
    public var actionsPublisherForUI: AnyPublisher<Action, Never> {
        store.actionsPublisherForUI
    }
    
    public var actionsPublisher: AnyPublisher<Action, Never> {
        store.actionsPublisher
    }

    private let store: ImprovedStoreV2<State>
    private var cancellable: AnyCancellable?

    public init(store: ImprovedStoreV2<State>) {
        self.store = store
        state = store.getCurrentState()

        // Subscribe to changes and update the @Published state
        cancellable = store.statePublisherForUI
            .sink { [weak self] in self?.state = $0 }
    }

    // Delegate methods
    public func dispatch(_ action: Action) {
        store.dispatch(action)
    }
    
    public func dispatch(_ thunk: Thunk) {
        store.dispatch(thunk)
    }

    public var middlewares: [Middleware] {
        store.middlewares
    }

    public func set(middlewares: [Middleware]) {
        store.set(middlewares: middlewares)
    }

    public func getCurrentState() -> State {
        return store.getCurrentState()
    }
}
