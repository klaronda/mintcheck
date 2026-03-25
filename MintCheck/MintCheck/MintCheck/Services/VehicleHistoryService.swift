//
//  VehicleHistoryService.swift
//  MintCheck
//
//  Free vehicle history APIs (NHTSA Recalls, Complaints, Safety Ratings)
//

import Foundation

/// Service for fetching free vehicle history data
class VehicleHistoryService {
    
    // MARK: - NHTSA Recalls API (Free)
    
    /// Check for open recalls on a vehicle by VIN
    func getRecalls(vin: String) async throws -> [RecallInfo] {
        let urlString = "https://api.nhtsa.gov/recalls/recallsByVehicle?vin=\(vin)"
        guard let url = URL(string: urlString) else {
            throw HistoryError.invalidVIN
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HistoryError.networkError
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(RecallsResponse.self, from: data)
        
        return apiResponse.results.map { recall in
            RecallInfo(
                campaignNumber: recall.NHTSACampaignNumber,
                component: recall.Component,
                summary: recall.Summary,
                consequence: recall.Consequence,
                remedy: recall.Remedy,
                manufacturer: recall.Manufacturer,
                reportDate: recall.ReportReceivedDate
            )
        }
    }
    
    /// Check for recalls by make/model/year (alternative if no VIN)
    func getRecalls(make: String, model: String, year: String) async throws -> [RecallInfo] {
        let encodedMake = make.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? make
        let encodedModel = model.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? model
        
        let urlString = "https://api.nhtsa.gov/recalls/recallsByVehicle?make=\(encodedMake)&model=\(encodedModel)&modelYear=\(year)"
        guard let url = URL(string: urlString) else {
            throw HistoryError.invalidRequest
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HistoryError.networkError
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(RecallsResponse.self, from: data)
        
        return apiResponse.results.map { recall in
            RecallInfo(
                campaignNumber: recall.NHTSACampaignNumber,
                component: recall.Component,
                summary: recall.Summary,
                consequence: recall.Consequence,
                remedy: recall.Remedy,
                manufacturer: recall.Manufacturer,
                reportDate: recall.ReportReceivedDate
            )
        }
    }
    
    // MARK: - NHTSA Complaints API (Free)
    
    /// Get consumer complaints for a vehicle
    func getComplaints(make: String, model: String, year: String) async throws -> [ComplaintInfo] {
        let encodedMake = make.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? make
        let encodedModel = model.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? model
        
        let urlString = "https://api.nhtsa.gov/complaints/complaintsByVehicle?make=\(encodedMake)&model=\(encodedModel)&modelYear=\(year)"
        guard let url = URL(string: urlString) else {
            throw HistoryError.invalidRequest
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HistoryError.networkError
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ComplaintsResponse.self, from: data)
        
        return apiResponse.results.prefix(20).map { complaint in
            ComplaintInfo(
                odiNumber: complaint.odiNumber,
                component: complaint.components,
                summary: complaint.summary,
                crash: complaint.crash,
                fire: complaint.fire,
                injuries: complaint.numberOfInjuries,
                deaths: complaint.numberOfDeaths,
                dateComplaint: complaint.dateComplaintFiled,
                mileage: complaint.odoMiles
            )
        }
    }
    
    // MARK: - NHTSA Safety Ratings API (Free)
    
    /// Get crash test safety ratings for a vehicle
    func getSafetyRatings(make: String, model: String, year: String) async throws -> SafetyRatings? {
        let encodedMake = make.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? make
        let encodedModel = model.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? model
        
        let urlString = "https://api.nhtsa.gov/SafetyRatings/modelyear/\(year)/make/\(encodedMake)/model/\(encodedModel)"
        guard let url = URL(string: urlString) else {
            throw HistoryError.invalidRequest
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HistoryError.networkError
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(SafetyRatingsResponse.self, from: data)
        
        // Get detailed ratings for first vehicle ID
        guard let firstResult = apiResponse.Results.first,
              let vehicleId = firstResult.VehicleId else {
            return nil
        }
        
        return try await getSafetyRatingDetails(vehicleId: vehicleId)
    }
    
    private func getSafetyRatingDetails(vehicleId: Int) async throws -> SafetyRatings {
        let urlString = "https://api.nhtsa.gov/SafetyRatings/VehicleId/\(vehicleId)"
        guard let url = URL(string: urlString) else {
            throw HistoryError.invalidRequest
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HistoryError.networkError
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(SafetyRatingDetailsResponse.self, from: data)
        
        guard let result = apiResponse.Results.first else {
            throw HistoryError.noData
        }
        
        return SafetyRatings(
            overallRating: result.OverallRating,
            frontalCrashRating: result.OverallFrontCrashRating,
            sideCrashRating: result.OverallSideCrashRating,
            rolloverRating: result.RolloverRating,
            sidePoleCrashRating: result.SidePoleCrashRating,
            vehicleDescription: result.VehicleDescription
        )
    }
    
    // MARK: - Comprehensive Check
    
    /// Run all free checks and return combined results
    func runFreeHistoryCheck(vin: String?, make: String, model: String, year: String) async -> VehicleHistoryReport {
        var report = VehicleHistoryReport()
        
        // Recalls (try VIN first, fall back to make/model/year)
        do {
            if let vin = vin, !vin.isEmpty {
                report.recalls = try await getRecalls(vin: vin)
            } else {
                report.recalls = try await getRecalls(make: make, model: model, year: year)
            }
        } catch {
            print("Recalls check failed: \(error)")
            report.recalls = []
        }
        
        // Complaints
        do {
            report.complaints = try await getComplaints(make: make, model: model, year: year)
        } catch {
            print("Complaints check failed: \(error)")
            report.complaints = []
        }
        
        // Safety Ratings
        do {
            report.safetyRatings = try await getSafetyRatings(make: make, model: model, year: year)
        } catch {
            print("Safety ratings check failed: \(error)")
            report.safetyRatings = nil
        }
        
        return report
    }
}

// MARK: - Shared fetch (ScanFlow, ContentView, history)

extension VehicleHistoryService {
    /// True when NHTSA APIs can be queried meaningfully (Y/M/M or 17-character VIN).
    static func canFetchNHTSA(for vehicle: VehicleInfo) -> Bool {
        let vin = (vehicle.vin ?? "").trimmingCharacters(in: .whitespaces).uppercased()
        if vin.count == 17 { return true }
        let y = vehicle.year.trimmingCharacters(in: .whitespaces)
        let m = vehicle.make.trimmingCharacters(in: .whitespaces)
        let md = vehicle.model.trimmingCharacters(in: .whitespaces)
        if m.isEmpty || md.isEmpty { return false }
        if y.isEmpty || y == "(Year N/A)" { return false }
        return true
    }
    
    /// Fetches recalls, complaints, and safety ratings for display and Supabase storage.
    static func fetchReport(for vehicle: VehicleInfo) async -> VehicleHistoryReport {
        await VehicleHistoryService().runFreeHistoryCheck(
            vin: vehicle.vin,
            make: vehicle.make,
            model: vehicle.model,
            year: vehicle.year
        )
    }
}

// MARK: - Response Models

private struct RecallsResponse: Decodable {
    let Count: Int
    let Message: String
    let results: [RecallResult]
}

private struct RecallResult: Decodable {
    let NHTSACampaignNumber: String?
    let Component: String?
    let Summary: String?
    let Consequence: String?
    let Remedy: String?
    let Manufacturer: String?
    let ReportReceivedDate: String?
}

private struct ComplaintsResponse: Decodable {
    let count: Int
    let results: [ComplaintResult]
}

private struct ComplaintResult: Decodable {
    let odiNumber: Int?
    let components: String?
    let summary: String?
    let crash: Bool?
    let fire: Bool?
    let numberOfInjuries: Int?
    let numberOfDeaths: Int?
    let dateComplaintFiled: String?
    let odoMiles: Int?
}

private struct SafetyRatingsResponse: Decodable {
    let Count: Int
    let Results: [SafetyRatingResult]
}

private struct SafetyRatingResult: Decodable {
    let VehicleId: Int?
}

private struct SafetyRatingDetailsResponse: Decodable {
    let Count: Int
    let Results: [SafetyRatingDetails]
}

private struct SafetyRatingDetails: Decodable {
    let OverallRating: String?
    let OverallFrontCrashRating: String?
    let OverallSideCrashRating: String?
    let RolloverRating: String?
    let SidePoleCrashRating: String?
    let VehicleDescription: String?
}

// MARK: - Public Models

/// Information about a vehicle recall
struct RecallInfo: Identifiable {
    let id = UUID()
    let campaignNumber: String?
    let component: String?
    let summary: String?
    let consequence: String?
    let remedy: String?
    let manufacturer: String?
    let reportDate: String?
    
    var isOpen: Bool {
        // All recalls from this API are open/unrepaired for the specific VIN
        return true
    }
}

/// Information about a consumer complaint
struct ComplaintInfo: Identifiable {
    let id = UUID()
    let odiNumber: Int?
    let component: String?
    let summary: String?
    let crash: Bool?
    let fire: Bool?
    let injuries: Int?
    let deaths: Int?
    let dateComplaint: String?
    let mileage: Int?
    
    var isSevere: Bool {
        return (crash ?? false) || (fire ?? false) || (injuries ?? 0) > 0 || (deaths ?? 0) > 0
    }
}

/// NHTSA crash test safety ratings (1-5 stars)
struct SafetyRatings {
    let overallRating: String?       // "5" = 5 stars, "Not Rated"
    let frontalCrashRating: String?
    let sideCrashRating: String?
    let rolloverRating: String?
    let sidePoleCrashRating: String?
    let vehicleDescription: String?
    
    var overallStars: Int? {
        guard let rating = overallRating, let stars = Int(rating) else { return nil }
        return stars
    }
}

/// Combined vehicle history report from free sources
struct VehicleHistoryReport {
    var recalls: [RecallInfo] = []
    var complaints: [ComplaintInfo] = []
    var safetyRatings: SafetyRatings?
    
    var hasOpenRecalls: Bool {
        !recalls.isEmpty
    }
    
    var recallCount: Int {
        recalls.count
    }
    
    var complaintCount: Int {
        complaints.count
    }
    
    var severeComplaintCount: Int {
        complaints.filter { $0.isSevere }.count
    }
    
    /// Summary for display
    var summary: String {
        var parts: [String] = []
        
        if hasOpenRecalls {
            parts.append("⚠️ \(recallCount) open recall(s)")
        } else {
            parts.append("✅ No open recalls")
        }
        
        if complaintCount > 0 {
            if severeComplaintCount > 0 {
                parts.append("⚠️ \(severeComplaintCount) severe complaint(s)")
            } else {
                parts.append("ℹ️ \(complaintCount) complaint(s) on file")
            }
        }
        
        if let stars = safetyRatings?.overallStars {
            parts.append("⭐ \(stars)/5 safety rating")
        }
        
        return parts.joined(separator: "\n")
    }
    
    /// Convert to JSON for storage
    func toJSON() -> NHTSADataJSON {
        NHTSADataJSON(
            recalls: recalls.map { RecallJSON(
                campaignNumber: $0.campaignNumber,
                component: $0.component,
                summary: $0.summary,
                consequence: $0.consequence,
                remedy: $0.remedy,
                manufacturer: $0.manufacturer,
                reportDate: $0.reportDate
            )},
            safetyRatings: safetyRatings.map { SafetyRatingsJSON(
                overallRating: $0.overallRating,
                frontalCrashRating: $0.frontalCrashRating,
                sideCrashRating: $0.sideCrashRating,
                rolloverRating: $0.rolloverRating,
                sidePoleCrashRating: $0.sidePoleCrashRating,
                vehicleDescription: $0.vehicleDescription
            )}
        )
    }
    
    /// Create from JSON
    static func fromJSON(_ json: NHTSADataJSON) -> VehicleHistoryReport {
        var report = VehicleHistoryReport()
        report.recalls = json.recalls?.map { RecallInfo(
            campaignNumber: $0.campaignNumber,
            component: $0.component,
            summary: $0.summary,
            consequence: $0.consequence,
            remedy: $0.remedy,
            manufacturer: $0.manufacturer,
            reportDate: $0.reportDate
        )} ?? []
        report.safetyRatings = json.safetyRatings.map { SafetyRatings(
            overallRating: $0.overallRating,
            frontalCrashRating: $0.frontalCrashRating,
            sideCrashRating: $0.sideCrashRating,
            rolloverRating: $0.rolloverRating,
            sidePoleCrashRating: $0.sidePoleCrashRating,
            vehicleDescription: $0.vehicleDescription
        )}
        return report
    }
}

// MARK: - JSON Models for Storage

/// JSON-serializable NHTSA data for Supabase storage
struct NHTSADataJSON: Codable {
    let recalls: [RecallJSON]?
    let safetyRatings: SafetyRatingsJSON?
}

struct RecallJSON: Codable {
    let campaignNumber: String?
    let component: String?
    let summary: String?
    let consequence: String?
    let remedy: String?
    let manufacturer: String?
    let reportDate: String?
}

struct SafetyRatingsJSON: Codable {
    let overallRating: String?
    let frontalCrashRating: String?
    let sideCrashRating: String?
    let rolloverRating: String?
    let sidePoleCrashRating: String?
    let vehicleDescription: String?
}

// MARK: - Errors

enum HistoryError: LocalizedError {
    case invalidVIN
    case invalidRequest
    case networkError
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidVIN:
            return "Invalid VIN format."
        case .invalidRequest:
            return "Invalid request parameters."
        case .networkError:
            return "Network error. Please check your connection."
        case .noData:
            return "No data available for this vehicle."
        }
    }
}
