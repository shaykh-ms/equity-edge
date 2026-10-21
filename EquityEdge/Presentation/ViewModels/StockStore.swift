
import Foundation
import Observation

@MainActor
@Observable
final class StockStore {

    var stocks: [Stock] = StockCatalogue.stocks
    var isLoading = false
    var errorMessage: String?

    private let repository: StockRepository

    init(repository: StockRepository? = nil) {
        self.repository = repository ?? StockRepositoryImpl()
    }

    func refreshQuotes() async {
        await refreshQuotes(for: stocks.map(\.symbol))
    }

    func refreshQuotes(for requestedSymbols: [String]? = nil) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let symbols = requestedSymbols ?? stocks.map(\.symbol)
        var failedSymbols: [String] = []

        for symbol in Set(symbols.map { $0.uppercased() }) {
            guard let index = stocks.firstIndex(where: {
                $0.symbol.uppercased() == symbol
            }) else {
                continue
            }

            do {
                let quote = try await repository.fetchQuote(for: symbol)

                stocks[index].price = quote.price
                stocks[index].currency = quote.currency
                stocks[index].hasFetchedPrice = true

            } catch {
                failedSymbols.append(symbol)
                print("Quote refresh failed for \(symbol): \(error)")
            }
        }

        if !failedSymbols.isEmpty {
            errorMessage = "Some prices couldn't be updated: \(failedSymbols.joined(separator: ", ")). Please try again."
        }
    }

    func addStockIfNeeded(symbol: String, name: String) {
        guard !stocks.contains(where: {
            $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame
        }) else {
            return
        }

        stocks.append(
            Stock(
                symbol: symbol,
                name: name,
                price: 0,
                changePercent: 0
            )
        )
    }

    func ensureStocks(
        for savedStocks: [(symbol: String, name: String)]
    ) async {
        var symbolsToRefresh: [String] = []

        for savedStock in savedStocks {
            let symbol = savedStock.symbol.uppercased()

            if !stocks.contains(where: {
                $0.symbol.uppercased() == symbol
            }) {
                let savedName = savedStock.name.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                stocks.append(
                    Stock(
                        symbol: symbol,
                        name: savedName.isEmpty ? symbol : savedName,
                        price: 0,
                        changePercent: 0
                    )
                )
            }

            if let stock = stocks.first(where: {
                $0.symbol.uppercased() == symbol
            }), !stock.hasFetchedPrice {
                symbolsToRefresh.append(symbol)
            }
        }

        if !symbolsToRefresh.isEmpty {
            await refreshQuotes(for: symbolsToRefresh)
        }
    }
}
