import SwiftUI

struct OnboardingSegmentedProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < currentStep
                          ? Color.bwPrimary
                          : colorScheme == .dark
                            ? Color.white.opacity(0.15)
                            : Color.gray.opacity(0.2))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingSegmentedProgressBar(currentStep: 1, totalSteps: 8)
        OnboardingSegmentedProgressBar(currentStep: 4, totalSteps: 8)
        OnboardingSegmentedProgressBar(currentStep: 8, totalSteps: 8)
    }
    .padding()
    .bwBackground()
}
