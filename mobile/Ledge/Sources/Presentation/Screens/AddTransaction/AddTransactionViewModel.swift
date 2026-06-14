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

    /// Apenas os dígitos digitados pelo usuário (ex: "12350" = R$ 123,50).
    /// Nunca expor diretamente na UI — usar `amountDisplayText` e `updateAmount(_:)`.
    private(set) var amountDigits: String = ""
    var description: String = ""
    var type: TransactionType = .essential
    var paymentMethod: PaymentMethod = .pix
    var date: Date = Calendar.current.startOfDay(for: .now)
    var isInstallment: Bool = false
    var installmentTotal: Int = 2

    var saveState: SaveState = .idle

    // MARK: - Computed

    /// Texto formatado em Real para exibição no TextField (ex: "1.234,56").
    var amountDisplayText: String {
        guard let cents = amountInCents else { return "" }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? ""
    }

    /// Valor total digitado em centavos.
    var amountInCents: Int? {
        guard !amountDigits.isEmpty, let value = Int(amountDigits), value > 0 else { return nil }
        return value
    }

    var isValid: Bool {
        amountInCents != nil && !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var effectiveInstallmentTotal: Int {
        (isInstallment && paymentMethod == .creditCard) ? installmentTotal : 1
    }

    // MARK: - Input handling

    /// Chamado pelo TextField a cada keystroke; extrai só os dígitos e limita a 10 chars.
    func updateAmount(_ rawInput: String) {
        let digits = rawInput.filter(\.isNumber)
        amountDigits = String(digits.prefix(10))
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
        guard let totalCents = amountInCents else { return }
        saveState = .saving

        let installments = effectiveInstallmentTotal
        // Valor por parcela: divide o total e arredonda para centavos inteiros
        let perInstallmentCents = Int((Double(totalCents) / Double(installments)).rounded())

        let input = NewTransaction(
            description: description.trimmingCharacters(in: .whitespaces),
            amount: perInstallmentCents,
            date: date,
            type: type,
            paymentMethod: paymentMethod,
            installmentTotal: installments
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
