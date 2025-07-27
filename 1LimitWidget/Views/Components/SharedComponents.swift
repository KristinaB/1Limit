//
//  SharedComponents.swift
//  1LimitWidget
//
//  Shared UI components for widgets 🎨✨
//

import SwiftUI
import WidgetKit

// MARK: - Mini OHLC Chart View

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
                            
                            // Price level lines
                            let priceLevels = getPriceLevels(min: minPrice, max: maxPrice)
                            ForEach(priceLevels, id: \.self) { level in
                                let y = height - ((level - minPrice) / priceRange) * height
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: width, y: y))
                                }
                                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                            }
                            
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
    
    private func getPriceLevels(min: Double, max: Double) -> [Double] {
        var levels: [Double] = []
        
        // Determine step size based on price range
        let step: Double
        if max < 1.0 {
            step = 0.05  // Every $0.05 below $1
        } else {
            step = 0.15  // Every $0.15 above $1
        }
        
        // Start from a rounded value
        let start = floor(min / step) * step
        var current = start
        
        while current <= max {
            if current >= min && current <= max {
                levels.append(current)
            }
            current += step
        }
        
        return levels
    }
}

// MARK: - Position Row View

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