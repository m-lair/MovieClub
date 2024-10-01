//
//  ErrorManager.swift
//  MovieClub
//
//  Created by Marcus Lair on 10/1/24.
//

import Foundation
import FirebaseFunctions
import SwiftUI

protocol ErrorProtocol {
    func handleError(error: Error) -> String
}

// MARK: - Error Handling (work in progress)

enum AppError: LocalizedError {
    case invalidParameters
    case unauthorized
    case functionError(code: FunctionsErrorCode, message: String)
    case invalidResponse
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidParameters:
            return "Invalid parameters."
        case .unauthorized:
            return "Unauthorized access."
        case .functionError(let code, let message):
            return "Function error (\(code.rawValue)): \(message)"
        case .invalidResponse:
            return "Invalid response from the server."
        case .unknownError(let error):
            return error.localizedDescription
        }
    }
}

class ErrorManager: ErrorProtocol {
    
    func handleError(error: Error) -> String {
        return error.localizedDescription.isEmpty ? handleUnknownError(error) : error.localizedDescription
    }
        
    private func handleUnknownError(_ error: Error) -> String {
        return error.localizedDescription
    }
}
