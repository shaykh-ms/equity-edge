//
//  LiveStockSearchView.swift
//  MarketHub
//
//  Created by Shaykh Mohd Shaya on 19/10/26.
//


import SwiftUI
import SwiftData

struct LiveStockSearchView: View {
    let store: StockStore

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var entries: [WatchlistEntry]

    @State private var searchText = ""
    @State private var results: [StockSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    private let searchService = StockSearchService()

    private var savedSymbols: Set<String> {
        Set(entries.map { $0.symbol.uppercased() })
    }

    var body: some View {
        List {
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                ContentUnavailableView(
                    "Search Stocks",
                    systemImage: "magnifyingglass",
                    description: Text("Enter a company name or ticker, such as Netflix or NFLX.")
                )
            } else if isSearching {
                ProgressView("Searching Yahoo Finance...")
            } else if results.isEmpty && errorMessage == nil {
                ContentUnavailableView(
                    "No Stocks Found",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Try another company name or ticker.")
                )
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            ForEach(results) { result in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(result.symbol)
                            .font(.headline)

                        Text(result.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let exchange = result.exchange {
                            Text(exchange)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        toggleStock(result)
                    } label: {
                        Label(
                            savedSymbols.contains(result.symbol.uppercased())
                                ? "Added"
                                : "Add",
                            systemImage: savedSymbols.contains(result.symbol.uppercased())
                                ? "checkmark.circle.fill"
                                : "plus.circle"
                        )
                    }
                    .buttonStyle(.bordered)
                    .tint(
                        savedSymbols.contains(result.symbol.uppercased())
                            ? .green
                            : .blue
                    )
                }
                .padding(.vertical, 4)
            }
        }
        .searchable(
            text: $searchText,
            prompt: "Company name or ticker"
        )
        .navigationTitle("Find Stocks")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task(id: searchText) {
            await performSearch()
        }
    }

    @MainActor
    private func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard query.count >= 2 else {
            results = []
            errorMessage = nil
            isSearching = false
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            try await Task.sleep(for: .milliseconds(350))

            guard !Task.isCancelled else { return }

            let found = try await searchService.search(query: query)

            guard !Task.isCancelled else { return }

            results = found
            isSearching = false
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            results = []
            errorMessage = "Search failed. Check your connection and try again."
            isSearching = false
        }
    }

    private func toggleStock(_ result: StockSearchResult) {
        let symbol = result.symbol.uppercased()

        if let existing = entries.first(where: {
            $0.symbol.uppercased() == symbol
        }) {
            modelContext.delete(existing)
        } else {
           
            
            modelContext.insert(
                WatchlistEntry(
                    symbol: symbol,
                    name: result.displayName
                )
            )

            store.addStockIfNeeded(
                symbol: symbol,
                name: result.displayName
            )

            Task {
                await store.refreshQuotes(for: [symbol])            }
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save watchlist: \(error.localizedDescription)")
        }
    }
}
