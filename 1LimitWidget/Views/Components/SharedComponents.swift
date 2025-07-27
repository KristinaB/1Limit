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
                        // Price axis legend with price level labels
                        GeometryReader { axisGeometry in
                            let minPrice = chartData.map(\.low).min() ?? 0
                            let maxPrice = chartData.map(\.high).max() ?? 1
                            let priceRange = maxPrice - minPrice
                            let axisHeight = axisGeometry.size.height
                            
                            let priceLevels = getPriceLevels(min: minPrice, max: maxPrice)
                            
                            ForEach(priceLevels, id: \.self) { level in
                                let y = axisHeight - ((level - minPrice) / priceRange) * axisHeight
                                Text("$\(level, specifier: level < 1 ? "%.2f" : "%.1f")")
                                    .font(.system(size: 7))
                                    .foregroundColor(.gray)
                                    .position(x: 35, y: y)
                            }
                            
                            // Always show min/max if they're not already covered by price levels
                            if !priceLevels.contains(where: { abs($0 - minPrice) < 0.001 }) {
                                Text("$\(minPrice, specifier: "%.3f")")
                                    .font(.system(size: 7))
                                    .foregroundColor(.gray.opacity(0.7))
                                    .position(x: 35, y: axisHeight)
                            }
                            
                            if !priceLevels.contains(where: { abs($0 - maxPrice) < 0.001 }) {
                                Text("$\(maxPrice, specifier: "%.3f")")
                                    .font(.system(size: 7))
                                    .foregroundColor(.gray.opacity(0.7))
                                    .position(x: 35, y: 0)
                            }
                        }
                        .frame(width: 40)
                        
                        // Chart area
                        GeometryReader { chartGeometry in
                            let width = chartGeometry.size.width
                            let height = chartGeometry.size.height
                            
                            let minPrice = chartData.map(\.low).min() ?? 0
                            let maxPrice = chartData.map(\.high).max() ?? 1
                            let priceRange = maxPrice - minPrice
                            
                            // Price level lines (behind candlesticks)
                            let priceLevels = getPriceLevels(min: minPrice, max: maxPrice)
                            ForEach(priceLevels, id: \.self) { level in
                                let y = height - ((level - minPrice) / priceRange) * height
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: width, y: y))
                                }
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.0)
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
        
        // Determine step size based on overall price range
        let step: Double
        if max < 1.0 {
            step = 0.05  // Every $0.05 below $1
        } else {
            step = 0.15  // Every $0.15 above $1  
        }
        
        // Start from a level that gives good coverage
        let start = floor((min - step/2) / step) * step
        var current = start
        
        // Generate levels that are within or slightly outside the range for better labeling
        while current <= max + step {
            if current >= min - step/4 && current <= max + step/4 {
                levels.append(round(current * 100) / 100)  // Round to 2 decimal places
            }
            current += step
        }
        
        return levels.sorted()
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

// MARK: - Order Row View

struct OrderRowView: View {
    let order: WidgetTransaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(order.fromToken)/\(order.toToken)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("\(order.fromAmount) \(order.fromToken)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(order.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(statusColor(order.status))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(statusColor(order.status).opacity(0.2))
                    )
                
                Text("@$\(order.limitPrice)")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(_ status: WidgetTransactionStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .confirmed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }
}