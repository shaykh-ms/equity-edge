//
//  WatchlistEntry.swift
//  MarketHub
//
//  Created by Shaykh Mohd Shaya on 19/10/26.
//



import Foundation
import SwiftData

@Model
final class WatchlistEntry {
    @Attribute(.unique) var symbol: String
    var name: String = ""

    init(symbol: String, name: String = "") {
        self.symbol = symbol
        self.name = name
    }
}

