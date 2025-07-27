//
//  LineChartView.swift
//  1LimitWidget
//
//  Line chart component for widget 📈✨
//

import SwiftUI
import WidgetKit

struct LineChartView: View {
    let priceData: [PricePoint]
    let closedOrders: [WidgetTransaction]
    
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
                VStack(spacing: 0) {
                    HStack(spacing: 4) {
                        // Price axis legend with price level labels
                        GeometryReader { axisGeometry in
                            let minPrice = priceData.map(\.price).min() ?? 0
                            let maxPrice = priceData.map(\.price).max() ?? 1
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
                            
                            let minPrice = priceData.map(\.price).min() ?? 0
                            let maxPrice = priceData.map(\.price).max() ?? 1
                            let priceRange = maxPrice - minPrice
                            
                            // Price level lines (behind line chart)
                            let priceLevels = getPriceLevels(min: minPrice, max: maxPrice)
                            ForEach(priceLevels, id: \.self) { level in
                                let y = height - ((level - minPrice) / priceRange) * height
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: width, y: y))
                                }
                                .stroke(Color.white.opacity(0.6), lineWidth: 1.0)
                            }
                            
                            // Line chart path
                            Path { path in
                                for (index, point) in priceData.enumerated() {
                                    let x = (width / CGFloat(priceData.count - 1)) * CGFloat(index)
                                    let normalizedY = (point.price - minPrice) / priceRange
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
                            
                            // Closed order dots
                            ForEach(closedOrders) { order in
                                if let orderX = getXPosition(for: order.date, width: width),
                                   let price = Double(order.limitPrice),
                                   let orderY = getYPosition(for: price, minPrice: minPrice, maxPrice: maxPrice, height: height) {
                                    Circle()
                                        .fill(order.status == .confirmed ? Color.green : Color.red)
                                        .frame(width: 6, height: 6)
                                        .position(x: orderX, y: orderY)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 1)
                                                .frame(width: 6, height: 6)
                                                .position(x: orderX, y: orderY)
                                        )
                                }
                            }
                        }
                    }
                    
                    // Time axis legend
                    HStack {
                        Spacer(minLength: 40)
                        if let firstTime = priceData.first?.timestamp,
                           let lastTime = priceData.last?.timestamp {
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
    
    private func getXPosition(for date: Date, width: CGFloat) -> CGFloat? {
        guard let firstTime = priceData.first?.timestamp,
              let lastTime = priceData.last?.timestamp else { return nil }
        
        let timeRange = lastTime.timeIntervalSince(firstTime)
        guard timeRange > 0 else { return nil }
        
        let timeSinceStart = date.timeIntervalSince(firstTime)
        let normalizedX = timeSinceStart / timeRange
        
        guard normalizedX >= 0 && normalizedX <= 1 else { return nil }
        
        return width * CGFloat(normalizedX)
    }
    
    private func getYPosition(for price: Double, minPrice: Double, maxPrice: Double, height: CGFloat) -> CGFloat? {
        let priceRange = maxPrice - minPrice
        guard priceRange > 0 else { return nil }
        
        let normalizedY = (price - minPrice) / priceRange
        return height - (normalizedY * height)
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

// Sample closed orders using WidgetTransaction
let sampleClosedOrders: [WidgetTransaction] = []