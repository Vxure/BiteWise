import SwiftUI

// Custom spinner component using SwiftUI animations
struct Spinner: View {
    @State private var isAnimating: Bool = false

    var body: some View {
        Circle()
            .trim(from: 0.2, to: 1)
            .stroke(Color.green, lineWidth: 5)
            .frame(width: 50, height: 50)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct PhotoUploadScreen: View {
    @State private var isAnalyzing = false
    var onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer()
                    .frame(height: 20)
                
                // Header
                VStack(spacing: 12) {
                    Text("Show Us Your Ingredients")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Take a photo of your fridge contents for AI ingredient detection")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                
                // Upload box - now using a reusable component with analyzing state
                UploadBoxView(
                    isAnalyzing: $isAnalyzing,
                    onUpload: simulatePhotoAnalysis
                )
                .padding(.horizontal, 20)
                
                // Tips box - now using a reusable component
                TipsBoxView()
                    .padding(.horizontal, 20)
                
                Spacer()
                    .frame(height: 20)
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationTitle("Photo Upload")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func simulatePhotoAnalysis() {
        // Set analyzing state
        isAnalyzing = true
        
        // Simulate delay for analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Navigate to detected ingredients screen after analysis completes
            isAnalyzing = false
            onContinue()
        }
    }
}

// Reusable upload box component
struct UploadBoxView: View {
    @Binding var isAnalyzing: Bool
    var onUpload: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundColor(.gray.opacity(0.5))
                .frame(height: 320)
            
            if isAnalyzing {
                // Analyzing state
                VStack(spacing: 24) {
                    // Custom spinner instead of ProgressView
                    Spinner()
                        .padding()
                    
                    Text("Analyzing your fridge...")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                }
            } else {
                // Empty state with camera icon and text
                VStack(spacing: 24) {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray.opacity(0.7))
                    
                    Text("Tap to take a photo or upload from gallery")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    // Upload button inside the box
                    Button(action: onUpload) {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.body)
                            
                            Text("Upload Fridge Photo")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isAnalyzing {
                onUpload()
            }
        }
    }
}

// Reusable tips box component
struct TipsBoxView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tips for best results:")
                .font(.headline)
                .foregroundColor(Color.blue.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 10) {
                BulletPointView(text: "Ensure good lighting")
                BulletPointView(text: "Keep items visible and unobstructed")
                BulletPointView(text: "Include expiration dates if possible")
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
}

struct BulletPointView: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.blue.opacity(0.8))
            
            Text(text)
                .font(.callout)
                .foregroundColor(Color.blue.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        PhotoUploadScreen(onContinue: {})
    }
} 
 