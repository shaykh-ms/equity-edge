//
//  StockQuoteService.swift
//  MarketHub
//
//  Created by Shaykh Mohd Shaya on 18/10/26.
//

import Foundation

struct StockQuoteResponse: Decodable {
    let chart: ChartData
}

struct ChartData: Decodable {
    let result: [ChartResult]?
    let error: APIError?
}

struct ChartResult: Decodable {
    let meta: StockQuoteDTO
}

struct StockQuoteDTO: Decodable {
    let symbol: String
    let currency: String?
    let regularMarketPrice: Double?
}

struct APIError: Decodable {
    let description: String?
}

struct StockQuoteService {

    func fetchQuote(symbol: String) async throws -> StockQuoteDTO {
        let urlString =
            "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?range=1d&interval=1d"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decodedResponse = try JSONDecoder().decode(
            StockQuoteResponse.self,
            from: data
        )

        guard let quote = decodedResponse.chart.result?.first?.meta,
              quote.regularMarketPrice != nil else {
            throw URLError(.cannotParseResponse)
        }

        return quote
    }
}
