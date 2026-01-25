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
    
    // Fridge & Pantry distinct colors
    static let bwFridgeBlue = Color(hex: "5B9BD5")        // Cool blue for fridge
    static let bwPantryBrown = Color(hex: "A67C52")       // Warm brown for pantry
}

// MARK: - Semantic System Colors (Dark Mode Adaptive)
public extension Color {
    /// Main background - pure black in dark mode, white in light mode
    static var bwSystemBackground: Color { Color(.systemBackground) }
    
    /// Card/Surface background - elevated surface with subtle contrast
    static var bwCardSurface: Color { Color(.secondarySystemBackground) }
    
    /// Tertiary/elevated surface for nested elements
    static var bwElevatedSurface: Color { Color(.tertiarySystemBackground) }
    
    /// System grouped background for list-style interfaces
    static var bwGroupedBackground: Color { Color(.systemGroupedBackground) }
}

// MARK: - Adaptive Accent Colors (Neon Pop for Dark Mode)
public extension Color {
    /// Adaptive primary green - brighter in dark mode for neon effect
    static func bwAdaptivePrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "4ADE80") : Color(hex: "2D6A4F")
    }
    
    /// Adaptive secondary green
    static func bwAdaptiveSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "6EE7A0") : Color(hex: "40916C")
    }
    
    /// Adaptive accent terracotta - vibrant coral in dark mode
    static func bwAdaptiveAccent(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "FF8A65") : Color(hex: "E76F51")
    }
    
    /// Adaptive protein gold - brighter yellow in dark mode
    static func bwAdaptiveProtein(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "FBBF24") : Color(hex: "E9C46A")
    }
    
    /// Adaptive carbs peach - warmer orange in dark mode
    static func bwAdaptiveCarbs(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "FB923C") : Color(hex: "F4A261")
    }
    
    /// Adaptive fats teal - brighter cyan in dark mode
    static func bwAdaptiveFats(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "22D3EE") : Color(hex: "264653")
    }
    
    /// Adaptive calories red
    static func bwAdaptiveCalories(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "F87171") : Color(hex: "E76F51")
    }
    
    /// Adaptive fridge blue - brighter in dark mode
    static func bwAdaptiveFridgeBlue(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "60A5FA") : Color(hex: "5B9BD5")
    }
    
    /// Adaptive pantry brown - warmer in dark mode
    static func bwAdaptivePantryBrown(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "D4A574") : Color(hex: "A67C52")
    }
    
    /// Adaptive success green
    static func bwAdaptiveSuccess(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "4ADE80") : Color(hex: "40916C")
    }
    
    /// Adaptive warning gold
    static func bwAdaptiveWarning(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "FBBF24") : Color(hex: "E9C46A")
    }
    
    /// Adaptive error red
    static func bwAdaptiveError(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "F87171") : Color(hex: "E76F51")
    }
    
    /// Adaptive coral - vibrant coral in dark mode
    static func bwAdaptivePrimaryCoral(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "FF8A65") : Color(hex: "E76F51")
    }
    
    /// Adaptive orange/peach - brighter orange in dark mode
    static func bwAdaptivePrimaryOrange(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "FB923C") : Color(hex: "F4A261")
    }
    
    /// Adaptive gold - brighter yellow in dark mode
    static func bwAdaptiveAccentGold(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "FBBF24") : Color(hex: "E9C46A")
    }
    
    /// Adaptive green - brighter green in dark mode (maps to bwAccentGreen)
    static func bwAdaptiveAccentGreen(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "4ADE80") : Color(hex: "2D6A4F")
    }
    
    /// Adaptive blue - brighter blue in dark mode
    static func bwAdaptiveAccentBlue(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "38BDF8") : Color(hex: "264653")
    }
}

// MARK: - BiteWise Theme Gradients
public struct BWGradients {
    // Main background gradient - warm cream tones (light mode only, use solid color in dark mode)
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
    
    /// Adaptive background gradient - cream in light mode, solid dark in dark mode
    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return backgroundGradient
        }
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
    
    /// Adaptive accent gradient - brighter in dark mode
    static func accentGradient(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [Color(hex: "FF8A65"), Color(hex: "FFAB91")],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return accentGradient
        }
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
    
    /// Adaptive primary gradient - brighter greens in dark mode
    static func primaryGradient(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [Color(hex: "4ADE80"), Color(hex: "6EE7A0")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return primaryGradient
        }
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
    
    /// Adaptive card gradient
    static func cardGradient(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    Color(.secondarySystemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return cardGradient
        }
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
    
    /// Adaptive greeting gradient
    static func greetingGradient(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    Color(hex: "4ADE80").opacity(0.9),
                    Color(hex: "6EE7A0").opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return greetingGradient
        }
    }
    
    /// Header fade gradient - fades from background to transparent
    static func headerFadeGradient(for scheme: ColorScheme) -> LinearGradient {
        let bgColor = scheme == .dark ? Color(.systemBackground) : Color.bwGradientCream
        return LinearGradient(
            stops: [
                .init(color: bgColor, location: 0),
                .init(color: bgColor, location: 0.6),
                .init(color: bgColor.opacity(0.8), location: 0.75),
                .init(color: bgColor.opacity(0), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Enhanced Card Style Modifier (24pt corners, adaptive colors, conditional shadows)
public struct BWCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var padding: CGFloat = 20
    var cornerRadius: CGFloat = 24
    var shadowColor: Color = Color.black.opacity(0.08)
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(
                        color: colorScheme == .dark ? .clear : shadowColor.opacity(0.04),
                        radius: 1,
                        x: 0,
                        y: 1
                    )
                    .shadow(
                        color: colorScheme == .dark ? .clear : shadowColor,
                        radius: 16,
                        x: 0,
                        y: 8
                    )
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

// MARK: - Background Modifier (Adaptive)
public struct BWBackgroundStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    public func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if colorScheme == .dark {
                        Color(.systemBackground)
                    } else {
                        BWGradients.backgroundGradient
                    }
                }
                .ignoresSafeArea()
            )
    }
}

public extension View {
    func bwBackground() -> some View {
        modifier(BWBackgroundStyle())
    }
}

// MARK: - Adaptive Shadow Modifier
/// Applies shadow only in light mode, removes in dark mode for cleaner look
public struct AdaptiveShadowModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var color: Color
    var radius: CGFloat
    var x: CGFloat
    var y: CGFloat
    
    public func body(content: Content) -> some View {
        content
            .shadow(
                color: colorScheme == .dark ? .clear : color,
                radius: radius,
                x: x,
                y: y
            )
    }
}

public extension View {
    /// Applies shadow only in light mode
    func adaptiveShadow(color: Color = Color.black.opacity(0.08), radius: CGFloat = 8, x: CGFloat = 0, y: CGFloat = 4) -> some View {
        modifier(AdaptiveShadowModifier(color: color, radius: radius, x: x, y: y))
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
