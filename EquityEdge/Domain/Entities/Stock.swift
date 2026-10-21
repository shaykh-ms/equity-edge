//
//  Stock.swift
//  MarketHub
//
//  Created by Shaykh Mohd Shaya on 09/10/26.
//
import Foundation

struct Stock {
    let symbol: String
    let name: String
    var price: Double
    let changePercent: Double

    var currency: String = "USD"
    var hasFetchedPrice = false
}

