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
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .preferredColorScheme(.dark)
        .onAppear {
          // Lock orientation to portrait
          AppDelegate.orientationLock = UIInterfaceOrientationMask.portrait
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
