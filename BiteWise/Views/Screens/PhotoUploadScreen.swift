import SwiftUI

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Custom spinner component using SwiftUI animations
struct Spinner: View {
    @State private var isAnimating: Bool = false
    var color: Color = Color.bwPrimaryCoral

    var body: some View {
        Circle()
            .trim(from: 0.2, to: 1)
            .stroke(
                LinearGradient(
                    colors: [color, color.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
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
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var errorMessage: String?
    @ObservedObject private var sessionContext = SessionContext.shared
    @Environment(\.colorScheme) var colorScheme
    var onContinue: () -> Void
    
    // Scroll tracking state for fading header
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerVisible: Bool = true
    
    // Header configuration
    private let headerHeight: CGFloat = 35
    
    // MARK: - Header Animation Calculations
    
    private var scrollProgress: CGFloat {
        min(1, max(0, -scrollOffset / headerHeight))
    }
    
    private var headerOpacity: Double {
        if headerVisible {
            return 1.0
        }
        return Double(1.0 - scrollProgress)
    }
    
    private var headerTranslateY: CGFloat {
        if headerVisible {
            return 0
        }
        return -headerHeight * scrollProgress
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Adaptive background
            Group {
                if colorScheme == .dark {
                    Color(.systemBackground)
                } else {
                    BWGradients.backgroundGradient
                }
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Invisible anchor for scroll offset tracking
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                    }
                    .frame(height: 0)
                    
                    // Spacer for floating header
                    Color.clear
                        .frame(height: headerHeight)
                    
                    // Header content (scrollable)
                    VStack(spacing: 12) {
                        Text("Show Us Your Ingredients")
                            .font(.bwTitle2())
                            .multilineTextAlignment(.center)
                        
//                        Text("Take a photo of your fridge contents for AI ingredient detection")
                        Text("Scan your fridge and we’ll suggest recipes you can make right now, tailored to your taste")
                            .font(.bwSubheadline())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .staggeredAppear(index: 0)
                    
                    // Upload box - now using a reusable component with analyzing state
                    UploadBoxView(
                        isAnalyzing: $isAnalyzing,
                        onUpload: { showImagePicker = true }
                    )
                    .padding(.horizontal, 20)
                    .staggeredAppear(index: 1)
                    
                    // Tips box
                    TipsBoxView()
                        .padding(.horizontal, 20)
                        .staggeredAppear(index: 2)
                    
                    // Manual entry option - modernized card style
                    Button(action: enterManually) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.bwAdaptivePrimary(for: colorScheme).opacity(0.1))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "pencil.line")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color.bwAdaptivePrimary(for: colorScheme))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enter Manually")
                                    .font(BWTypography.bodyPrimary)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text("Type your ingredients yourself")
                                    .font(BWTypography.captionSmall)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(15)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .adaptiveShadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.bwPressable)
                    .padding(.horizontal, 20)
                    .padding(.top, -20)
                    .staggeredAppear(index: 3)
                    
                    // Security note - compact dark green card
                    SecurityNoteView()
                        .padding(.horizontal, 20)
                        .padding(.top, -20)
                        .staggeredAppear(index: 4)
                    
                    Spacer()
                        .frame(height: 80)

                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                handleScrollChange(newOffset: value)
            }
            
            // MARK: - Floating Title Overlay
            VStack(spacing: 0) {
                Text("Photo Upload")
                    .font(BWTypography.sectionHeader)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(BWGradients.headerFadeGradient(for: colorScheme))
            .offset(y: headerTranslateY)
            .opacity(headerOpacity)
            .animation(.easeOut(duration: 0.2), value: headerVisible)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showImagePicker) {
            ImageSourceSheet(
                isPresented: $showImagePicker,
                selectedImage: $selectedImage
            )
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                analyzeImage(image)
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Scroll Handling
    
    private func handleScrollChange(newOffset: CGFloat) {
        let delta = newOffset - lastScrollOffset
        
        if delta > 2 {
            if !headerVisible {
                withAnimation(.easeOut(duration: 0.2)) {
                    headerVisible = true
                }
            }
        } else if delta < -2 {
            if headerVisible && newOffset < -10 {
                withAnimation(.easeOut(duration: 0.15)) {
                    headerVisible = false
                }
            }
        }
        
        if newOffset >= -5 {
            if !headerVisible {
                withAnimation(.easeOut(duration: 0.2)) {
                    headerVisible = true
                }
            }
        }
        
        scrollOffset = newOffset
        lastScrollOffset = newOffset
    }
    
    /// Analyze the selected image using GeminiService
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        sessionContext.analyzedImage = image
        
        Task {
            do {
                // Call GeminiService to analyze image
                let ingredients = try await GeminiService.shared.analyzeImage(image)
                
                await MainActor.run {
                    // Store results in session context
                    sessionContext.detectedIngredients = ingredients
                    isAnalyzing = false
                    selectedImage = nil
                    
                    // Navigate to detected ingredients screen
                    onContinue()
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    selectedImage = nil
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    /// Skip photo upload and enter ingredients manually
    private func enterManually() {
        // Clear any previous detected ingredients
        sessionContext.detectedIngredients = []
        sessionContext.analyzedImage = nil
        
        // Navigate to detected ingredients screen with empty state
        onContinue()
    }
}

// Reusable upload box component
struct UploadBoxView: View {
    @Binding var isAnalyzing: Bool
    var onUpload: () -> Void
    @State private var isPressed = false
    @State private var animationAngle: Double = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
            
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white.opacity(0.6))
            
            // Animated gradient border
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color.bwAdaptivePrimaryCoral(for: colorScheme),
                            Color.bwAdaptivePrimaryOrange(for: colorScheme),
                            Color.bwAdaptiveAccentGold(for: colorScheme),
                            Color.bwAdaptivePrimaryCoral(for: colorScheme).opacity(0.5),
                            Color.bwAdaptivePrimaryCoral(for: colorScheme)
                        ]),
                        center: .center,
                        angle: .degrees(animationAngle)
                    ),
                    lineWidth: 3
                )
            
            if isAnalyzing {
                // Analyzing state
                VStack(spacing: 24) {
                    // Custom spinner
                    Spinner()
                        .padding()
                    
                    Text("Analyzing your fridge...")
                        .font(.bwTitle3())
                        .foregroundColor(Color.bwPrimaryCoral)
                        .multilineTextAlignment(.center)
                }
            } else {
                // Empty state with camera icon and text
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.bwPrimaryCoral.opacity(0.15), Color.bwPrimaryOrange.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "camera.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(Color.bwPrimaryCoral)
                    }
                    
                    Text("Tap to take a photo or upload from gallery")
                        .font(.bwSubheadline())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Upload button inside the box
                    GradientButton(
                        icon: "camera.fill",
                        text: "Upload Fridge Photo",
                        action: onUpload
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .frame(height: 320)
        .scaleEffect(isPressed && !isAnalyzing ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .adaptiveShadow(color: Color.bwAdaptivePrimaryCoral(for: colorScheme).opacity(0.25), radius: 20, x: 0, y: 10)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isAnalyzing { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
        .onTapGesture {
            if !isAnalyzing {
                onUpload()
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                animationAngle = 360
            }
        }
    }
}

// Reusable tips box component
struct TipsBoxView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color.bwAccentGold)
                Text("Tips for best results:")
                    .font(.bwHeadline())
                    .foregroundColor(Color.bwAccentGold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                BulletPointView(text: "Ensure good lighting")
                BulletPointView(text: "Keep items visible and unobstructed")
                BulletPointView(text: "Include expiration dates if possible")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle(padding: 16, cornerRadius: 16)
    }
}

// Security note component - compact dark green tinted card
struct SecurityNoteView: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.bwAccentGreen)
            
            Text("Your photo is analyzed securely and never stored.")
                .font(BWTypography.captionSmall)
                .foregroundColor(Color.bwAccentGreen.opacity(0.9))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.bwAccentGreen.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.bwAccentGreen.opacity(0.2), lineWidth: 1)
        )
    }
}

struct BulletPointView: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(Color.bwAccentGold)
                .frame(width: 6, height: 6)
            
            Text(text)
                .font(.bwSubheadline())
                .foregroundColor(.primary.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        PhotoUploadScreen(onContinue: {})
    }
}
