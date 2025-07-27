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
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct LineChartEntryView: View {
    var entry: LineChartProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            LineChartMediumWidgetView(entry: entry)
        case .systemLarge:
            LineChartLargeWidgetView(entry: entry)
        default:
            LineChartMediumWidgetView(entry: entry)
        }
    }
}

#Preview(as: .systemMedium) {
    LineChartWidget()
} timeline: {
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