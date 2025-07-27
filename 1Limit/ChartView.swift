//
//  ChartView.swift
//  1Limit
//
//  OHLC Candlestick Chart View for currency pairs 📈✨
//

import Charts
import SwiftUI

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
  @State private var selectedTimeframe: ChartTimeframe = .fiveMinutes

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
    AppCard {
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          ZStack {
            Circle()
              .fill(
                LinearGradient(
                  colors: [
                    Color.white.opacity(0.25),
                    Color.white.opacity(0.15),
                    Color.white.opacity(0.1),
                  ],
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
              .frame(width: 50, height: 50)
              .overlay(
                Circle()
                  .strokeBorder(
                    LinearGradient(
                      colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                  )
              )
              .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
              .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)

            Image(systemName: "chart.line.uptrend.xyaxis")
              .font(.system(size: 20, weight: .medium))
              .foregroundColor(.white)
          }

          Text(currencyPair)
            .appTitle()
        }

        if let latest = chartService.candlestickData.last {
          HStack {
            Text("Current: \(latest.formattedClose)")
              .priceText(color: latest.isBullish ? Color.bullishGreen : Color.bearishRed)

            Spacer()

            HStack(spacing: 4) {
              Image(systemName: latest.isBullish ? "arrow.up" : "arrow.down")
                .font(.caption)
                .foregroundColor(latest.isBullish ? Color.bullishGreen : Color.bearishRed)
              Text(latest.formattedPercentChange)
                .captionText()
                .foregroundColor(latest.isBullish ? Color.bullishGreen : Color.bearishRed)
            }
          }
        }
      }
    }
  }

  private var timeframeSelector: some View {
    AppCard {
      VStack(spacing: 12) {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(ChartTimeframe.allCases, id: \.self) { timeframe in
              SmallButton(
                timeframe.displayName, style: selectedTimeframe == timeframe ? .primary : .secondary
              ) {
                selectedTimeframe = timeframe
                Task {
                  await chartService.fetchChartData(
                    fromToken: tokenPair.from,
                    toToken: tokenPair.to,
                    timeframe: timeframe
                  )
                }
              }
            }
          }
          .padding(.horizontal, 4)
        }
      }
    }
    .padding(.horizontal)
  }

  @ViewBuilder
  private var selectedCandleDetails: some View {
    if let selected = selectedData {
      AppCard {
        VStack(alignment: .leading, spacing: 12) {
          Text(selected.timestamp, style: .date)
            .cardTitle()

          HStack(spacing: 16) {
            VStack(spacing: 4) {
              Text("Open")
                .captionText()
              Text(selected.formattedOpen)
                .priceText(color: Color.secondaryText)
            }
            VStack(spacing: 4) {
              Text("High")
                .captionText()
              Text(selected.formattedHigh)
                .priceText(color: Color.bullishGreen)
            }
            VStack(spacing: 4) {
              Text("Low")
                .captionText()
              Text(selected.formattedLow)
                .priceText(color: Color.bearishRed)
            }
            VStack(spacing: 4) {
              Text("Close")
                .captionText()
              Text(selected.formattedClose)
                .priceText(color: selected.isBullish ? Color.bullishGreen : Color.bearishRed)
            }
          }

          HStack {
            Text("Change: \(selected.formattedChange)")
              .captionText()
            Spacer()
            Text("Volume: \(selected.formattedVolume)")
              .captionText()
          }
        }
      }
      .padding(.horizontal)
    }
  }

  @ViewBuilder
  private var chartSection: some View {
    ZStack {
      if !chartService.candlestickData.isEmpty {
        HStack(spacing: 0) {
          mainChart
          yAxisChart
        }
        .padding(.horizontal)
      } else if !chartService.isLoading {
        emptyStateView
      }

      // Centered loading overlay
      if chartService.isLoading {
        VStack {
          Spacer()
          HStack {
            Spacer()
            VStack(spacing: 12) {
              ProgressView()
                .scaleEffect(1.2)
              Text("Loading chart data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(20)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(12)
            .shadow(radius: 4)
            Spacer()
          }
          Spacer()
          Spacer()  // Push slightly toward center-bottom
        }
      }
    }
  }

  private var candlestickChart: some View {
    Chart(visibleData) { item in
      CandlestickMark(data: item, width: 12)

      if item.id == selectedData?.id {
        RuleMark(x: .value("Selected", item.timestamp))
          .foregroundStyle(.gray.opacity(0.3))
          .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
      }
    }
  }

  private var chartModifiers: some View {
    candlestickChart
      .frame(width: CGFloat(visibleData.count) * 20, height: 400)
      .chartYScale(domain: (minPrice - minPrice * 0.02)...(maxPrice + maxPrice * 0.02))
      .chartXAxis {
        AxisMarks(values: .automatic(desiredCount: 6)) { value in
          AxisGridLine()
          AxisValueLabel(format: .dateTime.month().day())
        }
      }
      .chartYAxis(.hidden)
  }

  private func chartBackground(geometry: GeometryProxy) -> some View {
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

  private var mainChart: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        chartModifiers
          .chartBackground { chartProxy in
            GeometryReader { geometry in
              chartBackground(geometry: geometry)
            }
          }
          .onAppear {
            // Auto-scroll to show latest candles by scrolling to end
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              // The chart will naturally show the latest data since it's at the trailing edge
            }
          }
        Spacer()
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
    .chartYScale(domain: (minPrice - minPrice * 0.02)...(maxPrice + maxPrice * 0.02))
    .chartXAxis(.hidden)
    .chartYAxis {
      AxisMarks(position: .trailing) { value in
        AxisValueLabel()
      }
    }
    .background(Color.clear)
  }

  private var emptyStateView: some View {
    AppCard {
      VStack(spacing: 20) {
        Image(systemName: "chart.line.downtrend.xyaxis")
          .font(.system(size: 60))
          .foregroundColor(.secondaryText)

        Text("No Chart Data Available")
          .sectionTitle()

        Text("Try selecting a different timeframe or check your connection")
          .secondaryText()
          .multilineTextAlignment(.center)
          .lineSpacing(4)
      }
    }
    .frame(height: 200)
    .padding(.horizontal)
  }

  private var chartLegend: some View {
    AppCard {
      HStack {
        Text("\(visibleData.count) candles")
          .captionText()
      }
    }
    .padding(.horizontal)
  }

  var body: some View {
    NavigationView {
      ZStack {
        Color.appBackground
          .ignoresSafeArea()

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
      }
      .navigationTitle("Chart")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(Color.appBackground, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          SmallButton("Done", style: .secondary) {
            dismiss()
          }
        }
      }
    }
    .preferredColorScheme(.dark)
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
