//
//  PortfolioHolding.swift
//  MarketHub
//
//  Created by Shaykh Mohd Shaya on 20/10/26.
//

import Foundation
import SwiftData

@Model
final class PortfolioHolding {
    @Attribute(.unique) var symbol: String
    var name: String
    var quantity: Double
    var purchasePrice: Double

    init(
        symbol: String,
        name: String,
        quantity: Double,
        purchasePrice: Double
    ) {
        self.symbol = symbol
        self.name = name
        self.quantity = quantity
        self.purchasePrice = purchasePrice
    }
}
