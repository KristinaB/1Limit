//
//  WidgetBundle.swift
//  1LimitWidget
//
//  Main widget bundle that includes all widgets 📱✨
//

import WidgetKit
import SwiftUI

@main
struct _LimitWidgetBundle: WidgetBundle {
    var body: some Widget {
        OHLCWidget()
        LineChartWidget()
    }
}