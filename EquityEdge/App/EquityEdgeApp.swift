
import SwiftUI
import SwiftData
import Pulse
import PulseProxy

@main
struct EquityEdgeApp: App {

    @State private var container = AppContainer()

    init() {
        #if DEBUG
        NetworkLogger.enableProxy()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
        }
        .modelContainer(
            for: [WatchlistEntry.self, PortfolioHolding.self]
        )
    }
}
