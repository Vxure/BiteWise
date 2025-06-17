import SwiftUI

struct WelcomeScreen: View {
    var onGetStarted: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo placeholder
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 180, height: 180)
                
                Image(systemName: "leaf")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80)
                    .foregroundColor(.green)
            }
            
            // App name
            Text("BiteWise")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Smart recipes for your ingredients")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Get started button
            Button(action: onGetStarted) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
                .frame(height: 60)
        }
        .padding()
    }
}

#Preview {
    WelcomeScreen(onGetStarted: {})
} 