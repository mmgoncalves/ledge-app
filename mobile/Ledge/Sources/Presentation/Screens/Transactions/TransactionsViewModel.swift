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
    var allCycles: [BillingCycle] = []
    var currentCycleIndex: Int = 0

    var currentCycle: BillingCycle? { allCycles[safe: currentCycleIndex] }
    var canGoPrevious: Bool { currentCycleIndex > 0 }
    var canGoNext: Bool { currentCycleIndex < allCycles.count - 1 }

    // MARK: - Dependencies

    private let getCyclesUseCase: GetCyclesUseCaseProtocol
    private let getTransactionsUseCase: GetTransactionsUseCaseProtocol
    private let initialCycleId: String

    // MARK: - Init

    init(
        initialCycleId: String,
        getCyclesUseCase: GetCyclesUseCaseProtocol,
        getTransactionsUseCase: GetTransactionsUseCaseProtocol
    ) {
        self.initialCycleId = initialCycleId
        self.getCyclesUseCase = getCyclesUseCase
        self.getTransactionsUseCase = getTransactionsUseCase
    }

    // MARK: - Public

    func loadInitialData() async {
        state = .loading
        do {
            let cycles = try await getCyclesUseCase.execute()
            allCycles = cycles
            // Posiciona no ciclo inicial
            currentCycleIndex = cycles.firstIndex(where: { $0.id == initialCycleId }) ?? 0
            await loadTransactions()
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func goToPreviousCycle() async {
        guard canGoPrevious else { return }
        currentCycleIndex -= 1
        await loadTransactions()
    }

    func goToNextCycle() async {
        guard canGoNext else { return }
        currentCycleIndex += 1
        await loadTransactions()
    }

    func refresh() async {
        await loadTransactions()
    }

    // MARK: - Private

    private func loadTransactions() async {
        guard let cycle = currentCycle else { return }
        state = .loading
        do {
            let transactions = try await getTransactionsUseCase.execute(cycleId: cycle.id)
            state = transactions.isEmpty ? .empty : .loaded(transactions)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
