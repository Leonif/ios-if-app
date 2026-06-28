//
//  Container.swift
//  IFApp
//
//  Service Locator for dependency injection (see .cursor / architecture rules).
//  Usage: `let repo: SomeProtocol = container.inject()`.
//

import Foundation

final class Container {
    private var factories: [ObjectIdentifier: () -> Any] = [:]

    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        factories[ObjectIdentifier(type)] = factory
    }

    func inject<T>() -> T {
        guard let factory = factories[ObjectIdentifier(T.self)],
              let instance = factory() as? T else {
            fatalError("Container: no registration for \(T.self)")
        }
        return instance
    }
}

/// Global service locator. Registrations happen once at app launch via `AppDependencies.register()`.
let container = Container()
