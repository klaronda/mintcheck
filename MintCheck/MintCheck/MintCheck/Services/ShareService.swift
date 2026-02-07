//
//  ShareService.swift
//  MintCheck
//
//  Service for sharing scan reports via email and creating shareable links
//

import Foundation

class ShareService {
    static let shared = ShareService()
    
    private var supabaseURL: String {
        SupabaseConfig.shared.baseURL.absoluteString
    }
    
    private var supabaseAnonKey: String {
        SupabaseConfig.shared.anonKey
    }
    
    private init() {}
    
    // MARK: - Share Report Request/Response
    
    /// Minimal DTC analysis payload for sharing with the web report
    struct SharedDTCAnalysis: Codable {
        let code: String
        let name: String
        let description: String?
        let repairCostLow: Int?
        let repairCostHigh: Int?
        let urgency: String?
    }
    
    struct ShareRequest: Codable {
        let scanId: String
        let recipients: [String]
        let message: String?
        let createLink: Bool
        let reportData: ReportData
        let userEmail: String
        let userName: String
    }
    
    struct ReportData: Codable {
        let vehicleYear: String
        let vehicleMake: String
        let vehicleModel: String
        let vin: String?
        let recommendation: String
        let scanDate: String
        let summary: String?
        let findings: [String]?
        let valuationLow: Int?
        let valuationHigh: Int?
        let odometerReading: Int?
        let askingPrice: Int?
        let dtcAnalyses: [SharedDTCAnalysis]?
        let nhtsaData: NHTSADataJSON?
    }
    
    struct ShareResponse: Codable {
        let success: Bool
        let emailId: String?
        let shareCode: String?
        let shareUrl: String?
        let recipientCount: Int?
        let error: String?
    }
    
    struct SharedReport: Codable, Identifiable {
        let id: UUID
        let userId: UUID
        let scanId: UUID
        let shareCode: String
        let vin: String?
        let reportData: ReportDataJSON
        let createdAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case scanId = "scan_id"
            case shareCode = "share_code"
            case vin
            case reportData = "report_data"
            case createdAt = "created_at"
        }
        
        var vehicleName: String {
            "\(reportData.vehicleYear) \(reportData.vehicleMake) \(reportData.vehicleModel)"
        }
        
        var shareUrl: String {
            "https://mintcheckapp.com/report/\(shareCode)"
        }
    }
    
    struct ReportDataJSON: Codable {
        let vehicleYear: String
        let vehicleMake: String
        let vehicleModel: String
        let vin: String?
        let recommendation: String
        let scanDate: String
        let summary: String?
        let findings: [String]?
        let valuationLow: Int?
        let valuationHigh: Int?
        let odometerReading: Int?
        let askingPrice: Int?
        let dtcAnalyses: [SharedDTCAnalysis]?
        let nhtsaData: NHTSADataJSON?
    }
    
    // MARK: - Share Report
    
    func shareReport(
        scanId: UUID,
        recipients: [String],
        message: String?,
        createLink: Bool,
        vehicleInfo: VehicleInfo,
        recommendation: RecommendationType,
        scanDate: Date,
        summary: String?,
        findings: [String]?,
        valuationLow: Int?,
        valuationHigh: Int?,
        odometerReading: Int?,
        askingPrice: Int?,
        dtcAnalyses: [DTCAnalysisService.DTCAnalysis]?,
        nhtsaData: NHTSADataJSON?,
        userEmail: String,
        userName: String,
        accessToken: String
    ) async throws -> ShareResponse {
        let url = URL(string: "\(supabaseURL)/functions/v1/share-report")!
        
        // Format scan date as ISO string
        let dateFormatter = ISO8601DateFormatter()
        let scanDateString = dateFormatter.string(from: scanDate)
        
        // Build report data
        let sharedDtcAnalyses: [SharedDTCAnalysis]? = dtcAnalyses?.map { analysis in
            SharedDTCAnalysis(
                code: analysis.code,
                name: analysis.name,
                description: analysis.description,
                repairCostLow: analysis.repairCostLow,
                repairCostHigh: analysis.repairCostHigh,
                urgency: analysis.urgency
            )
        }
        
        let reportData = ReportData(
            vehicleYear: vehicleInfo.year,
            vehicleMake: vehicleInfo.make,
            vehicleModel: vehicleInfo.model,
            vin: vehicleInfo.vin,
            recommendation: recommendation.rawValue,
            scanDate: scanDateString,
            summary: summary,
            findings: findings,
            valuationLow: valuationLow,
            valuationHigh: valuationHigh,
            odometerReading: odometerReading,
            askingPrice: askingPrice,
            dtcAnalyses: sharedDtcAnalyses,
            nhtsaData: nhtsaData
        )
        
        let request = ShareRequest(
            scanId: scanId.uuidString,
            recipients: recipients,
            message: message,
            createLink: createLink,
            reportData: reportData,
            userEmail: userEmail,
            userName: userName
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ShareError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ShareResponse.self, from: data) {
                throw ShareError.serverError(errorResponse.error ?? "Unknown error")
            }
            throw ShareError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(ShareResponse.self, from: data)
    }
    
    // MARK: - Get User's Shared Reports
    
    func getSharedReports(userId: UUID, accessToken: String) async throws -> [SharedReport] {
        let url = URL(string: "\(supabaseURL)/rest/v1/shared_reports?user_id=eq.\(userId.uuidString)&order=created_at.desc")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ShareError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([SharedReport].self, from: data)
    }
    
    // MARK: - Delete Shared Report
    
    func deleteSharedReport(reportId: UUID, accessToken: String) async throws {
        let url = URL(string: "\(supabaseURL)/rest/v1/shared_reports?id=eq.\(reportId.uuidString)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
            throw ShareError.deleteFailed
        }
    }
    
    // MARK: - Errors
    
    enum ShareError: LocalizedError {
        case invalidResponse
        case serverError(String)
        case deleteFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid response from server"
            case .serverError(let message):
                return message
            case .deleteFailed:
                return "Failed to delete shared report"
            }
        }
    }
}
