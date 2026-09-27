import SwiftUI

struct AuthForgotPasswordScreen: View {
    var initialEmail: String = ""
    var onBackToLogin: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    @State private var email = ""
    @State private var submitted = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var cooldownRemaining = 0
    @State private var cooldownTimer: Timer?
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(.systemBackground) : Color.white)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                if !submitted {
                    formState
                } else {
                    successState
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .opacity(contentOpacity)
            .offset(y: contentOffset)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    BWHaptics.lightImpact()
                    onBackToLogin()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            if email.isEmpty, !initialEmail.isEmpty {
                email = initialEmail
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
        }
        .onDisappear {
            cooldownTimer?.invalidate()
        }
    }
    
    // MARK: - Form State
    
    private var formState: some View {
        VStack(spacing: 24) {
            iconCircle
            
            VStack(spacing: 8) {
                Text("Forgot Password?")
                    .font(BWTypography.displayMedium)
                    .foregroundColor(.primary)
                
                Text("No worries, we'll send you reset instructions")
                    .font(BWTypography.bodyPrimary)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if showError, let message = errorMessage {
                ErrorBanner(message: message, onDismiss: {
                    withAnimation { showError = false }
                })
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(BWTypography.caption)
                    .foregroundColor(.secondary)
                
                TextField("your@email.com", text: $email)
                    .font(BWTypography.bodyPrimary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(colorScheme == .dark
                                  ? Color(.secondarySystemBackground)
                                  : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .submitLabel(.send)
                    .onSubmit { sendReset() }
            }
            
            Button {
                sendReset()
            } label: {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Reset Password")
                            .font(BWTypography.buttonLabel)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(BWGradients.accentGradient(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0.8 : 1.0)
            .buttonStyle(.bwPressable)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showError)
    }
    
    // MARK: - Success State
    
    private var successState: some View {
        VStack(spacing: 24) {
            iconCircle
            
            VStack(spacing: 8) {
                Text("Check Your Email")
                    .font(BWTypography.displayMedium)
                    .foregroundColor(.primary)
                
                VStack(spacing: 4) {
                    Text("We sent a password reset link to")
                        .font(BWTypography.bodyPrimary)
                        .foregroundColor(.secondary)
                    
                    Text(email)
                        .font(BWTypography.bodyEmphasis)
                        .foregroundColor(.primary)
                }
            }
            
            GradientButton(text: "Back to Sign In", action: onBackToLogin)
            
            Button {
                sendReset()
            } label: {
                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .tint(Color.bwPrimary)
                            .scaleEffect(0.8)
                    }
                    Text(resendButtonText)
                        .font(BWTypography.caption)
                        .foregroundColor(isResendDisabled ? .secondary : Color.bwPrimary)
                }
            }
            .disabled(isResendDisabled)
            
            if showError, let message = errorMessage {
                ErrorBanner(message: message, onDismiss: {
                    withAnimation { showError = false }
                })
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private var iconCircle: some View {
        Circle()
            .fill(Color.bwPrimary.opacity(0.12))
            .frame(width: 72, height: 72)
            .overlay(
                Image(systemName: "envelope.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color.bwPrimary)
            )
    }
    
    // MARK: - Logic
    
    private var isResendDisabled: Bool {
        cooldownRemaining > 0 || isLoading
    }
    
    private var resendButtonText: String {
        if cooldownRemaining > 0 {
            return "Resend in \(cooldownRemaining)s"
        }
        return "Didn't receive the email? Click to resend"
    }
    
    private func sendReset() {
        let trimmed = email.lowercased().trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            displayError("Please enter your email address.")
            return
        }
        
        isLoading = true
        withAnimation { showError = false }
        
        Task {
            do {
                try await AuthService.shared.sendPasswordResetEmail(to: trimmed)
                BWHaptics.success()
                withAnimation(.bwSpring) { submitted = true }
                startCooldown(for: trimmed)
            } catch let error as AuthError {
                if case .rateLimited(let seconds) = error {
                    cooldownRemaining = seconds
                    startCooldownTimer()
                    displayError("Please wait \(seconds) seconds before requesting again.")
                } else {
                    displayError(error.errorDescription ?? "Failed to send reset email.")
                }
            } catch {
                displayError("Failed to send reset email. Please try again.")
            }
            isLoading = false
        }
    }
    
    private func startCooldown(for email: String) {
        cooldownRemaining = AuthService.shared.secondsUntilPasswordResetAllowed(for: email)
        guard cooldownRemaining > 0 else { return }
        startCooldownTimer()
    }
    
    private func startCooldownTimer() {
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                cooldownRemaining -= 1
                if cooldownRemaining <= 0 {
                    timer.invalidate()
                }
            }
        }
    }
    
    private func displayError(_ message: String) {
        BWHaptics.error()
        errorMessage = message
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showError = true
        }
    }
}

#Preview {
    NavigationStack {
        AuthForgotPasswordScreen(onBackToLogin: {})
    }
}
