//
//  AddPortfolioHoldingView.swift
//  MarketHub
//
//  Created by Shaykh Mohd Shaya on 20/10/26.
//

import SwiftUI
import SwiftData

struct AddPortfolioHoldingView: View {
    let store: StockStore

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var holdings: [PortfolioHolding]

    @State private var searchText = ""
    @State private var results: [StockSearchResult] = []
    @State private var selectedStock: StockSearchResult?
    @State private var quantityText = "1"
    @State private var purchasePriceText = ""
    @State private var isSearching = false
    @State private var errorMessage: String?

    private let searchService = StockSearchService()

    private var quantity: Double? {
        Double(quantityText)
    }

    private var purchasePrice: Double? {
        Double(purchasePriceText)
    }

    private var canSave: Bool {
        guard let quantity, let purchasePrice else {
            return false
        }

        return quantity > 0
            && purchasePrice > 0
            && selectedStock != nil
            && !holdings.contains {
                $0.symbol.caseInsensitiveCompare(
                    selectedStock?.symbol ?? ""
                ) == .orderedSame
            }
    }

    var body: some View {
        Form {
            if let selectedStock {
                Section("Selected Stock") {
                    LabeledContent("Symbol", value: selectedStock.symbol)
                    LabeledContent("Company", value: selectedStock.displayName)

                    Button("Choose a Different Stock") {
                        self.selectedStock = nil
                        purchasePriceText = ""
                    }
                }

                Section("Purchase Details") {
                    TextField("Quantity of shares", text: $quantityText)
                        .keyboardType(.decimalPad)

                    TextField(
                        "Purchase price per share",
                        text: $purchasePriceText
                    )
                    .keyboardType(.decimalPad)

                    if let quantity, let purchasePrice,
                       quantity > 0, purchasePrice > 0 {
                        LabeledContent(
                            "Total Cost",
                            value: (quantity * purchasePrice),
                            format: .currency(code: "USD")
                        )
                    }

                    Text(
                        "Enter the purchase price in the stock's trading currency."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if holdings.contains(where: {
                    $0.symbol.caseInsensitiveCompare(selectedStock.symbol)
                        == .orderedSame
                }) {
                    Text("This stock is already in your portfolio.")
                        .foregroundStyle(.red)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                Section {
                    Button("Save Holding", action: saveHolding)
                        .frame(maxWidth: .infinity)
                        .disabled(!canSave)
                }
            } else {
                Section("Find a Stock") {
                    TextField(
                        "Search company or ticker",
                        text: $searchText
                    )
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)

                    if isSearching {
                        ProgressView("Searching...")
                    }

                    ForEach(results) { result in
                        Button {
                            selectedStock = result
                            searchText = result.symbol
                            results = []
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.symbol)
                                    .font(.headline)

                                Text(result.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(.primary)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("Add Holding")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .task(id: searchText) {
            await searchStocks()
        }
    }

    private func searchStocks() async {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard selectedStock == nil, query.count >= 2 else {
            results = []
            isSearching = false
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(350))
            try Task.checkCancellation()

            isSearching = true
            defer { isSearching = false }

            results = try await searchService.search(query: query)
            errorMessage = nil
        } catch is CancellationError {
            // A newer search replaced this one.
        } catch {
            results = []
            errorMessage = "Search failed. Please try again."
        }
    }

    private func saveHolding() {
        guard let selectedStock,
              let quantity,
              let purchasePrice,
              canSave else {
            return
        }

        let holding = PortfolioHolding(
            symbol: selectedStock.symbol.uppercased(),
            name: selectedStock.displayName,
            quantity: quantity,
            purchasePrice: purchasePrice
        )

        modelContext.insert(holding)

        do {
            try modelContext.save()

            store.addStockIfNeeded(
                symbol: selectedStock.symbol,
                name: selectedStock.displayName
            )

            Task {
                await store.refreshQuotes(
                    for: [selectedStock.symbol]
                )
            }

            dismiss()
        } catch {
            modelContext.delete(holding)
            errorMessage = "Couldn't save this holding. Please try again."
            print("Failed to save portfolio holding: \(error)")
        }
    }
}
