import SwiftUI
import SwiftData

struct PortfolioView: View {
    let store: StockStore

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PortfolioHolding.symbol)
    private var holdings: [PortfolioHolding]

    @State private var showingAddHolding = false

    private func stock(for holding: PortfolioHolding) -> Stock? {
        store.stocks.first {
            $0.symbol.caseInsensitiveCompare(holding.symbol) == .orderedSame
        }
    }

    private var totalInvested: Double {
        holdings.reduce(0) {
            $0 + ($1.quantity * $1.purchasePrice)
        }
    }

    private var totalCurrentValue: Double {
        holdings.reduce(0) { total, holding in
            guard let stock = stock(for: holding),
                  stock.hasFetchedPrice else {
                return total
            }

            return total + (holding.quantity * stock.price)
        }
    }

    private var currencies: Set<String> {
        Set(holdings.compactMap { stock(for: $0)?.currency })
    }

    private var hasAllPrices: Bool {
        holdings.allSatisfy {
            stock(for: $0)?.hasFetchedPrice == true
        }
    }

    private var canShowTotals: Bool {
        !holdings.isEmpty && currencies.count == 1 && hasAllPrices
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Portfolio Summary") {
                    if holdings.isEmpty {
                        ContentUnavailableView(
                            "No Holdings Yet",
                            systemImage: "chart.pie",
                            description: Text(
                                "Add stocks you own to track their value."
                            )
                        )
                    } else if canShowTotals {
                        summaryRow(
                            "Invested",
                            value: totalInvested,
                            currency: currencies.first!
                        )

                        summaryRow(
                            "Current Value",
                            value: totalCurrentValue,
                            currency: currencies.first!
                        )

                        HStack {
                            Text("Unrealized Profit/Loss")

                            Spacer()

                            let profitLoss = totalCurrentValue - totalInvested

                            Text(
                                profitLoss,
                                format: .currency(code: currencies.first!)
                            )
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                profitLoss >= 0 ? .green : .red
                            )
                        }
                    } else {
                        Text(
                            currencies.count > 1
                                ? "Summary unavailable for mixed currencies."
                                : "Waiting for all holding prices to load."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }

                Section("Your Holdings") {
                    ForEach(holdings, id: \.symbol) { holding in
                        holdingRow(holding)
                    }
                    .onDelete(perform: deleteHoldings)
                }
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddHolding = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add holding")
                }

                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddHolding) {
                NavigationStack {
                    AddPortfolioHoldingView(store: store)
                }
            }
            .task(id: holdings.map(\.symbol).sorted().joined(separator: ",")) {
                await store.ensureStocks(
                    for: holdings.map {
                        (symbol: $0.symbol, name: $0.name)
                    }
                )
                await store.refreshQuotes(
                    for: holdings.map(\.symbol)
                )
            }
        }
    }

    private func summaryRow(
        _ title: String,
        value: Double,
        currency: String
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value, format: .currency(code: currency))
                .fontWeight(.semibold)
        }
    }

    @ViewBuilder
    private func holdingRow(
        _ holding: PortfolioHolding
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(holding.symbol)
                        .font(.headline)

                    Text(holding.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let stock = stock(for: holding),
                   stock.hasFetchedPrice {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(
                            holding.quantity * stock.price,
                            format: .currency(code: stock.currency)
                        )
                        .fontWeight(.semibold)

                        Text("Current value")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Price unavailable")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text("Shares: \(holding.quantity, format: .number)")

                Spacer()

                Text(
                    "Avg. cost: \(holding.purchasePrice, format: .currency(code: stock(for: holding)?.currency ?? "USD"))"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let stock = stock(for: holding),
               stock.hasFetchedPrice {
                let invested = holding.quantity * holding.purchasePrice
                let value = holding.quantity * stock.price
                let profitLoss = value - invested

                HStack {
                    Text("Unrealized P/L")

                    Spacer()

                    Text(
                        profitLoss,
                        format: .currency(code: stock.currency)
                    )
                    .foregroundStyle(profitLoss >= 0 ? .green : .red)
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 5)
    }

    private func deleteHoldings(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(holdings[index])
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete portfolio holding: \(error)")
        }
    }
}
