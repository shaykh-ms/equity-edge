
import SwiftUI
import SwiftData

struct WatchlistView: View {
    let store: StockStore

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WatchlistEntry.symbol)
    private var entries: [WatchlistEntry]

    @State private var searchText = ""
    @State private var showingCatalogue = false

    private var filteredEntries: [WatchlistEntry] {
        guard !searchText.isEmpty else { return entries }

        return entries.filter { entry in
            entry.symbol.localizedCaseInsensitiveContains(searchText) ||
            (StockCatalogue.stocks.first {
                $0.symbol == entry.symbol
            }?.name.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        List {
            if store.isLoading {
                ProgressView("Refreshing stock prices...")
            }

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if filteredEntries.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty
                        ? "Your Watchlist Is Empty"
                        : "No Stocks Found",
                    systemImage: searchText.isEmpty
                        ? "star"
                        : "magnifyingglass",
                    description: Text(
                        searchText.isEmpty
                            ? "Tap + to find and add stocks."
                            : "Try another company name or ticker."
                    )
                )
            } else {
                watchlistRows
            }
        }
        .searchable(text: $searchText, prompt: "Search watchlist")
        .navigationTitle("Watchlist")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Task {
                        await store.refreshQuotes(
                            for: entries.map(\.symbol)
                        )
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(store.isLoading)
                .accessibilityLabel("Refresh stock prices")

                Button {
                    showingCatalogue = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Browse stocks")
            }
        }
        .sheet(isPresented: $showingCatalogue) {
            NavigationStack {
                LiveStockSearchView(store: store)
            }
        }
        .task(id: entriesKey) {
            await store.ensureStocks(for: savedStocks)
        }
    }
    private var entriesKey: String {
        entries
            .map { "\($0.symbol):\($0.name)" }
            .sorted()
            .joined(separator: ",")
    }

    private var savedStocks: [(symbol: String, name: String)] {
        entries.map { entry in
            (symbol: entry.symbol, name: entry.name)
        }
    }

    private var watchlistRows: some View {
        ForEach(filteredEntries, id: \.symbol) { entry in
            watchlistEntryRow(for: entry)
        }
    }

    @ViewBuilder
    private func watchlistEntryRow(
        for entry: WatchlistEntry
    ) -> some View {
        if let stock = store.stocks.first(where: {
            $0.symbol.caseInsensitiveCompare(entry.symbol) == .orderedSame
        }) {
            NavigationLink {
                StockDetailView(
                    symbol: stock.symbol,
                    store: store
                )
            } label: {
                watchlistRow(
                    symbol: stock.symbol,
                    name: stock.name,
                    price: stock.price,
                    currency: stock.currency,
                    hasFetchedPrice: stock.hasFetchedPrice
                )
            }
            .swipeActions {
                removeButton(for: entry)
            }
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.symbol)
                        .font(.headline)

                    Text(entry.name.isEmpty ? entry.symbol : entry.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                ProgressView()
            }
            .swipeActions {
                removeButton(for: entry)
            }
        }
    }

    private func removeButton(for entry: WatchlistEntry) -> some View {
        Button(role: .destructive) {
            removeStock(entry)
        } label: {
            Label("Remove", systemImage: "trash")
        }
    }
    
    private func watchlistRow(
        symbol: String,
        name: String,
        price: Double,
        currency: String,
        hasFetchedPrice: Bool
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(symbol)
                    .font(.headline)

                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(price, format: .currency(code: currency))
                    .fontWeight(.semibold)

                Text(hasFetchedPrice ? "Live quote" : "Sample price")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func removeStock(_ entry: WatchlistEntry) {
        modelContext.delete(entry)

        do {
            try modelContext.save()
        } catch {
            print("Failed to remove stock: \(error)")
        }
    }
}

private struct StockCatalogueView: View {
    let store: StockStore

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WatchlistEntry.symbol)
    private var entries: [WatchlistEntry]

    @State private var searchText = ""
    @State private var saveError = ""
    @State private var showingSaveError = false

    private var savedSymbols: Set<String> {
        Set(entries.map(\.symbol))
    }

    private var filteredStocks: [Stock] {
        guard !searchText.isEmpty else {
            return StockCatalogue.stocks
        }

        return StockCatalogue.stocks.filter { stock in
            stock.symbol.localizedCaseInsensitiveContains(searchText) ||
            stock.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredStocks, id: \.symbol) { catalogueStock in
                let stock = store.stocks.first(where: {
                    $0.symbol == catalogueStock.symbol
                }) ?? catalogueStock

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stock.symbol)
                            .font(.headline)

                        Text(stock.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(
                            stock.price,
                            format: .currency(code: stock.currency)
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        toggleStock(stock.symbol)
                    } label: {
                        Label(
                            savedSymbols.contains(stock.symbol)
                                ? "Remove"
                                : "Add",
                            systemImage: savedSymbols.contains(stock.symbol)
                                ? "minus.circle"
                                : "plus.circle"
                        )
                    }
                    .buttonStyle(.bordered)
                    .tint(
                        savedSymbols.contains(stock.symbol)
                            ? .red
                            : .blue
                    )
                }
                .padding(.vertical, 4)
            }
        }
        .searchable(
            text: $searchText,
            prompt: "Search company or ticker"
        )
        .navigationTitle("Browse Stocks")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Couldn't Save Watchlist", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveError)
        }
    }

    private func toggleStock(_ symbol: String) {
        if let existing = entries.first(where: {
            $0.symbol == symbol
        }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(WatchlistEntry(symbol: symbol))
        }

        do {
            try modelContext.save()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
            print("Failed to save watchlist: \(error)")
        }
    }
}
