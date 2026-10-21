//
//  StockRepositoryImpl.swift
//  MarketHub
//
//  Created by Shaykh Mohd Shaya on 21/10/26.
//


import Foundation

struct StockRepositoryImpl: StockRepository {

    private let quoteService: StockQuoteService
    private let searchService: StockSearchService

    init(
        quoteService: StockQuoteService = StockQuoteService(),
        searchService: StockSearchService = StockSearchService()
    ) {
        self.quoteService = quoteService
        self.searchService = searchService
    }

    func fetchQuote(for symbol: String) async throws -> StockQuote {
        let dto = try await quoteService.fetchQuote(symbol: symbol)

        guard let price = dto.regularMarketPrice else {
            throw URLError(.cannotParseResponse)
        }

        return StockQuote(
            symbol: dto.symbol,
            price: price,
            currency: dto.currency ?? "USD"
        )
    }

    func searchStocks(query: String) async throws -> [StockSearchItem] {
        let results = try await searchService.search(query: query)

        return results.map { result in
            StockSearchItem(
                symbol: result.symbol,
                name: result.displayName,
                exchange: result.exchange
            )
        }
    }
}
