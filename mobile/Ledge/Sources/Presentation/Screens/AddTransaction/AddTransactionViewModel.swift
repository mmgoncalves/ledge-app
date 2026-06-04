import Foundation

@Observable
final class AddTransactionViewModel {

    // MARK: - State

    enum SaveState {
        case idle
        case saving
        case success
        case error(String)
    }

    // MARK: - Form fields

    var amountText: String = ""
    var description: String = ""
    var type: TransactionType = .essential
    var paymentMethod: PaymentMethod = .pix
    var date: Date = Calendar.current.startOfDay(for: .now)
    var isInstallment: Bool = false
    var installmentTotal: Int = 2

    var saveState: SaveState = .idle

    // MARK: - Computed

    /// Converte o texto digitado em centavos. Aceita "150" ou "150,50" ou "150.50".
    var amountInCents: Int? {
        let normalized = amountText
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(normalized), value > 0 else { return nil }
        return Int((value * 100).rounded())
    }

    var isValid: Bool {
        amountInCents != nil && !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var effectiveInstallmentTotal: Int {
        (isInstallment && paymentMethod == .creditCard) ? installmentTotal : 1
    }

    // MARK: - Dependencies

    private let cycleId: String
    private let useCase: CreateTransactionUseCaseProtocol
    let onSuccess: () -> Void

    // MARK: - Init

    init(
        cycleId: String,
        useCase: CreateTransactionUseCaseProtocol,
        onSuccess: @escaping () -> Void
    ) {
        self.cycleId = cycleId
        self.useCase = useCase
        self.onSuccess = onSuccess
    }

    // MARK: - Public

    func save() async {
        guard let cents = amountInCents else { return }
        saveState = .saving

        let input = NewTransaction(
            description: description.trimmingCharacters(in: .whitespaces),
            amount: cents,
            date: date,
            type: type,
            paymentMethod: paymentMethod,
            installmentTotal: effectiveInstallmentTotal
        )

        do {
            _ = try await useCase.execute(cycleId: cycleId, input: input)
            saveState = .success
            onSuccess()
        } catch {
            saveState = .error(error.localizedDescription)
        }
    }
}
