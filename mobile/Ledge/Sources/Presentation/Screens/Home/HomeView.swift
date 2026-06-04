import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    let onLogout: () -> Void

    init(onLogout: @escaping () -> Void) {
        self.onLogout = onLogout
        self._viewModel = State(
            initialValue: HomeViewModel(
                useCase: GetCurrentCycleSummaryUseCase(
                    repository: BillingCycleRepositoryImpl()
                )
            )
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView("Carregando...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .noCycle:
                    NoCycleView()

                case .loaded(let cycle, let summary):
                    SummaryView(cycle: cycle, summary: summary)

                case .error(let message):
                    ErrorView(message: message) {
                        Task { await viewModel.load() }
                    }
                }
            }
            .navigationTitle("Ledge")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sair", action: onLogout)
                }
            }
        }
        .task { await viewModel.load() }
    }
}

// MARK: - Summary view

private struct SummaryView: View {
    let cycle: BillingCycle
    let summary: CycleSummary

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                cyclePeriodHeader
                summaryCards
                transactionCountFooter
            }
            .padding()
        }
    }

    private var cyclePeriodHeader: some View {
        VStack(spacing: 4) {
            Text("Ciclo atual")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(cycle.formattedPeriod)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var summaryCards: some View {
        VStack(spacing: 12) {
            SummaryCard(
                title: "Receitas",
                amount: summary.totalIncome,
                color: .green,
                icon: "arrow.down.circle.fill"
            )
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Essenciais",
                    amount: summary.totalEssential,
                    color: .blue,
                    icon: "house.fill"
                )
                SummaryCard(
                    title: "Não essenciais",
                    amount: summary.totalNonEssential,
                    color: .orange,
                    icon: "cart.fill"
                )
            }
            SummaryCard(
                title: "Saldo",
                amount: summary.balance,
                color: summary.balance >= 0 ? .green : .red,
                icon: "banknote.fill",
                isHighlighted: true
            )
        }
    }

    private var transactionCountFooter: some View {
        NavigationLink(destination: TransactionsView(cycle: cycle)) {
            HStack {
                Text("\(summary.transactionCount) lançamento\(summary.transactionCount == 1 ? "" : "s") no ciclo")
                    .font(.footnote)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Summary card

private struct SummaryCard: View {
    let title: String
    let amount: Int
    let color: Color
    let icon: String
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(amount.formattedAsBRL)
                .font(isHighlighted ? .title2.bold() : .title3.bold())
                .foregroundStyle(isHighlighted ? color : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(isHighlighted ? color.opacity(0.1) : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            isHighlighted
                ? RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1)
                : nil
        )
    }
}

// MARK: - No cycle view

private struct NoCycleView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Nenhum ciclo ativo")
                .font(.title3.bold())
            Text("Crie um ciclo de fatura para começar a registrar seus lançamentos.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error view

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.red)
            Text("Erro ao carregar")
                .font(.title3.bold())
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

extension Int {
    var formattedAsBRL: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: Double(self) / 100.0)) ?? "R$ 0,00"
    }
}
