import SwiftUI

struct AuthWelcomeScreen: View {
    var onLogin: () -> Void
    var onRegister: () -> Void
    var onDevSkip: (() -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    
    @State private var mascotScale: CGFloat = 0.8
    @State private var mascotOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @State private var buttonsOpacity: Double = 0
    
    @State private var isJumping = false
    @State private var mascotOffsetY: CGFloat = 0
    @State private var plateOffsetY: CGFloat = 0
    @State private var plateScaleX: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Group {
                if colorScheme == .dark {
                    Color(.systemBackground)
                } else {
                    BWGradients.backgroundGradient
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                mascotSection
                    .padding(.bottom, 32)
                
                titleSection
                    .padding(.bottom, 48)
                
                buttonsSection
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { startAnimations() }
    }
    
    // MARK: - Mascot
    
    private var mascotSection: some View {
        VStack(spacing: 0) {
            Image("Mascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 160)
                .zIndex(1)
                .offset(y: mascotOffsetY + 90)
            
            Image("Plate")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 210)
                .offset(y: plateOffsetY - 55)
                .scaleEffect(x: plateScaleX, y: 1.0)
        }
        .scaleEffect(mascotScale)
        .opacity(mascotOpacity)
        .onTapGesture { triggerBounce() }
    }
    
    // MARK: - Title
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Welcome to Taberoux")
                .font(BWTypography.displayLarge)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.bwPrimary, Color.bwSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
            
            Text("Discover delicious recipes tailored just for you")
                .font(BWTypography.bodyPrimary)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .opacity(contentOpacity)
        .offset(y: contentOffset)
    }
    
    // MARK: - Buttons
    
    private var buttonsSection: some View {
        VStack(spacing: 16) {
            GradientButton(
                icon: "arrow.right",
                text: "Get Started",
                action: onLogin
            )
            
            Button(action: onRegister) {
                Text("Create Account")
                    .font(BWTypography.buttonLabel)
                    .foregroundColor(Color.bwPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.bwPrimary, lineWidth: 2)
                    )
            }
            .buttonStyle(.bwPressable)
            
            #if DEBUG
            if let onDevSkip {
                Button {
                    BWHaptics.lightImpact()
                    onDevSkip()
                } label: {
                    Text("Skip Auth (Dev)")
                        .font(BWTypography.caption)
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .padding(.top, 8)
            }
            #endif
        }
        .opacity(buttonsOpacity)
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
            mascotScale = 1.0
            mascotOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            triggerBounce()
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.4)) {
            contentOpacity = 1.0
            contentOffset = 0
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.6)) {
            buttonsOpacity = 1.0
        }
    }
    
    private func triggerBounce() {
        guard !isJumping else { return }
        isJumping = true
        
        withAnimation(.easeOut(duration: 0.3)) { mascotOffsetY = -40 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.2)) { mascotOffsetY = 0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.1)) {
                plateOffsetY = 10
                plateScaleX = 1.05
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                plateOffsetY = 0
                plateScaleX = 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { isJumping = false }
    }
}

#Preview {
    AuthWelcomeScreen(onLogin: {}, onRegister: {})
}
