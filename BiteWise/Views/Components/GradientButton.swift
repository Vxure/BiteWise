import SwiftUI

struct GradientButton: View {
    var icon: String
    var text: String
    var action: () -> Void
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            BWHaptics.mediumImpact()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(text)
                    .font(BWTypography.buttonLabel)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(BWGradients.accentGradient(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Secondary Button Variant
struct SecondaryButton: View {
    var icon: String?
    var text: String
    var color: Color = .bwPrimary
    var action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            BWHaptics.lightImpact()
            action()
        }) {
            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                
                Text(text)
                    .font(BWTypography.buttonSmall)
            }
            .foregroundColor(color)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        GradientButton(icon: "paperplane.fill", text: "Refine Recipes with AI") {
            print("Button tapped")
        }
        
        SecondaryButton(icon: "plus.circle.fill", text: "Add Ingredient") {
            print("Secondary tapped")
        }
        
        SecondaryButton(text: "Cancel", color: .secondary) {
            print("Cancel tapped")
        }
    }
    .padding()
    .bwBackground()
}
