//
//  LineChartWidget.swift
//  1LimitWidget
//
//  Line chart widget implementation 📊✨
//

import WidgetKit
import SwiftUI

struct LineChartWidget: Widget {
    let kind: String = "LineChartWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LineChartProvider()) { entry in
            LineChartEntryView(entry: entry)
        }
        .configurationDisplayName("1Limit Line Chart")
        .description("Track WMATIC/USDC price with order execution history")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct LineChartEntryView: View {
    var entry: LineChartProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            LineChartSmallWidgetView(entry: entry)
        case .systemMedium:
            LineChartMediumWidgetView(entry: entry)
        case .systemLarge:
            LineChartLargeWidgetView(entry: entry)
        default:
            LineChartMediumWidgetView(entry: entry)
        }
    }
}

#Preview(as: .systemSmall) {
    LineChartWidget()
} timeline: {
    WidgetEntry(
        date: .now,
        positions: [],
        totalValue: 0,
        priceData: samplePriceData,
        chartData: sampleChartData
    )
}