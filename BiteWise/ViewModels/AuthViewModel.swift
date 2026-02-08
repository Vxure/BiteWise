//
//  AuthViewModel.swift
//  BiteWise
//
//  Created by Regan on 2026-01-26.
//

import Foundation
import SwiftUI

// MARK: - Auth State

/// Explicit authentication states for clear UX flow
enum AuthState: Equatable {
    case login
    case signup
    case awaitingEmailVerification(email: String)
    case awaitingMagicLink(email: String)
    case verifiedAwaitingLogin(email: String)
    case passwordResetPending(email: String)
    
    var isLoginOrSignup: Bool {
        switch self {
        case .login, .signup:
            return true
        default:
            return false
        }
    }
    
    var isAwaitingVerification: Bool {
        if case .awaitingEmailVerification = self {
            return true
        }
        return false
    }
    
    var isAwaitingMagicLink: Bool {
        if case .awaitingMagicLink = self {
            return true
        }
        return false
    }
    
    var isVerifiedAwaitingLogin: Bool {
        if case .verifiedAwaitingLogin = self {
            return true
        }
        return false
    }
    
    var isPasswordResetPending: Bool {
        if case .passwordResetPending = self {
            return true
        }
        return false
    }
    
    var email: String? {
        switch self {
        case .awaitingEmailVerification(let email), .awaitingMagicLink(let email), .verifiedAwaitingLogin(let email), .passwordResetPending(let email):
            return email
        default:
            return nil
        }
    }
}

// MARK: - Auth Mode (for UI toggle)

enum AuthMode: String, CaseIterable {
    case login = "Sign In"
    case signup = "Sign Up"
}

// MARK: - Auth ViewModel

@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var name: String = ""
    
    @Published var authState: AuthState = .login
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var successMessage: String?
    @Published var showSuccess: Bool = false
    
    /// The last error that occurred (for contextual actions like "Go to Login")
    @Published private(set) var lastError: AuthError?
    
    /// Seconds remaining until resend is allowed (for rate limiting UI)
    @Published var resendCooldownRemaining: Int = 0
    
    /// Whether to show password field in login mode (false = magic link mode, true = password mode)
    @Published var usePasswordLogin: Bool = false
    
    // MARK: - Private Properties
    
    private let authService: AuthService
    
    /// Tracks active tasks for cleanup on deinit
    /// Uses UUID keys to enable removal of specific tasks after completion
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    
    /// Timer for resend cooldown countdown
    private var cooldownTimer: Timer?
    
    // MARK: - Computed Properties
    
    /// Current auth mode for UI toggle (login/signup only)
    var authMode: AuthMode {
        switch authState {
        case .login, .verifiedAwaitingLogin, .passwordResetPending, .awaitingMagicLink:
            return .login
        case .signup:
            return .signup
        case .awaitingEmailVerification:
            return .signup
        }
    }
    
    var isLoginMode: Bool {
        authMode == .login
    }
    
    var isSignupMode: Bool {
        authMode == .signup
    }
    
    var primaryButtonTitle: String {
        if isLoading { return "" }
        if isLoginMode {
            return usePasswordLogin ? "Sign In" : "Sign in with email"
        }
        return "Sign Up"
    }
    
    /// Icon for the primary action button
    var primaryButtonIcon: String {
        if isLoginMode {
            return usePasswordLogin ? "arrow.right" : "envelope.fill"
        }
        return "person.badge.plus"
    }
    
    var switchModePrompt: String {
        isLoginMode 
            ? "Don't have an account?" 
            : "Already have an account?"
    }
    
    var switchModeAction: String {
        isLoginMode ? "Sign Up" : "Sign In"
    }
    
    var isFormValid: Bool {
        if isLoginMode {
            return isValidEmail(email) && password.count >= 6
        } else {
            return isValidEmail(email) && 
                   password.count >= 6 && 
                   password == confirmPassword &&
                   !name.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    // MARK: - Initialization
    
    init(authService: AuthService = .shared, initialState: AuthState = .login) {
        self.authService = authService
        self.authState = initialState
    }
    
    deinit {
        // Cancel all active tasks to prevent memory leaks
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
        
        // Stop cooldown timer
        cooldownTimer?.invalidate()
        cooldownTimer = nil
    }
    
    // MARK: - Task Management
    
    /// Creates a tracked task that will be cancelled on deinit
    /// The task is automatically removed from tracking after completion to prevent memory leaks
    private func createTrackedTask(_ operation: @escaping @MainActor () async -> Void) {
        // Generate a unique ID for this task to enable removal after completion
        let taskId = UUID()
        
        let task = Task { @MainActor [weak self] in
            // Execute the operation
            await operation()
            
            // Clean up: remove this task from tracking after completion
            // This prevents memory leaks from accumulating completed tasks
            self?.activeTasks.removeValue(forKey: taskId)
        }
        
        activeTasks[taskId] = task
        
        // Also clean up any cancelled tasks while we're here
        activeTasks = activeTasks.filter { !$0.value.isCancelled }
    }
    
    // MARK: - Deep Link Handling
    
    // Note: Deep link events are handled through DeepLinkStateManager (single source of truth).
    // AuthViewModel can still handle deep link results directly via handleDeepLinkResult(_:)
    // when called from views that need to update auth state (e.g., transitioning to verified state).
    // This avoids duplicate handling that would occur with notification-based listeners.
    
    private func handleVerificationCompleted() {
        // Get the email from current state if available
        let verifiedEmail: String
        if case .awaitingEmailVerification(let email) = authState {
            verifiedEmail = email
        } else {
            verifiedEmail = email
        }
        
        // Transition to verified state
        transitionToVerifiedAwaitingLogin(email: verifiedEmail)
    }
    
    private func handlePasswordRecoveryReady(email: String) {
        transitionToPasswordResetPending(email: email)
    }
    
    private func handleMagicLinkAuthenticated() {
        // User is now authenticated via magic link
        // The AuthService will update isAuthenticated, triggering navigation to home
        BWHaptics.success()
        successMessage = "Email sign-in successful!"
        showSuccess = true
        
        // Auto-dismiss after delay
        createTrackedTask {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                self.showSuccess = false
            }
        }
    }
    
    private func handleEmailChangeConfirmed(newEmail: String) {
        // Email has been changed successfully
        BWHaptics.success()
        successMessage = "Email updated to \(maskEmail(newEmail))"
        showSuccess = true
        
        // Update local profile email (with full email)
        var profile = DataManager.shared.userProfile
        profile.email = newEmail
        DataManager.shared.userProfile = profile
        DataManager.shared.saveUserProfile()
        
        // Auto-dismiss after delay
        createTrackedTask {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            withAnimation {
                self.showSuccess = false
            }
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
    
    private func handleDeepLinkError(_ error: AuthError) {
        BWHaptics.error()
        lastError = error
        displayError(error.errorDescription ?? "An error occurred with the link.")
    }
    
    // MARK: - State Transitions
    
    /// Transition to awaiting email verification state
    func transitionToAwaitingVerification(email: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            authState = .awaitingEmailVerification(email: email)
        }
    }
    
    /// Transition to awaiting magic link state (passwordless sign-in)
    func transitionToAwaitingMagicLink(email: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            authState = .awaitingMagicLink(email: email)
        }
    }
    
    /// Transition to verified awaiting login state (shows success message)
    func transitionToVerifiedAwaitingLogin(email: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            authState = .verifiedAwaitingLogin(email: email)
            self.email = email // Pre-fill email for login
            successMessage = "Email verified — please sign in"
            showSuccess = true
        }
        
        // Auto-dismiss success message after 5 seconds (tracked task)
        createTrackedTask {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            withAnimation {
                self.showSuccess = false
            }
        }
    }
    
    /// Transition to login state
    func transitionToLogin() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            authState = .login
            usePasswordLogin = false // Default to magic link mode
            clearError()
            password = ""
            confirmPassword = ""
        }
    }
    
    /// Transition to signup state
    func transitionToSignup() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            authState = .signup
            clearError()
            clearSuccess()
            password = ""
            confirmPassword = ""
        }
    }
    
    /// Transition to password reset pending state (from deep link)
    func transitionToPasswordResetPending(email: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            authState = .passwordResetPending(email: email)
            self.email = email
            clearError()
            clearSuccess()
            password = ""
            confirmPassword = ""
        }
    }
    
    /// Complete password reset with new password
    func completePasswordReset(newPassword: String) async {
        guard case .passwordResetPending = authState else { return }
        
        // Validate password
        guard newPassword.count >= 6 else {
            displayError("Password must be at least 6 characters.")
            return
        }
        
        isLoading = true
        clearError()
        
        do {
            try await authService.updatePasswordFromRecovery(newPassword: newPassword)
            
            BWHaptics.success()
            successMessage = "Password updated! Please sign in with your new password."
            showSuccess = true
            
            // Transition to login state
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                authState = .login
                password = ""
                confirmPassword = ""
            }
            
            // Auto-dismiss success message after delay
            createTrackedTask {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                withAnimation {
                    self.showSuccess = false
                }
            }
        } catch let error as AuthError {
            lastError = error
            displayError(error.errorDescription ?? "Failed to update password.")
        } catch {
            lastError = .unknown(error.localizedDescription)
            displayError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// Handle deep link result directly (alternative to notification-based handling)
    func handleDeepLinkResult(_ result: DeepLinkResult) {
        switch result {
        case .signupConfirmed:
            handleVerificationCompleted()
        case .recoveryReady(let email):
            handlePasswordRecoveryReady(email: email)
        case .magicLinkAuthenticated:
            handleMagicLinkAuthenticated()
        case .emailChangeConfirmed(let newEmail):
            handleEmailChangeConfirmed(newEmail: newEmail)
        case .inviteAccepted:
            // Similar to magic link - user is now authenticated
            handleMagicLinkAuthenticated()
        case .error(let error):
            handleDeepLinkError(error)
        case .notHandled:
            break
        }
    }
    
    // MARK: - Actions
    
    /// Toggle between login and signup modes
    func toggleMode() {
        if isLoginMode {
            transitionToSignup()
        } else {
            transitionToLogin()
        }
    }
    
    /// Set auth mode directly
    func setMode(_ mode: AuthMode) {
        switch mode {
        case .login:
            if !isLoginMode {
                transitionToLogin()
            }
        case .signup:
            if !isSignupMode {
                transitionToSignup()
            }
        }
    }
    
    /// Perform login with password
    func login() async {
        guard validateLoginInput() else { return }
        
        isLoading = true
        clearError()
        
        do {
            try await authService.signIn(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                password: password
            )
            // Success - AuthService will update isAuthenticated
            BWHaptics.success()
            lastError = nil
            clearForm()
        } catch let error as AuthError {
            lastError = error
            displayError(error.errorDescription ?? "An error occurred")
        } catch {
            lastError = .unknown(error.localizedDescription)
            displayError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// Send magic link for passwordless login
    func sendMagicLink() async {
        // Validate email
        let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else {
            displayError("Please enter your email address.")
            return
        }
        
        guard isValidEmail(trimmedEmail) else {
            displayError("Please enter a valid email address.")
            return
        }
        
        isLoading = true
        clearError()
        
        do {
            try await authService.sendMagicLink(to: trimmedEmail)
            
            // Success - transition to check email state
            BWHaptics.success()
            lastError = nil
            
            // Show check email screen (reuse awaiting verification UI)
            transitionToAwaitingMagicLink(email: trimmedEmail)
            
        } catch let error as AuthError {
            lastError = error
            displayError(error.errorDescription ?? "Failed to send sign-in link.")
        } catch {
            lastError = .unknown(error.localizedDescription)
            displayError("Failed to send sign-in link. Please try again.")
        }
        
        isLoading = false
    }
    
    /// Toggle between magic link and password login modes
    func togglePasswordMode() {
        BWHaptics.lightImpact()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            usePasswordLogin.toggle()
            // Clear password when switching modes
            password = ""
            clearError()
        }
    }
    
    /// Retry the last failed action (for network errors)
    func retryLastAction() async {
        guard let error = lastError, error.isRetryable else { return }
        
        // Determine what to retry based on current state
        if isLoginMode {
            await login()
        } else if authState.isAwaitingVerification {
            await resendVerificationEmail()
        } else {
            await signup()
        }
    }
    
    /// Whether the last error is retryable
    var canRetry: Bool {
        lastError?.isRetryable ?? false
    }
    
    /// Perform signup
    func signup() async {
        guard validateSignupInput() else { return }
        
        isLoading = true
        clearError()
        
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        
        do {
            try await authService.signUp(
                email: trimmedEmail,
                password: password,
                name: trimmedName
            )
            
            // Update local profile with signup name immediately
            // This ensures the greeting shows the correct name right away
            var profile = DataManager.shared.userProfile
            profile.name = trimmedName
            profile.email = trimmedEmail
            DataManager.shared.userProfile = profile
            DataManager.shared.saveUserProfile()
            
            // Success - transition to awaiting verification
            BWHaptics.success()
            transitionToAwaitingVerification(email: trimmedEmail)
            
            // Clear sensitive fields but keep email
            password = ""
            confirmPassword = ""
            
        } catch let error as AuthError {
            lastError = error
            displayError(error.errorDescription ?? "An error occurred")
        } catch {
            lastError = .unknown(error.localizedDescription)
            displayError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// Navigate to login when user already exists (from signup error)
    func goToLoginFromDuplicateError() {
        // Keep the email so user doesn't have to re-enter
        let currentEmail = email
        transitionToLogin()
        email = currentEmail
        clearError()
    }
    
    /// Check if the last error was a duplicate user error
    var showGoToLoginOption: Bool {
        lastError == .userAlreadyExists
    }
    
    /// Resend verification email
    func resendVerificationEmail() async {
        guard case .awaitingEmailVerification(let email) = authState else { return }
        
        isLoading = true
        clearError()
        
        do {
            try await authService.resendVerificationEmail(to: email)
            BWHaptics.success()
            
            // Show success message
            successMessage = "Verification email sent!"
            withAnimation {
                showSuccess = true
            }
            
            // Start cooldown timer
            startResendCooldown(for: email)
            
            // Auto-dismiss after 3 seconds (tracked task)
            createTrackedTask {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation {
                    self.showSuccess = false
                }
            }
        } catch let error as AuthError {
            if case .rateLimited(let seconds) = error {
                // Show rate limit error with countdown
                resendCooldownRemaining = seconds
                displayError("Please wait \(seconds) seconds before resending.")
                startResendCooldown(for: email, startingAt: seconds)
            } else {
                displayError(error.errorDescription ?? "Failed to resend email.")
            }
        } catch {
            displayError("Failed to resend email. Please try again.")
        }
        
        isLoading = false
    }
    
    /// Resend magic link email
    func resendMagicLink() async {
        guard case .awaitingMagicLink(let email) = authState else { return }
        
        isLoading = true
        clearError()
        
        do {
            try await authService.sendMagicLink(to: email)
            BWHaptics.success()
            
            // Show success message
            successMessage = "Sign-in link sent!"
            withAnimation {
                showSuccess = true
            }
            
            // Start cooldown timer
            startResendCooldown(for: email)
            
            // Auto-dismiss after 3 seconds (tracked task)
            createTrackedTask {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation {
                    self.showSuccess = false
                }
            }
        } catch let error as AuthError {
            if case .rateLimited(let seconds) = error {
                // Show rate limit error with countdown
                resendCooldownRemaining = seconds
                displayError("Please wait \(seconds) seconds before resending.")
                startResendCooldown(for: email, startingAt: seconds)
            } else {
                displayError(error.errorDescription ?? "Failed to send sign-in link.")
            }
        } catch {
            displayError("Failed to send sign-in link. Please try again.")
        }
        
        isLoading = false
    }
    
    /// Start the cooldown countdown timer
    private func startResendCooldown(for email: String, startingAt: Int? = nil) {
        // Get initial value from service or use provided value
        resendCooldownRemaining = startingAt ?? authService.secondsUntilResendAllowed(for: email)
        
        // Stop any existing timer
        cooldownTimer?.invalidate()
        
        guard resendCooldownRemaining > 0 else { return }
        
        // Start countdown timer
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                self.resendCooldownRemaining -= 1
                
                if self.resendCooldownRemaining <= 0 {
                    timer.invalidate()
                    self.cooldownTimer = nil
                }
            }
        }
    }
    
    /// Whether resend button should be disabled (cooling down)
    var isResendDisabled: Bool {
        resendCooldownRemaining > 0 || isLoading
    }
    
    /// Text for resend button (shows countdown if cooling down)
    var resendButtonText: String {
        if resendCooldownRemaining > 0 {
            return "Resend in \(resendCooldownRemaining)s"
        }
        return "Resend Email"
    }
    
    /// Perform the current auth action (login, magic link, or signup)
    func performAuthAction() async {
        if isLoginMode {
            if usePasswordLogin {
                await login()
            } else {
                await sendMagicLink()
            }
        } else {
            await signup()
        }
    }
    
    /// Go back from verification screen to login
    func backToLogin() {
        transitionToLogin()
        clearForm()
    }
    
    /// Clear any displayed error
    func clearError() {
        errorMessage = nil
        showError = false
        lastError = nil
    }
    
    /// Clear any displayed success message
    func clearSuccess() {
        successMessage = nil
        showSuccess = false
    }
    
    /// Clear the form fields
    func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        name = ""
    }
    
    // MARK: - Validation
    
    private func validateLoginInput() -> Bool {
        // Email validation
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            displayError("Please enter your email address.")
            return false
        }
        
        if !isValidEmail(email) {
            displayError("Please enter a valid email address.")
            return false
        }
        
        // Password validation
        if password.isEmpty {
            displayError("Please enter your password.")
            return false
        }
        
        if password.count < 6 {
            displayError("Password must be at least 6 characters.")
            return false
        }
        
        return true
    }
    
    private func validateSignupInput() -> Bool {
        // Name validation
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            displayError("Please enter your name.")
            return false
        }
        
        // Email validation
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            displayError("Please enter your email address.")
            return false
        }
        
        if !isValidEmail(email) {
            displayError("Please enter a valid email address.")
            return false
        }
        
        // Password validation
        if password.isEmpty {
            displayError("Please enter a password.")
            return false
        }
        
        // Strong password requirements (8+ chars, uppercase, lowercase, numbers)
        if !isPasswordStrong(password) {
            displayError("Password must be at least 8 characters with uppercase, lowercase, and numbers.")
            return false
        }
        
        // Confirm password validation
        if confirmPassword.isEmpty {
            displayError("Please confirm your password.")
            return false
        }
        
        if password != confirmPassword {
            displayError("Passwords do not match.")
            return false
        }
        
        return true
    }
    
    /// Validates password strength according to security requirements
    private func isPasswordStrong(_ password: String) -> Bool {
        let hasMinLength = password.count >= 8
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasMinLength && hasUppercase && hasLowercase && hasNumber
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespaces))
    }
    
    // MARK: - Error Handling
    
    private func displayError(_ message: String) {
        BWHaptics.error()
        errorMessage = message
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showError = true
        }
    }
}
