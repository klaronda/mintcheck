//
//  ContentView.swift
//  MintCheck
//
//  Root navigation controller
//

import SwiftUI

/// Navigation state manager for the app
class NavigationManager: ObservableObject {
    @Published var currentScreen: Screen = .home
    @Published var hasSeenOnboarding: Bool = false
    @Published var currentScanData: ScanData = ScanData()
    @Published var selectedSystemDetail: String? = nil
    
    init() {
        // Load persisted state
        hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }
    
    func completeOnboarding() {
        hasSeenOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
    }
    
    func resetScanData() {
        currentScanData = ScanData()
    }
}

/// All possible screens in the app
enum Screen {
    case home
    case signIn
    case onboarding
    case dashboard
    case vehicleBasics
    case deviceConnection
    case scanning
    case disconnectReconnect
    case quickHumanCheck
    case results
    case systemDetail
}

/// Data collected during a scan session
struct ScanData {
    var vehicleInfo: VehicleInfo?
    var deviceType: DeviceType?
    var vin: String?
    var humanCheck: QuickCheckData?
    var recommendation: RecommendationType?
    var scanResults: OBDScanResults?
}

enum DeviceType {
    case wifi
    case bluetooth
}

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var scanService: ScanService
    @EnvironmentObject var nav: NavigationManager
    
    var body: some View {
        ZStack {
            switch nav.currentScreen {
            case .home:
                HomeView(
                    onStartCheck: handleStartCheck,
                    onSignIn: { nav.currentScreen = .signIn }
                )
                .transition(.opacity)
                
            case .signIn:
                SignInView(
                    onBack: { nav.currentScreen = .home },
                    onSignIn: handleSignIn
                )
                .transition(.move(edge: .trailing))
                
            case .onboarding:
                OnboardingView(
                    onComplete: handleOnboardingComplete,
                    onBack: { nav.currentScreen = .home }
                )
                .transition(.move(edge: .trailing))
                
            case .dashboard:
                DashboardView(
                    onStartCheck: { nav.currentScreen = .vehicleBasics },
                    onViewHistory: handleViewHistory
                )
                .transition(.move(edge: .trailing))
                
            case .vehicleBasics:
                VehicleBasicsView(
                    onBack: { nav.currentScreen = .dashboard },
                    onNext: handleVehicleBasicsNext
                )
                .transition(.move(edge: .trailing))
                
            case .deviceConnection:
                DeviceConnectionView(
                    onBack: { nav.currentScreen = .vehicleBasics },
                    onConnect: handleDeviceConnect
                )
                .transition(.move(edge: .trailing))
                
            case .scanning:
                ScanningView(onComplete: handleScanComplete)
                    .transition(.opacity)
                
            case .disconnectReconnect:
                DisconnectReconnectView(onComplete: handleDisconnectComplete)
                    .transition(.move(edge: .trailing))
                
            case .quickHumanCheck:
                QuickHumanCheckView(onComplete: handleQuickCheckComplete)
                    .transition(.move(edge: .trailing))
                
            case .results:
                if let vehicleInfo = nav.currentScanData.vehicleInfo,
                   let recommendation = nav.currentScanData.recommendation {
                    ResultsView(
                        vehicleInfo: vehicleInfo,
                        recommendation: recommendation,
                        scanResults: nav.currentScanData.scanResults,
                        onViewDetails: handleViewSystemDetail,
                        onShare: handleShare,
                        onReturnHome: handleReturnToDashboard
                    )
                    .transition(.move(edge: .trailing))
                }
                
            case .systemDetail:
                if let section = nav.selectedSystemDetail {
                    SystemDetailView(
                        section: section,
                        status: nav.currentScanData.recommendation == .safe ? "Good" : "Needs Attention",
                        onBack: { nav.currentScreen = .results }
                    )
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: nav.currentScreen)
    }
    
    // MARK: - Navigation Handlers
    
    private func handleStartCheck() {
        if authService.currentUser == nil {
            nav.currentScreen = .signIn
        } else if !nav.hasSeenOnboarding {
            nav.currentScreen = .onboarding
        } else {
            nav.currentScreen = .vehicleBasics
        }
    }
    
    private func handleSignIn(user: UserProfile) {
        if !nav.hasSeenOnboarding {
            nav.currentScreen = .onboarding
        } else {
            nav.currentScreen = .dashboard
        }
    }
    
    private func handleOnboardingComplete() {
        nav.completeOnboarding()
        if authService.currentUser != nil {
            nav.currentScreen = .dashboard
        } else {
            nav.currentScreen = .signIn
        }
    }
    
    private func handleVehicleBasicsNext(vehicleInfo: VehicleInfo) {
        nav.currentScanData.vehicleInfo = vehicleInfo
        nav.currentScanData.vin = vehicleInfo.vin
        nav.currentScreen = .deviceConnection
    }
    
    private func handleDeviceConnect(deviceType: DeviceType) {
        nav.currentScanData.deviceType = deviceType
        nav.currentScreen = .scanning
    }
    
    private func handleScanComplete() {
        nav.currentScreen = .disconnectReconnect
    }
    
    private func handleDisconnectComplete() {
        nav.currentScreen = .quickHumanCheck
    }
    
    private func handleQuickCheckComplete(data: QuickCheckData) {
        nav.currentScanData.humanCheck = data
        
        // Determine recommendation based on scan results and human check
        let recommendation = determineRecommendation(
            scanResults: nav.currentScanData.scanResults,
            humanCheck: data
        )
        nav.currentScanData.recommendation = recommendation
        
        nav.currentScreen = .results
    }
    
    private func handleViewSystemDetail(section: String) {
        nav.selectedSystemDetail = section
        nav.currentScreen = .systemDetail
    }
    
    private func handleReturnToDashboard() {
        nav.resetScanData()
        nav.currentScreen = .dashboard
    }
    
    private func handleShare() {
        // TODO: Implement share functionality
    }
    
    private func handleViewHistory(scanId: String) {
        // TODO: Load historical scan data
    }
    
    private func determineRecommendation(scanResults: OBDScanResults?, humanCheck: QuickCheckData) -> RecommendationType {
        // Check for serious issues from OBD scan
        if let results = scanResults {
            if !results.dtcs.isEmpty {
                return .notRecommended
            }
            
            // Check coolant temp (overheating)
            if let coolant = results.coolantTemp, coolant > 105 {
                return .notRecommended
            }
            
            // Check battery voltage (alternator issue)
            if let voltage = results.batteryVoltage, voltage < 12.5 {
                return .caution
            }
        }
        
        // Check human inspection results
        if humanCheck.dashboardLights && humanCheck.engineSounds {
            return .notRecommended
        }
        
        if humanCheck.dashboardLights || humanCheck.engineSounds {
            return .caution
        }
        
        if humanCheck.tireCondition == "Bare" || humanCheck.interiorCondition == "Poor" {
            return .caution
        }
        
        return .safe
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
        .environmentObject(ScanService())
        .environmentObject(NavigationManager())
}
