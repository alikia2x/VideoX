//
//  VideoXApp.swift
//  VideoX
//
//  Created by Alikia2x on 2024/6/10.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Do clean when load
        let outputURL = URL.documentsDirectory.appending(path: "compressed.mp4")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
                print("Launch clean successfully operated.")
            } catch {
                print("Error removing existing file: \(error.localizedDescription)")
            }
        }
        return true
    }
}

@main
struct VideoXApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
