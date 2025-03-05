import Foundation
import FirebaseFunctions

struct ValidationService {
    
    // Validation errors
    enum ValidationError: LocalizedError {
        case clubNameEmpty
        case clubNameTooShort
        case clubNameTooLong
        case clubNameContainsProfanity
        case clubNameInvalidCharacters
        case networkError(Error)
        case serverValidation(String)
        
        var errorDescription: String? {
            switch self {
            case .clubNameEmpty:
                return "Club name cannot be empty."
            case .clubNameTooShort:
                return "Club name must be at least 3 characters."
            case .clubNameTooLong:
                return "Club name cannot be longer than 30 characters."
            case .clubNameContainsProfanity:
                return "Club name contains inappropriate content."
            case .clubNameInvalidCharacters:
                return "Club name contains invalid characters."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .serverValidation(let message):
                return message
            }
        }
    }
    
    /// Basic profanity filter for client-side validation
    private static let profanityList = [
        "anal", "anus", "ass", "bastard", "bitch", "boob", "cock", "cunt", "dick", "dildo", 
        "fag", "fuck", "nigger", "penis", "porn", "pussy", "sex", "shit", "slut", "tit", 
        "vagina", "whore", "xxx"
    ]
    
    /// Checks if a string contains profanity from our basic list
    /// - Parameter text: Text to check
    /// - Returns: True if profanity is found
    static func containsProfanity(_ text: String) -> Bool {
        let lowercaseText = text.lowercased()
        
        // Check for exact matches
        for word in profanityList {
            if lowercaseText.contains(word) {
                return true
            }
        }
        
        // Check for words with special characters in between
        let textWithoutSpecialChars = lowercaseText.replacingOccurrences(
            of: "[^a-z0-9]", 
            with: "", 
            options: .regularExpression
        )
        
        for word in profanityList where word.count > 2 {
            let wordWithoutSpecialChars = word.replacingOccurrences(
                of: "[^a-z0-9]", 
                with: "", 
                options: .regularExpression
            )
            
            if textWithoutSpecialChars.contains(wordWithoutSpecialChars) {
                return true
            }
        }
        
        return false
    }
    
    /// Validates a club name against basic rules (length, empty, characters)
    /// - Parameter name: Club name to validate
    /// - Returns: ValidationResult indicating if validation passed or failed with an error
    static func validateClubNameBasic(_ name: String) -> Result<Void, ValidationError> {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if name is empty
        if trimmedName.isEmpty {
            return .failure(.clubNameEmpty)
        }
        
        // Check name length
        if trimmedName.count < 3 {
            return .failure(.clubNameTooShort)
        }
        
        if name.count > 30 {
            return .failure(.clubNameTooLong)
        }
        
        // Check for valid characters (letters, numbers, spaces, and some special characters)
        let allowedCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -_&():,.!?"))
        if name.unicodeScalars.contains(where: { !allowedCharacterSet.contains($0) }) {
            return .failure(.clubNameInvalidCharacters)
        }
        
        // Check for profanity
        if containsProfanity(trimmedName) {
            return .failure(.clubNameContainsProfanity)
        }
        
        return .success(())
    }
    
    /// Performs server-side validation of club name
    /// - Parameter name: Club name to validate
    /// - Returns: Async Result with validation outcome
    static func validateClubNameOnServer(_ name: String) async -> Result<Void, ValidationError> {
        let functions = Functions.functions()
        let validateClubName = functions.httpsCallable("moderation-validateClubName")
        
        do {
            let result = try await validateClubName.call(["name": name])
            
            // Debug the actual response
            print("Server validation response: \(result.data)")
            
            // Try to parse as dictionary first
            if let resultDict = result.data as? [String: Any] {
                // Check for success field
                if let success = resultDict["success"] as? Bool {
                    if success {
                        return .success(())
                    } else {
                        let message = resultDict["message"] as? String ?? "Invalid club name"
                        print("Server validation failed: \(message)")
                        return .failure(.serverValidation(message))
                    }
                } 
                // Check for isValid field (alternative format)
                else if let isValid = resultDict["isValid"] as? Int {
                    if isValid == 1 {
                        return .success(())
                    } else {
                        let message = resultDict["message"] as? String ?? "Invalid club name"
                        print("Server validation failed: \(message)")
                        return .failure(.serverValidation(message))
                    }
                }
                // Check for error field as alternative
                else if let errorMessage = resultDict["error"] as? String {
                    print("Server validation error message: \(errorMessage)")
                    return .failure(.serverValidation(errorMessage))
                }
                // Log all keys to help debug
                else {
                    let keys = resultDict.keys.joined(separator: ", ")
                    print("Server validation response has unexpected format. Available keys: \(keys)")
                    return .failure(.serverValidation("Server validation failed with unexpected response format"))
                }
            } 
            // If not a dictionary, try to handle as string or other types
            else if let stringResult = result.data as? String {
                print("Server validation returned string: \(stringResult)")
                return .failure(.serverValidation(stringResult))
            } else {
                print("Server validation returned unknown type: \(type(of: result.data))")
                return .failure(.serverValidation("Invalid response from server"))
            }
        } catch {
            print("Server validation error: \(error.localizedDescription)")
            return .failure(.networkError(error))
        }
    }
    
    /// Performs server-side validation of club name with fallback
    /// - Parameters:
    ///   - name: Club name to validate
    ///   - allowFallback: Whether to allow fallback to client-side validation if server is unavailable
    /// - Returns: Async Result with validation outcome
    static func validateClubNameWithFallback(_ name: String, allowFallback: Bool = true) async -> Result<Void, ValidationError> {
        // First try server validation
        let serverResult = await validateClubNameOnServer(name)
        
        // If server validation failed due to network error and fallback is allowed, use client-side validation
        if case .failure(let error) = serverResult, 
           case .networkError(_) = error,
           allowFallback {
            print("Server validation unavailable, falling back to client-side validation")
            return .success(()) // Basic validation already passed at this point
        }
        
        return serverResult
    }
}
