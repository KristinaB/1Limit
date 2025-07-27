//
//  OHLCWidget.swift
//  1LimitWidget
//
//  OHLC widget implementation 📈✨
//

import WidgetKit
import SwiftUI

struct OHLCWidget: Widget {
    let kind: String = "1LimitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OHLCProvider()) { entry in
            OHLCEntryView(entry: entry)
        }
        .configurationDisplayName("1Limit Trading")
        .description("Monitor your limit orders and trading positions")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct OHLCEntryView: View {
    var entry: OHLCProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallOHLCWidgetView(entry: entry)
        case .systemMedium:
            MediumOHLCWidgetView(entry: entry)
        case .systemLarge:
            LargeOHLCWidgetView(entry: entry)
        default:
            MediumOHLCWidgetView(entry: entry)
        }
    }
}

#Preview(as: .systemSmall) {
    OHLCWidget()
} timeline: {
    WidgetEntry(
        date: .now,
        positions: samplePositions,
        totalValue: 125.50,
        priceData: samplePriceData,
        chartData: sampleChartData
    )
}