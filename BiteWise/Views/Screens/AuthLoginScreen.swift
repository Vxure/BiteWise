import SwiftUI

struct AuthLoginScreen: View {
    @ObservedObject var viewModel: AuthViewModel
    var onSignUp: () -> Void
    var onForgotPassword: () -> Void
    var onMagicLinkSent: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var showPassword = false
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @FocusState private var focusedField: Field?
    
    private enum Field: Hashable {
        case email, password
    }
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(.systemBackground) : Color.white)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, 40)
                        .padding(.bottom, 32)
                    
                    bannersSection
                    
                    formSection
                        .padding(.bottom, 24)
                    
                    dividerSection
                        .padding(.bottom, 24)
                    
                    socialSection
                        .padding(.bottom, 32)
                    
                    footerSection
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .opacity(contentOpacity)
            .offset(y: contentOffset)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.setMode(.login)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
        }
        .onChange(of: viewModel.authState) { _, newState in
            if case .awaitingMagicLink = newState {
                onMagicLinkSent()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Welcome Back")
                .font(BWTypography.displayMedium)
                .foregroundColor(.primary)
            
            Text("Sign in to continue")
                .font(BWTypography.bodyPrimary)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Banners
    
    private var bannersSection: some View {
        VStack(spacing: 8) {
            if viewModel.showError, let message = viewModel.errorMessage {
                ErrorBanner(
                    message: message,
                    onDismiss: { viewModel.clearError() },
                    actionTitle: viewModel.showGoToLoginOption ? "Go to Sign In" : (viewModel.canRetry ? "Try Again" : nil),
                    onAction: viewModel.showGoToLoginOption
                        ? { viewModel.goToLoginFromDuplicateError() }
                        : (viewModel.canRetry ? { Task<Void, Never> { await viewModel.retryLastAction() } } : nil)
                )
                .padding(.bottom, 12)
            }
            
            if viewModel.showSuccess, let message = viewModel.successMessage {
                SuccessBanner(message: message, onDismiss: { viewModel.clearSuccess() })
                    .padding(.bottom, 12)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showError)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showSuccess)
    }
    
    // MARK: - Form
    
    private var formSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(BWTypography.caption)
                    .foregroundColor(.secondary)
                
                TextField("your@email.com", text: $viewModel.email)
                    .font(BWTypography.bodyPrimary)
                    .padding(16)
                    .background(fieldBackground)
                    .overlay(fieldBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .email)
                    .submitLabel(showPassword ? .next : .send)
                    .onSubmit {
                        if showPassword {
                            focusedField = .password
                        } else {
                            sendMagicLink()
                        }
                    }
            }
            
            if showPassword {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(BWTypography.caption)
                        .foregroundColor(.secondary)
                    
                    SecureField("Enter password", text: $viewModel.password)
                        .font(BWTypography.bodyPrimary)
                        .padding(16)
                        .background(fieldBackground)
                        .overlay(fieldBorder)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { loginWithPassword() }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
                
                HStack {
                    Spacer()
                    Button {
                        BWHaptics.lightImpact()
                        onForgotPassword()
                    } label: {
                        Text("Forgot Password?")
                            .font(BWTypography.caption)
                            .foregroundColor(Color.bwPrimary)
                    }
                }
            }
            
            primaryButton
                .padding(.top, 8)
            
            modeToggle
        }
    }
    
    // MARK: - Primary Button
    
    private var primaryButton: some View {
        Button {
            if showPassword {
                loginWithPassword()
            } else {
                sendMagicLink()
            }
        } label: {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: showPassword ? "arrow.right" : "envelope.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(showPassword ? "Sign In" : "Sign in with email")
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
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.8 : 1.0)
        .buttonStyle(.bwPressable)
    }
    
    // MARK: - Mode Toggle
    
    private var modeToggle: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showPassword.toggle()
                if !showPassword {
                    viewModel.password = ""
                    focusedField = nil
                }
                viewModel.clearError()
            }
            BWHaptics.lightImpact()
        } label: {
            Text(showPassword ? "Use magic link instead" : "Use password instead")
                .font(BWTypography.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Divider
    
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            Text("Or continue with")
                .font(BWTypography.caption)
                .foregroundColor(.secondary)
                .fixedSize()
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    // MARK: - Social Login (non-functional)
    
    private var socialSection: some View {
        VStack(spacing: 12) {
            Button(action: {}) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 18))
                    Text("Continue with Google")
                        .font(BWTypography.buttonLabel)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(colorScheme == .dark
                              ? Color(.secondarySystemBackground)
                              : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.bwPressable)
            
            Button(action: {}) {
                HStack(spacing: 12) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18))
                    Text("Continue with Apple")
                        .font(BWTypography.buttonLabel)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.black)
                )
            }
            .buttonStyle(.bwPressable)
        }
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(BWTypography.bodySecondary)
                .foregroundColor(.secondary)
            
            Button("Sign up") {
                BWHaptics.lightImpact()
                onSignUp()
            }
            .font(BWTypography.bodySecondary)
            .foregroundColor(Color.bwPrimary)
        }
    }
    
    // MARK: - Helpers
    
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(colorScheme == .dark
                  ? Color(.secondarySystemBackground)
                  : Color(.systemGray6))
    }
    
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }
    
    private func sendMagicLink() {
        focusedField = nil
        Task { await viewModel.sendMagicLink() }
    }
    
    private func loginWithPassword() {
        focusedField = nil
        Task { await viewModel.login() }
    }
}

#Preview {
    AuthLoginScreen(
        viewModel: AuthViewModel(initialState: .login),
        onSignUp: {},
        onForgotPassword: {},
        onMagicLinkSent: {}
    )
}
