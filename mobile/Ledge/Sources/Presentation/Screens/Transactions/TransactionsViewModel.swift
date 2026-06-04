import Foundation

@Observable
final class TransactionsViewModel {

    // MARK: - State

    enum ViewState {
        case loading
        case loaded([Transaction])
        case empty
        case error(String)
    }

    var state: ViewState = .loading
    var currentCycle: BillingCycle
    var neighbors: CycleNeighbors?

    var canGoPrevious: Bool { neighbors?.previous != nil }
    var canGoNext: Bool { neighbors?.next != nil }

    // MARK: - Dependencies

    private let getCycleNeighborsUseCase: GetCycleNeighborsUseCaseProtocol
    private let getTransactionsUseCase: GetTransactionsUseCaseProtocol

    // MARK: - Init

    init(
        initialCycle: BillingCycle,
        getCycleNeighborsUseCase: GetCycleNeighborsUseCaseProtocol,
        getTransactionsUseCase: GetTransactionsUseCaseProtocol
    ) {
        self.currentCycle = initialCycle
        self.getCycleNeighborsUseCase = getCycleNeighborsUseCase
        self.getTransactionsUseCase = getTransactionsUseCase
    }

    // MARK: - Public

    func loadInitialData() async {
        await loadCycleData(for: currentCycle)
    }

    func goToPreviousCycle() async {
        guard let previous = neighbors?.previous else { return }
        currentCycle = previous
        await loadCycleData(for: previous)
    }

    func goToNextCycle() async {
        guard let next = neighbors?.next else { return }
        currentCycle = next
        await loadCycleData(for: next)
    }

    func refresh() async {
        await loadCycleData(for: currentCycle)
    }

    // MARK: - Private

    /// Carrega transações e vizinhos do ciclo em paralelo.
    /// As setas ficam disponíveis assim que os vizinhos chegarem,
    /// sem bloquear a exibição da lista de transações.
    private func loadCycleData(for cycle: BillingCycle) async {
        state = .loading
        do {
            async let transactions = getTransactionsUseCase.execute(cycleId: cycle.id)
            async let fetchedNeighbors = getCycleNeighborsUseCase.execute(cycleId: cycle.id)

            let (txns, nbrs) = try await (transactions, fetchedNeighbors)
            neighbors = nbrs
            state = txns.isEmpty ? .empty : .loaded(txns)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
