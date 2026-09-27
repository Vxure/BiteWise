import SwiftUI

struct OnboardingAgeScreen: View {
    var onContinue: () -> Void
    var onBack: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedAge = ""
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    
    private let ageRanges = [
        "Under 18", "18-24", "25-34", "35-44", "45-54", "55+", "Prefer not to say"
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
                        OnboardingSegmentedProgressBar(currentStep: 2, totalSteps: 8)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 32)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What's your age range?")
                                .font(BWTypography.displayMedium)
                                .foregroundColor(.primary)
                            
                            Text("Used only for analytics")
                                .font(BWTypography.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(ageRanges, id: \.self) { range in
                                radioCard(title: range, isSelected: selectedAge == range) {
                                    BWHaptics.selection()
                                    withAnimation(.bwSnappy) { selectedAge = range }
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
    
    private func radioCard(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(BWTypography.bodyPrimary)
                    .foregroundColor(.primary)
                
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
            guard !selectedAge.isEmpty else { return }
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
                        .fill(selectedAge.isEmpty ? Color.gray.opacity(0.3) : Color.bwPrimary)
                )
        }
        .disabled(selectedAge.isEmpty)
        .buttonStyle(.bwPressable)
    }
}

#Preview {
    OnboardingAgeScreen(onContinue: {})
}
