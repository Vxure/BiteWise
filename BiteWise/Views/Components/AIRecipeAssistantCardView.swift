import SwiftUI

struct AIRecipeAssistantCardView: View {
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon, title and subtitle
                HStack(spacing: 14) {
                    // Purple circular icon with chef hat
                    ZStack {
                        Circle()
                            .fill(Color(hex: "A45DE8"))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "chef.hat")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    
                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 3) {
                        Text("AI Recipe Assistant")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Get personalized recipe suggestions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Description text
                Text("Want recipes tailored to your preferences?\nChat with our AI to refine suggestions based on dietary needs, cooking time, or flavor preferences.")
                    .font(.body)
                    .foregroundColor(Color.primary.opacity(0.8))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Gradient button
                GradientButton(
                    icon: "paperplane.fill",
                    text: "Refine Recipes with AI",
                    action: onTap
                )
                .padding(.top, 6)
            }
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "F5F1FF"), // Light purple
                        Color.white
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AIRecipeAssistantCardView {
        print("Card tapped")
    }
    .padding()
    .previewLayout(.sizeThatFits)
} 