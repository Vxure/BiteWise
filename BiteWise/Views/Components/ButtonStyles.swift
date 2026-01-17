import SwiftUI
import UIKit

// MARK: - Haptic Feedback Helper
public struct BWHaptics {
    /// Light impact feedback
    public static func lightImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Medium impact feedback
    public static func mediumImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Soft impact feedback
    public static func softImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.impactOccurred()
    }
    
    /// Selection feedback (for toggles, selections)
    public static func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    /// Success notification feedback
    public static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Warning notification feedback
    public static func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    /// Error notification feedback
    public static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
}

// MARK: - Pressable Button Style
public struct BWPressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    var enableHaptics: Bool = true
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && enableHaptics {
                    BWHaptics.lightImpact()
                }
            }
    }
}

// MARK: - Bouncy Button Style
public struct BWBouncyButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.92
    var enableHaptics: Bool = true
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && enableHaptics {
                    BWHaptics.mediumImpact()
                }
            }
    }
}

// MARK: - Card Press Style (for interactive cards)
public struct BWCardPressStyle: ButtonStyle {
    var shadowColor: Color = Color.black.opacity(0.1)
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(
                color: configuration.isPressed ? shadowColor.opacity(0.05) : shadowColor,
                radius: configuration.isPressed ? 4 : 16,
                x: 0,
                y: configuration.isPressed ? 2 : 8
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    BWHaptics.softImpact()
                }
            }
    }
}

// MARK: - Tab Bar Button Style
public struct BWTabButtonStyle: ButtonStyle {
    var isSelected: Bool
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : (isSelected ? 1.1 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    BWHaptics.selection()
                }
            }
    }
}

// MARK: - Button Style Extensions
public extension ButtonStyle where Self == BWPressableButtonStyle {
    static var bwPressable: BWPressableButtonStyle { BWPressableButtonStyle() }
    static func bwPressable(scale: CGFloat = 0.96, haptics: Bool = true) -> BWPressableButtonStyle {
        BWPressableButtonStyle(scale: scale, enableHaptics: haptics)
    }
}

public extension ButtonStyle where Self == BWBouncyButtonStyle {
    static var bwBouncy: BWBouncyButtonStyle { BWBouncyButtonStyle() }
    static func bwBouncy(scale: CGFloat = 0.92, haptics: Bool = true) -> BWBouncyButtonStyle {
        BWBouncyButtonStyle(scale: scale, enableHaptics: haptics)
    }
}

public extension ButtonStyle where Self == BWCardPressStyle {
    static var bwCard: BWCardPressStyle { BWCardPressStyle() }
    static func bwCard(shadowColor: Color) -> BWCardPressStyle {
        BWCardPressStyle(shadowColor: shadowColor)
    }
}

// MARK: - View Transitions for Cards
public extension AnyTransition {
    /// Spring scale + fade transition for cards
    static var bwCardAppear: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        )
    }
    
    /// Slide up + fade transition
    static var bwSlideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    /// Scale from center transition
    static var bwPop: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }
}

// MARK: - Animation Presets
public extension Animation {
    /// Standard BiteWise spring animation
    static var bwSpring: Animation {
        .spring(response: 0.35, dampingFraction: 0.7)
    }
    
    /// Bouncy spring for emphasis
    static var bwBouncy: Animation {
        .spring(response: 0.4, dampingFraction: 0.6)
    }
    
    /// Snappy spring for quick interactions
    static var bwSnappy: Animation {
        .spring(response: 0.25, dampingFraction: 0.8)
    }
    
    /// Smooth ease for subtle changes
    static var bwSmooth: Animation {
        .easeInOut(duration: 0.3)
    }
}

// MARK: - Staggered Animation Helper
public struct StaggeredAnimation: ViewModifier {
    let index: Int
    let baseDelay: Double
    let delayIncrement: Double
    
    @State private var isVisible = false
    
    public init(index: Int, baseDelay: Double = 0.1, delayIncrement: Double = 0.05) {
        self.index = index
        self.baseDelay = baseDelay
        self.delayIncrement = delayIncrement
    }
    
    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .scaleEffect(isVisible ? 1 : 0.95)
            .onAppear {
                let delay = baseDelay + (Double(index) * delayIncrement)
                withAnimation(.bwSpring.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

public extension View {
    func staggeredAppear(index: Int, baseDelay: Double = 0.1, delayIncrement: Double = 0.05) -> some View {
        modifier(StaggeredAnimation(index: index, baseDelay: baseDelay, delayIncrement: delayIncrement))
    }
}

