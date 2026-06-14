protocol TransactionRepository: AnyObject {
    /// Cria um lançamento no ciclo indicado.
    /// Retorna o primeiro lançamento criado (ou a primeira parcela, se parcelado).
    func createTransaction(cycleId: String, input: NewTransaction) async throws -> Transaction
}
