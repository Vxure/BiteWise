import SwiftUI

struct PhotoUploadScreen: View {
    @State private var hasUploadedImage = false
    var onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Upload Your Fridge Photo")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            Text("Let BiteWise analyze your fridge contents to suggest the perfect recipes")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Image view - either placeholder or "uploaded" image
            ZStack {
                if hasUploadedImage {
                    // This would be replaced with the actual uploaded image
                    // For now, we're just using a placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(4/3, contentMode: .fit)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                                
                                Text("Sample Fridge Photo")
                                    .foregroundColor(.gray)
                            }
                        )
                } else {
                    Rectangle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(.gray)
                        .aspectRatio(4/3, contentMode: .fit)
                        .overlay(
                            VStack {
                                Image(systemName: "camera")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                                
                                Text("No Photo Selected")
                                    .foregroundColor(.gray)
                            }
                        )
                }
            }
            .padding()
            
            Spacer()
            
            // Upload button
            Button(action: {
                // Simulate photo upload
                self.hasUploadedImage = true
            }) {
                HStack {
                    Image(systemName: "photo.fill")
                    Text("Upload Fridge Photo")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            // Continue button (only enabled if photo has been "uploaded")
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(hasUploadedImage ? Color.green : Color.gray)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom)
            .disabled(!hasUploadedImage)
        }
    }
}

#Preview {
    PhotoUploadScreen(onContinue: {})
} 