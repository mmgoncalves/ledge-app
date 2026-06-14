import Foundation

@Observable
final class HomeViewModel {

    // MARK: - State

    enum ViewState {
        case loading
        case loaded(cycle: BillingCycle, summary: CycleSummary)
        case noCycle
        case error(String)
    }

    var state: ViewState = .loading
    var showAddTransaction: Bool = false

    // MARK: - Dependencies

    private let useCase: GetCurrentCycleSummaryUseCaseProtocol

    // MARK: - Init

    init(useCase: GetCurrentCycleSummaryUseCaseProtocol) {
        self.useCase = useCase
    }

    // MARK: - Public

    func refresh() async {
        await load()
    }

    func load() async {
        state = .loading
        do {
            if let result = try await useCase.execute() {
                state = .loaded(cycle: result.cycle, summary: result.summary)
            } else {
                state = .noCycle
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
