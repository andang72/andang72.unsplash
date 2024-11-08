//
//  UnsplashApp.swift
//  Unsplash
//
//  Created by 손동혁 on 11/5/24.
//

import SwiftUI

@main
struct UnsplashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        
        var body: some Scene {
            WindowGroup {
                ContentView()
                    .frame(minWidth: 800, minHeight: 600) // 초기 크기 설정
            }
            Settings {
                SettingsView()
            }
        }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainWindow?.toggleFullScreen(nil) // 전체 화면 모드로 전환
    }
}
