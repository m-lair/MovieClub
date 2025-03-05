import Foundation
import SwiftUI

struct UserValidationService {
    // Validation errors for user input
    enum ValidationError: LocalizedError, Identifiable {
        var id: String { errorDescription ?? UUID().uuidString }
        
        case emailEmpty
        case emailInvalid
        case passwordEmpty
        case passwordTooShort
        case passwordTooWeak
        case passwordsDoNotMatch
        case nameEmpty
        case nameTooShort
        case nameTooLong
        case nameContainsProfanity
        
        var errorDescription: String? {
            switch self {
            case .emailEmpty:
                return "Email cannot be empty"
            case .emailInvalid:
                return "Please enter a valid email address"
            case .passwordEmpty:
                return "Password cannot be empty"
            case .passwordTooShort:
                return "Password must be at least 8 characters"
            case .passwordTooWeak:
                return "Password must contain at least one uppercase letter, one number, and one special character"
            case .passwordsDoNotMatch:
                return "Passwords do not match"
            case .nameEmpty:
                return "Name cannot be empty"
            case .nameTooShort:
                return "Name must be at least 2 characters"
            case .nameTooLong:
                return "Name cannot be longer than 50 characters"
            case .nameContainsProfanity:
                return "Name contains inappropriate content"
            }
        }
    }
    
    // Validate email
    static func validateEmail(_ email: String) -> Result<Void, ValidationError> {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedEmail.isEmpty {
            return .failure(.emailEmpty)
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: trimmedEmail) {
            return .failure(.emailInvalid)
        }
        
        return .success(())
    }
    
    // Validate password
    static func validatePassword(_ password: String) -> Result<Void, ValidationError> {
        if password.isEmpty {
            return .failure(.passwordEmpty)
        }
        
        if password.count < 8 {
            return .failure(.passwordTooShort)
        }
        
        // Check for at least one uppercase letter
        let uppercaseRegex = ".*[A-Z]+.*"
        let uppercasePredicate = NSPredicate(format: "SELF MATCHES %@", uppercaseRegex)
        
        // Check for at least one number
        let numberRegex = ".*[0-9]+.*"
        let numberPredicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        
        // Check for at least one special character
        let specialCharRegex = ".*[!@#$%^&*()_\\-+=\\[\\]{}|:;\"'<>,.?/~`]+.*"
        let specialCharPredicate = NSPredicate(format: "SELF MATCHES %@", specialCharRegex)
        
        // For a strong password, require at least two of the three criteria
        let criteriaCount = [
            uppercasePredicate.evaluate(with: password),
            numberPredicate.evaluate(with: password),
            specialCharPredicate.evaluate(with: password)
        ].filter { $0 }.count
        
        if criteriaCount < 2 {
            return .failure(.passwordTooWeak)
        }
        
        return .success(())
    }
    
    // Validate password confirmation
    static func validatePasswordConfirmation(password: String, confirmation: String) -> Result<Void, ValidationError> {
        if password != confirmation {
            return .failure(.passwordsDoNotMatch)
        }
        
        return .success(())
    }
    
    // Validate name
    static func validateName(_ name: String) -> Result<Void, ValidationError> {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return .failure(.nameEmpty)
        }
        
        if trimmedName.count < 2 {
            return .failure(.nameTooShort)
        }
        
        if trimmedName.count > 50 {
            return .failure(.nameTooLong)
        }
        
        // Use existing profanity check from ValidationService
        if ValidationService.containsProfanity(trimmedName) {
            return .failure(.nameContainsProfanity)
        }
        
        return .success(())
    }
}

// MARK: - UI Components for validation

struct ValidatedTextField: View {
    let title: String
    @Binding var text: String
    @Binding var error: String?
    let validate: (String) -> Result<Void, UserValidationService.ValidationError>
    let isSecure: Bool
    let icon: String?
    
    init(
        title: String,
        text: Binding<String>,
        error: Binding<String?>,
        validate: @escaping (String) -> Result<Void, UserValidationService.ValidationError>,
        isSecure: Bool = false,
        icon: String? = nil
    ) {
        self.title = title
        self._text = text
        self._error = error
        self.validate = validate
        self.isSecure = isSecure
        self.icon = icon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(error == nil ? .gray : .red)
                }
                
                if isSecure {
                    SecureField(title, text: $text)
                        .onChange(of: text) { _, newValue in
                            validateText(newValue)
                        }
                } else {
                    TextField(title, text: $text)
                        .onChange(of: text) { _, newValue in
                            validateText(newValue)
                        }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(error == nil ? Color.clear : Color.red, lineWidth: 1)
                    )
            )
            
            if let error = error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private func validateText(_ text: String) {
        let result = validate(text)
        
        withAnimation {
            switch result {
            case .success:
                error = nil
            case .failure(let validationError):
                error = validationError.errorDescription
            }
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    let isLoading: Bool
    
    init(
        title: String,
        action: @escaping () -> Void,
        isDisabled: Bool = false,
        isLoading: Bool = false
    ) {
        self.title = title
        self.action = action
        self.isDisabled = isDisabled
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 5)
                }
                
                Text(title)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
            }
            .frame(minWidth: 200, minHeight: 50)
            .background(isDisabled ? Color.gray : Color.blue)
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .disabled(isDisabled || isLoading)
    }
}

struct FormErrorBanner: View {
    let error: Error?
    let dismiss: () -> Void
    
    var body: some View {
        if let error = error {
            VStack {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.white)
                    
                    Text(error.localizedDescription)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: dismiss) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red)
                )
                .padding(.horizontal)
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
} 