//
//  MintCheckApp.swift
//  MintCheck
//
//  Main app entry point
//

import SwiftUI

@main
struct MintCheckApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var scanService = ScanService()
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var connectionManager = ConnectionManagerService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(scanService)
                .environmentObject(navigationManager)
                .environmentObject(connectionManager)
                // Force light mode: UI is designed for light surfaces; avoids mixed dark/light when system is dark.
                .preferredColorScheme(.light)
        }
    }
}
