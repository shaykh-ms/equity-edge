
import SwiftUI
import SwiftData

struct DashboardView: View {
    let store: StockStore

    @Query(sort: \WatchlistEntry.symbol)
    private var entries: [WatchlistEntry]

    private let backgroundColor = Color(red: 0.035, green: 0.045, blue: 0.065)
    private let cardColor = Color(red: 0.075, green: 0.09, blue: 0.12)
    private let accentColor = Color(red: 0.25, green: 0.88, blue: 0.58)

    private var savedStocks: [Stock] {
        entries.compactMap { entry in
            store.stocks.first {
                $0.symbol.caseInsensitiveCompare(entry.symbol) == .orderedSame
            }
        }
    }

    private var topStocks: [Stock] {
        Array(savedStocks.prefix(5))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                watchlistSummary
                refreshButton
                stockSection
                marketOverview
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(backgroundColor.ignoresSafeArea())
        .task(id: entries.map {
            "\($0.symbol):\($0.name)"
        }.sorted().joined(separator: ",")) {
            await store.ensureStocks(
                for: entries.map {
                    (symbol: $0.symbol, name: $0.name)
                }
            )
        }
        .refreshable {
            await store.refreshQuotes(for: entries.map(\.symbol))
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(accentColor)

                Text("YOUR MARKET DASHBOARD")
                    .font(.caption.weight(.bold))
                    .tracking(1.8)
                    .foregroundStyle(.secondary)
            }

            Text("EquityEdge")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Your market. Your strategy.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Watchlist Summary

    private var watchlistSummary: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 56, height: 56)

                Image(systemName: "star.fill")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Your Watchlist")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("\(entries.count) saved stocks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accentColor)
        }
        .padding(18)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(.white.opacity(0.06), lineWidth: 1)
        }
    }

    // MARK: - Refresh

    private var refreshButton: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                Task {
                    await store.refreshQuotes(for: entries.map(\.symbol))
                }
            } label: {
                HStack(spacing: 10) {
                    if store.isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .bold))
                    }

                    Text(store.isLoading ? "Updating prices..." : "Refresh Market Prices")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(store.isLoading)

            if let errorMessage = store.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Saved Stocks

    private var stockSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeading(
                title: "Your Stocks",
                subtitle: "QUICK ACCESS",
                count: topStocks.count
            )

            if topStocks.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 32))
                        .foregroundStyle(accentColor)

                    Text("Your watchlist starts here")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Add stocks from the Watchlist tab to see them on your dashboard.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .background(cardColor)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(.white.opacity(0.06), lineWidth: 1)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(topStocks, id: \.symbol) { stock in
                        NavigationLink {
                            StockDetailView(
                                symbol: stock.symbol,
                                store: store
                            )
                        } label: {
                            stockRow(stock)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func stockRow(_ stock: Stock) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(accentColor.opacity(0.10))
                    .frame(width: 48, height: 48)

                Text(String(stock.symbol.prefix(1)))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(stock.symbol.uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Text(stock.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                if stock.hasFetchedPrice {
                    Text(
                        stock.price,
                        format: .currency(code: stock.currency)
                    )
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 5, height: 5)

                        Text("LIVE PRICE")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.7)
                            .foregroundStyle(accentColor)
                    }
                } else {
                    Text("—")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Awaiting quote")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.3))
                .padding(.leading, 2)
        }
        .padding(14)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.055), lineWidth: 1)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Market Overview

    private var marketOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Market Overview")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Illustrative index figures · Not live quotes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                indexCard(
                    title: "S&P 500",
                    symbol: "chart.line.uptrend.xyaxis",
                    value: "5,842.47",
                    change: "+1.24%"
                )

                indexCard(
                    title: "NASDAQ",
                    symbol: "chart.xyaxis.line",
                    value: "18,120.50",
                    change: "+0.86%"
                )
            }
        }
    }

    private func indexCard(
        title: String,
        symbol: String,
        value: String,
        change: String
    ) -> some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text("Market index")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(change)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor)
            }
        }
        .padding(15)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.white.opacity(0.055), lineWidth: 1)
        }
    }

    // MARK: - Section Heading

    private func sectionHeading(
        title: String,
        subtitle: String,
        count: Int
    ) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(String(format: "%02d", count))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(accentColor.opacity(0.10))
                .clipShape(Capsule())
        }
    }
}
