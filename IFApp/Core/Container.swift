//
//  Container.swift
//  IFApp
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

let container = Container()
