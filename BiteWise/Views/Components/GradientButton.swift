import SwiftUI

struct GradientButton: View {
    var icon: String
    var text: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Text(text)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "A45DE8"),  // Purple
                        Color(hex: "3D7BFF")   // Blue
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }
}

#Preview {
    GradientButton(icon: "paperplane.fill", text: "Refine Recipes with AI") {
        print("Button tapped")
    }
    .padding()
    .previewLayout(.sizeThatFits)
} 