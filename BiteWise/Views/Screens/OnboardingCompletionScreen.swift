import SwiftUI

/// Celebration screen shown when onboarding completes
/// Guides the user to their first scan action
struct OnboardingCompletionScreen: View {
    var onComplete: () -> Void
    var onScanNow: () -> Void
    
    // Animation states
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var buttonsOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 30
    @State private var confettiVisible = false
    
    var body: some View {
        ZStack {
            // Background gradient
            BWGradients.backgroundGradient
                .ignoresSafeArea()
            
            // Confetti-like decorative elements
            if confettiVisible {
                ConfettiView()
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // Checkmark celebration
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.bwPrimary.opacity(0.15),
                                    Color.bwPrimary.opacity(0.05),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.bwPrimary, Color.bwSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.bwPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(checkmarkScale)
                .opacity(checkmarkOpacity)
                .padding(.bottom, 40)
                
                // Success text
                VStack(spacing: 12) {
                    Text("You're All Set!")
                        .font(BWTypography.heroTitle)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.bwPrimary, Color.bwSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Your preferences are saved. Now let's discover some delicious recipes!")
                        .font(BWTypography.bodySecondary)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    // Primary action - Scan fridge
                    GradientButton(
                        icon: "camera.fill",
                        text: "Scan My Fridge",
                        action: onScanNow
                    )
                    
                    // Secondary action - Go to dashboard
                    Button(action: onComplete) {
                        HStack(spacing: 6) {
                            Text("Explore Dashboard First")
                                .font(.bwSubheadline())
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.secondary)
                        .padding(.vertical, 14)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .opacity(buttonsOpacity)
                .offset(y: buttonsOffset)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Checkmark bounce in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
            checkmarkScale = 1.0
            checkmarkOpacity = 1.0
        }
        
        // Confetti
        withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
            confettiVisible = true
        }
        
        // Text reveal
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.5)) {
            textOpacity = 1.0
            textOffset = 0
        }
        
        // Buttons reveal
        withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.7)) {
            buttonsOpacity = 1.0
            buttonsOffset = 0
        }
    }
}

// Simple confetti-like decorative view
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.bwPrimary, .bwAccent, .bwProtein, .bwCarbs, .bwSecondary]
        
        particles = (0..<20).map { _ in
            ConfettiParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: -50...size.height * 0.3)
                ),
                color: colors.randomElement() ?? .bwPrimary,
                size: CGFloat.random(in: 6...12),
                opacity: 0
            )
        }
    }
    
    private func animateParticles() {
        for index in particles.indices {
            let delay = Double.random(in: 0...0.5)
            
            withAnimation(.easeOut(duration: 0.3).delay(delay)) {
                particles[index].opacity = 0.8
            }
            
            withAnimation(.easeIn(duration: 2.0).delay(delay + 0.3)) {
                particles[index].position.y += 400
                particles[index].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

#Preview {
    OnboardingCompletionScreen(
        onComplete: {},
        onScanNow: {}
    )
}

