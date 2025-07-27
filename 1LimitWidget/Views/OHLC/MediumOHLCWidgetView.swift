//
//  MediumOHLCWidgetView.swift
//  1LimitWidget
//
//  Medium size OHLC widget view 📊✨
//

import SwiftUI
import WidgetKit

struct MediumOHLCWidgetView: View {
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