import SwiftUI

struct AuthRegisterScreen: View {
    @ObservedObject var viewModel: AuthViewModel
    var onSignIn: () -> Void
    var onSuccess: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @FocusState private var focusedField: Field?
    
    private enum Field: Hashable {
        case name, email, password, confirmPassword
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
            viewModel.setMode(.signup)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
        }
        .onChange(of: viewModel.authState) { _, newState in
            if case .awaitingEmailVerification = newState {
                onSuccess()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Create Account")
                .font(BWTypography.displayMedium)
                .foregroundColor(.primary)
            
            Text("Join us to get started")
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
                        ? { viewModel.goToLoginFromDuplicateError(); onSignIn() }
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
                Text("Name")
                    .font(BWTypography.caption)
                    .foregroundColor(.secondary)
                
                TextField("Your name", text: $viewModel.name)
                    .font(BWTypography.bodyPrimary)
                    .padding(16)
                    .background(fieldBackground)
                    .overlay(fieldBorder)
                    .textContentType(.name)
                    .autocapitalization(.words)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }
            }
            
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
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(BWTypography.caption)
                    .foregroundColor(.secondary)
                
                SecureField("Create a password", text: $viewModel.password)
                    .font(BWTypography.bodyPrimary)
                    .padding(16)
                    .background(fieldBackground)
                    .overlay(fieldBorder)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .confirmPassword }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(BWTypography.caption)
                    .foregroundColor(.secondary)
                
                SecureField("Confirm your password", text: $viewModel.confirmPassword)
                    .font(BWTypography.bodyPrimary)
                    .padding(16)
                    .background(fieldBackground)
                    .overlay(fieldBorder)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .submitLabel(.go)
                    .onSubmit { performSignup() }
            }
            
            signupButton
                .padding(.top, 8)
        }
    }
    
    // MARK: - Signup Button
    
    private var signupButton: some View {
        Button {
            performSignup()
        } label: {
            HStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Create Account")
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
    
    // MARK: - Divider
    
    private var dividerSection: some View {
        HStack {
            Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
            Text("Or continue with")
                .font(BWTypography.caption)
                .foregroundColor(.secondary)
                .fixedSize()
            Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
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
                        .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
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
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.black))
            }
            .buttonStyle(.bwPressable)
        }
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        HStack(spacing: 4) {
            Text("Already have an account?")
                .font(BWTypography.bodySecondary)
                .foregroundColor(.secondary)
            Button("Sign in") {
                BWHaptics.lightImpact()
                onSignIn()
            }
            .font(BWTypography.bodySecondary)
            .foregroundColor(Color.bwPrimary)
        }
    }
    
    // MARK: - Helpers
    
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemGray6))
    }
    
    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    }
    
    private func performSignup() {
        focusedField = nil
        Task { await viewModel.signup() }
    }
}

#Preview {
    AuthRegisterScreen(
        viewModel: AuthViewModel(initialState: .signup),
        onSignIn: {},
        onSuccess: {}
    )
}
