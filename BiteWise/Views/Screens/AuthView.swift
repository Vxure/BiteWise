//
//  AuthView.swift
//  BiteWise
//
//  Created by Regan on 2026-01-26.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var onSkip: (() -> Void)?
    
    init(onSkip: (() -> Void)? = nil) {
        self.onSkip = onSkip
    }
    
    var body: some View {
        ZStack {
            // Animated background (shared across all states)
            AuthAnimatedBackground()
            
            // Content based on auth state
            switch viewModel.authState {
            case .login, .signup, .verifiedAwaitingLogin:
                AuthFormView(viewModel: viewModel, onSkip: onSkip)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
            case .awaitingEmailVerification(let email):
                CheckEmailView(
                    email: email,
                    isLoading: viewModel.isLoading,
                    successMessage: viewModel.showSuccess ? viewModel.successMessage : nil,
                    resendCooldown: viewModel.resendCooldownRemaining,
                    resendButtonText: viewModel.resendButtonText,
                    onResendEmail: {
                        Task { await viewModel.resendVerificationEmail() }
                    },
                    onBackToLogin: {
                        viewModel.backToLogin()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.authState)
    }
}

// MARK: - Auth Form View (Login / Signup)

struct AuthFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focusedField: AuthField?
    
    var onSkip: (() -> Void)?
    
    // Animation states
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 30
    
    // Forgot password state
    @State private var showForgotPassword = false
    
    private enum AuthField {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer(minLength: 60)
                
                // Logo section
                AuthLogoView(scale: logoScale, opacity: logoOpacity)
                    .padding(.bottom, 32)
                
                // Success banner (shown after email verification)
                if viewModel.showSuccess, let message = viewModel.successMessage {
                    SuccessBanner(message: message) {
                        viewModel.clearSuccess()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Title
                titleSection
                    .padding(.bottom, 8)
                
                // Subtitle
                subtitleSection
                    .padding(.bottom, 32)
                
                // Auth form card
                authFormCard
                    .padding(.horizontal, 24)
                
                // Switch mode footer
                switchModeFooter
                    .padding(.top, 24)
                
                // Skip / Guest mode option
                if let onSkip = onSkip {
                    skipButton(action: onSkip)
                        .padding(.top, 16)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            startAnimations()
        }
        .onTapGesture {
            focusedField = nil
        }
    }
    
    // MARK: - Skip Button
    
    private func skipButton(action: @escaping () -> Void) -> some View {
        Button {
            BWHaptics.lightImpact()
            action()
        } label: {
            Text("Continue as Guest")
                .font(BWTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .opacity(contentOpacity)
    }
    
    // MARK: - Error Action Helpers
    
    /// Title for error action button (if applicable)
    private var errorActionTitle: String? {
        if viewModel.showGoToLoginOption {
            return "Go to Sign In"
        } else if viewModel.canRetry {
            return "Try Again"
        }
        return nil
    }
    
    /// Action for error action button (if applicable)
    private var errorAction: (() -> Void)? {
        if viewModel.showGoToLoginOption {
            return { viewModel.goToLoginFromDuplicateError() }
        } else if viewModel.canRetry {
            return { Task { await viewModel.retryLastAction() } }
        }
        return nil
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        Text(viewModel.isLoginMode ? "Welcome back" : "Create account")
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
    }
    
    // MARK: - Subtitle Section
    
    private var subtitleSection: some View {
        Text(viewModel.isLoginMode 
             ? "Sign in to continue your wellness journey" 
             : "Start your personalized food journey")
            .font(BWTypography.bodySecondary)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .opacity(contentOpacity)
            .offset(y: contentOffset)
    }
    
    // MARK: - Auth Form Card
    
    private var authFormCard: some View {
        VStack(spacing: 20) {
            // Mode picker
            authModePicker
            
            // Form fields
            VStack(spacing: 16) {
                // Name field (signup only)
                if viewModel.isSignupMode {
                    AuthTextField(
                        placeholder: "Full Name",
                        text: $viewModel.name,
                        icon: "person.fill",
                        keyboardType: .default,
                        textContentType: .name,
                        isSecure: false
                    )
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
                
                // Email field
                AuthTextField(
                    placeholder: "Email",
                    text: $viewModel.email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    isSecure: false
                )
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                
                // Password field
                AuthTextField(
                    placeholder: "Password",
                    text: $viewModel.password,
                    icon: "lock.fill",
                    keyboardType: .default,
                    textContentType: viewModel.isLoginMode ? .password : .newPassword,
                    isSecure: true
                )
                .focused($focusedField, equals: .password)
                .submitLabel(viewModel.isSignupMode ? .next : .go)
                .onSubmit {
                    if viewModel.isSignupMode {
                        focusedField = .confirmPassword
                    } else {
                        Task { await viewModel.performAuthAction() }
                    }
                }
                
                // Confirm password (signup only)
                if viewModel.isSignupMode {
                    AuthTextField(
                        placeholder: "Confirm Password",
                        text: $viewModel.confirmPassword,
                        icon: "lock.fill",
                        keyboardType: .default,
                        textContentType: .newPassword,
                        isSecure: true
                    )
                    .focused($focusedField, equals: .confirmPassword)
                    .submitLabel(.go)
                    .onSubmit {
                        Task { await viewModel.performAuthAction() }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.authMode)
            
            // Error message with contextual actions
            if viewModel.showError, let errorMessage = viewModel.errorMessage {
                ErrorBanner(
                    message: errorMessage,
                    onDismiss: { viewModel.clearError() },
                    actionTitle: errorActionTitle,
                    onAction: errorAction
                )
            }
            
            // Primary action button
            primaryActionButton
                .padding(.top, 8)
            
            // Forgot password link (login mode only)
            if viewModel.isLoginMode {
                Button {
                    showForgotPassword = true
                } label: {
                    Text("Forgot Password?")
                        .font(BWTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.bwPrimary)
                }
                .padding(.top, 8)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemBackground))
                .shadow(
                    color: colorScheme == .dark ? .clear : Color.black.opacity(0.06),
                    radius: 20,
                    x: 0,
                    y: 10
                )
        )
        .opacity(contentOpacity)
        .offset(y: contentOffset)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet(
                initialEmail: viewModel.email,
                onDismiss: { showForgotPassword = false }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Auth Mode Picker
    
    private var authModePicker: some View {
        HStack(spacing: 0) {
            ForEach(AuthMode.allCases, id: \.self) { mode in
                Button {
                    viewModel.setMode(mode)
                } label: {
                    Text(mode.rawValue)
                        .font(BWTypography.buttonSmall)
                        .fontWeight(viewModel.authMode == mode ? .semibold : .medium)
                        .foregroundColor(viewModel.authMode == mode 
                                        ? .white 
                                        : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if viewModel.authMode == mode {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.bwPrimary, Color.bwSecondary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: Color.bwPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(.tertiarySystemBackground))
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.authMode)
    }
    
    // MARK: - Primary Action Button
    
    private var primaryActionButton: some View {
        Button {
            focusedField = nil
            Task { await viewModel.performAuthAction() }
        } label: {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: viewModel.isLoginMode ? "arrow.right" : "person.badge.plus")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Text(viewModel.primaryButtonTitle)
                        .font(BWTypography.buttonLabel)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if viewModel.isLoading {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.bwPrimary.opacity(0.6))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(BWGradients.accentGradient(for: colorScheme))
                    }
                }
            )
            .shadow(
                color: colorScheme == .dark ? .clear : Color.bwAccent.opacity(0.3),
                radius: viewModel.isLoading ? 0 : 12,
                x: 0,
                y: viewModel.isLoading ? 0 : 6
            )
        }
        .disabled(viewModel.isLoading)
        .buttonStyle(BWPressableButtonStyle(scale: 0.97, enableHaptics: !viewModel.isLoading))
    }
    
    // MARK: - Switch Mode Footer
    
    private var switchModeFooter: some View {
        HStack(spacing: 4) {
            Text(viewModel.switchModePrompt)
                .font(BWTypography.caption)
                .foregroundColor(.secondary)
            
            Button {
                viewModel.toggleMode()
            } label: {
                Text(viewModel.switchModeAction)
                    .font(BWTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.bwPrimary)
            }
        }
        .opacity(contentOpacity)
    }
    
    // MARK: - Animation Sequence
    
    private func startAnimations() {
        // Logo entrance
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Content reveal
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.3)) {
            contentOpacity = 1.0
            contentOffset = 0
        }
    }
}

// MARK: - Check Email View

struct CheckEmailView: View {
    let email: String
    let isLoading: Bool
    let successMessage: String?
    let resendCooldown: Int
    let resendButtonText: String
    let onResendEmail: () -> Void
    let onBackToLogin: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @State private var pulseScale: CGFloat = 1.0
    
    /// Whether resend is disabled (loading or cooling down)
    private var isResendDisabled: Bool {
        isLoading || resendCooldown > 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated envelope icon
            envelopeIcon
                .padding(.bottom, 32)
            
            // Success message (for resend confirmation)
            if let message = successMessage {
                SuccessBanner(message: message, onDismiss: nil)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Title
            Text("Check your email")
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
                Text("We sent a verification link to")
                    .font(BWTypography.bodySecondary)
                    .foregroundColor(.secondary)
                
                Text(email)
                    .font(BWTypography.bodyEmphasis)
                    .foregroundColor(.primary)
            }
            .multilineTextAlignment(.center)
            .opacity(contentOpacity)
            .offset(y: contentOffset)
            .padding(.bottom, 24)
            
            // Instruction
            Text("Tap the link in your email to verify your account")
                .font(BWTypography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(contentOpacity)
                .offset(y: contentOffset)
            
            Spacer()
            
            // Actions
            VStack(spacing: 16) {
                // Resend email button
                Button {
                    onResendEmail()
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.bwPrimary))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "envelope.arrow.triangle.branch")
                                .font(.system(size: 15, weight: .medium))
                        }
                        Text(resendButtonText)
                            .font(BWTypography.buttonSmall)
                    }
                    .foregroundColor(isResendDisabled ? .secondary : Color.bwPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isResendDisabled ? Color.secondary.opacity(0.1) : Color.bwPrimary.opacity(0.1))
                    )
                }
                .disabled(isResendDisabled)
                .buttonStyle(BWPressableButtonStyle(scale: 0.97, enableHaptics: !isLoading))
                
                // Back to login
                Button {
                    onBackToLogin()
                } label: {
                    Text("Back to sign in")
                        .font(BWTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
            .opacity(contentOpacity)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Envelope Icon
    
    private var envelopeIcon: some View {
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
            
            // Envelope icon
            Image(systemName: "envelope.badge.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 55)
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

// MARK: - Auth Logo View

struct AuthLogoView: View {
    let scale: CGFloat
    let opacity: Double
    
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Subtle glow
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
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(pulseScale)
            
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.bwPrimary.opacity(0.15), Color.bwPrimary.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 130, height: 130)
            
            // Main circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 110, height: 110)
                .shadow(color: Color.bwPrimary.opacity(0.15), radius: 20, x: 0, y: 10)
                .shadow(color: Color.bwPrimary.opacity(0.08), radius: 8, x: 0, y: 4)
            
            // Leaf icon
            Image(systemName: "leaf.fill")
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
                .shadow(color: Color.bwPrimary.opacity(0.2), radius: 6, x: 0, y: 3)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
        }
    }
}

// MARK: - Auth Animated Background

struct AuthAnimatedBackground: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var gradientOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Base gradient - adaptive
            Group {
                if colorScheme == .dark {
                    Color(.systemBackground)
                } else {
                    LinearGradient(
                        colors: [
                            Color.bwSurface,
                            Color.bwBackgroundPeach,
                            Color.bwSurface.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .ignoresSafeArea()
            
            // Floating accent shapes
            GeometryReader { geometry in
                // Top right accent
                Circle()
                    .fill(Color.bwPrimary.opacity(0.06))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(
                        x: geometry.size.width * 0.4 + gradientOffset * 0.3,
                        y: -80 - gradientOffset * 0.2
                    )
                
                // Bottom left accent
                Circle()
                    .fill(Color.bwAccent.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .offset(
                        x: -80 - gradientOffset * 0.2,
                        y: geometry.size.height * 0.5 + gradientOffset * 0.3
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                gradientOffset = 20
            }
        }
    }
}

// MARK: - Success Banner

struct SuccessBanner: View {
    let message: String
    let onDismiss: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.bwSuccess)
            
            Text(message)
                .font(BWTypography.caption)
                .foregroundColor(.bwSuccess)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.bwSuccess.opacity(0.12))
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .opacity
        ))
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.bwError)
                
                Text(message)
                    .font(BWTypography.caption)
                    .foregroundColor(.bwError)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            
            // Optional action button (for "Go to Login" or "Retry")
            if let actionTitle = actionTitle, let onAction = onAction {
                Button {
                    onAction()
                } label: {
                    Text(actionTitle)
                        .font(BWTypography.buttonSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.bwPrimary)
                        )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.bwError.opacity(0.1))
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .opacity
        ))
    }
}

// MARK: - Auth Text Field Component

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let isSecure: Bool
    
    @State private var isSecureTextHidden: Bool = true
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? Color.bwPrimary : .secondary)
                .frame(width: 24)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            // Text field
            Group {
                if isSecure && isSecureTextHidden {
                    SecureField(placeholder, text: $text)
                        .textContentType(textContentType)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textContentType(textContentType)
                }
            }
            .font(BWTypography.bodyPrimary)
            .focused($isFocused)
            
            // Toggle visibility for password fields
            if isSecure {
                Button {
                    isSecureTextHidden.toggle()
                } label: {
                    Image(systemName: isSecureTextHidden ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isFocused 
                        ? Color.bwPrimary.opacity(0.5) 
                        : Color.clear,
                    lineWidth: 1.5
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Onboarding Auth View
// Specialized auth view for the onboarding flow - defaults to signup with contextual messaging

struct OnboardingAuthView: View {
    @StateObject private var viewModel: AuthViewModel
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.colorScheme) var colorScheme
    
    var onComplete: () -> Void
    var onSkip: (() -> Void)?
    
    init(onComplete: @escaping () -> Void, onSkip: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onSkip = onSkip
        // Initialize with signup state
        _viewModel = StateObject(wrappedValue: AuthViewModel(initialState: .signup))
    }
    
    var body: some View {
        ZStack {
            // Animated background
            AuthAnimatedBackground()
            
            // Content based on auth state
            switch viewModel.authState {
            case .login, .signup, .verifiedAwaitingLogin:
                OnboardingAuthFormView(viewModel: viewModel, onSkip: onSkip)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
            case .awaitingEmailVerification(let email):
                CheckEmailView(
                    email: email,
                    isLoading: viewModel.isLoading,
                    successMessage: viewModel.showSuccess ? viewModel.successMessage : nil,
                    resendCooldown: viewModel.resendCooldownRemaining,
                    resendButtonText: viewModel.resendButtonText,
                    onResendEmail: {
                        Task { await viewModel.resendVerificationEmail() }
                    },
                    onBackToLogin: {
                        viewModel.backToLogin()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.authState)
        .navigationBarBackButtonHidden(false)
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                // Update local profile with auth user data (for login flow)
                if let user = authService.currentUser {
                    var profile = DataManager.shared.userProfile
                    // Only update email if not already set (signup already sets both)
                    if let email = user.email, profile.email.isEmpty {
                        profile.email = email
                    }
                    // Try to get name from user metadata if local profile name is empty
                    if profile.name.isEmpty, let metadata = user.userMetadata["name"] {
                        if case .string(let name) = metadata {
                            profile.name = name
                        }
                    }
                    DataManager.shared.userProfile = profile
                    DataManager.shared.saveUserProfile()
                }
                
                // Successfully signed in - proceed to completion
                BWHaptics.success()
                onComplete()
            }
        }
    }
}

// MARK: - Onboarding Auth Form View

struct OnboardingAuthFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focusedField: OnboardingAuthField?
    
    var onSkip: (() -> Void)?
    
    // Animation states
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 30
    
    // Forgot password state
    @State private var showForgotPassword = false
    
    private enum OnboardingAuthField {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                // Progress indicator
                progressIndicator
                    .padding(.bottom, 24)
                
                // Logo section (smaller for onboarding)
                smallLogoSection
                    .padding(.bottom, 24)
                
                // Success banner (shown after email verification)
                if viewModel.showSuccess, let message = viewModel.successMessage {
                    SuccessBanner(message: message) {
                        viewModel.clearSuccess()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Title
                titleSection
                    .padding(.bottom, 8)
                
                // Subtitle
                subtitleSection
                    .padding(.bottom, 28)
                
                // Auth form card
                authFormCard
                    .padding(.horizontal, 24)
                
                // Switch mode footer
                switchModeFooter
                    .padding(.top, 20)
                
                // Skip / Guest mode option
                if let onSkip = onSkip {
                    skipButton(action: onSkip)
                        .padding(.top, 16)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            startAnimations()
        }
        .onTapGesture {
            focusedField = nil
        }
    }
    
    // MARK: - Skip Button
    
    private func skipButton(action: @escaping () -> Void) -> some View {
        Button {
            BWHaptics.lightImpact()
            action()
        } label: {
            Text("Continue as Guest")
                .font(BWTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .opacity(contentOpacity)
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                Capsule()
                    .fill(index == 3 ? Color.bwPrimary : Color.bwPrimary.opacity(0.3))
                    .frame(width: index == 3 ? 24 : 8, height: 4)
            }
        }
        .opacity(contentOpacity)
    }
    
    // MARK: - Small Logo Section
    
    private var smallLogoSection: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.bwPrimary.opacity(0.1),
                            Color.bwPrimary.opacity(0.03),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .shadow(color: Color.bwPrimary.opacity(0.12), radius: 15, x: 0, y: 8)
            
            Image(systemName: "leaf.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.bwPrimary, Color.bwSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
    }
    
    // MARK: - Title Section
    
    private var titleSection: some View {
        Text(viewModel.isLoginMode ? "Welcome back" : "Almost there!")
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
    }
    
    // MARK: - Subtitle Section
    
    private var subtitleSection: some View {
        Text(viewModel.isLoginMode 
             ? "Sign in to access your saved preferences" 
             : "Create your account to save your preferences")
            .font(BWTypography.bodySecondary)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .opacity(contentOpacity)
            .offset(y: contentOffset)
    }
    
    // MARK: - Auth Form Card
    
    private var authFormCard: some View {
        VStack(spacing: 18) {
            // Mode picker
            authModePicker
            
            // Form fields
            VStack(spacing: 14) {
                if viewModel.isSignupMode {
                    AuthTextField(
                        placeholder: "Full Name",
                        text: $viewModel.name,
                        icon: "person.fill",
                        keyboardType: .default,
                        textContentType: .name,
                        isSecure: false
                    )
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
                
                AuthTextField(
                    placeholder: "Email",
                    text: $viewModel.email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    isSecure: false
                )
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                
                AuthTextField(
                    placeholder: "Password",
                    text: $viewModel.password,
                    icon: "lock.fill",
                    keyboardType: .default,
                    textContentType: viewModel.isLoginMode ? .password : .newPassword,
                    isSecure: true
                )
                .focused($focusedField, equals: .password)
                .submitLabel(viewModel.isSignupMode ? .next : .go)
                .onSubmit {
                    if viewModel.isSignupMode {
                        focusedField = .confirmPassword
                    } else {
                        Task { await viewModel.performAuthAction() }
                    }
                }
                
                if viewModel.isSignupMode {
                    AuthTextField(
                        placeholder: "Confirm Password",
                        text: $viewModel.confirmPassword,
                        icon: "lock.fill",
                        keyboardType: .default,
                        textContentType: .newPassword,
                        isSecure: true
                    )
                    .focused($focusedField, equals: .confirmPassword)
                    .submitLabel(.go)
                    .onSubmit {
                        Task { await viewModel.performAuthAction() }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.authMode)
            
            // Error message with contextual actions
            if viewModel.showError, let errorMessage = viewModel.errorMessage {
                ErrorBanner(
                    message: errorMessage,
                    onDismiss: { viewModel.clearError() },
                    actionTitle: errorActionTitle,
                    onAction: errorAction
                )
            }
            
            // Primary action button
            primaryActionButton
                .padding(.top, 6)
            
            // Forgot password link (login mode only)
            if viewModel.isLoginMode {
                Button {
                    showForgotPassword = true
                } label: {
                    Text("Forgot Password?")
                        .font(BWTypography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color.bwPrimary)
                }
                .padding(.top, 6)
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemBackground))
                .shadow(
                    color: colorScheme == .dark ? .clear : Color.black.opacity(0.05),
                    radius: 18,
                    x: 0,
                    y: 8
                )
        )
        .opacity(contentOpacity)
        .offset(y: contentOffset)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordSheet(
                initialEmail: viewModel.email,
                onDismiss: { showForgotPassword = false }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Error Action Helpers
    
    /// Title for error action button (if applicable)
    private var errorActionTitle: String? {
        if viewModel.showGoToLoginOption {
            return "Go to Sign In"
        } else if viewModel.canRetry {
            return "Try Again"
        }
        return nil
    }
    
    /// Action for error action button (if applicable)
    private var errorAction: (() -> Void)? {
        if viewModel.showGoToLoginOption {
            return { viewModel.goToLoginFromDuplicateError() }
        } else if viewModel.canRetry {
            return { Task { await viewModel.retryLastAction() } }
        }
        return nil
    }
    
    // MARK: - Auth Mode Picker
    
    private var authModePicker: some View {
        HStack(spacing: 0) {
            ForEach(AuthMode.allCases, id: \.self) { mode in
                Button {
                    viewModel.setMode(mode)
                } label: {
                    Text(mode.rawValue)
                        .font(BWTypography.buttonSmall)
                        .fontWeight(viewModel.authMode == mode ? .semibold : .medium)
                        .foregroundColor(viewModel.authMode == mode ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            Group {
                                if viewModel.authMode == mode {
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.bwPrimary, Color.bwSecondary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: Color.bwPrimary.opacity(0.25), radius: 6, x: 0, y: 3)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(.tertiarySystemBackground))
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.authMode)
    }
    
    // MARK: - Primary Action Button
    
    private var primaryActionButton: some View {
        Button {
            focusedField = nil
            Task { await viewModel.performAuthAction() }
        } label: {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: viewModel.isLoginMode ? "arrow.right" : "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Text(viewModel.isLoginMode ? "Sign In" : "Create Account")
                        .font(BWTypography.buttonLabel)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if viewModel.isLoading {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.bwPrimary.opacity(0.6))
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(BWGradients.accentGradient(for: colorScheme))
                    }
                }
            )
            .shadow(
                color: colorScheme == .dark ? .clear : Color.bwAccent.opacity(0.25),
                radius: viewModel.isLoading ? 0 : 10,
                x: 0,
                y: viewModel.isLoading ? 0 : 5
            )
        }
        .disabled(viewModel.isLoading)
        .buttonStyle(BWPressableButtonStyle(scale: 0.97, enableHaptics: !viewModel.isLoading))
    }
    
    // MARK: - Switch Mode Footer
    
    private var switchModeFooter: some View {
        HStack(spacing: 4) {
            Text(viewModel.switchModePrompt)
                .font(BWTypography.caption)
                .foregroundColor(.secondary)
            
            Button {
                viewModel.toggleMode()
            } label: {
                Text(viewModel.switchModeAction)
                    .font(BWTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.bwPrimary)
            }
        }
        .opacity(contentOpacity)
    }
    
    // MARK: - Animation Sequence
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            contentOpacity = 1.0
            contentOffset = 0
        }
    }
}

// MARK: - Forgot Password Sheet

struct ForgotPasswordSheet: View {
    let initialEmail: String
    let onDismiss: () -> Void
    
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Group {
                    if colorScheme == .dark {
                        Color(.systemBackground)
                    } else {
                        Color.bwSurface
                    }
                }
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.bwPrimary.opacity(0.1),
                                        Color.bwPrimary.opacity(0.03),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 140, height: 140)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.bwPrimary.opacity(0.12), radius: 15, x: 0, y: 8)
                        
                        Image(systemName: "key.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.bwPrimary, Color.bwSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    // Title and description
                    VStack(spacing: 8) {
                        Text("Reset Password")
                            .font(BWTypography.sectionHeader)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.bwPrimary, Color.bwSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(BWTypography.bodySecondary)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Email input
                    VStack(spacing: 16) {
                        HStack(spacing: 14) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isEmailFocused ? Color.bwPrimary : .secondary)
                                .frame(width: 24)
                            
                            TextField("Email address", text: $email)
                                .font(BWTypography.bodyPrimary)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($isEmailFocused)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.tertiarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    isEmailFocused ? Color.bwPrimary.opacity(0.5) : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                        .padding(.horizontal, 24)
                        
                        // Error message
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 14))
                                Text(error)
                                    .font(BWTypography.caption)
                            }
                            .foregroundColor(Color.bwError)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                        }
                        
                        // Success message
                        if let success = successMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                Text(success)
                                    .font(BWTypography.caption)
                            }
                            .foregroundColor(Color.bwSuccess)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                        }
                    }
                    
                    // Send button
                    Button {
                        sendResetLink()
                    } label: {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text("Send Reset Link")
                                    .font(BWTypography.buttonLabel)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    canSend
                                        ? BWGradients.accentGradient(for: colorScheme)
                                        : LinearGradient(colors: [Color.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                                )
                        )
                        .shadow(
                            color: colorScheme == .dark ? .clear : (canSend ? Color.bwPrimary.opacity(0.25) : .clear),
                            radius: 10,
                            x: 0,
                            y: 5
                        )
                    }
                    .disabled(!canSend || isLoading)
                    .buttonStyle(BWPressableButtonStyle(scale: 0.97, enableHaptics: canSend && !isLoading))
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(Color.bwPrimary)
                }
            }
        }
        .onAppear {
            email = initialEmail
        }
        .animation(.bwSnappy, value: errorMessage)
        .animation(.bwSnappy, value: successMessage)
    }
    
    private var canSend: Bool {
        let emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
        return email.wholeMatch(of: emailRegex) != nil
    }
    
    private func sendResetLink() {
        guard canSend else { return }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        isEmailFocused = false
        
        Task {
            do {
                try await AuthService.shared.sendPasswordResetEmail(to: email)
                
                await MainActor.run {
                    BWHaptics.success()
                    successMessage = "If an account exists for this email, you'll receive a reset link shortly."
                    isLoading = false
                    
                    // Auto-dismiss after success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        onDismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    BWHaptics.error()
                    if let authError = error as? AuthError {
                        switch authError {
                        case .rateLimited, .networkError, .invalidEmail:
                            errorMessage = authError.errorDescription
                        default:
                            successMessage = "If an account exists for this email, you'll receive a reset link shortly."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                onDismiss()
                            }
                        }
                    } else {
                        errorMessage = "Unable to send reset link. Please try again."
                    }
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Login") {
    AuthView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    AuthView()
        .preferredColorScheme(.dark)
}

#Preview("Check Email") {
    ZStack {
        AuthAnimatedBackground()
        CheckEmailView(
            email: "test@example.com",
            isLoading: false,
            successMessage: nil,
            resendCooldown: 0,
            resendButtonText: "Resend Email",
            onResendEmail: {},
            onBackToLogin: {}
        )
    }
}

#Preview("Onboarding Auth") {
    NavigationStack {
        OnboardingAuthView {
            print("Completed!")
        }
    }
}

#Preview("Forgot Password") {
    ForgotPasswordSheet(
        initialEmail: "test@example.com",
        onDismiss: {}
    )
}
