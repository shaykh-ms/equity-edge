
import SwiftUI
import PulseUI

struct ContentView: View {

    @State private var started = false
    @State private var container: AppContainer
    @State private var stockStore: StockStore
    @State private var isShowingPulse = false

    init(container: AppContainer) {
        self.container = container
        _stockStore = State(initialValue: container.makeStockStore())
    }

    var body: some View {
        if started {
            TabView {
                NavigationStack {
                    DashboardView(store: stockStore)
                }
                .tabItem {
                    Label("Home", systemImage: "house")
                }

                NavigationStack {
                    WatchlistView(store: stockStore)
                }
                .tabItem {
                    Label("Watchlist", systemImage: "star")
                }

                PortfolioView(store: stockStore)
                    .tabItem {
                        Label("Portfolio", systemImage: "chart.pie")
                    }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    isShowingPulse = true
                } label: {
                    Image(systemName: "network")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 44, height: 44)
                        .background(.white, in: Circle())
                        .shadow(radius: 4)
                }
                .accessibilityLabel("Open Pulse Network Inspector")
                .padding(.trailing, 16)
                .padding(.top, 8)
                .zIndex(1)
            }
            .sheet(isPresented: $isShowingPulse) {
                NavigationStack {
                    ConsoleView(mode: .network)
                }
            }
        } else {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("EquityEdge")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your personal market dashboard")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Button("Get Started") {
                    started = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

struct MarketCard: View {
    let title: String
    let value: String
    let change: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(change)
                .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
