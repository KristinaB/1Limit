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
    let closedOrders: [ClosedOrder]
    
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
                        // Price axis legend
                        VStack(alignment: .trailing, spacing: 0) {
                            let minPrice = priceData.map(\.price).min() ?? 0
                            let maxPrice = priceData.map(\.price).max() ?? 1
                            
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
                            
                            let minPrice = priceData.map(\.price).min() ?? 0
                            let maxPrice = priceData.map(\.price).max() ?? 1
                            let priceRange = maxPrice - minPrice
                            
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
                                if let orderX = getXPosition(for: order.executedAt, width: width),
                                   let orderY = getYPosition(for: order.executionPrice, minPrice: minPrice, maxPrice: maxPrice, height: height) {
                                    Circle()
                                        .fill(order.isSuccessful ? Color.green : Color.red)
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
}

// MARK: - Closed Order Model

struct ClosedOrder: Identifiable {
    let id = UUID()
    let symbol: String
    let amount: Double
    let executionPrice: Double
    let executedAt: Date
    let isSuccessful: Bool
    let type: OrderType
    
    enum OrderType: String {
        case limit = "Limit"
        case market = "Market"
    }
}

// Sample closed orders
let sampleClosedOrders: [ClosedOrder] = [
    ClosedOrder(
        symbol: "WMATIC/USDC",
        amount: 100,
        executionPrice: 0.445,
        executedAt: Date().addingTimeInterval(-3600 * 2),
        isSuccessful: true,
        type: .limit
    ),
    ClosedOrder(
        symbol: "WMATIC/USDC",
        amount: 50,
        executionPrice: 0.451,
        executedAt: Date().addingTimeInterval(-3600 * 5),
        isSuccessful: false,
        type: .limit
    )
]