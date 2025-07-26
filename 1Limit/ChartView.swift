//
//  ChartView.swift
//  1Limit
//
//  OHLC Candlestick Chart View for currency pairs 📈✨
//

import SwiftUI
import Charts

struct CandlestickMark: ChartContent {
    let data: CandlestickData
    let width: CGFloat

    var body: some ChartContent {
        RuleMark(
            x: .value("Date", data.timestamp),
            yStart: .value("Low", data.low),
            yEnd: .value("High", data.high)
        )
        .foregroundStyle(data.isBullish ? .green : .red)
        .lineStyle(StrokeStyle(lineWidth: 1))

        RectangleMark(
            x: .value("Date", data.timestamp),
            yStart: .value("Start", min(data.open, data.close)),
            yEnd: .value("End", max(data.open, data.close)),
            width: .fixed(12)
        )
        .foregroundStyle(data.isBullish ? .green : .red)
    }
}

struct ChartView: View {
    let currencyPair: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chartService = ChartDataService.shared

    @State private var selectedData: CandlestickData?
    @State private var selectedTimeframe: ChartTimeframe = .oneHour

    var visibleData: [CandlestickData] {
        // Show all real chart data, no pagination needed
        return chartService.candlestickData
    }


    var minPrice: Double {
        visibleData.map { $0.low }.min() ?? 0
    }

    var maxPrice: Double {
        visibleData.map { $0.high }.max() ?? 100
    }

    private var tokenPair: (from: String, to: String) {
        let components = currencyPair.components(separatedBy: "/")
        return (from: components.first ?? "WMATIC", to: components.last ?? "USDC")
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title)
                    .foregroundColor(.blue)

                Text(currencyPair)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            if let latest = chartService.candlestickData.last {
                HStack {
                    Text("Current: \(latest.formattedClose)")
                        .font(.headline)
                        .foregroundColor(latest.isBullish ? .green : .red)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: latest.isBullish ? "arrow.up" : "arrow.down")
                        Text(latest.formattedPercentChange)
                    }
                    .font(.caption)
                    .foregroundColor(latest.isBullish ? .green : .red)
                }
            }

            if chartService.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading chart data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var timeframeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChartTimeframe.allCases, id: \.self) { timeframe in
                    Button(action: {
                        selectedTimeframe = timeframe
                        Task {
                            await chartService.fetchChartData(
                                fromToken: tokenPair.from,
                                toToken: tokenPair.to,
                                timeframe: timeframe
                            )
                            // Auto-scroll to latest data after timeframe change
                            // Chart will automatically show all available data
                        }
                    }) {
                        Text(timeframe.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTimeframe == timeframe ? Color.blue : Color(.systemGray6))
                            .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var selectedCandleDetails: some View {
        if let selected = selectedData {
            VStack(alignment: .leading, spacing: 8) {
                Text(selected.timestamp, style: .date)
                    .font(.headline)
                HStack(spacing: 20) {
                    Label("O: \(selected.formattedOpen)", systemImage: "circle")
                    Label("H: \(selected.formattedHigh)", systemImage: "arrow.up")
                    Label("L: \(selected.formattedLow)", systemImage: "arrow.down")
                    Label("C: \(selected.formattedClose)", systemImage: "circle.fill")
                }
                .font(.caption)
                .foregroundColor(selected.isBullish ? .green : .red)

                HStack {
                    Text("Change: \(selected.formattedChange)")
                    Spacer()
                    Text("Volume: \(selected.formattedVolume)")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var chartSection: some View {
        if !chartService.candlestickData.isEmpty {
            HStack(spacing: 0) {
                mainChart
                yAxisChart
            }
            .padding(.horizontal)
        } else if !chartService.isLoading {
            emptyStateView
        }
    }

    private var mainChart: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Chart(visibleData) { item in
                CandlestickMark(data: item, width: 12)

                if item.id == selectedData?.id {
                    RuleMark(x: .value("Selected", item.timestamp))
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
    }

    private var yAxisChart: some View {
        Chart(visibleData.prefix(1)) { item in
            PointMark(x: .value("Date", item.timestamp), y: .value("Price", item.close))
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

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No chart data available")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Try selecting a different timeframe or check your connection")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 300)
    }


    private var chartLegend: some View {
        HStack(spacing: 30) {
            Spacer()

            Text("\(visibleData.count) candles")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .font(.caption)
        .padding(.horizontal)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerView
                        .padding(.horizontal)

                    timeframeSelector

                    selectedCandleDetails

                    chartSection


                    chartLegend
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
            Task {
                await chartService.fetchChartData(
                    fromToken: tokenPair.from,
                    toToken: tokenPair.to,
                    timeframe: selectedTimeframe
                )
            }
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
