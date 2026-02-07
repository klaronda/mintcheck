//
//  VINDecoderService.swift
//  MintCheck
//
//  NHTSA VIN decoding API service
//

import Foundation

/// Service for decoding VIN numbers using NHTSA API
class VINDecoderService {
    private let baseURL = "https://vpic.nhtsa.dot.gov/api/vehicles"
    
    /// Decode a VIN and return vehicle details
    func decodeVIN(_ vin: String) async throws -> VINDecodeResult {
        let urlString = "\(baseURL)/decodevin/\(vin)?format=json"
        guard let url = URL(string: urlString) else {
            throw VINError.invalidVIN
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VINError.networkError
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(NHTSAResponse.self, from: data)
        
        return parseNHTSAResponse(apiResponse, vin: vin)
    }
    
    /// Parse NHTSA API response into our model
    private func parseNHTSAResponse(_ response: NHTSAResponse, vin: String) -> VINDecodeResult {
        var result = VINDecodeResult(
            vin: vin,
            year: nil,
            make: nil,
            model: nil,
            trim: nil,
            fuelType: nil,
            engineSize: nil,
            engineCylinders: nil,
            transmission: nil,
            driveType: nil,
            bodyClass: nil
        )
        
        for item in response.Results {
            guard let value = item.Value, !value.isEmpty else { continue }
            
            switch item.Variable {
            case "Model Year":
                result = VINDecodeResult(vin: vin, year: value, make: result.make, model: result.model, trim: result.trim, fuelType: result.fuelType, engineSize: result.engineSize, engineCylinders: result.engineCylinders, transmission: result.transmission, driveType: result.driveType, bodyClass: result.bodyClass)
            case "Make":
                result = VINDecodeResult(vin: vin, year: result.year, make: value, model: result.model, trim: result.trim, fuelType: result.fuelType, engineSize: result.engineSize, engineCylinders: result.engineCylinders, transmission: result.transmission, driveType: result.driveType, bodyClass: result.bodyClass)
            case "Model":
                result = VINDecodeResult(vin: vin, year: result.year, make: result.make, model: value, trim: result.trim, fuelType: result.fuelType, engineSize: result.engineSize, engineCylinders: result.engineCylinders, transmission: result.transmission, driveType: result.driveType, bodyClass: result.bodyClass)
            case "Trim":
                result = VINDecodeResult(vin: vin, year: result.year, make: result.make, model: result.model, trim: value, fuelType: result.fuelType, engineSize: result.engineSize, engineCylinders: result.engineCylinders, transmission: result.transmission, driveType: result.driveType, bodyClass: result.bodyClass)
            case "Fuel Type - Primary":
                result = VINDecodeResult(vin: vin, year: result.year, make: result.make, model: result.model, trim: result.trim, fuelType: value, engineSize: result.engineSize, engineCylinders: result.engineCylinders, transmission: result.transmission, driveType: result.driveType, bodyClass: result.bodyClass)
            case "Displacement (L)":
                result = VINDecodeResult(vin: vin, year: result.year, make: result.make, model: result.model, trim: result.trim, fuelType: result.fuelType, engineSize: "\(value)L", engineCylinders: result.engineCylinders, transmission: result.transmission, driveType: result.driveType, bodyClass: result.bodyClass)
            case "Engine Number of Cylinders":
                result = VINDecodeResult(vin: vin, year: result.year, make: result.make, model: result.model, trim: result.trim, fuelType: result.fuelType, engineSize: result.engineSize, engineCylinders: value, transmission: result.transmission, driveType: result.driveType, bodyClass: result.bodyClass)
            case "Transmission Style":
                result = VINDecodeResult(vin: vin, year: result.year, make: result.make, model: result.model, trim: result.trim, fuelType: result.fuelType, engineSize: result.engineSize, engineCylinders: result.engineCylinders, transmission: value, driveType: result.driveType, bodyClass: result.bodyClass)
            case "Drive Type":
                result = VINDecodeResult(vin: vin, year: result.year, make: result.make, model: result.model, trim: result.trim, fuelType: result.fuelType, engineSize: result.engineSize, engineCylinders: result.engineCylinders, transmission: result.transmission, driveType: value, bodyClass: result.bodyClass)
            case "Body Class":
                result = VINDecodeResult(vin: vin, year: result.year, make: result.make, model: result.model, trim: result.trim, fuelType: result.fuelType, engineSize: result.engineSize, engineCylinders: result.engineCylinders, transmission: result.transmission, driveType: result.driveType, bodyClass: value)
            default:
                break
            }
        }
        
        return result
    }
}

// MARK: - NHTSA API Response Models
private struct NHTSAResponse: Decodable {
    let Count: Int
    let Message: String
    let Results: [NHTSAResult]
}

private struct NHTSAResult: Decodable {
    let Value: String?
    let Variable: String
    let VariableId: Int
}

// MARK: - VIN Errors
enum VINError: LocalizedError {
    case invalidVIN
    case networkError
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidVIN:
            return "Invalid VIN format. VIN must be 17 characters."
        case .networkError:
            return "Unable to decode VIN. Please check your internet connection."
        case .decodingFailed:
            return "Unable to decode VIN. Please enter vehicle details manually."
        }
    }
}

// MARK: - VIN Validation
extension String {
    /// Validate VIN format (17 characters, alphanumeric, no I/O/Q)
    var isValidVIN: Bool {
        guard count == 17 else { return false }
        let invalidChars = CharacterSet(charactersIn: "IOQ")
        let vinChars = CharacterSet(charactersIn: uppercased())
        guard vinChars.isDisjoint(with: invalidChars) else { return false }
        return uppercased().range(of: "^[A-HJ-NPR-Z0-9]{17}$", options: .regularExpression) != nil
    }
}
