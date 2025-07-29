//
//  WidgetModels.swift
//  1LimitWidget
//
//  Shared data models for widgets 🏗️✨
//

import Foundation
import SwiftUI
import WidgetKit

// MARK: - Widget Entry

struct WidgetEntry: TimelineEntry {
    let date: Date
    let positions: [WidgetPosition]
    let totalValue: Double
    let priceData: [PricePoint]
    let chartData: [WidgetCandlestickData]
    let openOrders: [WidgetTransaction]
    let closedOrders: [WidgetTransaction]
}

// MARK: - Widget Position

struct WidgetPosition: Identifiable, Codable {
    let id: UUID
    let symbol: String
    let amount: Double
    let value: Double
    let status: PositionStatus
    
    init(symbol: String, amount: Double, value: Double, status: PositionStatus) {
        self.id = UUID()
        self.symbol = symbol
        self.amount = amount
        self.value = value
        self.status = status
    }
}

enum PositionStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case filled = "Filled"
    case cancelled = "Cancelled"
    case failed = "Failed"
    
    var color: Color {
        switch self {
        case .pending:
            return .gray
        case .filled:
            return .blue
        case .cancelled:
            return .orange
        case .failed:
            return .purple
        }
    }
}

// MARK: - Price Point

struct PricePoint: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let price: Double
    
    init(timestamp: Date, price: Double) {
        self.id = UUID()
        self.timestamp = timestamp
        self.price = price
    }
}

// MARK: - Widget Transaction

enum WidgetTransactionStatus: String, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case failed = "failed"
    case cancelled = "cancelled"
}

struct WidgetTransaction: Identifiable, Codable {
    let id: UUID
    let type: String
    let fromAmount: String
    let fromToken: String
    let toAmount: String
    let toToken: String
    let limitPrice: String
    let status: WidgetTransactionStatus
    let date: Date
    let txHash: String?
}

// MARK: - Widget Candlestick Data

struct WidgetCandlestickData: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    init(timestamp: Date, open: Double, high: Double, low: Double, close: Double, volume: Double) {
        self.id = UUID()
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
    
    var isBullish: Bool {
        return close >= open
    }
}

// MARK: - Sample Data

let samplePositions = [
    WidgetPosition(symbol: "WMATIC/USDC", amount: 10.0, value: 45.50, status: .filled),
    WidgetPosition(symbol: "USDC/WMATIC", amount: 25.0, value: 80.0, status: .pending)
]

let samplePriceData: [PricePoint] = {
    let basePrice = 1.25
    return (0..<24).map { hour in
        let variation = Double.random(in: -0.1...0.1)
        return PricePoint(
            timestamp: Date().addingTimeInterval(-Double(hour) * 3600),
            price: basePrice + variation
        )
    }
}()

let sampleChartData: [WidgetCandlestickData] = {
    let basePrice = 0.45
    let now = Date()
    
    return (0..<25).map { index in
        let timestamp = now.addingTimeInterval(-Double(index) * 300) // 5-minute intervals
        let openVariation = Double.random(in: -0.02...0.02)
        let open = basePrice + openVariation
        
        let closeVariation = Double.random(in: -0.02...0.02)
        let close = open + closeVariation
        
        let high = max(open, close) + Double.random(in: 0...0.01)
        let low = min(open, close) - Double.random(in: 0...0.01)
        let volume = Double.random(in: 1000...5000)
        
        return WidgetCandlestickData(
            timestamp: timestamp,
            open: max(0.1, open),
            high: max(0.1, high),
            low: max(0.1, low),
            close: max(0.1, close),
            volume: volume
        )
    }.reversed()
}()

