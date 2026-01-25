import SwiftUI

/// A reusable modern glassmorphic chat input bar
struct ChatInputBar: View {
    @Binding var message: String
    let isTyping: Bool
    var isFocused: FocusState<Bool>.Binding
    var onSend: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    // Tab bar height to account for when keyboard is NOT visible
    var tabBarHeight: CGFloat = 100
    
    // Track keyboard visibility
    @State private var isKeyboardVisible = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Text field with glassmorphic design
                HStack(spacing: 8) {
                    TextField("Ask me anything about recipes...", text: $message)
                        .font(BWTypography.bodyPrimary)
                        .focused(isFocused)
                        .disabled(isTyping)
                        .submitLabel(.send)
                        .onSubmit {
                            if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTyping {
                                onSend()
                            }
                        }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 15)
                .background(
                    ZStack {
                        // Frosted glass effect
                        RoundedRectangle(cornerRadius: 26)
                            .fill(.ultraThinMaterial)
                        
                        // Tinted overlay matching app theme - adaptive
                        if colorScheme == .dark {
                            RoundedRectangle(cornerRadius: 26)
                                .fill(Color(.secondarySystemBackground).opacity(0.8))
                        } else {
                            RoundedRectangle(cornerRadius: 26)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.bwGradientCream.opacity(0.6),
                                            Color.white.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        // Subtle border for depth
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.1)
                                    : Color.white.opacity(0.8),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: colorScheme == .dark ? .clear : Color.bwPrimary.opacity(0.08), radius: 12, x: 0, y: 4)
                    .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                )
                
                // Send button
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(15)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: (message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping)
                                            ? [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]
                                            : [Color.bwAccent, Color.bwCarbs],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(
                            color: (message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping) 
                                ? .clear 
                                : Color.bwAccent.opacity(0.3),
                            radius: 8,
                            y: 4
                        )
                }
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTyping)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: message.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            // If keyboard is visible, we don't need the tab bar padding
            .padding(.bottom, isKeyboardVisible ? 12 : tabBarHeight)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                isKeyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                isKeyboardVisible = false
            }
        }
    }
}

