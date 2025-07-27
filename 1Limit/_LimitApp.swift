//
//  _LimitApp.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

@main
struct _LimitApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject private var widgetSyncService = WidgetSyncServiceFactory.createForProduction()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .preferredColorScheme(.dark)
        .environmentObject(widgetSyncService)
        .onAppear {
          // Lock orientation to portrait
          AppDelegate.orientationLock = UIInterfaceOrientationMask.portrait
          
          // Setup widget sync
          widgetSyncService.setupAppLifecycleObservers()
          widgetSyncService.syncToWidget()
        }
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  static var orientationLock = UIInterfaceOrientationMask.portrait
  
  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    return AppDelegate.orientationLock
  }
}
