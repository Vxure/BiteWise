import SwiftUI

struct OnboardingDietaryScreen: View {
    var onContinue: () -> Void
    var onBack: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selected: Set<String> = []
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    
    private let dietaryOptions = ["Halal", "Vegan", "Vegetarian", "None"]
    
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
                        OnboardingSegmentedProgressBar(currentStep: 3, totalSteps: 8)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 32)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Any dietary constraints?")
                                .font(BWTypography.displayMedium)
                                .foregroundColor(.primary)
                            
                            Text("Select all that apply")
                                .font(BWTypography.bodyPrimary)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(dietaryOptions, id: \.self) { option in
                                checkboxCard(title: option, isSelected: selected.contains(option)) {
                                    BWHaptics.selection()
                                    withAnimation(.bwSnappy) { toggleOption(option) }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)
                
                GradientButton(text: "Continue", action: {
                    BWHaptics.mediumImpact()
                    onContinue()
                })
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
    
    private func toggleOption(_ option: String) {
        if option == "None" {
            selected = ["None"]
        } else {
            selected.remove("None")
            if selected.contains(option) {
                selected.remove(option)
            } else {
                selected.insert(option)
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
    
    private func checkboxCard(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(BWTypography.bodyPrimary)
                    .foregroundColor(.primary)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isSelected ? Color.bwPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Group {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.bwPrimary : Color.clear)
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
}

#Preview {
    OnboardingDietaryScreen(onContinue: {})
}
