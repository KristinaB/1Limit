//
//  LineChartWidget.swift
//  1LimitWidget
//
//  Line chart widget for price trends 📈✨
//

import WidgetKit
import SwiftUI

struct LineChartWidget: Widget {
    let kind: String = "1LimitLineChartWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LineChartProvider()) { entry in
            LineChartWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("1Limit Line Chart")
        .description("Price trend visualization with line chart")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct LineChartWidgetEntryView: View {
    var entry: LineChartProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                HStack {
                    Text("1Limit Price Chart")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal)
                .padding(.top)
                
                Text("Line Chart Coming Soon")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}