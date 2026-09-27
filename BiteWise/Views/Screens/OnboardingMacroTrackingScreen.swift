import SwiftUI

struct OnboardingMacroTrackingScreen: View {
    var onContinue: () -> Void
    var onSkip: (() -> Void)?
    var onBack: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    @State private var wantsTracking: Bool? = nil
    @State private var calories: Double = 2000
    @State private var protein: Double = 150
    @State private var carbs: Double = 250
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    
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
                        OnboardingSegmentedProgressBar(currentStep: 8, totalSteps: 8)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 32)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Track macros?")
                                .font(BWTypography.displayMedium)
                                .foregroundColor(.primary)
                            
                            Text("Optional: Set your daily nutrition goals")
                                .font(BWTypography.bodyPrimary)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        if wantsTracking == nil {
                            choiceSection
                                .padding(.horizontal, 24)
                        }
                        
                        if wantsTracking == true {
                            slidersSection
                                .padding(.horizontal, 24)
                        }
                    }
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)
                
                if wantsTracking == true {
                    VStack(spacing: 8) {
                        GradientButton(text: "Complete Setup", action: {
                            BWHaptics.mediumImpact()
                            onContinue()
                        })
                        
                        Button(action: { onSkip?() ?? onContinue() }) {
                            Text("Skip for now")
                                .font(BWTypography.buttonSmall)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                contentOpacity = 1.0
                contentOffset = 0
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
    
    // MARK: - Choice
    
    private var choiceSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                BWHaptics.selection()
                withAnimation(.bwSpring) { wantsTracking = true }
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Yes, I want to track macros")
                        .font(BWTypography.cardTitle)
                        .foregroundColor(.primary)
                    Text("Set daily calorie and macro goals")
                        .font(BWTypography.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.bwPressable(scale: 0.98))
            
            Button(action: {
                BWHaptics.selection()
                onSkip?() ?? onContinue()
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No, skip for now")
                        .font(BWTypography.cardTitle)
                        .foregroundColor(.primary)
                    Text("You can always set this up later")
                        .font(BWTypography.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.bwPressable(scale: 0.98))
        }
    }
    
    // MARK: - Sliders
    
    private var slidersSection: some View {
        VStack(spacing: 28) {
            macroSlider(label: "Daily Calories", value: $calories, range: 1000...4000, step: 50,
                        displayValue: "\(Int(calories))")
            
            macroSlider(label: "Protein (g)", value: $protein, range: 50...300, step: 5,
                        displayValue: "\(Int(protein))")
            
            macroSlider(label: "Carbs (g)", value: $carbs, range: 50...500, step: 10,
                        displayValue: "\(Int(carbs))")
        }
        .transition(.opacity.combined(with: .offset(y: 10)))
    }
    
    private func macroSlider(label: String, value: Binding<Double>,
                             range: ClosedRange<Double>, step: Double,
                             displayValue: String) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(label)
                    .font(BWTypography.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(displayValue)
                    .font(BWTypography.bodyEmphasis)
                    .foregroundColor(.primary)
                    .frame(width: 60, alignment: .trailing)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark
                                  ? Color(.secondarySystemBackground)
                                  : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            Slider(value: value, in: range, step: step)
                .tint(Color.bwPrimary)
        }
    }
}

#Preview {
    OnboardingMacroTrackingScreen(onContinue: {})
}
