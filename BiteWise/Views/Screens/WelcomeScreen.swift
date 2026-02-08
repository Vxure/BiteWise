import SwiftUI

struct WelcomeScreen: View {
    var onGetStarted: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    // Animation states
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var logoRotation: Double = -10
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 15
    @State private var benefitsOpacity: Double = 0
    @State private var benefitsOffset: CGFloat = 15
    @State private var buttonOffset: CGFloat = 60
    @State private var buttonOpacity: Double = 0
    
    // Mascot bounce animation states
    @State private var mascotOffsetY: CGFloat = 0
    @State private var plateOffsetY: CGFloat = 0
    @State private var plateScaleX: CGFloat = 1.0
    
    // Background animation
    @State private var gradientOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Animated gradient background
            animatedBackground
            
            VStack(spacing: 0) {
                Spacer()
                
                // Enhanced logo with layered shapes
                logoSection
                    .padding(.bottom, 40)
                
                // App name with staggered reveal
                titleSection
                    .padding(.bottom, 12)
                
                // Tagline
                subtitleSection
                
                // Key benefits
                benefitsSection
                    .padding(.top, 32)
                
                Spacer()
                
                // Enhanced Get Started button
                buttonSection
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animated Background
    private var animatedBackground: some View {
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
            
            // Animated floating shapes
            GeometryReader { geometry in
                // Top right accent
                Circle()
                    .fill(Color.bwPrimary.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(
                        x: geometry.size.width * 0.3 + gradientOffset * 0.5,
                        y: -100 - gradientOffset * 0.3
                    )
                
                // Bottom left accent
                Circle()
                    .fill(Color.bwAccent.opacity(0.06))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(
                        x: -100 - gradientOffset * 0.3,
                        y: geometry.size.height * 0.6 + gradientOffset * 0.4
                    )
                
                // Center subtle glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.bwProtein.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .scaleEffect(pulseScale)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.35)
            }
        }
        .onAppear {
            // Subtle continuous animation
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                gradientOffset = 30
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
    
    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: 0) {
            // Mascot - sits on top of the plate
            Image("Mascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140)
                .zIndex(1)
                .offset(y: mascotOffsetY + 90) // push mascot down onto plate
            
            // Plate - right below mascot
            Image("Plate")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 190)
                .offset(y: plateOffsetY - 55) // pull plate up under mascot
                .scaleEffect(x: plateScaleX, y: 1.0)
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
        .rotationEffect(.degrees(logoRotation))
        .onTapGesture {
            triggerBounce()
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        Text("Taberoux")
            .font(BWTypography.heroTitle)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.bwPrimary, Color.bwSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .opacity(titleOpacity)
            .offset(y: titleOffset)
    }
    
    // MARK: - Subtitle Section
    private var subtitleSection: some View {
        Text("Personalized recipes, minus the thinking.")
            .font(BWTypography.bodySecondary)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .opacity(subtitleOpacity)
            .offset(y: subtitleOffset)
    }
    
    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            benefitRow(icon: "camera.fill", text: "Snap your fridge, get instant recipe ideas")
            benefitRow(icon: "chart.pie.fill", text: "Track macros tailored to your goals")
            benefitRow(icon: "sparkles", text: "AI assistant for cooking help anytime")
        }
        .padding(.horizontal, 8)
        .opacity(benefitsOpacity)
        .offset(y: benefitsOffset)
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.bwPrimary)
                .frame(width: 24)
            
            Text(text)
                .font(BWTypography.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Button Section
    private var buttonSection: some View {
        GradientButton(
            icon: "arrow.right",
            text: "Get Started",
            action: onGetStarted
        )
        .offset(y: buttonOffset)
        .opacity(buttonOpacity)
    }
    
    // MARK: - Animation Sequence
    private func startAnimations() {
        // Logo entrance - spring with rotation
        withAnimation(.spring(response: 0.9, dampingFraction: 0.7).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
            logoRotation = 0
        }
        
        // Mascot bounce after logo settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            triggerBounce()
        }
        
        // Title reveal
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.5)) {
            titleOpacity = 1.0
            titleOffset = 0
        }
        
        // Subtitle reveal
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.65)) {
            subtitleOpacity = 1.0
            subtitleOffset = 0
        }
        
        // Benefits reveal
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.8)) {
            benefitsOpacity = 1.0
            benefitsOffset = 0
        }
        
        // Button entrance
        withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(1.0)) {
            buttonOffset = 0
            buttonOpacity = 1.0
        }
    }
    
    // MARK: - Mascot Bounce Animation
    @State private var isBouncing = false
    
    private func triggerBounce() {
        guard !isBouncing else { return }
        isBouncing = true
        
        // Phase 1: Mascot jumps up off the plate
        withAnimation(.easeOut(duration: 0.3)) {
            mascotOffsetY = -40
        }
        
        // Phase 2: Mascot falls back down
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.2)) {
                mascotOffsetY = 0
            }
        }
        
        // Phase 3: Plate recoils down on impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.1)) {
                plateOffsetY = 10
                plateScaleX = 1.05
            }
        }
        
        // Phase 4: Everything springs back to rest
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                plateOffsetY = 0
                plateScaleX = 1.0
            }
        }
        
        // Allow re-trigger after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isBouncing = false
        }
    }
}

#Preview {
    WelcomeScreen(onGetStarted: {})
}
