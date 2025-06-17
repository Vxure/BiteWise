import SwiftUI

struct RecipeAIIntroView: View {
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Custom header with back button and title
            HStack(spacing: 16) {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                ZStack {
                    Circle()
                        .fill(Color(hex: "A45DE8"))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "chef.hat")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                Text("Recipe AI Assistant")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 16)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Main content box
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Hi! I'm your Recipe AI Assistant.")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        Text("I can help you:")
                            .font(.body)
                        
                        // Bullet points
                        VStack(alignment: .leading, spacing: 10) {
                            BulletPoint(text: "Modify recipes for dietary restrictions")
                            BulletPoint(text: "Suggest ingredient substitutions")
                            BulletPoint(text: "Adjust cooking times and servings")
                            BulletPoint(text: "Find recipes by cuisine or cooking method")
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    Spacer(minLength: 40)
                    
                    // Start button
                    GradientButton(
                        icon: "message.fill",
                        text: "Start Chat",
                        action: {
                            // In a real app, this would navigate to the chat UI
                            print("Start chat tapped")
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "A45DE8"))
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    RecipeAIIntroView {
        print("Dismissed")
    }
} 
