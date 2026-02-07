//
//  ScanService.swift
//  MintCheck
//
//  Scan history and vehicle CRUD operations
//

import Foundation
import Combine
import Supabase

/// Service for managing scans and vehicles
@MainActor
class ScanService: ObservableObject {
    @Published var scanHistory: [ScanHistoryItem] = []
    @Published var vehicles: [VehicleInfo] = []
    @Published var isLoading: Bool = false
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
            drivetrain: vehicle.drivetrain
        )
        
        let response: VehicleInfo = try await supabase.database
            .from("vehicles")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        
        vehicles.append(response)
        return response
    }
    
    /// Load user's vehicles
    func loadVehicles(userId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        vehicles = try await supabase.database
            .from("vehicles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    // MARK: - Scans
    
    /// Save a scan result
    func saveScan(
        userId: UUID,
        vehicleId: UUID,
        recommendation: RecommendationType,
        scanData: ScanDataJSON?,
        quickCheck: QuickCheckJSON?,
        obdData: OBDDataJSON?
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
        }
        
        let insert = ScanInsert(
            user_id: userId.uuidString,
            vehicle_id: vehicleId.uuidString,
            recommendation: recommendation.rawValue,
            scan_data: scanData,
            quick_check: quickCheck,
            obd_data: obdData
        )
        
        let response: ScanResult = try await supabase.database
            .from("scans")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        
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
        
        let response: [ScanWithVehicle] = try await supabase.database
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
        
        return try await supabase.database
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
        
        try await supabase.database
            .from("scans")
            .delete()
            .eq("id", value: scanId.uuidString)
            .execute()
        
        // Refresh history
        try await loadScanHistory(userId: userId)
    }
}
