//
//  PasswordResetScreen.swift
//  BiteWise
//
//  Screen displayed when user clicks a password reset link from email.
//  Allows user to set a new password with their valid recovery session.
//

import SwiftUI

struct PasswordResetScreen: View {
    let email: String
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var successMessage: String?
    @State private var showSuccess = false
    
    // Animation states
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 30
    @State private var pulseScale: CGFloat = 1.0
    
    @FocusState private var focusedField: PasswordField?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase
    
    private enum PasswordField {
        case newPassword, confirmPassword
    }
    
    var body: some View {
        ZStack {
            // Animated background
            AuthAnimatedBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)
                    
                    // Lock icon
                    lockIcon
                        .padding(.bottom, 32)
                    
                    // Success banner
                    if showSuccess, let message = successMessage {
                        SuccessBanner(message: message, onDismiss: nil)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Title
                    Text("Set new password")
                        .font(BWTypography.sectionHeader)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.bwPrimary, Color.bwSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(contentOpacity)
                        .offset(y: contentOffset)
                        .padding(.bottom, 16)
                    
                    // Description
                    VStack(spacing: 8) {
                        Text("Create a new password for")
                            .font(BWTypography.bodySecondary)
                            .foregroundColor(.secondary)
                        
                        Text(email)
                            .font(BWTypography.bodyEmphasis)
                            .foregroundColor(.primary)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)
                    .padding(.bottom, 32)
                    
                    // Password form
                    passwordForm
                        .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                    
                    // Cancel button
                    Button {
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .font(BWTypography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 50)
                    .opacity(contentOpacity)
                }
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            startAnimations()
        }
        .onTapGesture {
            focusedField = nil
        }
        // Security: Clear password fields when app goes to background
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                newPassword = ""
                confirmPassword = ""
                focusedField = nil
            }
        }
    }
    
    // MARK: - Lock Icon
    
    private var lockIcon: some View {
        ZStack {
            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.bwPrimary.opacity(0.12),
                            Color.bwPrimary.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
                .scaleEffect(pulseScale)
            
            // Circle background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: Color.bwPrimary.opacity(0.15), radius: 20, x: 0, y: 10)
            
            // Lock icon
            Image(systemName: "lock.rotation")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.bwPrimary, Color.bwSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .scaleEffect(iconScale)
        .opacity(iconOpacity)
    }
    
    // MARK: - Password Form
    
    private var passwordForm: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                // New password field
                AuthTextField(
                    placeholder: "New Password",
                    text: $newPassword,
                    icon: "lock.fill",
                    keyboardType: .default,
                    textContentType: .newPassword,
                    isSecure: true
                )
                .focused($focusedField, equals: .newPassword)
                .submitLabel(.next)
                .onSubmit { focusedField = .confirmPassword }
                
                // Confirm password field
                AuthTextField(
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    icon: "lock.fill",
                    keyboardType: .default,
                    textContentType: .newPassword,
                    isSecure: true
                )
                .focused($focusedField, equals: .confirmPassword)
                .submitLabel(.done)
                .onSubmit { submitPassword() }
                
                // Password requirements hint
                if let hint = passwordHint {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text(hint)
                            .font(BWTypography.captionSmall)
                    }
                    .foregroundColor(Color.bwAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
                } else if !newPassword.isEmpty && isPasswordStrong {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Password strength: Good")
                            .font(BWTypography.captionSmall)
                    }
                    .foregroundColor(Color.bwSuccess)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
                }
                
                // Password mismatch warning
                if !confirmPassword.isEmpty && newPassword != confirmPassword {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text("Passwords do not match")
                            .font(BWTypography.captionSmall)
                    }
                    .foregroundColor(Color.bwError)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
                }
            }
            .animation(.bwSnappy, value: newPassword)
            .animation(.bwSnappy, value: confirmPassword)
            
            // Error banner
            if showError, let errorMessage = errorMessage {
                ErrorBanner(
                    message: errorMessage,
                    onDismiss: { clearError() }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
            }
            
            // Submit button
            Button {
                submitPassword()
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(isLoading ? "Updating..." : "Update Password")
                        .font(BWTypography.buttonLabel)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isFormValid
                                ? LinearGradient(
                                    colors: [Color.bwPrimary, Color.bwSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                )
                .shadow(
                    color: isFormValid ? Color.bwPrimary.opacity(0.3) : Color.clear,
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .disabled(!isFormValid || isLoading)
            .buttonStyle(BWPressableButtonStyle(scale: 0.97, enableHaptics: !isLoading))
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
        )
        .opacity(contentOpacity)
        .offset(y: contentOffset)
    }
    
    // MARK: - Password Validation
    
    private var hasMinLength: Bool { newPassword.count >= 8 }
    private var hasUppercase: Bool { newPassword.range(of: "[A-Z]", options: .regularExpression) != nil }
    private var hasLowercase: Bool { newPassword.range(of: "[a-z]", options: .regularExpression) != nil }
    private var hasNumber: Bool { newPassword.range(of: "[0-9]", options: .regularExpression) != nil }
    private var passwordsMatch: Bool { newPassword == confirmPassword && !confirmPassword.isEmpty }
    
    private var isPasswordStrong: Bool {
        hasMinLength && hasUppercase && hasLowercase && hasNumber
    }
    
    private var isFormValid: Bool {
        isPasswordStrong && passwordsMatch
    }
    
    /// Returns the current password requirement hint
    private var passwordHint: String? {
        if newPassword.isEmpty { return nil }
        
        var missing: [String] = []
        if !hasMinLength { missing.append("8+ characters") }
        if !hasUppercase { missing.append("uppercase letter") }
        if !hasLowercase { missing.append("lowercase letter") }
        if !hasNumber { missing.append("number") }
        
        if missing.isEmpty { return nil }
        return "Needs: " + missing.joined(separator: ", ")
    }
    
    // MARK: - Actions
    
    private func submitPassword() {
        guard isFormValid else { return }
        
        focusedField = nil
        isLoading = true
        clearError()
        
        Task {
            do {
                try await AuthService.shared.updatePasswordFromRecovery(newPassword: newPassword)
                
                await MainActor.run {
                    BWHaptics.success()
                    successMessage = "Password updated successfully!"
                    showSuccess = true
                    isLoading = false
                    
                    // Navigate to login after short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onComplete()
                    }
                }
            } catch {
                await MainActor.run {
                    BWHaptics.error()
                    if let authError = error as? AuthError {
                        errorMessage = authError.errorDescription
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // Icon entrance
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        // Content reveal
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.25)) {
            contentOpacity = 1.0
            contentOffset = 0
        }
        
        // Pulse animation
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.5)) {
            pulseScale = 1.08
        }
    }
}

// MARK: - Preview

#Preview("Password Reset") {
    PasswordResetScreen(
        email: "test@example.com",
        onComplete: {},
        onCancel: {}
    )
}

#Preview("Password Reset Dark") {
    PasswordResetScreen(
        email: "test@example.com",
        onComplete: {},
        onCancel: {}
    )
    .preferredColorScheme(.dark)
}
