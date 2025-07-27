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
            chartData: sampleChartData
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let entry = WidgetEntry(
            date: Date(),
            positions: [],
            totalValue: 0,
            priceData: loadLineChartData(),
            chartData: sampleChartData
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let lineData = await loadLineChartDataAsync()
            
            var entries: [WidgetEntry] = []
            let currentDate = Date()
            
            // Update every 5 minutes
            for minuteOffset in stride(from: 0, to: 60, by: 5) {
                let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
                let entry = WidgetEntry(
                    date: entryDate,
                    positions: [],
                    totalValue: 0,
                    priceData: lineData,
                    chartData: sampleChartData
                )
                entries.append(entry)
            }
            
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
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