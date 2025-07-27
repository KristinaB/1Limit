//
//  1LimitWidget.swift
//  1LimitWidget
//
//  iOS Widget showing limit order status and trading positions 📱✨
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
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

struct WidgetEntry: TimelineEntry {
    let date: Date
    let positions: [WidgetPosition]
    let totalValue: Double
    let priceData: [PricePoint]
    let chartData: [WidgetCandlestickData]
}

struct _LimitWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct _LimitWidget: Widget {
    let kind: String = "1LimitWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            _LimitWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("1Limit Trading")
        .description("Monitor your limit orders and trading positions")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Sizes

struct SmallWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("1Limit")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Circle()
                        .fill(entry.positions.isEmpty ? Color.gray : Color.green)
                        .frame(width: 6, height: 6)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("WMATIC/USDC")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    if let lastCandle = entry.chartData.last {
                        Text("$\(lastCandle.close, specifier: "%.4f")")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        let change = lastCandle.close - lastCandle.open
                        let changePercent = (change / lastCandle.open) * 100
                        HStack(spacing: 2) {
                            Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                .font(.caption2)
                            Text("\(changePercent, specifier: "%.2f")%")
                                .font(.caption2)
                        }
                        .foregroundColor(change >= 0 ? .green : .red)
                    }
                }
                
                Spacer()
                
                if !entry.positions.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.positions.count) Position\(entry.positions.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        ForEach(entry.positions.prefix(2), id: \.id) { position in
                            HStack {
                                Text(position.symbol)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(position.status.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(position.status.color)
                            }
                        }
                    }
                }
            }
            .padding(12)
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    }
}

struct MediumWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        HStack(spacing: 16) {
                // Left side - Portfolio info
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("1Limit")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                        Circle()
                            .fill(entry.positions.isEmpty ? Color.gray : Color.green)
                            .frame(width: 8, height: 8)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WMATIC/USDC")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let lastCandle = entry.chartData.last {
                            Text("$\(lastCandle.close, specifier: "%.4f")")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            let change = lastCandle.close - lastCandle.open
                            let changePercent = (change / lastCandle.open) * 100
                            HStack(spacing: 2) {
                                Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.caption)
                                Text("\(changePercent, specifier: "%.2f")%")
                                    .font(.caption)
                            }
                            .foregroundColor(change >= 0 ? .green : .red)
                        }
                    }
                    
                    if !entry.positions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Active Positions")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            ForEach(entry.positions.prefix(3), id: \.id) { position in
                                HStack {
                                    Text(position.symbol)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(position.status.rawValue)
                                        .font(.caption)
                                        .foregroundColor(position.status.color)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(position.status.color.opacity(0.2))
                                        )
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right side - Mini chart
                VStack(alignment: .trailing, spacing: 8) {
                    Text("5M Chart")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    MiniOHLCChartView(chartData: entry.chartData)
                        .frame(width: 80, height: 60)
                    
                    Text("Last: \(entry.date.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    }
}

struct LargeWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("1Limit Trading")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let lastCandle = entry.chartData.last {
                            Text("WMATIC/USDC: $\(lastCandle.close, specifier: "%.4f")")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Circle()
                            .fill(entry.positions.isEmpty ? Color.gray : Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("Updated \(entry.date.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Chart section
                VStack(alignment: .leading, spacing: 8) {
                    Text("OHLC Chart (5M)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    MiniOHLCChartView(chartData: entry.chartData)
                        .frame(height: 80)
                }
                
                // Positions list
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Active Positions")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(entry.positions.count) Total")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if entry.positions.isEmpty {
                        Text("No active positions")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(entry.positions.prefix(5), id: \.id) { position in
                            PositionRowView(position: position)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .containerBackground(for: .widget) {
                LinearGradient(
                    colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    }
}

// MARK: - Supporting Views

struct MiniOHLCChartView: View {
    let chartData: [WidgetCandlestickData]
    
    var body: some View {
        GeometryReader { geometry in
            if chartData.isEmpty {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        VStack {
                            Text("No Data")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("(\(chartData.count) points)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    )
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 4) {
                        // Price axis legend
                        VStack(alignment: .trailing, spacing: 0) {
                            let minPrice = chartData.map(\.low).min() ?? 0
                            let maxPrice = chartData.map(\.high).max() ?? 1
                            
                            Text("$\(maxPrice, specifier: "%.4f")")
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("$\(minPrice, specifier: "%.4f")")
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 40)
                        
                        // Chart area
                        GeometryReader { chartGeometry in
                            let width = chartGeometry.size.width
                            let height = chartGeometry.size.height
                            
                            let minPrice = chartData.map(\.low).min() ?? 0
                            let maxPrice = chartData.map(\.high).max() ?? 1
                            let priceRange = maxPrice - minPrice
                            
                            let candleWidth = width / CGFloat(chartData.count) * 0.8
                            let spacing = width / CGFloat(chartData.count) * 0.2
                            
                            ForEach(Array(chartData.enumerated()), id: \.element.id) { index, candle in
                                let x = CGFloat(index) * (candleWidth + spacing) + candleWidth / 2
                                
                                // High-Low wick
                                let highY = height - ((candle.high - minPrice) / priceRange) * height
                                let lowY = height - ((candle.low - minPrice) / priceRange) * height
                                
                                Path { path in
                                    path.move(to: CGPoint(x: x, y: highY))
                                    path.addLine(to: CGPoint(x: x, y: lowY))
                                }
                                .stroke(candle.isBullish ? Color.green : Color.red, lineWidth: 1)
                                
                                // Open-Close body
                                let openY = height - ((candle.open - minPrice) / priceRange) * height
                                let closeY = height - ((candle.close - minPrice) / priceRange) * height
                                let bodyTop = min(openY, closeY)
                                let bodyHeight = abs(openY - closeY)
                                
                                Rectangle()
                                    .fill(candle.isBullish ? Color.green : Color.red)
                                    .frame(width: candleWidth, height: max(1, bodyHeight))
                                    .position(x: x, y: bodyTop + bodyHeight / 2)
                            }
                        }
                    }
                    
                    // Time axis legend
                    HStack {
                        Spacer(minLength: 40)
                        if let firstTime = chartData.first?.timestamp,
                           let lastTime = chartData.last?.timestamp {
                            HStack {
                                Text(formatTime(firstTime))
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(formatTime(lastTime))
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(height: 12)
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct MiniChartView: View {
    let priceData: [PricePoint]
    
    var body: some View {
        GeometryReader { geometry in
            if priceData.isEmpty {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text("No Data")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    )
            } else {
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    guard let minPrice = priceData.map(\.price).min(),
                          let maxPrice = priceData.map(\.price).max(),
                          maxPrice > minPrice else { return }
                    
                    let stepWidth = width / CGFloat(priceData.count - 1)
                    
                    for (index, point) in priceData.enumerated() {
                        let x = CGFloat(index) * stepWidth
                        let normalizedY = (point.price - minPrice) / (maxPrice - minPrice)
                        let y = height - (normalizedY * height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
            }
        }
    }
}

struct PositionRowView: View {
    let position: WidgetPosition
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(position.symbol)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("\(position.amount, specifier: "%.6f")")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(position.status.rawValue)
                    .font(.caption)
                    .foregroundColor(position.status.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(position.status.color.opacity(0.2))
                    )
                
                Text("$\(position.value, specifier: "%.2f")")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Data Models

struct WidgetPosition: Identifiable, Codable {
    let id = UUID()
    let symbol: String
    let amount: Double
    let value: Double
    let status: PositionStatus
}

enum PositionStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case filled = "Filled"
    case cancelled = "Cancelled"
    case failed = "Failed"
    
    var color: Color {
        switch self {
        case .pending:
            return .gray
        case .filled:
            return .blue
        case .cancelled:
            return .orange
        case .failed:
            return .purple
        }
    }
}

struct PricePoint: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let price: Double
}

// MARK: - Sample Data

let samplePositions = [
    WidgetPosition(symbol: "WMATIC/USDC", amount: 10.0, value: 45.50, status: .filled),
    WidgetPosition(symbol: "USDC/WMATIC", amount: 25.0, value: 80.0, status: .pending)
]

let samplePriceData: [PricePoint] = {
    let basePrice = 1.25
    return (0..<24).map { hour in
        let variation = Double.random(in: -0.1...0.1)
        return PricePoint(
            timestamp: Date().addingTimeInterval(-Double(hour) * 3600),
            price: basePrice + variation
        )
    }
}()

@main
struct _LimitWidgetBundle: WidgetBundle {
    var body: some Widget {
        _LimitWidget()
    }
}

#Preview("Small", as: .systemSmall) {
    _LimitWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        positions: samplePositions,
        totalValue: 125.50,
        priceData: samplePriceData,
        chartData: sampleChartData
    )
}

#Preview("Medium", as: .systemMedium) {
    _LimitWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        positions: samplePositions,
        totalValue: 125.50,
        priceData: samplePriceData,
        chartData: sampleChartData
    )
}

#Preview("Large", as: .systemLarge) {
    _LimitWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        positions: samplePositions,
        totalValue: 125.50,
        priceData: samplePriceData,
        chartData: sampleChartData
    )
}