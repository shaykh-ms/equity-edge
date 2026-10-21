//
//  StockSearchService.swift
//  MarketHub
//
//  Created by Shaykh Mohd Shaya on 19/10/26.
//


import Foundation

struct StockSearchResponse: Decodable {
    let quotes: [StockSearchResult]
}

struct StockSearchResult: Decodable, Identifiable {
    let symbol: String
    let shortname: String?
    let longname: String?
    let quoteType: String?
    let exchange: String?

    var id: String { symbol }

    var displayName: String {
        longname ?? shortname ?? symbol
    }
}

struct StockSearchService {
    func search(query: String) async throws -> [StockSearchResult] {
        var components = URLComponents(
            string: "https://query1.finance.yahoo.com/v1/finance/search"
        )!

        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "quotesCount", value: "20"),
            URLQueryItem(name: "newsCount", value: "0")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(
            StockSearchResponse.self,
            from: data
        )

        return decoded.quotes.filter {
            $0.quoteType == "EQUITY" &&
            !$0.symbol.isEmpty
        }
    }
}
