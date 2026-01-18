import SwiftUI

// MARK: - Expandable Floating Action Button (Speed Dial Pattern)
/// A reusable expandable FAB component that reveals secondary action buttons
/// with smooth spring animations. Supports customizable accent colors and actions.
struct ExpandableFAB: View {
    // MARK: - Configuration
    let accentColor: Color
    let onScan: () -> Void
    let onManual: () -> Void
    
    // MARK: - State
    @State private var isExpanded = false
    
    // MARK: - Animation Configuration
    private let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.6)
    private let quickSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    // MARK: - Layout Constants
    private let mainButtonHeight: CGFloat = 48
    private let mainButtonExpandedSize: CGFloat = 52
    private let secondaryButtonSize: CGFloat = 44
    private let buttonSpacing: CGFloat = 16
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // MARK: - Dismissal Overlay
            if isExpanded {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeFAB()
                    }
                    .transition(.opacity)
            }
            
            // MARK: - FAB Container
            VStack(alignment: .trailing, spacing: buttonSpacing) {
                // Secondary Buttons (appear when expanded)
                if isExpanded {
                    // Manual Entry Button
                    SecondaryFABButton(
                        icon: "square.and.pencil",
                        label: "Type",
                        accentColor: accentColor,
                        delay: 0.05
                    ) {
                        closeFAB()
                        // Small delay to let animation complete before action
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            onManual()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.3).combined(with: .opacity).combined(with: .offset(y: 30)),
                        removal: .scale(scale: 0.5).combined(with: .opacity)
                    ))
                    
                    // Scan Button
                    SecondaryFABButton(
                        icon: "camera.viewfinder",
                        label: "Scan",
                        accentColor: accentColor,
                        delay: 0
                    ) {
                        closeFAB()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            onScan()
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.3).combined(with: .opacity).combined(with: .offset(y: 20)),
                        removal: .scale(scale: 0.5).combined(with: .opacity)
                    ))
                }
                
                // MARK: - Main FAB Button
                mainButton
            }
            .padding(.trailing, 20)
            .padding(.bottom, 90)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
    
    // MARK: - Main Button
    private var mainButton: some View {
        Button(action: {
            toggleFAB()
        }) {
            ZStack {
                // Background shape that morphs
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: isExpanded ? mainButtonExpandedSize : nil,
                        height: mainButtonHeight
                    )
                    .frame(width: isExpanded ? nil : 100)
                
                // Content
                HStack(spacing: 8) {
                    // Plus icon that rotates to X
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                    
                    // Text that fades out
                    if !isExpanded {
                        Text("Add")
                            .font(BWTypography.buttonSmall)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
            }
            .shadow(color: accentColor.opacity(0.4), radius: isExpanded ? 16 : 12, x: 0, y: isExpanded ? 8 : 6)
        }
        .buttonStyle(FABButtonStyle())
    }
    
    // MARK: - Helper Methods
    private func toggleFAB() {
        BWHaptics.mediumImpact()
        withAnimation(springAnimation) {
            isExpanded.toggle()
        }
    }
    
    private func closeFAB() {
        BWHaptics.lightImpact()
        withAnimation(quickSpring) {
            isExpanded = false
        }
    }
}

// MARK: - Secondary FAB Button
private struct SecondaryFABButton: View {
    let icon: String
    let label: String
    let accentColor: Color
    let delay: Double
    let action: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        Button(action: {
            BWHaptics.lightImpact()
            action()
        }) {
            HStack(spacing: 12) {
                // Label
                Text(label)
                    .font(BWTypography.captionSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    )
                
                // Icon button
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                        .shadow(color: accentColor.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(accentColor)
                }
            }
            .scaleEffect(isVisible ? 1 : 0.5)
            .opacity(isVisible ? 1 : 0)
        }
        .buttonStyle(FABButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay)) {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
        }
    }
}

// MARK: - FAB Button Style
private struct FABButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        BWGradients.backgroundGradient
            .ignoresSafeArea()
        
        VStack {
            Text("Preview Content")
                .font(.title)
            Spacer()
        }
        
        ExpandableFAB(
            accentColor: .bwPrimary,
            onScan: { print("Scan tapped") },
            onManual: { print("Manual tapped") }
        )
    }
}
