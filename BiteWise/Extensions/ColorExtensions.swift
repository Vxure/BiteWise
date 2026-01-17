import SwiftUI
import Foundation

// Color extension for hex colors
public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - BiteWise Theme Colors (Food-Friendly Earthy Palette)
public extension Color {
    // Primary colors - earthy, appetizing tones
    static let bwPrimary = Color(hex: "2D6A4F")           // Rich forest green
    static let bwAccent = Color(hex: "E76F51")            // Warm terracotta
    static let bwSurface = Color(hex: "FEFAE0")           // Warm cream surface
    static let bwSecondary = Color(hex: "40916C")         // Medium forest green
    
    // Legacy aliases for backwards compatibility
    static let bwPrimaryCoral = Color(hex: "E76F51")      // Maps to terracotta
    static let bwPrimaryOrange = Color(hex: "F4A261")     // Peach accent
    static let bwAccentGreen = Color(hex: "2D6A4F")       // Maps to forest green
    static let bwAccentGold = Color(hex: "E9C46A")        // Golden
    static let bwAccentRose = Color(hex: "E76F51")        // Maps to terracotta
    static let bwAccentBlue = Color(hex: "264653")        // Deep teal
    static let bwAccentOrange = Color(hex: "F4A261")      // Peach
    static let bwAccentPurple = Color(hex: "E76F51")      // Maps to terracotta
    
    // Background colors - warm creams
    static let bwBackgroundCream = Color(hex: "FEFAE0")   // Primary cream
    static let bwBackgroundPeach = Color(hex: "FAEDCD")   // Light peach cream
    static let bwBackgroundWarm = Color(hex: "FFF8E7")    // Warm white
    
    // Gradient colors for background
    static let bwGradientCream = Color(hex: "FEFAE0")     // Top - warm cream
    static let bwGradientPeach = Color(hex: "FAEDCD")     // Middle - light peach
    static let bwGradientWarm = Color(hex: "FFF5E1")      // Bottom - warm glow
    
    // Card colors
    static let bwCardBackground = Color.white.opacity(0.92)
    static let bwCardBorder = Color.white.opacity(0.8)
    
    // Macro colors - distinct, appetizing
    static let bwProtein = Color(hex: "E9C46A")           // Golden (protein)
    static let bwCarbs = Color(hex: "F4A261")             // Peach (carbs)
    static let bwFats = Color(hex: "264653")              // Deep teal (fats)
    static let bwCalories = Color(hex: "E76F51")          // Terracotta (calories)
    
    // Semantic colors
    static let bwSuccess = Color(hex: "40916C")           // Green success
    static let bwWarning = Color(hex: "E9C46A")           // Golden warning
    static let bwError = Color(hex: "E76F51")             // Terracotta error
}

// MARK: - BiteWise Theme Gradients
public struct BWGradients {
    // Main background gradient - warm cream tones
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.bwGradientCream,
                Color.bwGradientPeach,
                Color.bwGradientWarm
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // Accent button gradient - terracotta to peach
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "E76F51"),
                Color(hex: "F4A261")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // Primary gradient - forest green tones
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "2D6A4F"),
                Color(hex: "40916C")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Card subtle gradient overlay
    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.98),
                Color.white.opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Warm greeting card gradient
    static var greetingGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "2D6A4F").opacity(0.9),
                Color(hex: "40916C").opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Enhanced Card Style Modifier (24pt corners, colored shadows)
public struct BWCardStyle: ViewModifier {
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 24
    var shadowColor: Color = Color.black.opacity(0.08)
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                    .shadow(color: shadowColor.opacity(0.04), radius: 1, x: 0, y: 1)
                    .shadow(color: shadowColor, radius: 16, x: 0, y: 8)
            )
    }
}

public extension View {
    func bwCardStyle(padding: CGFloat = 20, cornerRadius: CGFloat = 24) -> some View {
        modifier(BWCardStyle(padding: padding, cornerRadius: cornerRadius))
    }
    
    func bwCardStyle(padding: CGFloat = 20, cornerRadius: CGFloat = 24, shadowColor: Color) -> some View {
        modifier(BWCardStyle(padding: padding, cornerRadius: cornerRadius, shadowColor: shadowColor))
    }
}

// MARK: - Background Modifier
public struct BWBackgroundStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(
                BWGradients.backgroundGradient
                    .ignoresSafeArea()
            )
    }
}

public extension View {
    func bwBackground() -> some View {
        modifier(BWBackgroundStyle())
    }
}

// MARK: - Pressable Card Modifier
public struct PressableCardStyle: ViewModifier {
    @State private var isPressed = false
    var onTap: () -> Void
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onTapGesture {
                onTap()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

public extension View {
    func pressableCard(onTap: @escaping () -> Void) -> some View {
        modifier(PressableCardStyle(onTap: onTap))
    }
}

// MARK: - Animated Circular Progress Ring
public struct CircularProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    var showPercentage: Bool = false
    var animateOnAppear: Bool = true
    
    @State private var animatedProgress: Double = 0
    
    public init(
        progress: Double,
        lineWidth: CGFloat = 8,
        backgroundColor: Color = Color.white.opacity(0.3),
        foregroundColor: Color = .white,
        showPercentage: Bool = false,
        animateOnAppear: Bool = true
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.showPercentage = showPercentage
        self.animateOnAppear = animateOnAppear
    }
    
    public var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(min(animatedProgress, 1.0)))
                .stroke(
                    foregroundColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Optional percentage text
            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(BWTypography.badge)
                    .fontWeight(.bold)
                    .foregroundColor(foregroundColor)
            }
        }
        .onAppear {
            if animateOnAppear {
                withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                    animatedProgress = progress
                }
            } else {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}
