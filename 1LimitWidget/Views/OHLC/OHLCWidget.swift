//
//  OHLCWidget.swift
//  1LimitWidget
//
//  OHLC widget implementation 📈✨
//

import SwiftUI
import WidgetKit

struct OHLCWidget: Widget {
  let kind: String = "1LimitWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: OHLCProvider()) { entry in
      OHLCEntryView(entry: entry)
    }
    .configurationDisplayName("1Limit")
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
      SmallOHLCWidgetView(entry: entry) // Use small view since medium was deleted
    case .systemLarge:
      LargeOHLCWidgetView(entry: entry)
    default:
      SmallOHLCWidgetView(entry: entry) // Default to small view
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
