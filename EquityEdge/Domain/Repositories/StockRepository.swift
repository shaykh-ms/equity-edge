//
//  StockRepository.swift
//  MarketHub
//
//  Created by Shaykh Mohd Shaya on 21/10/26.
//
import Foundation

protocol StockRepository {
    func fetchQuote(for symbol: String) async throws -> StockQuote

    func searchStocks(
        query: String
    ) async throws -> [StockSearchItem]
}
