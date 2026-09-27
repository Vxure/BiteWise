import SwiftUI

struct AuthMagicLinkSentScreen: View {
    let email: String
    @ObservedObject var viewModel: AuthViewModel
    var onBackToLogin: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var iconScale: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(.systemBackground) : Color.white)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                Circle()
                    .fill(Color.bwPrimary.opacity(0.12))
                    .frame(width: 88, height: 88)
                    .overlay(
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 38))
                            .foregroundColor(Color.bwPrimary)
                    )
                    .scaleEffect(iconScale)
                    .padding(.bottom, 28)
                
                VStack(spacing: 8) {
                    Text("Check Your Email")
                        .font(BWTypography.displayMedium)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 4) {
                        Text("We sent a sign-in link to")
                            .font(BWTypography.bodyPrimary)
                            .foregroundColor(.secondary)
                        
                        Text(email)
                            .font(BWTypography.bodyEmphasis)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Tap the link in the email to sign in. It may take a minute to arrive.")
                        .font(BWTypography.bodySecondary)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                        .padding(.horizontal, 8)
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)
                .padding(.bottom, 40)
                
                VStack(spacing: 12) {
                    if viewModel.showSuccess, let message = viewModel.successMessage {
                        SuccessBanner(message: message, onDismiss: { viewModel.clearSuccess() })
                            .padding(.bottom, 4)
                    }
                    
                    if viewModel.showError, let message = viewModel.errorMessage {
                        ErrorBanner(message: message, onDismiss: { viewModel.clearError() })
                            .padding(.bottom, 4)
                    }
                    
                    Button {
                        Task { await viewModel.resendMagicLink() }
                    } label: {
                        HStack(spacing: 6) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(Color.bwPrimary)
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.resendButtonText)
                                .font(BWTypography.buttonSmall)
                                .foregroundColor(viewModel.isResendDisabled ? .secondary : Color.bwPrimary)
                        }
                        .padding(.vertical, 12)
                    }
                    .disabled(viewModel.isResendDisabled)
                    
                    Button {
                        BWHaptics.lightImpact()
                        viewModel.backToLogin()
                        onBackToLogin()
                    } label: {
                        Text("Back to Sign In")
                            .font(BWTypography.buttonSmall)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .opacity(contentOpacity)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showError)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showSuccess)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                iconScale = 1.0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
        }
    }
}

#Preview {
    AuthMagicLinkSentScreen(
        email: "test@example.com",
        viewModel: AuthViewModel(initialState: .login),
        onBackToLogin: {}
    )
}
