//
//  SmallOHLCWidgetView.swift
//  1LimitWidget
//
//  Small size OHLC widget view 📱✨
//

import SwiftUI
import WidgetKit

struct SmallOHLCWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Text("1Limit")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Circle()
                    .fill(entry.openOrders.isEmpty ? Color.gray : Color.green)
                    .frame(width: 6, height: 6)
            }
            
            // Price info
            VStack(alignment: .leading, spacing: 2) {
                Text("WMATIC/USDC")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                if let lastCandle = entry.chartData.last {
                    HStack {
                        Text("$\(lastCandle.close, specifier: "%.4f")")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        let change = lastCandle.close - lastCandle.open
                        let changePercent = (change / lastCandle.open) * 100
                        HStack(spacing: 1) {
                            Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 8))
                            Text("\(changePercent, specifier: "%.1f")%")
                                .font(.system(size: 8))
                        }
                        .foregroundColor(change >= 0 ? .green : .red)
                    }
                }
            }
            
            // Chart - takes more space when fewer orders
            MiniOHLCChartView(chartData: entry.chartData)
                .frame(height: entry.openOrders.isEmpty ? 50 : (entry.openOrders.count == 1 ? 40 : 30))
            
            Spacer(minLength: 0)
            
            // Orders section - compact
            if !entry.openOrders.isEmpty {
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(entry.openOrders.count) Open")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    
                    ForEach(entry.openOrders.prefix(entry.openOrders.count == 1 ? 1 : 2)) { order in
                        HStack {
                            Text("\(order.fromToken)/\(order.toToken)")
                                .font(.system(size: 9))
                                .foregroundColor(.white)
                            Spacer()
                            Text("$\(order.limitPrice)")
                                .font(.system(size: 9))
                                .foregroundColor(.orange)
                        }
                    }
                }
            } else {
                Text("No open orders")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
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