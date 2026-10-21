//
//  StockSearchItem.swift
//  MarketHub
//
//  Created by Shaykh Mohd Shaya on 21/10/26.
//
import Foundation

struct StockSearchItem: Identifiable {
    let symbol: String
    let name: String
    let exchange: String?

    var id: String { symbol }
}
