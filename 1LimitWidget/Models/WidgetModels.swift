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
}

// MARK: - Widget Position

struct WidgetPosition: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let amount: Double
    let value: Double
    let status: PositionStatus
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
    let id = UUID()
    let timestamp: Date
    let price: Double
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

// This is defined in WidgetDataManager.swift
// let sampleChartData: [WidgetCandlestickData]