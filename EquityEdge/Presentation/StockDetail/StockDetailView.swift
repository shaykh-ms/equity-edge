
import SwiftUI

struct StockDetailView: View {
    let symbol: String
    let store: StockStore

    private var stock: Stock? {
        store.stocks.first { $0.symbol == symbol }
    }

    var body: some View {
        Group {
            if let stock {
                ScrollView {
                    VStack(spacing: 20) {
                        Text(stock.name)
                            .font(.title2)
                            .foregroundStyle(.secondary)

                        Text(stock.symbol)
                            .font(.headline)

                        Text(
                            stock.price,
                            format: .currency(code: stock.currency)
                        )
                        .font(.system(size: 36, weight: .bold))

                        Text(
                            stock.hasFetchedPrice
                                ? "Live quote fetched"
                                : "Waiting for live quote"
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            stock.hasFetchedPrice ? .green : .secondary
                        )

                        Button {
                            Task {
                              
                                await store.refreshQuotes(for: [symbol])
                            }
                        } label: {
                            Label("Refresh Price", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "Stock Not Found",
                    systemImage: "chart.line.downtrend.xyaxis"
                )
            }
        }
        .navigationTitle(symbol)
        .navigationBarTitleDisplayMode(.inline)
    }
}
