
import Foundation

enum StockCatalogue {
    static let stocks: [Stock] = [
        Stock(symbol: "AAPL", name: "Apple", price: 245.60, changePercent: 2.31),
        Stock(symbol: "MSFT", name: "Microsoft", price: 510.20, changePercent: 0.92),
        Stock(symbol: "NVDA", name: "NVIDIA", price: 180.25, changePercent: 1.85),
        Stock(symbol: "AMZN", name: "Amazon", price: 225.40, changePercent: 1.12),
        Stock(symbol: "GOOGL", name: "Alphabet", price: 245.30, changePercent: 1.40),
        Stock(symbol: "META", name: "Meta Platforms", price: 715.50, changePercent: 0.65),
        Stock(symbol: "TSLA", name: "Tesla", price: 340.10, changePercent: -0.75),
        Stock(symbol: "NFLX", name: "Netflix", price: 1180.00, changePercent: 0.45),
        Stock(symbol: "AMD", name: "Advanced Micro Devices", price: 165.00, changePercent: 1.10),
        Stock(symbol: "INTC", name: "Intel", price: 25.00, changePercent: -0.60),
        Stock(symbol: "AVGO", name: "Broadcom", price: 350.00, changePercent: 1.25),
        Stock(symbol: "ORCL", name: "Oracle", price: 220.00, changePercent: 0.80),
        Stock(symbol: "CRM", name: "Salesforce", price: 260.00, changePercent: 0.55),
        Stock(symbol: "JPM", name: "JPMorgan Chase", price: 290.00, changePercent: 0.40),
        Stock(symbol: "V", name: "Visa", price: 350.00, changePercent: 0.35),
        Stock(symbol: "WMT", name: "Walmart", price: 105.00, changePercent: 0.70),
        Stock(symbol: "COST", name: "Costco", price: 950.00, changePercent: 0.50),
        Stock(symbol: "DIS", name: "Walt Disney", price: 115.00, changePercent: -0.20),
        Stock(symbol: "KO", name: "Coca-Cola", price: 70.00, changePercent: 0.25),
        Stock(symbol: "NKE", name: "Nike", price: 75.00, changePercent: -0.45)
    ]
}
