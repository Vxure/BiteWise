import SwiftUI

struct OnboardingIntroductionScreen: View {
    var onContinue: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    @State private var imageOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 30
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geometry in
                Image("OnboardingSplash")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .opacity(imageOpacity)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.6),
                                Color.black.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("Welcome to Your\nCulinary Journey")
                    .font(BWTypography.displayLarge)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)
                
                Text("Discover personalized recipes, track your nutrition, and cook amazing meals with AI-powered assistance.")
                    .font(BWTypography.bodyPrimary)
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(4)
                    .padding(.bottom, 32)
                
                pageDots
                    .padding(.bottom, 24)
                
                Button(action: {
                    BWHaptics.mediumImpact()
                    onContinue()
                }) {
                    Text("Continue")
                        .font(BWTypography.buttonLabel)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.bwSecondary)
                        )
                        .shadow(color: Color.bwSecondary.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.bwPressable)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
            .opacity(contentOpacity)
            .offset(y: contentOffset)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                imageOpacity = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
        }
    }
    
    private var pageDots: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 8, height: 8)
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OnboardingIntroductionScreen(onContinue: {})
}
