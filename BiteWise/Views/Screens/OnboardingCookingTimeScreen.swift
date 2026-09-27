import SwiftUI

struct OnboardingCookingTimeScreen: View {
    var onContinue: () -> Void
    var onBack: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selected = ""
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    
    private let timePrefs: [(value: String, time: String, icon: String)] = [
        ("Quick & easy", "15-30 min", "⚡"),
        ("Balanced", "30-60 min", "⏱️"),
        ("Flexible", "Any duration", "🎯"),
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
                        OnboardingSegmentedProgressBar(currentStep: 6, totalSteps: 8)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 32)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How much time for cooking?")
                                .font(BWTypography.displayMedium)
                                .foregroundColor(.primary)
                            
                            Text("We'll tailor recipes to your schedule")
                                .font(BWTypography.bodyPrimary)
                                .foregroundColor(.secondary)
                            
                            Text("You can adjust this later")
                                .font(BWTypography.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(timePrefs, id: \.value) { pref in
                                timeCard(pref: pref, isSelected: selected == pref.value) {
                                    BWHaptics.selection()
                                    withAnimation(.bwSnappy) { selected = pref.value }
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
    
    private func timeCard(pref: (value: String, time: String, icon: String),
                          isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(pref.icon)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(pref.value)
                        .font(BWTypography.cardTitle)
                        .foregroundColor(.primary)
                    
                    Text(pref.time)
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
            .padding(20)
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
    OnboardingCookingTimeScreen(onContinue: {})
}
