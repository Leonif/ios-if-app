//
//  StoreRepositoryProtocol.swift
//  IFApp
//

protocol StoreRepositoryProtocol {
    func refresh() async -> (entitlement: Entitlement, product: ProProductInfo?)
    func purchase() async -> PurchaseOutcome
    func restore() async -> RestoreOutcome
    func entitlementUpdates() -> AsyncStream<Entitlement>
}
