//
//  LineChartWidgetViews.swift
//  1LimitWidget
//
//  Line chart widget views for all sizes 📊✨
//

import SwiftUI
import WidgetKit

// MARK: - Medium Widget View

struct LineChartMediumWidgetView: View {
  let entry: WidgetEntry

  var body: some View {
    VStack(spacing: 6) {
      // Header with price info
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("WMATIC/USDC")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)

          if let currentPrice = entry.priceData.last?.price {
            Text("$\(currentPrice, specifier: "%.4f")")
              .font(.title3)
              .fontWeight(.bold)
              .foregroundColor(.white)
          }
        }

        Spacer()

        // Price change indicator
        if let priceChange = getPriceChange() {
          VStack(alignment: .trailing, spacing: 1) {
            Text(
              "\(priceChange.percentage >= 0 ? "+" : "")\(priceChange.percentage, specifier: "%.2f")%"
            )
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(priceChange.percentage >= 0 ? .green : .red)

            Text(
              "\(priceChange.absolute >= 0 ? "+" : "")\(priceChange.absolute, specifier: "%.4f")"
            )
            .font(.caption2)
            .foregroundColor(.gray)
          }
        }
      }

      // Line chart
      LineChartView(
        priceData: entry.priceData,
        closedOrders: entry.closedOrders
      )
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

  private func getPriceChange() -> (absolute: Double, percentage: Double)? {
    guard let first = entry.priceData.first,
      let last = entry.priceData.last
    else {
      return nil
    }

    let absolute = last.price - first.price
    let percentage = first.price != 0 ? (absolute / first.price) * 100 : 0

    return (absolute: absolute, percentage: percentage)
  }
}

// MARK: - Large Widget View

struct LineChartLargeWidgetView: View {
  let entry: WidgetEntry

  var body: some View {
    VStack(spacing: 8) {
      // Header section
      HStack {
        VStack(alignment: .leading, spacing: 3) {
          Text("WMATIC/USDC")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)

          if let currentPrice = entry.priceData.last?.price {
            Text("$\(currentPrice, specifier: "%.4f")")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(.white)
          }
        }

        Spacer()

        // Price change and time
        VStack(alignment: .trailing, spacing: 2) {
          if let priceChange = getPriceChange() {
            HStack(spacing: 4) {
              Image(systemName: priceChange.percentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
                .foregroundColor(priceChange.percentage >= 0 ? .green : .red)

              Text(
                "\(priceChange.percentage >= 0 ? "+" : "")\(priceChange.percentage, specifier: "%.2f")%"
              )
              .font(.caption)
              .fontWeight(.medium)
              .foregroundColor(priceChange.percentage >= 0 ? .green : .red)
            }

            Text(
              "$\(priceChange.absolute >= 0 ? "+" : "")\(priceChange.absolute, specifier: "%.4f")"
            )
            .font(.caption2)
            .foregroundColor(.gray)
          }

          Text("24H")
            .font(.caption2)
            .foregroundColor(.gray)
        }
      }

      // Line chart (takes most space)
      LineChartView(
        priceData: entry.priceData,
        closedOrders: entry.closedOrders
      )
      .frame(minHeight: 120)

      // Recent orders table
      VStack(spacing: 4) {
        HStack {
          Text("Recent Orders")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
          Spacer()
          Text("\(entry.closedOrders.count)")
            .font(.caption2)
            .foregroundColor(.gray)
        }

        // Orders list
        ForEach(entry.closedOrders.prefix(2)) { order in
          HStack(spacing: 6) {
            // Status indicator
            Circle()
              .fill(order.status == .confirmed ? Color.green : Color.red)
              .frame(width: 6, height: 6)

            // Order details
            VStack(alignment: .leading, spacing: 1) {
              Text("\(order.fromAmount) \(order.fromToken)/\(order.toToken)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)

              Text("$\(order.limitPrice)")
                .font(.caption2)
                .foregroundColor(.gray)
            }

            Spacer()

            // Time and type
            VStack(alignment: .trailing, spacing: 1) {
              Text(formatOrderTime(order.date))
                .font(.caption2)
                .foregroundColor(.gray)

              Text(order.type)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            }
          }
          .padding(.horizontal, 4)
          .padding(.vertical, 2)
        }
      }
      .padding(.top, 4)
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

  private func getPriceChange() -> (absolute: Double, percentage: Double)? {
    guard let first = entry.priceData.first,
      let last = entry.priceData.last
    else {
      return nil
    }

    let absolute = last.price - first.price
    let percentage = first.price != 0 ? (absolute / first.price) * 100 : 0

    return (absolute: absolute, percentage: percentage)
  }

  private func formatOrderTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
  }
}
