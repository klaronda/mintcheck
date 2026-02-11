//
//  ScanService.swift
//  MintCheck
//
//  Scan history and vehicle CRUD operations
//

import Foundation
import Combine
import Supabase

/// Service for managing scans, vehicles (cars), and subscriptions
@MainActor
class ScanService: ObservableObject {
    @Published var scanHistory: [ScanHistoryItem] = []
    @Published var vehicles: [VehicleInfo] = []
    @Published var subscriptions: [SubscriptionInfo] = []
    @Published var isLoading: Bool = false

    private static let scansTodayCountKey = "mintcheck_scans_completed_today_count"
    private static let scansTodayDateKey = "mintcheck_scans_completed_today_date"
    
    /// Number of scans completed today. Does not decrease when user deletes a scan (persisted count for limit).
    var todayScansCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let stored = UserDefaults.standard
        let storedDate = stored.object(forKey: Self.scansTodayDateKey) as? Date
        let storedCount = stored.integer(forKey: Self.scansTodayCountKey)
        if let d = storedDate, calendar.isDate(d, inSameDayAs: today) {
            return storedCount
        }
        // New day or first run: use actual history count for today and persist
        let count = scanHistory.filter { calendar.isDate($0.date, inSameDayAs: today) }.count
        stored.set(today, forKey: Self.scansTodayDateKey)
        stored.set(count, forKey: Self.scansTodayCountKey)
        return count
    }
    
    /// Call when a scan is successfully saved so "Scans Today" increments and does not decrease on delete.
    func incrementScansCompletedToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let stored = UserDefaults.standard
        let storedDate = stored.object(forKey: Self.scansTodayDateKey) as? Date
        let storedCount = stored.integer(forKey: Self.scansTodayCountKey)
        if let d = storedDate, calendar.isDate(d, inSameDayAs: today) {
            stored.set(storedCount + 1, forKey: Self.scansTodayCountKey)
        } else {
            stored.set(today, forKey: Self.scansTodayDateKey)
            stored.set(1, forKey: Self.scansTodayCountKey)
        }
        objectWillChange.send()
    }
    @Published var error: String?
    
    private var supabase: SupabaseClient {
        SupabaseConfig.shared.client
    }
    
    // MARK: - Vehicles
    
    /// Create a new vehicle
    func createVehicle(_ vehicle: VehicleInfo, userId: UUID) async throws -> VehicleInfo {
        isLoading = true
        defer { isLoading = false }
        
        var newVehicle = vehicle
        newVehicle.userId = userId
        
        struct VehicleInsert: Encodable {
            let user_id: String
            let vin: String?
            let year: String
            let make: String
            let model: String
            let trim: String?
            let fuel_type: String?
            let engine: String?
            let transmission: String?
            let drivetrain: String?
            let name: String?
            let odometer_baseline: Int?
            let vin_hash: String?
        }
        
        let insert = VehicleInsert(
            user_id: userId.uuidString,
            vin: vehicle.vin,
            year: vehicle.year,
            make: vehicle.make,
            model: vehicle.model,
            trim: vehicle.trim,
            fuel_type: vehicle.fuelType,
            engine: vehicle.engine,
            transmission: vehicle.transmission,
            drivetrain: vehicle.drivetrain,
            name: vehicle.name,
            odometer_baseline: vehicle.odometerBaseline,
            vin_hash: vehicle.vinHash
        )
        
        let response: VehicleInfo = try await supabase
            .from("vehicles")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        
        vehicles.append(response)
        return response
    }
    
    /// Set vin_locked = true on a vehicle (for Early Access after first VIN save)
    func setVehicleVinLocked(vehicleId: UUID) async throws {
        try await supabase
            .from("vehicles")
            .update(["vin_locked": true])
            .eq("id", value: vehicleId.uuidString)
            .execute()
        if let idx = vehicles.firstIndex(where: { $0.id == vehicleId }) {
            vehicles[idx].vinLocked = true
        }
    }
    
    /// Returns true if user has any scan with vin_mismatch (Early Access: block new scans until resolved)
    func hasVinMismatch(userId: UUID) async throws -> Bool {
        struct Row: Decodable { let id: UUID }
        let rows: [Row] = try await supabase
            .from("scans")
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .eq("vin_mismatch", value: true)
            .limit(1)
            .execute()
            .value
        return !rows.isEmpty
    }
    
    /// Load user's vehicles
    func loadVehicles(userId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        vehicles = try await supabase
            .from("vehicles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    /// Load user's subscriptions
    func loadSubscriptions(userId: UUID) async throws {
        subscriptions = try await supabase
            .from("subscriptions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }
    
    /// Find vehicle by normalized VIN for this user (scan-to-car match)
    func findVehicleByVinHash(userId: UUID, vinHash: String) async throws -> VehicleInfo? {
        guard !vinHash.isEmpty else { return nil }
        let list: [VehicleInfo] = try await supabase
            .from("vehicles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("vin_hash", value: vinHash)
            .limit(1)
            .execute()
            .value
        return list.first
    }
    
    /// Last scan date for a vehicle
    func lastScanDate(vehicleId: UUID) async -> Date? {
        let dates = await scanDatesForVehicle(vehicleId: vehicleId)
        return dates.first
    }
    
    /// All scan dates for a vehicle
    func scanDatesForVehicle(vehicleId: UUID) async -> [Date] {
        struct Row: Decodable { let created_at: Date }
        let rows: [Row] = (try? await supabase
            .from("scans")
            .select("created_at")
            .eq("vehicle_id", value: vehicleId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value) ?? []
        return rows.map { $0.created_at }
    }
    
    // MARK: - Scans
    
    /// Save a scan result
    func saveScan(
        userId: UUID,
        vehicleId: UUID,
        recommendation: RecommendationType,
        scanData: ScanDataJSON?,
        quickCheck: QuickCheckJSON?,
        obdData: OBDDataJSON?,
        nhtsaData: NHTSADataJSON?,
        odometerReading: Int? = nil,
        askingPrice: Int? = nil,
        estimatedValue: ValuationJSON? = nil,
        summary: String? = nil,
        vinVerified: Bool? = nil,
        vinMismatch: Bool? = nil,
        analysisEnabled: Bool = true
    ) async throws -> ScanResult {
        isLoading = true
        defer { isLoading = false }
        
        struct ScanInsert: Encodable {
            let user_id: String
            let vehicle_id: String
            let recommendation: String
            let scan_data: ScanDataJSON?
            let quick_check: QuickCheckJSON?
            let obd_data: OBDDataJSON?
            let nhtsa_data: NHTSADataJSON?
            let odometer_reading: Int?
            let asking_price: Int?
            let estimated_value: ValuationJSON?
            let summary: String?
            let vin_verified: Bool?
            let vin_mismatch: Bool?
            let analysis_enabled: Bool
        }
        
        let insert = ScanInsert(
            user_id: userId.uuidString,
            vehicle_id: vehicleId.uuidString,
            recommendation: recommendation.rawValue,
            scan_data: scanData,
            quick_check: quickCheck,
            obd_data: obdData,
            nhtsa_data: nhtsaData,
            odometer_reading: odometerReading,
            asking_price: askingPrice,
            estimated_value: estimatedValue,
            summary: summary,
            vin_verified: vinVerified,
            vin_mismatch: vinMismatch,
            analysis_enabled: analysisEnabled
        )
        
        let response: ScanResult = try await supabase
            .from("scans")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        
        // Increment "Scans Today" so the count does not decrease when user later deletes a scan
        incrementScansCompletedToday()
        
        // Refresh scan history
        try await loadScanHistory(userId: userId)
        
        return response
    }
    
    /// Load scan history for dashboard
    func loadScanHistory(userId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        struct ScanWithVehicle: Decodable {
            let id: UUID
            let recommendation: String
            let created_at: Date
            let vehicles: VehicleInfo
        }
        
        let response: [ScanWithVehicle] = try await supabase
            .from("scans")
            .select("id, recommendation, created_at, vehicles(*)")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(20)
            .execute()
            .value
        
        scanHistory = response.map { scan in
            ScanHistoryItem(
                id: scan.id,
                date: scan.created_at,
                vehicle: scan.vehicles.displayName,
                recommendation: RecommendationType(rawValue: scan.recommendation) ?? .safe
            )
        }
    }
    
    /// Load full scan details
    func loadScanDetails(scanId: UUID) async throws -> ScanResult {
        isLoading = true
        defer { isLoading = false }
        
        return try await supabase
            .from("scans")
            .select()
            .eq("id", value: scanId.uuidString)
            .single()
            .execute()
            .value
    }
    
    /// Delete a scan
    func deleteScan(scanId: UUID, userId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await supabase
            .from("scans")
            .delete()
            .eq("id", value: scanId.uuidString)
            .execute()
        
        // Refresh history
        try await loadScanHistory(userId: userId)
    }
}
