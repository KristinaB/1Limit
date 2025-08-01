//
//  OHLCProvider.swift
//  1LimitWidget
//
//  Timeline provider for OHLC widget data 📈✨
//

import WidgetKit
import SwiftUI

struct OHLCProvider: TimelineProvider {
    typealias Entry = WidgetEntry
    
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            positions: samplePositions,
            totalValue: 125.50,
            priceData: samplePriceData,
            chartData: sampleChartData,
            openOrders: [],
            closedOrders: []
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let snapshotTime = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        print("📊 OHLC Widget snapshot at: \(formatter.string(from: snapshotTime))")
        
        let entry = WidgetEntry(
            date: snapshotTime,
            positions: loadPositions(),
            totalValue: calculateTotalValue(),
            priceData: loadPriceData(),
            chartData: loadChartData(),
            openOrders: WidgetDataManager.shared.loadOpenOrders(),
            closedOrders: []
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let refreshTime = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        print("📊 OHLC Widget timeline refresh at: \(formatter.string(from: refreshTime)) - Context: \(context)")
        
        let currentDate = Date()
        
        // Create a single entry with real open orders
        let openOrders = WidgetDataManager.shared.loadOpenOrders()
        let entry = WidgetEntry(
            date: currentDate,
            positions: samplePositions, // Use sample data to avoid data loading issues
            totalValue: 125.50,
            priceData: samplePriceData,
            chartData: sampleChartData,
            openOrders: openOrders,
            closedOrders: []
        )

        // Set next refresh in 5 minutes (longer interval)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        print("📊 OHLC Widget next refresh scheduled for: \(formatter.string(from: nextRefresh))")
        completion(timeline)
    }
    
    private func loadPositions() -> [WidgetPosition] {
        // Load from shared UserDefaults or App Group container
        return WidgetDataManager.shared.loadPositions()
    }
    
    private func calculateTotalValue() -> Double {
        return WidgetDataManager.shared.calculateTotalPortfolioValue()
    }
    
    private func loadPriceData() -> [PricePoint] {
        return WidgetDataManager.shared.loadRecentPriceData()
    }
    
    private func loadChartData() -> [WidgetCandlestickData] {
        let chartData = WidgetDataManager.shared.loadChartData()
        print("📱 Widget Provider loaded \(chartData.count) chart data points")
        
        // Debug: Force some test data if empty
        if chartData.isEmpty {
            print("⚠️ Chart data is empty, creating test data")
            return createTestChartData()
        }
        
        return chartData
    }
    
    private func createTestChartData() -> [WidgetCandlestickData] {
        let now = Date()
        return (0..<25).map { index in
            let timestamp = now.addingTimeInterval(-Double(index) * 300)
            let basePrice = 0.45
            let open = basePrice + Double.random(in: -0.01...0.01)
            let close = open + Double.random(in: -0.02...0.02)
            let high = max(open, close) + Double.random(in: 0...0.005)
            let low = min(open, close) - Double.random(in: 0...0.005)
            
            return WidgetCandlestickData(
                timestamp: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: 1000
            )
        }.reversed()
    }
}