//
//  InputField.swift
//  MintCheck
//
//  Styled text input field component
//

import SwiftUI

struct InputField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var errorMessage: String? = nil
    var helpText: String? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(label)
                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                .foregroundColor(.textPrimary)
            
            // Input field
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .font(.system(size: FontSize.bodyLarge))
            .foregroundColor(.textPrimary)
            .padding(.horizontal, LayoutConstants.padding3)
            .frame(height: 44)
            .background(Color.white)
            .cornerRadius(LayoutConstants.borderRadius)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .focused($isFocused)
            
            // Error or help text
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: FontSize.bodySmall))
                    .foregroundColor(.statusDanger)
            } else if let help = helpText {
                Text(help)
                    .font(.system(size: FontSize.bodySmall))
                    .foregroundColor(.textSecondary)
            }
        }
    }
    
    private var borderColor: Color {
        if errorMessage != nil {
            return .statusDanger
        } else if isFocused {
            return .mintGreen
        } else {
            return .borderColor
        }
    }
}

// MARK: - Date Input Field
struct DateInputField: View {
    let label: String
    @Binding var date: Date?
    var placeholder: String = "Select date"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                .foregroundColor(.textPrimary)
            
            DatePicker(
                "",
                selection: Binding(
                    get: { date ?? Date() },
                    set: { date = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(height: 44)
            .padding(.horizontal, LayoutConstants.padding3)
            .background(Color.white)
            .cornerRadius(LayoutConstants.borderRadius)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        InputField(
            label: "Email",
            text: .constant(""),
            placeholder: "john@example.com",
            keyboardType: .emailAddress
        )
        
        InputField(
            label: "Password",
            text: .constant(""),
            placeholder: "••••••••",
            isSecure: true
        )
        
        InputField(
            label: "VIN",
            text: .constant("1HGBH41JXMN"),
            placeholder: "Enter 17-character VIN",
            helpText: "Found on dashboard or driver's door"
        )
        
        InputField(
            label: "Email",
            text: .constant("invalid"),
            placeholder: "john@example.com",
            errorMessage: "Please enter a valid email address"
        )
    }
    .padding()
    .background(Color.deepBackground)
}
