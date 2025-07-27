//
//  LineChartProvider.swift
//  1LimitWidget
//
//  Timeline provider for line chart widget 📊✨
//

import WidgetKit
import SwiftUI

struct LineChartProvider: TimelineProvider {
    typealias Entry = WidgetEntry
    
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            positions: [],
            totalValue: 0,
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
        print("📈 LineChart Widget snapshot at: \(formatter.string(from: snapshotTime))")
        
        let entry = WidgetEntry(
            date: snapshotTime,
            positions: [],
            totalValue: 0,
            priceData: loadLineChartData(),
            chartData: sampleChartData,
            openOrders: [],
            closedOrders: WidgetDataManager.shared.loadClosedOrders()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let refreshTime = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        print("📈 LineChart Widget timeline refresh at: \(formatter.string(from: refreshTime)) - Context: \(context)")
        
        let currentDate = Date()
        
        // Create a single entry with real closed orders
        let closedOrders = WidgetDataManager.shared.loadClosedOrders()
        let entry = WidgetEntry(
            date: currentDate,
            positions: [],
            totalValue: 0,
            priceData: samplePriceData, // Use sample data to avoid async issues
            chartData: sampleChartData,
            openOrders: [],
            closedOrders: closedOrders
        )

        // Set next refresh in 5 minutes (longer interval)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        print("📈 LineChart Widget next refresh scheduled for: \(formatter.string(from: nextRefresh))")
        completion(timeline)
    }
    
    private func loadLineChartData() -> [PricePoint] {
        // Load cached line chart data from WidgetDataManager
        return WidgetDataManager.shared.loadLineChartData()
    }
    
    private func loadLineChartDataAsync() async -> [PricePoint] {
        // Try to fetch fresh data
        await WidgetDataManager.shared.updateLineChartData()
        return WidgetDataManager.shared.loadLineChartData()
    }
}