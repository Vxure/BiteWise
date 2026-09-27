import SwiftUI

struct OnboardingCongratulationsScreen: View {
    var onComplete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    @State private var mascotScale: CGFloat = 0
    @State private var mascotRotation: Double = -180
    @State private var partyScale: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var buttonOpacity: Double = 0
    @State private var buttonOffset: CGFloat = 20
    @State private var dotsOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Group {
                if colorScheme == .dark {
                    Color(.systemBackground)
                } else {
                    LinearGradient(
                        colors: [
                            Color.bwPrimary.opacity(0.08),
                            Color.bwSurface,
                            Color.white
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                mascotSection
                    .padding(.bottom, 32)
                
                titleSection
                    .padding(.bottom, 48)
                
                GradientButton(text: "Start Exploring Recipes", action: {
                    BWHaptics.success()
                    onComplete()
                })
                .opacity(buttonOpacity)
                .offset(y: buttonOffset)
                .padding(.horizontal, 24)
                
                bouncingDots
                    .padding(.top, 32)
                    .opacity(dotsOpacity)
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { startAnimations() }
    }
    
    // MARK: - Mascot
    
    private var mascotSection: some View {
        ZStack(alignment: .topTrailing) {
            Image("Mascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
            
            Image(systemName: "party.popper.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.bwProtein)
                .offset(x: 16, y: -16)
                .scaleEffect(partyScale)
        }
        .scaleEffect(mascotScale)
        .rotationEffect(.degrees(mascotRotation))
    }
    
    // MARK: - Title
    
    private var titleSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(Color.bwProtein)
                
                Text("Congratulations!")
                    .font(BWTypography.heroTitle)
                    .foregroundColor(.primary)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(Color.bwProtein)
            }
            
            Text("You're all set!")
                .font(BWTypography.sectionSubheader)
                .foregroundColor(.secondary)
            
            Text("Your personalized recipe experience is ready.\nLet's start cooking amazing meals together!")
                .font(BWTypography.bodyPrimary)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 4)
        }
        .opacity(textOpacity)
        .offset(y: textOffset)
    }
    
    // MARK: - Bouncing Dots
    
    private var bouncingDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                BouncingDot(delay: Double(index) * 0.15)
            }
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            mascotScale = 1.0
            mascotRotation = 0
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) {
            partyScale = 1.0
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            textOpacity = 1.0
            textOffset = 0
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
            buttonOpacity = 1.0
            buttonOffset = 0
        }
        withAnimation(.easeIn(duration: 0.3).delay(0.8)) {
            dotsOpacity = 1.0
        }
    }
}

// MARK: - Bouncing Dot

private struct BouncingDot: View {
    let delay: Double
    @State private var animating = false
    
    var body: some View {
        Circle()
            .fill(Color.bwPrimary)
            .frame(width: 8, height: 8)
            .offset(y: animating ? -8 : 0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    animating = true
                }
            }
    }
}

#Preview {
    OnboardingCongratulationsScreen(onComplete: {})
}
