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
            chartData: sampleChartData
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let entry = WidgetEntry(
            date: Date(),
            positions: loadPositions(),
            totalValue: calculateTotalValue(),
            priceData: loadPriceData(),
            chartData: loadChartData()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [WidgetEntry] = []
        let currentDate = Date()
        
        // Update every 5 minutes
        for minuteOffset in stride(from: 0, to: 60, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = WidgetEntry(
                date: entryDate,
                positions: loadPositions(),
                totalValue: calculateTotalValue(),
                priceData: loadPriceData(),
                chartData: loadChartData()
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
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