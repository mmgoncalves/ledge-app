import Foundation

/// Vizinhos imediatos de um ciclo de fatura (anterior e próximo).
///
/// `previous` e `next` são `nil` quando o ciclo for o mais antigo
/// ou o mais recente, respectivamente.
struct CycleNeighbors {
    let previous: BillingCycle?
    let next: BillingCycle?
}
