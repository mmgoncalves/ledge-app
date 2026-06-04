import SwiftUI

struct TransactionsView: View {
    @State private var viewModel: TransactionsViewModel

    init(cycle: BillingCycle) {
        let repository = BillingCycleRepositoryImpl()
        self._viewModel = State(
            initialValue: TransactionsViewModel(
                initialCycle: cycle,
                getCycleNeighborsUseCase: GetCycleNeighborsUseCase(repository: repository),
                getTransactionsUseCase: GetTransactionsUseCase(repository: repository)
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            cycleNavigator
            Divider()
            contentArea
        }
        .navigationTitle("Lançamentos")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadInitialData() }
    }

    // MARK: - Cycle navigator

    private var cycleNavigator: some View {
        HStack {
            Button {
                Task { await viewModel.goToPreviousCycle() }
            } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
            }
            .disabled(!viewModel.canGoPrevious)

            Spacer()

            Text(viewModel.currentCycle.formattedPeriod)
                .font(.subheadline.bold())

            Spacer()

            Button {
                Task { await viewModel.goToNextCycle() }
            } label: {
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
            }
            .disabled(!viewModel.canGoNext)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Content area

    @ViewBuilder
    private var contentArea: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Carregando...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            emptyView

        case .loaded(let transactions):
            transactionsList(transactions)

        case .error(let message):
            ErrorStateView(message: message) {
                Task { await viewModel.refresh() }
            }
        }
    }

    // MARK: - Transactions list

    private func transactionsList(_ transactions: [Transaction]) -> some View {
        let grouped = Dictionary(grouping: transactions) { $0.date.dayStart }
        let sortedKeys = grouped.keys.sorted(by: >)

        return List {
            ForEach(sortedKeys, id: \.self) { day in
                Section(header: Text(day.formattedAsSection)) {
                    ForEach(grouped[day] ?? []) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await viewModel.refresh() }
    }

    // MARK: - Empty view

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Nenhum lançamento")
                .font(.title3.bold())
            Text("Adicione lançamentos a este ciclo.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Transaction row

private struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            typeIcon
            details
            Spacer()
            amountLabel
        }
        .padding(.vertical, 2)
    }

    private var typeIcon: some View {
        Image(systemName: transaction.type.systemIcon)
            .font(.title3)
            .foregroundStyle(transaction.type.color)
            .frame(width: 32)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(transaction.description)
                .font(.body)
                .lineLimit(1)
            HStack(spacing: 6) {
                Text(transaction.paymentMethod.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let index = transaction.installmentIndex, let total = transaction.installmentTotal {
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(index)/\(total)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var amountLabel: some View {
        let isIncome = transaction.type == .income
        return Text(transaction.amount.formattedAsBRL)
            .font(.body.monospacedDigit())
            .foregroundStyle(isIncome ? .green : .primary)
    }
}

// MARK: - Error state view

private struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Tentar novamente", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Helpers

private extension TransactionType {
    var color: Color {
        switch self {
        case .essential: return .blue
        case .nonEssential: return .orange
        case .income: return .green
        }
    }
}

private extension Date {
    var dayStart: Date {
        Calendar.current.startOfDay(for: self)
    }

    var formattedAsSection: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        return formatter.string(from: self).capitalized
    }
}

private extension BillingCycle {
    var formattedPeriod: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "d MMM"
        let start = formatter.string(from: startDate)
        formatter.dateFormat = "d MMM yyyy"
        let end = formatter.string(from: endDate)
        return "\(start) – \(end)"
    }
}
