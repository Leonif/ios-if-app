# Redux - notes for agents

Why the store package is the way it is. Read the section of a file before editing it; an edit that changes or cancels a point below updates the point in the same commit.

## Connector.swift

- `ReduxConnector.lastProps` — the last mapped value, kept for a manual comparison through `areEqual`; the `Equatable` overload of `connect` uses plain `==`.

## Graph.swift

- `Graph.state` — read from the store on every access, never cached.

## ImprovedStoreV2.swift

- `ImprovedStoreV2.storeLock` — one recursive lock for the whole store; `internalState` and `internalMiddlewares` are stored directly and protected by it.
- `ImprovedStoreV2.dispatch(_:)` — thunk — the state snapshot and the middlewares' `handle(thunk:state:)` happen atomically under the lock; the thunk then executes asynchronously on that snapshot.
- `ImprovedStoreV2.processActionDirectly(_:)` — the lock covers only the state mutation. Holding it during the publisher sends or the middleware calls can deadlock when a subscriber or middleware dispatches back on a thread already waiting for the lock, so notifications and middleware run outside it. Consequence for every middleware: it is handed the state after the reducer, not before.
- `Store` — the `ObservableObject` facade: forwards the publishers and dispatch of `ImprovedStoreV2`, and mirrors its UI-thread state publisher into `@Published state`.

## Middleware.swift

- `DispatchFunction` — one value that dispatches both actions and thunks, handed to middleware.

## ThunkContext.swift

- `ThunkContext` — a `Sendable` wrapper for running thunks in a `TaskGroup`. `@unchecked` rests on the state being a read-only snapshot; dispatch goes back through the store, whose reduce step is serialized by its lock (middlewares run outside it).

## ThunkExecutionError.swift

- `ThunkExecutionError` — a shared error for thunk execution failures when state or context is invalid; `origin` names the thunk (or feature) that reported it.
- `ThunkExecutionError.invalidState(origin:)` — the state could not be cast to the expected type (e.g. `AppState`).
