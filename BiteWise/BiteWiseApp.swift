//
//  BiteWiseApp.swift
//  BiteWise
//
//  Created by Regan on 2025-06-16.
//

import SwiftUI

// MARK: - Deep Link State Manager

/// Observable class to manage deep link state across the app
@MainActor
final class DeepLinkStateManager: ObservableObject {
    static let shared = DeepLinkStateManager()
    
    /// The pending deep link result that needs to be handled
    @Published var pendingResult: DeepLinkResult?
    
    /// Error message to display for deep link failures
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    /// Success message to display for deep link successes
    @Published var successMessage: String?
    @Published var showSuccess: Bool = false
    
    private init() {}
    
    /// Handle a deep link result and update app state accordingly
    func handleResult(_ result: DeepLinkResult) {
        switch result {
        case .signupConfirmed:
            // Handled via notification in AuthViewModel
            // Also show a success message at app level
            successMessage = "Email verified successfully!"
            showSuccess = true
            autoDismissSuccess()
            
        case .recoveryReady:
            // Store for AppNavigation to handle - need to show password reset screen
            pendingResult = result
            
        case .magicLinkAuthenticated:
            // User is authenticated - AuthService updates isAuthenticated
            // Navigation will handle automatically
            successMessage = "Email sign-in successful!"
            showSuccess = true
            autoDismissSuccess()
            
        case .emailChangeConfirmed(let newEmail):
            // Show success message for email change (masked for privacy)
            successMessage = "Email updated to \(maskEmail(newEmail))"
            showSuccess = true
            autoDismissSuccess(delay: 5)
            // Also update local profile (with full email)
            var profile = DataManager.shared.userProfile
            profile.email = newEmail
            DataManager.shared.userProfile = profile
            DataManager.shared.saveUserProfile()
            
        case .inviteAccepted:
            // User is authenticated via invite - similar to magic link
            successMessage = "Invite accepted! Welcome to BiteWise."
            showSuccess = true
            autoDismissSuccess()
            
        case .error(let authError):
            // Show error to user
            errorMessage = authError.errorDescription
            showError = true
            
        case .notHandled:
            break
        }
    }
    
    /// Clear the pending result after it's been processed
    func clearPendingResult() {
        pendingResult = nil
    }
    
    /// Dismiss the error message
    func dismissError() {
        showError = false
        errorMessage = nil
    }
    
    /// Dismiss the success message
    func dismissSuccess() {
        showSuccess = false
        successMessage = nil
    }
    
    /// Auto-dismiss success message after delay
    private func autoDismissSuccess(delay: Double = 4) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.dismissSuccess()
        }
    }
    
    /// Mask an email address for privacy display
    /// Example: "test@example.com" → "t***@example.com"
    private func maskEmail(_ email: String) -> String {
        guard let atIndex = email.firstIndex(of: "@") else {
            return email
        }
        
        let localPart = String(email[..<atIndex])
        let domain = String(email[atIndex...])
        
        // Keep first character, mask the rest of local part
        if localPart.count <= 1 {
            return "\(localPart)***\(domain)"
        } else {
            let firstChar = localPart.prefix(1)
            return "\(firstChar)***\(domain)"
        }
    }
}

@main
struct BiteWiseApp: App {
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var deepLinkManager = DeepLinkStateManager.shared
    
    init() {
        // Make navigation bar transparent
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            AppNavigation()
                .preferredColorScheme(appSettings.appTheme.colorScheme)
                .environmentObject(appSettings)
                .environmentObject(deepLinkManager)
                .onOpenURL { url in
                    // Handle deep links for all Supabase auth flows
                    // URL scheme: bitewise://auth?type=X
                    Task {
                        let result = await AuthService.shared.handleOpenURL(url)
                        deepLinkManager.handleResult(result)
                    }
                }
                .overlay(alignment: .top) {
                    VStack(spacing: 8) {
                        // Global deep link success banner
                        if deepLinkManager.showSuccess, let successMessage = deepLinkManager.successMessage {
                            DeepLinkSuccessBanner(
                                message: successMessage,
                                onDismiss: {
                                    deepLinkManager.dismissSuccess()
                                }
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Global deep link error banner
                        if deepLinkManager.showError, let errorMessage = deepLinkManager.errorMessage {
                            DeepLinkErrorBanner(
                                message: errorMessage,
                                onDismiss: {
                                    deepLinkManager.dismissError()
                                }
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: deepLinkManager.showError)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: deepLinkManager.showSuccess)
                    .padding(.top, 50)
                    .padding(.horizontal, 16)
                    .zIndex(1000)
                }
        }
    }
}

// MARK: - Deep Link Success Banner

/// Success banner for displaying deep link successes at the app level
struct DeepLinkSuccessBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
            
            Text(message)
                .font(BWTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            Button {
                BWHaptics.lightImpact()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bwSuccess)
                .shadow(color: Color.bwSuccess.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Deep Link Error Banner

/// Error banner for displaying deep link failures at the app level
struct DeepLinkErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Link Error")
                    .font(BWTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button {
                BWHaptics.lightImpact()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bwError)
                .shadow(color: Color.bwError.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            // Auto-dismiss after 8 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                onDismiss()
            }
        }
    }
}
