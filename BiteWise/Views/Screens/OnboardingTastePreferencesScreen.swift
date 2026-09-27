import SwiftUI

struct OnboardingTastePreferencesScreen: View {
    var onContinue: () -> Void
    var onSkip: (() -> Void)?
    var onBack: (() -> Void)?
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selected: Set<String> = []
    @State private var customText = ""
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    
    private let cuisines: [(value: String, icon: String)] = [
        ("Asian", "🍜"),
        ("American", "🍔"),
        ("Middle Eastern", "🥙"),
        ("Mediterranean", "🫒"),
        ("Latin American", "🌮"),
        ("European", "🥖"),
    ]
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
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
                        OnboardingSegmentedProgressBar(currentStep: 7, totalSteps: 8)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 32)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What cuisines do you enjoy?")
                                .font(BWTypography.displayMedium)
                                .foregroundColor(.primary)
                            
                            Text("Select all that apply")
                                .font(BWTypography.bodyPrimary)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(cuisines, id: \.value) { cuisine in
                                cuisineCard(cuisine: cuisine, isSelected: selected.contains(cuisine.value)) {
                                    BWHaptics.selection()
                                    withAnimation(.bwSnappy) {
                                        if selected.contains(cuisine.value) {
                                            selected.remove(cuisine.value)
                                        } else {
                                            selected.insert(cuisine.value)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Other cuisines")
                                .font(BWTypography.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter other cuisines", text: $customText)
                                .font(BWTypography.bodyPrimary)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(colorScheme == .dark
                                              ? Color(.secondarySystemBackground)
                                              : Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)
                
                VStack(spacing: 8) {
                    let canContinue = !selected.isEmpty || !customText.trimmingCharacters(in: .whitespaces).isEmpty
                    
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
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(canContinue ? Color.bwPrimary : Color.gray.opacity(0.3))
                            )
                    }
                    .disabled(!canContinue)
                    .buttonStyle(.bwPressable)
                    
                    Button(action: { onSkip?() ?? onContinue() }) {
                        Text("Skip")
                            .font(BWTypography.buttonSmall)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
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
    
    private func cuisineCard(cuisine: (value: String, icon: String),
                             isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(cuisine.icon)
                    .font(.system(size: 36))
                
                Text(cuisine.value)
                    .font(BWTypography.caption)
                    .foregroundColor(.primary)
                
                Circle()
                    .strokeBorder(isSelected ? Color.bwPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 7, height: 7)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .background(
                        Circle()
                            .fill(isSelected ? Color.bwPrimary : Color.clear)
                            .frame(width: 20, height: 20)
                    )
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
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
        .buttonStyle(.bwPressable(scale: 0.97))
    }
}

#Preview {
    OnboardingTastePreferencesScreen(onContinue: {})
}
