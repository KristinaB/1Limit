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