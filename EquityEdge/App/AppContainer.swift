//
//  AppContainer.swift
//  MarketHub
//
//  Created by Shaykh Mohd Shaya on 21/10/26.
//


import Foundation

@MainActor
final class AppContainer {

    let stockRepository: StockRepository

    init() {
        let quoteService = StockQuoteService()
        let searchService = StockSearchService()

        self.stockRepository = StockRepositoryImpl(
            quoteService: quoteService,
            searchService: searchService
        )
    }

    func makeStockStore() -> StockStore {
        StockStore(repository: stockRepository)
    }
}


