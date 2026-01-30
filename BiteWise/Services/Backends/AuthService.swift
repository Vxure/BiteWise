//
//  AuthService.swift
//  BiteWise
//
//  Created by Regan on 2026-01-26.
//

import Foundation
import Supabase
import Auth
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
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .emailNotConfirmed:
            return "Please check your email to confirm your account."
        case .userAlreadyExists:
            return "An account with this email already exists."
        case .weakPassword:
            return "Password must be at least 6 characters."
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
        case .unknown(let message):
            return message
        }
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

// MARK: - Auth Event Notifications

extension Notification.Name {
    /// Posted when email verification is completed via deep link
    static let emailVerificationCompleted = Notification.Name("emailVerificationCompleted")
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
    /// - Returns: True if the URL was handled successfully
    @discardableResult
    func handleOpenURL(_ url: URL) async -> Bool {
        // Only handle our auth scheme
        guard url.scheme == "bitewise" else { return false }
        
        do {
            // Let Supabase handle the URL and extract session
            // This establishes a valid session for the verified user
            try await supabase.auth.session(from: url)
            
            // Note: We no longer force a sign out after verification.
            // The user clicked the link expecting to be logged in, so we keep them authenticated.
            // The auth state listener will automatically update isAuthenticated.
            
            // Post notification that verification is complete
            NotificationCenter.default.post(
                name: .emailVerificationCompleted,
                object: nil
            )
            
            return true
        } catch {
            logger.error("Failed to handle auth URL: \(error.localizedDescription, privacy: .public)")
            return false
        }
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
    
    /// Send a password reset email to the specified address
    /// - Parameter email: The email address to send the reset link to
    func sendPasswordResetEmail(to email: String) async throws {
        let normalizedEmail = email.lowercased()
        
        // Check rate limit
        let cooldownRemaining = secondsUntilPasswordResetAllowed(for: normalizedEmail)
        if cooldownRemaining > 0 {
            throw AuthError.rateLimited(retryAfter: cooldownRemaining)
        }
        
        do {
            try await supabase.auth.resetPasswordForEmail(normalizedEmail, redirectTo: redirectURL)
            lastPasswordResetTime[normalizedEmail] = Date()
        } catch {
            throw mapGenericError(error)
        }
    }
    
    // MARK: - Account Deletion
    
    /// Delete the current user's account and all associated data
    /// This triggers the server-side deletion flow (DB + storage + auth user)
    func deleteAccount() async throws {
        guard currentUser != nil else {
            throw AuthError.sessionExpired
        }
        
        do {
            // Perform server-side deletion (DB + storage + auth user)
            try await SupabaseDataService.shared.deleteAllUserData()
            
            // Clear local state immediately after server confirmation
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
        
        // Rate limiting detection
        if errorMessage.contains("rate limit") ||
           errorMessage.contains("too many requests") ||
           errorMessage.contains("429") {
            // Try to extract retry-after, default to 60 seconds
            return .rateLimited(retryAfter: 60)
        }
        
        // Expired verification link
        if errorMessage.contains("otp") && errorMessage.contains("expired") ||
           errorMessage.contains("link") && errorMessage.contains("expired") ||
           errorMessage.contains("token") && errorMessage.contains("expired") {
            return .verificationLinkExpired
        }
        
        // Return the original error message for unknown errors
        return .unknown(error.localizedDescription)
    }
}
