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
        VStack(alignment: .leading, spacing: 8) {
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
            
            if !entry.openOrders.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.openOrders.count) Open Order\(entry.openOrders.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    ForEach(entry.openOrders.prefix(2)) { order in
                        HStack {
                            Text("\(order.fromToken)/\(order.toToken)")
                                .font(.caption2)
                                .foregroundColor(.white)
                            Spacer()
                            Text("$\(order.limitPrice)")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            } else {
                Text("No open orders")
                    .font(.caption2)
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