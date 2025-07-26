//
//  ChartView.swift
//  1Limit
//
//  OHLC Candlestick Chart View for currency pairs 📈✨
//

import SwiftUI
import Charts

extension OHLCData {
    static func generateSampleData(for pair: String) -> [OHLCData] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // Generate realistic sample data based on currency pair 💎
        let basePrice: Double
        let volatility: Double
        
        switch pair {
        case "WMATIC/USDC":
            basePrice = 0.85
            volatility = 0.05
        case "USDC/WMATIC":
            basePrice = 1.18
            volatility = 0.06
        default:
            basePrice = 1.0
            volatility = 0.04
        }
        
        var data: [OHLCData] = []
        var currentPrice = basePrice
        
        for i in 0..<50 {
            let date = Calendar.current.date(byAdding: .day, value: -49 + i, to: Date()) ?? Date()
            
            // Generate realistic OHLC data with some randomness 🦋
            let open = currentPrice
            let change = (Double.random(in: -1...1) * volatility)
            let high = open + abs(change) + Double.random(in: 0...volatility/2)
            let low = open - abs(change) - Double.random(in: 0...volatility/2)
            let close = open + change
            
            data.append(OHLCData(
                date: date,
                open: max(0, open),
                high: max(0, high),
                low: max(0, low),
                close: max(0, close)
            ))
            
            currentPrice = close
        }
        
        return data
    }
}

struct CandlestickMark: ChartContent {
    let data: OHLCData
    let width: CGFloat
    
    var body: some ChartContent {
        RuleMark(
            x: .value("Date", data.date),
            yStart: .value("Low", data.low),
            yEnd: .value("High", data.high)
        )
        .foregroundStyle(data.isGreen ? .green : .red)
        .lineStyle(StrokeStyle(lineWidth: 1))
        
        RectangleMark(
            x: .value("Date", data.date),
            yStart: .value("Start", min(data.open, data.close)),
            yEnd: .value("End", max(data.open, data.close)),
            width: .fixed(12)
        )
        .foregroundStyle(data.isGreen ? .green : .red)
    }
}

struct ChartView: View {
    let currencyPair: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedData: OHLCData?
    @State private var visibleRange: Range<Int> = 0..<30
    @State private var chartData: [OHLCData] = []
    
    var visibleData: [OHLCData] {
        Array(chartData[visibleRange.clamped(to: 0..<chartData.count)])
    }
    
    var minPrice: Double {
        visibleData.map { $0.low }.min() ?? 0
    }
    
    var maxPrice: Double {
        visibleData.map { $0.high }.max() ?? 100
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with currency pair info 🎀
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            Text(currencyPair)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        
                        if let latest = chartData.last {
                            HStack {
                                Text("Current: $\(String(format: "%.4f", latest.close))")
                                    .font(.headline)
                                    .foregroundColor(latest.isGreen ? .green : .red)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: latest.isGreen ? "arrow.up" : "arrow.down")
                                    Text("\(latest.isGreen ? "+" : "")\(String(format: "%.2f", ((latest.close - latest.open) / latest.open) * 100))%")
                                }
                                .font(.caption)
                                .foregroundColor(latest.isGreen ? .green : .red)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Selected candle details 💖
                    if let selected = selectedData {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(selected.date, style: .date)
                                .font(.headline)
                            HStack(spacing: 20) {
                                Label(String(format: "O: %.4f", selected.open), systemImage: "circle")
                                Label(String(format: "H: %.4f", selected.high), systemImage: "arrow.up")
                                Label(String(format: "L: %.4f", selected.low), systemImage: "arrow.down")
                                Label(String(format: "C: %.4f", selected.close), systemImage: "circle.fill")
                            }
                            .font(.caption)
                            .foregroundColor(selected.isGreen ? .green : .red)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Chart with Y-axis 🌸
                    HStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Chart(visibleData) { item in
                                CandlestickMark(data: item, width: 12)
                                
                                if item.id == selectedData?.id {
                                    RuleMark(x: .value("Selected", item.date))
                                        .foregroundStyle(.gray.opacity(0.3))
                                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                }
                            }
                            .frame(width: CGFloat(visibleData.count) * 20, height: 400)
                            .chartYScale(domain: (minPrice - minPrice*0.02)...(maxPrice + maxPrice*0.02))
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                                    AxisGridLine()
                                    AxisValueLabel(format: .dateTime.month().day())
                                }
                            }
                            .chartYAxis(.hidden)
                            .chartBackground { chartProxy in
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .onTapGesture { location in
                                            let xPosition = location.x
                                            let chartWidth = geometry.size.width
                                            let candleWidth = chartWidth / CGFloat(visibleData.count)
                                            let index = Int(xPosition / candleWidth)
                                            
                                            if index >= 0 && index < visibleData.count {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    selectedData = visibleData[index]
                                                }
                                            }
                                        }
                                }
                            }
                        }
                        .clipped()
                        
                        // Y-axis price labels 🦄
                        Chart(visibleData.prefix(1)) { item in
                            PointMark(x: .value("Date", item.date), y: .value("Price", item.close))
                                .opacity(0)
                        }
                        .frame(width: 50, height: 400)
                        .chartYScale(domain: (minPrice - minPrice*0.02)...(maxPrice + maxPrice*0.02))
                        .chartXAxis(.hidden)
                        .chartYAxis {
                            AxisMarks(position: .trailing) { value in
                                AxisValueLabel()
                            }
                        }
                        .background(Color.clear)
                    }
                    .padding(.horizontal)
                    
                    // Page navigation 🌺
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(0..<(chartData.count / 30 + (chartData.count % 30 > 0 ? 1 : 0)), id: \.self) { page in
                                Button(action: {
                                    withAnimation {
                                        let start = page * 30
                                        let end = min(start + 30, chartData.count)
                                        visibleRange = start..<end
                                    }
                                }) {
                                    Text("Page \(page + 1)")
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(visibleRange.lowerBound / 30 == page ? Color.blue : Color(.systemGray6))
                                        .foregroundColor(visibleRange.lowerBound / 30 == page ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Chart legend 🎪
                    HStack(spacing: 30) {
                        Label("Bullish", systemImage: "arrow.up.circle.fill")
                            .foregroundColor(.green)
                        Label("Bearish", systemImage: "arrow.down.circle.fill")
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        Text("\(visibleData.count) candles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            chartData = OHLCData.generateSampleData(for: currencyPair)
        }
    }
}

extension Range where Bound == Int {
    func clamped(to range: Range<Int>) -> Range<Int> {
        let lower = Swift.max(range.lowerBound, self.lowerBound)
        let upper = Swift.min(range.upperBound, self.upperBound)
        return lower..<upper
    }
}

#Preview {
    ChartView(currencyPair: "WMATIC/USDC")
}