import SwiftUI

struct AIRecipeAssistantCardView: View {
    var onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon, title and subtitle
                HStack(spacing: 14) {
                    // Coral circular icon with sparkles
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.bwPrimaryCoral, Color.bwPrimaryOrange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .shadow(color: Color.bwPrimaryCoral.opacity(0.35), radius: 8, y: 4)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Recipe Assistant")
                            .font(.bwHeadline())
                            .foregroundColor(.primary)
                        
                        Text("Get personalized recipe suggestions")
                            .font(.bwSubheadline())
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Description text
                Text("Want recipes tailored to your preferences? Chat with our AI to refine suggestions based on dietary needs, cooking time, or flavor preferences.")
                    .font(.bwBody())
                    .foregroundColor(Color.primary.opacity(0.8))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Gradient button
                GradientButton(
                    icon: "message.fill",
                    text: "Refine Recipes with AI",
                    action: onTap
                )
                .padding(.top, 4)
            }
            .padding(20)
            .background(
                ZStack {
                    // Frosted glass effect
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle coral gradient overlay
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.bwPrimaryCoral.opacity(0.06),
                                    Color.white.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.bwPrimaryCoral.opacity(0.12), lineWidth: 1)
                }
            )
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    AIRecipeAssistantCardView {
        print("Card tapped")
    }
    .padding()
    .bwBackground()
}
