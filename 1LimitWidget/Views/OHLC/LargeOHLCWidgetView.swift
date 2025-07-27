//
//  LargeOHLCWidgetView.swift
//  1LimitWidget
//
//  Large size OHLC widget view 📈✨
//

import SwiftUI
import WidgetKit

struct LargeOHLCWidgetView: View {
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
                        .fill(entry.openOrders.isEmpty ? Color.gray : Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Updated \(entry.date.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Chart section - adaptive height based on orders count
            VStack(alignment: .leading, spacing: 8) {
                Text("OHLC Chart (5M)")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                let chartHeight: CGFloat = {
                    if entry.openOrders.isEmpty {
                        return 120  // More space when no orders
                    } else if entry.openOrders.count == 1 {
                        return 100  // Medium space for 1 order
                    } else {
                        return 80   // Standard space for multiple orders
                    }
                }()
                
                MiniOHLCChartView(chartData: entry.chartData)
                    .frame(height: chartHeight)
            }
            
            // Open Orders list - compact when fewer orders
            VStack(alignment: .leading, spacing: entry.openOrders.isEmpty ? 4 : 6) {
                HStack {
                    Text("Open Orders")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(entry.openOrders.count) Total")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if entry.openOrders.isEmpty {
                    Text("No open orders")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 4) {
                        ForEach(entry.openOrders.prefix(3), id: \.id) { order in
                            OrderRowView(order: order)
                        }
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