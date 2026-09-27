import SwiftUI

struct OnboardingExperienceScreen: View {
    var onContinue: () -> Void
    var onBack: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selected = ""
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    
    private let levels: [(value: String, icon: String, description: String)] = [
        ("Beginner", "👨‍🍳", "Just getting started"),
        ("Intermediate", "🔥", "Comfortable in the kitchen"),
        ("Advanced", "⭐", "Cooking expert"),
        ("Doesn't matter", "🎯", "I'm flexible"),
    ]
    
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
                        OnboardingSegmentedProgressBar(currentStep: 5, totalSteps: 8)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 32)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cooking experience?")
                                .font(BWTypography.displayMedium)
                                .foregroundColor(.primary)
                            
                            Text("Help us match the right recipes")
                                .font(BWTypography.bodyPrimary)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(levels, id: \.value) { level in
                                experienceCard(level: level, isSelected: selected == level.value) {
                                    BWHaptics.selection()
                                    withAnimation(.bwSnappy) { selected = level.value }
                                }
                            }
                        }
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
    
    private func experienceCard(level: (value: String, icon: String, description: String),
                                isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(level.icon)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.value)
                        .font(BWTypography.bodyEmphasis)
                        .foregroundColor(.primary)
                    
                    Text(level.description)
                        .font(BWTypography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .strokeBorder(isSelected ? Color.bwPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1 : 0)
                            .scaleEffect(isSelected ? 1 : 0.3)
                    )
                    .background(
                        Circle()
                            .fill(isSelected ? Color.bwPrimary : Color.clear)
                            .frame(width: 22, height: 22)
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? Color.bwPrimary.opacity(0.08)
                          : (colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.bwPrimary : Color.gray.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.bwPressable(scale: 0.98))
    }
    
    private var continueButton: some View {
        Button(action: {
            guard !selected.isEmpty else { return }
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
                        .fill(selected.isEmpty ? Color.gray.opacity(0.3) : Color.bwPrimary)
                )
        }
        .disabled(selected.isEmpty)
        .buttonStyle(.bwPressable)
    }
}

#Preview {
    OnboardingExperienceScreen(onContinue: {})
}
