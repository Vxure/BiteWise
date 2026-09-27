import SwiftUI

struct OnboardingNameScreen: View {
    var onContinue: () -> Void
    var onBack: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    @State private var name = ""
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @FocusState private var isNameFocused: Bool
    
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
                backButton
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Image("Mascot")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .padding(.top, 24)
                            .padding(.bottom, 24)
                        
                        OnboardingSegmentedProgressBar(currentStep: 1, totalSteps: 8)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                        
                        VStack(spacing: 8) {
                            Text("What should we call you?")
                                .font(BWTypography.displayMedium)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text("Let's personalize your experience")
                                .font(BWTypography.bodyPrimary)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 32)
                        
                        TextField("Enter your name", text: $name)
                            .font(BWTypography.bodyPrimary)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(colorScheme == .dark
                                          ? Color(.secondarySystemBackground)
                                          : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isNameFocused ? Color.bwPrimary : Color.gray.opacity(0.2), lineWidth: isNameFocused ? 2 : 1)
                            )
                            .focused($isNameFocused)
                            .textContentType(.name)
                            .padding(.horizontal, 24)
                    }
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)
                
                continueButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
    }
    
    private var backButton: some View {
        HStack {
            Button(action: { onBack?() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(BWTypography.bodyPrimary)
                }
                .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private var continueButton: some View {
        Button(action: {
            guard name.trimmingCharacters(in: .whitespaces).count > 0 else { return }
            BWHaptics.mediumImpact()
            onContinue()
        }) {
            Text("Continue")
                .font(BWTypography.buttonLabel)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(name.trimmingCharacters(in: .whitespaces).isEmpty
                              ? Color.gray.opacity(0.3)
                              : Color.bwPrimary)
                )
        }
        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        .buttonStyle(.bwPressable)
    }
}

#Preview {
    OnboardingNameScreen(onContinue: {})
}
