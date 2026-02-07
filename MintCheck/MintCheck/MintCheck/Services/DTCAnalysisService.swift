//
//  DTCAnalysisService.swift
//  MintCheck
//
//  Service for analyzing DTCs using AI via Supabase Edge Function
//

import Foundation

/// Service for getting AI-powered DTC analysis
class DTCAnalysisService {
    
    // MARK: - Models
    
    /// Analysis result for a single DTC
    struct DTCAnalysis: Codable, Identifiable {
        let code: String
        let name: String
        let description: String
        let repairCostLow: Int
        let repairCostHigh: Int
        let urgency: String  // "low", "medium", "high", "critical"
        let commonForVehicle: Bool
        
        var id: String { code }
        
        /// Average repair cost
        var averageRepairCost: Int {
            (repairCostLow + repairCostHigh) / 2
        }
        
        /// Formatted cost range
        var formattedCostRange: String {
            "$\(repairCostLow.formatted()) - $\(repairCostHigh.formatted())"
        }
        
        /// Urgency display text
        var urgencyText: String {
            switch urgency {
            case "critical": return "Critical - Don't Drive"
            case "high": return "Fix Soon"
            case "medium": return "Fix Within Weeks"
            case "low": return "Can Wait"
            default: return urgency.capitalized
            }
        }
    }
    
    /// Vehicle valuation from AI analysis
    struct VehicleValuation: Codable {
        let lowEstimate: Int
        let highEstimate: Int
        let reasoning: String?
        
        /// Formatted value range
        var formattedRange: String {
            "$\(lowEstimate.formatted()) - $\(highEstimate.formatted())"
        }
    }
    
    /// Full analysis response from the Edge Function
    struct AnalysisResponse: Codable {
        let analyses: [DTCAnalysis]
        let totalRepairCostLow: Int
        let totalRepairCostHigh: Int
        let overallUrgency: String
        let summary: String
        let vehicleValuation: VehicleValuation?
        
        /// Formatted total cost range
        var formattedTotalCostRange: String {
            "$\(totalRepairCostLow.formatted()) - $\(totalRepairCostHigh.formatted())"
        }
    }
    
    /// Request body for the Edge Function
    private struct AnalysisRequest: Encodable {
        let dtcs: [String]
        let make: String
        let model: String
        let year: Int
        let odometerReading: Int?
        let askingPrice: Int?
        let interiorCondition: String?
        let tireCondition: String?
    }
    
    // MARK: - Error Types
    
    enum AnalysisError: Error, LocalizedError {
        case noDTCs
        case networkError(Error)
        case serverError(String)
        case decodingError(Error)
        
        var errorDescription: String? {
            switch self {
            case .noDTCs:
                return "No diagnostic trouble codes to analyze"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .serverError(let message):
                return "Server error: \(message)"
            case .decodingError(let error):
                return "Failed to parse response: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - API
    
    /// Analyze DTCs for a specific vehicle using AI
    /// - Parameters:
    ///   - dtcs: Array of DTC codes (e.g., ["P0420", "P0171"])
    ///   - make: Vehicle make (e.g., "Subaru")
    ///   - model: Vehicle model (e.g., "Outback")
    ///   - year: Vehicle year (e.g., 2020)
    ///   - odometerReading: Vehicle mileage (optional)
    ///   - askingPrice: Asking price (optional)
    ///   - interiorCondition: Interior condition (optional)
    ///   - tireCondition: Tire condition (optional)
    /// - Returns: Analysis response with repair estimates and vehicle valuation
    func analyzeDTCs(
        dtcs: [String],
        make: String,
        model: String,
        year: Int,
        odometerReading: Int? = nil,
        askingPrice: Int? = nil,
        interiorCondition: String? = nil,
        tireCondition: String? = nil
    ) async throws -> AnalysisResponse {
        
        // Build request
        let request = AnalysisRequest(
            dtcs: dtcs,
            make: make,
            model: model,
            year: year,
            odometerReading: odometerReading,
            askingPrice: askingPrice,
            interiorCondition: interiorCondition,
            tireCondition: tireCondition
        )
        
        // Get Edge Function URL
        let baseURL = SupabaseConfig.shared.baseURL
        guard let url = URL(string: "\(baseURL.absoluteString)/functions/v1/analyze-dtcs") else {
            throw AnalysisError.serverError("Invalid URL")
        }
        
        // Create request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth header (anon key for JWT verification)
        let anonKey = SupabaseConfig.shared.anonKey
        urlRequest.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        
        // Encode body
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        // Make request with network error handling
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            // Check if it's a network connectivity error
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost:
                    throw AnalysisError.networkError(error)
                default:
                    throw AnalysisError.networkError(error)
                }
            }
            throw AnalysisError.networkError(error)
        }
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AnalysisError.serverError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let errorJson = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorJson["error"] {
                throw AnalysisError.serverError(errorMessage)
            }
            throw AnalysisError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        // Decode response
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(AnalysisResponse.self, from: data)
        } catch {
            throw AnalysisError.decodingError(error)
        }
    }
    
    /// Analyze DTCs from scan results with vehicle valuation
    func analyzeScanResults(
        scanResults: OBDScanResults,
        vehicleInfo: VehicleInfo,
        humanCheck: QuickCheckData?
    ) async throws -> AnalysisResponse {
        // Parse year - handle "(Year N/A)" or extract numeric part
        var yearString = vehicleInfo.year.replacingOccurrences(of: "(Year N/A)", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        var year = Int(yearString)
        if year == nil {
            // Try to extract year from string (e.g., "2020" from "2020 (Year N/A)")
            let numbers = yearString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            year = Int(numbers) ?? 2020
        }
        let finalYear = year ?? 2020
        
        return try await analyzeDTCs(
            dtcs: scanResults.dtcs,
            make: vehicleInfo.make,
            model: vehicleInfo.model,
            year: finalYear,
            odometerReading: humanCheck?.odometerReading,
            askingPrice: humanCheck?.askingPrice,
            interiorCondition: humanCheck?.interiorCondition,
            tireCondition: humanCheck?.tireCondition
        )
    }
}

// MARK: - Singleton for convenience

extension DTCAnalysisService {
    static let shared = DTCAnalysisService()
}
