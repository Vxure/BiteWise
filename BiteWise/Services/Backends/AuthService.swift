//
//  AuthService.swift
//  BiteWise
//
//  Created by Regan on 2026-01-26.
//

import Foundation
import Supabase
import Auth
import Functions
import os.log

// MARK: - Auth Error Types

enum AuthError: LocalizedError, Equatable {
    case invalidCredentials
    case emailNotConfirmed
    case userAlreadyExists
    case weakPassword
    case invalidEmail
    case networkError
    case sessionExpired
    case rateLimited(retryAfter: Int)
    case verificationLinkExpired
    case linkExpired
    case linkInvalid
    case linkAlreadyUsed
    case unknown(String)
    
    /// User-facing error description (sanitized for security)
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .emailNotConfirmed:
            return "Please check your email to confirm your account."
        case .userAlreadyExists:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password must be at least 8 characters with uppercase, lowercase, and numbers."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .networkError:
            return "Unable to connect. Please check your internet."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .rateLimited(let seconds):
            return "Too many requests. Please wait \(seconds) seconds."
        case .verificationLinkExpired:
            return "Verification link has expired. Please request a new one."
        case .linkExpired:
            return "This link has expired. Please request a new one."
        case .linkInvalid:
            return "This link is invalid or malformed."
        case .linkAlreadyUsed:
            return "This link has already been used."
        case .unknown:
            // Security: Do not expose internal error details to users
            return "An unexpected error occurred. Please try again."
        }
    }
    
    /// Internal error message for logging (not shown to users)
    /// Use this with privacy: .private in os.log
    var internalMessage: String? {
        if case .unknown(let message) = self {
            return message
        }
        return nil
    }
    
    /// Whether this error is recoverable by retrying
    var isRetryable: Bool {
        switch self {
        case .networkError:
            return true
        default:
            return false
        }
    }
}

// MARK: - Deep Link Types

/// The type of auth action from a Supabase email link
enum DeepLinkType: String {
    case signup
    case recovery
    case magiclink
    case emailChange = "email_change"
    case invite
    
    /// Initialize from URL query parameter
    init?(from url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let typeParam = components.queryItems?.first(where: { $0.name == "type" })?.value else {
            return nil
        }
        self.init(rawValue: typeParam)
    }
}

/// The result of handling a deep link URL
enum DeepLinkResult: Equatable {
    case signupConfirmed
    case recoveryReady(email: String)
    case magicLinkAuthenticated
    case emailChangeConfirmed(newEmail: String)
    case inviteAccepted
    case error(AuthError)
    case notHandled
    
    static func == (lhs: DeepLinkResult, rhs: DeepLinkResult) -> Bool {
        switch (lhs, rhs) {
        case (.signupConfirmed, .signupConfirmed):
            return true
        case (.recoveryReady(let lEmail), .recoveryReady(let rEmail)):
            return lEmail == rEmail
        case (.magicLinkAuthenticated, .magicLinkAuthenticated):
            return true
        case (.emailChangeConfirmed(let lEmail), .emailChangeConfirmed(let rEmail)):
            return lEmail == rEmail
        case (.inviteAccepted, .inviteAccepted):
            return true
        case (.error(let lError), .error(let rError)):
            return lError == rError
        case (.notHandled, .notHandled):
            return true
        default:
            return false
        }
    }
}

// MARK: - Auth Event Notifications

extension Notification.Name {
    /// Posted when email verification is completed via deep link
    static let emailVerificationCompleted = Notification.Name("emailVerificationCompleted")
    /// Posted when password recovery link is received and session is ready
    static let passwordRecoveryReady = Notification.Name("passwordRecoveryReady")
    /// Posted when magic link authentication is completed
    static let magicLinkAuthenticated = Notification.Name("magicLinkAuthenticated")
    /// Posted when email change is confirmed
    static let emailChangeConfirmed = Notification.Name("emailChangeConfirmed")
    /// Posted when invite is accepted
    static let inviteAccepted = Notification.Name("inviteAccepted")
    /// Posted when a deep link error occurs
    static let deepLinkError = Notification.Name("deepLinkError")
}

// MARK: - Auth Service

@MainActor
final class AuthService: ObservableObject {
    
    static let shared = AuthService()
    
    // MARK: - Privacy-Safe Logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BiteWise", category: "AuthService")
    
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var isEmailVerified: Bool = false
    
    /// The redirect URL for email verification
    private let redirectURL = URL(string: "bitewise://auth")!
    
    private var authStateTask: Task<Void, Never>?
    
    // MARK: - Rate Limiting
    
    /// Minimum seconds between resend verification email requests
    private let resendCooldownSeconds: TimeInterval = 60
    
    /// Minimum seconds between password reset email requests
    private let resetCooldownSeconds: TimeInterval = 60
    
    /// Tracks last resend time per email to prevent spam
    private var lastResendTime: [String: Date] = [:]
    
    /// Tracks last password reset time per email to prevent abuse
    private var lastPasswordResetTime: [String: Date] = [:]
    
    /// Returns seconds remaining before resend is allowed, or 0 if allowed
    func secondsUntilResendAllowed(for email: String) -> Int {
        guard let lastTime = lastResendTime[email.lowercased()] else { return 0 }
        let elapsed = Date().timeIntervalSince(lastTime)
        let remaining = resendCooldownSeconds - elapsed
        return max(0, Int(remaining))
    }
    
    /// Returns seconds remaining before password reset is allowed, or 0 if allowed
    func secondsUntilPasswordResetAllowed(for email: String) -> Int {
        guard let lastTime = lastPasswordResetTime[email.lowercased()] else { return 0 }
        let elapsed = Date().timeIntervalSince(lastTime)
        let remaining = resetCooldownSeconds - elapsed
        return max(0, Int(remaining))
    }
    
    private init() {
        // Start listening for auth state changes
        startAuthStateListener()
    }
    
    deinit {
        authStateTask?.cancel()
    }
    
    // MARK: - Auth State Listener
    
    private func startAuthStateListener() {
        authStateTask = Task { [weak self] in
            for await (event, session) in supabase.auth.authStateChanges {
                guard let self = self else { return }
                
                switch event {
                case .initialSession:
                    self.currentUser = session?.user
                    self.isAuthenticated = session?.user != nil
                    self.isEmailVerified = session?.user.emailConfirmedAt != nil
                case .signedIn:
                    self.currentUser = session?.user
                    self.isAuthenticated = session?.user != nil
                    self.isEmailVerified = session?.user.emailConfirmedAt != nil
                case .signedOut:
                    self.currentUser = nil
                    self.isAuthenticated = false
                    self.isEmailVerified = false
                case .tokenRefreshed:
                    self.currentUser = session?.user
                    self.isEmailVerified = session?.user.emailConfirmedAt != nil
                case .userUpdated:
                    self.currentUser = session?.user
                    self.isEmailVerified = session?.user.emailConfirmedAt != nil
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Handle Deep Link URL
    
    /// Handle incoming URL from email verification deep link
    /// - Parameter url: The URL received via onOpenURL
    /// - Returns: DeepLinkResult indicating what happened
    @discardableResult
    func handleOpenURL(_ url: URL) async -> DeepLinkResult {
        // Only handle our auth scheme
        guard url.scheme == "bitewise" else { return .notHandled }
        
        // Parse the deep link type from URL
        let linkType = DeepLinkType(from: url)
        
        do {
            // Let Supabase handle the URL and extract session
            // This establishes a valid session for the verified user
            let session = try await supabase.auth.session(from: url)
            
            // Route based on link type
            // Note: Results are returned directly to the caller (BiteWiseApp) which passes them
            // to DeepLinkStateManager - the single source of truth for deep link handling.
            // This avoids duplicate handling that would occur with notifications.
            switch linkType {
            case .signup:
                // Email verification completed
                return .signupConfirmed
                
            case .recovery:
                // Password reset - session is valid, user needs to set new password
                let email = session.user.email ?? ""
                return .recoveryReady(email: email)
                
            case .magiclink:
                // Magic link authentication - user is now logged in
                return .magicLinkAuthenticated
                
            case .emailChange:
                // Email change confirmed - user's email has been updated
                let newEmail = session.user.email ?? ""
                return .emailChangeConfirmed(newEmail: newEmail)
                
            case .invite:
                // Invite accepted - user is now part of the system
                return .inviteAccepted
                
            case .none:
                // No type specified - treat as generic email verification (legacy behavior)
                return .signupConfirmed
            }
        } catch {
            let authError = mapDeepLinkError(error)
            logger.error("Failed to handle auth URL: \(error.localizedDescription, privacy: .public)")
            
            return .error(authError)
        }
    }
    
    /// Map deep link specific errors
    private func mapDeepLinkError(_ error: Error) -> AuthError {
        let errorMessage = error.localizedDescription.lowercased()
        
        // Check for expired token/link
        if errorMessage.contains("expired") ||
           errorMessage.contains("otp has expired") ||
           errorMessage.contains("token has expired") {
            return .linkExpired
        }
        
        // Check for already used token
        if errorMessage.contains("already been used") ||
           errorMessage.contains("already used") ||
           errorMessage.contains("otp_disabled") {
            return .linkAlreadyUsed
        }
        
        // Check for invalid token
        if errorMessage.contains("invalid") ||
           errorMessage.contains("malformed") ||
           errorMessage.contains("not found") {
            return .linkInvalid
        }
        
        // Fall back to generic error mapping
        return mapGenericError(error)
    }
    
    // MARK: - Sign In
    
    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The authenticated user
    @discardableResult
    func signIn(email: String, password: String) async throws -> User {
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            return session.user
        } catch let error as AuthError {
            throw mapAuthError(error)
        } catch {
            throw mapGenericError(error)
        }
    }
    
    // MARK: - Sign Up
    
    /// Sign up with email and password
    /// Sends verification email to the provided address
    /// Database triggers automatically create profiles, user_preferences, and user_settings after verification
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - name: User's display name (optional)
    /// - Returns: The newly created user (unverified)
    @discardableResult
    func signUp(email: String, password: String, name: String? = nil) async throws -> User {
        // Validate password strength before attempting signup
        try validatePassword(password)
        
        do {
            // Include name in user metadata for the database trigger
            var userData: [String: AnyJSON] = [:]
            if let name = name, !name.isEmpty {
                userData["name"] = .string(name)
            }
            
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: userData,
                redirectTo: redirectURL
            )
            
            return response.user
        } catch let error as AuthError {
            throw mapAuthError(error)
        } catch {
            throw mapGenericError(error)
        }
    }
    
    // MARK: - Resend Verification Email
    
    /// Resend the verification email to the user
    /// - Parameter email: The email address to send verification to
    /// - Throws: `AuthError.rateLimited` if called too frequently
    func resendVerificationEmail(to email: String) async throws {
        let normalizedEmail = email.lowercased()
        
        // Check rate limit
        let cooldownRemaining = secondsUntilResendAllowed(for: normalizedEmail)
        if cooldownRemaining > 0 {
            throw AuthError.rateLimited(retryAfter: cooldownRemaining)
        }
        
        do {
            try await supabase.auth.resend(
                email: normalizedEmail,
                type: .signup
            )
            
            // Record successful send time
            lastResendTime[normalizedEmail] = Date()
        } catch {
            throw mapGenericError(error)
        }
    }
    
    // MARK: - Magic Link Authentication
    
    /// Send a magic link (passwordless) sign-in email
    /// User will receive an email with a link that signs them in directly
    /// - Parameter email: The email address to send the magic link to
    /// - Throws: `AuthError.rateLimited` if called too frequently, or other auth errors
    func sendMagicLink(to email: String) async throws {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Validate email format
        guard isValidEmailFormat(normalizedEmail) else {
            throw AuthError.invalidEmail
        }
        
        // Check rate limit (reuse resend rate limiting)
        let cooldownRemaining = secondsUntilResendAllowed(for: normalizedEmail)
        if cooldownRemaining > 0 {
            throw AuthError.rateLimited(retryAfter: cooldownRemaining)
        }
        
        do {
            try await supabase.auth.signInWithOTP(
                email: normalizedEmail,
                redirectTo: redirectURL
            )
            
            // Record successful send time for rate limiting
            lastResendTime[normalizedEmail] = Date()
        } catch {
            throw mapGenericError(error)
        }
    }
    
    /// Validates email format using a simple regex check
    private func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Sign Out
    
    /// Sign out the current user
    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
            DataManager.shared.clearLocalUserData()
        } catch {
            throw mapGenericError(error)
        }
    }
    
    // MARK: - Password Management
    
    /// Change password for the current user (requires current password verification)
    /// - Parameters:
    ///   - currentPassword: User's current password for verification
    ///   - newPassword: The new password to set
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = currentUser, let email = user.email else {
            throw AuthError.sessionExpired
        }
        
        // First verify current password by attempting to sign in
        do {
            _ = try await supabase.auth.signIn(email: email, password: currentPassword)
        } catch {
            throw AuthError.invalidCredentials
        }
        
        // Now update to the new password
        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
        } catch {
            throw mapGenericError(error)
        }
    }
    
    /// Update password during password recovery flow
    /// This is called after the user clicks the password reset link and has a valid recovery session
    /// - Parameter newPassword: The new password to set
    func updatePasswordFromRecovery(newPassword: String) async throws {
        // Ensure we have a valid session from the recovery link
        guard currentUser != nil else {
            throw AuthError.sessionExpired
        }
        
        // Validate password strength (8+ chars, uppercase, lowercase, numbers)
        try validatePassword(newPassword)
        
        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
            
            // Sign out after password reset so user can log in with new password
            // This is a security best practice
            try await supabase.auth.signOut()
        } catch {
            throw mapGenericError(error)
        }
    }
    
    // MARK: - Email Change
    
    /// Request an email change for the current user
    /// Sends a confirmation email to the new address
    /// - Parameter newEmail: The new email address
    func requestEmailChange(to newEmail: String) async throws {
        guard currentUser != nil else {
            throw AuthError.sessionExpired
        }
        
        // Validate email format
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: newEmail.trimmingCharacters(in: .whitespaces)) else {
            throw AuthError.invalidEmail
        }
        
        do {
            // Request email change - Supabase will send confirmation to new email
            try await supabase.auth.update(
                user: UserAttributes(email: newEmail.lowercased().trimmingCharacters(in: .whitespaces)),
                redirectTo: redirectURL
            )
        } catch {
            throw mapGenericError(error)
        }
    }
    
    /// Send a password reset email to the specified address
    /// Uses server-side Edge Function for additional rate limiting and security
    /// - Parameter email: The email address to send the reset link to
    func sendPasswordResetEmail(to email: String) async throws {
        let normalizedEmail = email.lowercased()
        
        // Check client-side rate limit first (quick rejection)
        let cooldownRemaining = secondsUntilPasswordResetAllowed(for: normalizedEmail)
        if cooldownRemaining > 0 {
            throw AuthError.rateLimited(retryAfter: cooldownRemaining)
        }
        
        do {
            // Use Edge Function for server-side rate limiting
            struct ResetRequest: Encodable {
                let email: String
                let redirect_to: String
            }
            
            struct ResetResponse: Decodable {
                let success: Bool?
                let message: String?
                let error: String?
                let retry_after: Int?
            }
            
            let request = ResetRequest(
                email: normalizedEmail,
                redirect_to: redirectURL.absoluteString
            )
            
            let response: ResetResponse = try await supabase.functions.invoke(
                "send-password-reset",
                options: FunctionInvokeOptions(body: request)
            )
            
            // Check for rate limit response
            if let retryAfter = response.retry_after {
                throw AuthError.rateLimited(retryAfter: retryAfter)
            }
            
            // Record successful send time for client-side cooldown
            lastPasswordResetTime[normalizedEmail] = Date()
        } catch let error as AuthError {
            throw error
        } catch {
            // Fall back to direct Supabase call if Edge Function fails
            logger.warning("Edge Function failed, falling back to direct call: \(error.localizedDescription, privacy: .public)")
            do {
                try await supabase.auth.resetPasswordForEmail(normalizedEmail, redirectTo: redirectURL)
                lastPasswordResetTime[normalizedEmail] = Date()
            } catch {
                throw mapGenericError(error)
            }
        }
    }
    
    // MARK: - Account Deletion
    
    /// Delete the current user's account and all associated data
    /// This triggers the server-side job-based deletion flow for robustness
    /// The job queue ensures deletion completes even if there are partial failures
    func deleteAccount() async throws {
        guard currentUser != nil else {
            throw AuthError.sessionExpired
        }
        
        do {
            // Perform server-side deletion (DB + storage + auth user)
            // This uses a job queue for robustness and idempotency
            let response = try await SupabaseDataService.shared.deleteAllUserData()
            
            // Log the deletion status
            logger.info("Account deletion initiated: status=\(response.status ?? "unknown", privacy: .public)")
            
            // Clear local state immediately
            // Even if the job is "queued" (202), we clear local state
            // The server will complete deletion in the background
            DataManager.shared.clearLocalUserData()
            
            // Attempt sign out to clear any remaining session tokens
            try? await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            isEmailVerified = false
        } catch {
            throw mapGenericError(error)
        }
    }
    
    // MARK: - Session Management
    
    /// Get the current session if one exists
    /// - Returns: The current session or nil
    func getCurrentSession() async -> Session? {
        do {
            return try await supabase.auth.session
        } catch {
            return nil
        }
    }
    
    /// Check if user is currently authenticated
    /// - Returns: True if authenticated
    func checkAuthentication() async -> Bool {
        let session = await getCurrentSession()
        return session != nil
    }
    
    /// Refresh the current session token
    /// If refresh fails, signs out the user to prevent inconsistent state
    func refreshSession() async throws {
        do {
            try await supabase.auth.refreshSession()
        } catch {
            // Session refresh failed - sign out to prevent inconsistent state
            try? await supabase.auth.signOut()
            DataManager.shared.clearLocalUserData()
            throw AuthError.sessionExpired
        }
    }
    
    // MARK: - Retry Helper
    
    /// Executes an async operation with automatic retry for network errors
    /// - Parameters:
    ///   - maxAttempts: Maximum number of attempts (default 3)
    ///   - delay: Initial delay between retries in seconds (doubles each retry)
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation
    func withRetry<T>(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var delay = initialDelay
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch let error as AuthError where error.isRetryable {
                lastError = error
                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    delay *= 2 // Exponential backoff
                }
            } catch {
                // Non-retryable error, throw immediately
                throw error
            }
        }
        
        throw lastError ?? AuthError.networkError
    }
    
    // MARK: - Password Validation
    
    /// Validates password strength according to security requirements
    /// Requirements:
    /// - Minimum 8 characters
    /// - At least one uppercase letter
    /// - At least one lowercase letter
    /// - At least one number
    /// - Parameter password: The password to validate
    /// - Returns: True if password meets all requirements
    private func isPasswordStrong(_ password: String) -> Bool {
        let hasMinLength = password.count >= 8
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        return hasMinLength && hasUppercase && hasLowercase && hasNumber
    }
    
    /// Validates password and throws weakPassword if requirements are not met
    /// - Parameter password: The password to validate
    /// - Throws: AuthError.weakPassword if validation fails
    private func validatePassword(_ password: String) throws {
        guard isPasswordStrong(password) else {
            throw AuthError.weakPassword
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapAuthError(_ error: AuthError) -> AuthError {
        // AuthError from Supabase SDK - pass through our custom errors
        return error
    }
    
    private func mapGenericError(_ error: Error) -> AuthError {
        let errorMessage = error.localizedDescription.lowercased()
        
        // Map common Supabase error messages to user-friendly errors
        if errorMessage.contains("invalid login credentials") ||
           errorMessage.contains("invalid_credentials") {
            return .invalidCredentials
        }
        
        if errorMessage.contains("email not confirmed") ||
           errorMessage.contains("email_not_confirmed") {
            return .emailNotConfirmed
        }
        
        if errorMessage.contains("user already registered") ||
           errorMessage.contains("already exists") ||
           errorMessage.contains("user_already_exists") {
            return .userAlreadyExists
        }
        
        if errorMessage.contains("password") && 
           (errorMessage.contains("weak") || errorMessage.contains("short") || errorMessage.contains("at least")) {
            return .weakPassword
        }
        
        if errorMessage.contains("invalid email") ||
           errorMessage.contains("invalid_email") {
            return .invalidEmail
        }
        
        if errorMessage.contains("network") ||
           errorMessage.contains("connection") ||
           errorMessage.contains("offline") ||
           errorMessage.contains("could not connect") ||
           errorMessage.contains("timed out") {
            return .networkError
        }
        
        if errorMessage.contains("session") && 
           (errorMessage.contains("expired") || errorMessage.contains("invalid")) {
            return .sessionExpired
        }
        
        // Rate limiting detection - extract retry-after time from error message
        if errorMessage.contains("rate limit") ||
           errorMessage.contains("too many requests") ||
           errorMessage.contains("429") ||
           errorMessage.contains("request rate limit") {
            let retryAfter = extractRetryAfterSeconds(from: error)
            logger.warning("Rate limited: retry after \(retryAfter) seconds")
            return .rateLimited(retryAfter: retryAfter)
        }
        
        // Expired verification link
        if errorMessage.contains("otp") && errorMessage.contains("expired") ||
           errorMessage.contains("link") && errorMessage.contains("expired") ||
           errorMessage.contains("token") && errorMessage.contains("expired") {
            return .verificationLinkExpired
        }
        
        // Link already used
        if errorMessage.contains("already been used") ||
           errorMessage.contains("already used") ||
           errorMessage.contains("otp_disabled") {
            return .linkAlreadyUsed
        }
        
        // Invalid link
        if errorMessage.contains("invalid otp") ||
           errorMessage.contains("invalid token") ||
           errorMessage.contains("malformed") {
            return .linkInvalid
        }
        
        // Return unknown error - internal message stored for logging but not shown to user
        // The errorDescription property returns a sanitized generic message
        let internalError = AuthError.unknown(error.localizedDescription)
        // Log the actual error privately for debugging
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "BiteWise", category: "AuthService")
            .error("Unknown auth error: \(error.localizedDescription, privacy: .private)")
        return internalError
    }
    
    // MARK: - Retry-After Extraction
    
    /// Extract the retry-after duration from various error formats
    /// Supabase may include this in different ways depending on the endpoint
    private func extractRetryAfterSeconds(from error: Error) -> Int {
        let errorString = String(describing: error)
        let errorMessage = error.localizedDescription
        
        // Try to extract from common patterns:
        // "Rate limit exceeded. Please try again in 60 seconds"
        // "Too many requests, retry after 45 seconds"
        // "request rate limit reached, retry after 30s"
        // "429: Too Many Requests" (default to 60)
        
        let patterns = [
            // Pattern: "in X seconds" or "in X second"
            #"in\s+(\d+)\s*seconds?"#,
            // Pattern: "after X seconds" or "after Xs"
            #"after\s+(\d+)\s*s(?:econds?)?"#,
            // Pattern: "retry_after: X" or "retry-after: X"
            #"retry[_-]?after[:\s]+(\d+)"#,
            // Pattern: "wait X seconds"
            #"wait\s+(\d+)\s*seconds?"#,
            // Pattern: just a number followed by seconds
            #"(\d+)\s*seconds?"#
        ]
        
        // Check both the error description and full error string
        for source in [errorMessage, errorString] {
            let lowercased = source.lowercased()
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                   let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)),
                   match.numberOfRanges > 1,
                   let range = Range(match.range(at: 1), in: lowercased),
                   let seconds = Int(lowercased[range]) {
                    // Sanity check: limit to reasonable range (1 second to 1 hour)
                    return min(max(seconds, 1), 3600)
                }
            }
        }
        
        // Default to 60 seconds if we can't extract a specific time
        return 60
    }
}
