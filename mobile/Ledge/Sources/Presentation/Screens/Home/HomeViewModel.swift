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

    enum ExportState {
        case idle
        case loading
        case error(String)
    }

    var state: ViewState = .loading
    var showAddTransaction: Bool = false

    // Export
    var exportState: ExportState = .idle
    var showExportPicker: Bool = false
    var exportData: Data?
    var exportFormat: ExportFormat = .json
    var showShareSheet: Bool = false

    // MARK: - Dependencies

    private let summaryUseCase: GetCurrentCycleSummaryUseCaseProtocol
    private let exportUseCase: ExportDataUseCaseProtocol

    // MARK: - Init

    init(
        useCase: GetCurrentCycleSummaryUseCaseProtocol,
        exportUseCase: ExportDataUseCaseProtocol = ExportDataUseCase(repository: ExportRepositoryImpl())
    ) {
        self.summaryUseCase = useCase
        self.exportUseCase = exportUseCase
    }

    // MARK: - Summary

    func refresh() async {
        await load()
    }

    func load() async {
        state = .loading
        do {
            if let result = try await summaryUseCase.execute() {
                state = .loaded(cycle: result.cycle, summary: result.summary)
            } else {
                state = .noCycle
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Export

    func export(format: ExportFormat) async {
        exportState = .loading
        exportFormat = format
        do {
            exportData = try await exportUseCase.execute(format: format)
            exportState = .idle
            showShareSheet = true
        } catch {
            exportState = .error(error.localizedDescription)
        }
    }
}
