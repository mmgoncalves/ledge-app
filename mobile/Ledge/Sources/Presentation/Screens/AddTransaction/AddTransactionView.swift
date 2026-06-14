import SwiftUI

struct AddTransactionView: View {
    @State private var viewModel: AddTransactionViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var amountFocused: Bool

    init(cycleId: String, onSuccess: @escaping () -> Void) {
        self._viewModel = State(
            initialValue: AddTransactionViewModel(
                cycleId: cycleId,
                useCase: CreateTransactionUseCase(
                    repository: TransactionRepositoryImpl()
                ),
                onSuccess: onSuccess
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                amountSection
                detailsSection
                typeSection
                paymentMethodSection
                if viewModel.paymentMethod == .creditCard {
                    installmentSection
                }
                dateSection
            }
            .navigationTitle("Novo lançamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
            }
            .alert("Erro ao salvar", isPresented: errorBinding) {
                Button("OK") { viewModel.saveState = .idle }
            } message: {
                if case .error(let msg) = viewModel.saveState {
                    Text(msg)
                }
            }
        }
        .onAppear { amountFocused = true }
    }

    // MARK: - Sections

    private var amountSection: some View {
        Section {
            HStack {
                Text("R$")
                    .foregroundStyle(.secondary)
                TextField("0,00", text: Binding(
                    get: { viewModel.amountDisplayText },
                    set: { viewModel.updateAmount($0) }
                ))
                .keyboardType(.numberPad)
                .focused($amountFocused)
                .font(.title2.bold())
            }
        } header: {
            Text("Valor")
        }
    }

    private var detailsSection: some View {
        Section {
            TextField("Ex: Aluguel, Supermercado...", text: $viewModel.description)
        } header: {
            Text("Descrição")
        }
    }

    private var typeSection: some View {
        Section {
            Picker("Tipo", selection: $viewModel.type) {
                ForEach([TransactionType.essential, .nonEssential, .income], id: \.self) { type in
                    Label(type.label, systemImage: type.systemIcon)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Tipo")
        }
    }

    private var paymentMethodSection: some View {
        Section {
            Picker("Forma de pagamento", selection: $viewModel.paymentMethod) {
                ForEach([PaymentMethod.pix, .debitCard, .creditCard, .cash], id: \.self) { method in
                    Text(method.label).tag(method)
                }
            }
        } header: {
            Text("Forma de pagamento")
        }
        .onChange(of: viewModel.paymentMethod) { _, newValue in
            if newValue != .creditCard {
                viewModel.isInstallment = false
            }
        }
    }

    private var dateSection: some View {
        Section {
            DatePicker(
                "Data",
                selection: $viewModel.date,
                displayedComponents: .date
            )
            .environment(\.locale, Locale(identifier: "pt_BR"))
        } header: {
            Text("Data")
        }
    }

    private var installmentSection: some View {
        Section {
            Toggle("Parcelado", isOn: $viewModel.isInstallment)
            if viewModel.isInstallment {
                Stepper(
                    "\(viewModel.installmentTotal)x",
                    value: $viewModel.installmentTotal,
                    in: 2...24
                )
            }
        } header: {
            Text("Parcelamento")
        }
    }

    // MARK: - Save button

    private var saveButton: some View {
        Group {
            if case .saving = viewModel.saveState {
                ProgressView()
            } else {
                Button("Salvar") {
                    Task { await viewModel.save() }
                }
                .disabled(!viewModel.isValid)
            }
        }
    }

    // MARK: - Helpers

    private var errorBinding: Binding<Bool> {
        Binding(
            get: {
                if case .error = viewModel.saveState { return true }
                return false
            },
            set: { _ in }
        )
    }
}
