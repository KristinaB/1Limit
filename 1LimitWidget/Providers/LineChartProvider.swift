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
            
            // Create entries: 1-minute intervals for first 10 minutes, then 10-minute intervals
            // First 10 entries at 1-minute intervals (for active usage)
            for minuteOffset in 0..<10 {
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
            
            // Then 6 more entries at 10-minute intervals (for background)
            for tenMinuteOffset in 1...6 {
                let entryDate = Calendar.current.date(byAdding: .minute, value: 10 + (tenMinuteOffset * 10), to: currentDate)!
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