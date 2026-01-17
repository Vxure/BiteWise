import SwiftUI

/// A reusable progress indicator for onboarding screens
/// Shows current step out of total steps with animated progress dots
struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.bwPrimary : Color.gray.opacity(0.3))
                    .frame(width: step == currentStep ? 10 : 8, height: step == currentStep ? 10 : 8)
                    .scaleEffect(step == currentStep ? 1.0 : 0.9)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
            }
            
            Spacer()
            
            Text("Step \(currentStep) of \(totalSteps)")
                .font(.bwCaption())
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingProgressView(currentStep: 1, totalSteps: 3)
        OnboardingProgressView(currentStep: 2, totalSteps: 3)
        OnboardingProgressView(currentStep: 3, totalSteps: 3)
    }
    .bwBackground()
}

