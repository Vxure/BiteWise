import SwiftUI

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct RecipeAIIntroView: View {
    var onDismiss: () -> Void
    var showBackButton: Bool = true
    
    // Animation states
    @State private var mascotScale: CGFloat = 0.8
    @State private var mascotOpacity: Double = 0
    
    // Chat states
    @State private var newMessage = ""
    @State private var isTyping = false
    @State private var showDrawer = false
    @FocusState private var isInputFocused: Bool
    
    // Session management
    @ObservedObject private var sessionContext = SessionContext.shared
    @ObservedObject private var dataManager = DataManager.shared
    
    // Scroll tracking
    @State private var scrollProxy: ScrollViewProxy?
    
    // Header configuration
    private let headerHeight: CGFloat = 56
    
    /// Whether we're in chat mode (has active session with messages)
    private var isInChatMode: Bool {
        guard let session = sessionContext.activeChatSession else { return false }
        return !session.messages.isEmpty
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            BWGradients.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ChatHeader(
                    showBackButton: showBackButton,
                    isInChatMode: isInChatMode,
                    onMenuTap: {
                        BWHaptics.lightImpact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showDrawer = true
                        }
                    },
                    onBackTap: {
                        BWHaptics.lightImpact()
                        if isInChatMode {
                            // Return to landing state
                            sessionContext.clearActiveChatSession()
                        } else {
                            onDismiss()
                        }
                    }
                )
                
                // Main content area
                if isInChatMode {
                    // Chat messages view
                    ChatMessagesView(
                        messages: sessionContext.activeChatSession?.messages ?? [],
                        isTyping: isTyping,
                        scrollProxy: $scrollProxy,
                        onDismissKeyboard: { isInputFocused = false }
                    )
                    .id(sessionContext.activeChatSession?.id) // Force refresh view when session changes
                } else {
                    // Landing state with mascot and feature cards
                    LandingContentView(
                        mascotScale: mascotScale,
                        mascotOpacity: mascotOpacity
                    )
                }
                
                // Chat input bar (always visible)
                ChatInputBar(
                    message: $newMessage,
                    isTyping: isTyping,
                    isFocused: $isInputFocused,
                    onSend: sendMessage,
                    tabBarHeight: 80
                )
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isInputFocused = false
            }
            .gesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onEnded { value in
                        if value.translation.height > 0 {
                            isInputFocused = false
                        }
                    }
            )
            
            // Chat history drawer overlay
            ChatHistoryDrawer(
                isOpen: $showDrawer,
                onSelectSession: { session in
                    sessionContext.loadChatSession(session.id)
                },
                onNewChat: {
                    sessionContext.clearActiveChatSession()
                }
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                mascotScale = 1.0
                mascotOpacity = 1.0
            }
        }
        .onDisappear {
            mascotScale = 0.8
            mascotOpacity = 0
        }
    }
    
    // MARK: - Send Message
    
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isTyping else { return }
        
        let userText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        newMessage = ""
        
        // Create a new session if we don't have one
        if sessionContext.activeChatSession == nil {
            sessionContext.startNewChatSession()
        }
        
        // Add user message
        let userMessage = ChatMessage(text: userText, isUser: true)
        sessionContext.addMessageToActiveSession(userMessage)
        
        // Show typing indicator
        isTyping = true
        
        // Scroll to bottom
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scrollProxy?.scrollTo("typing", anchor: .bottom)
            }
        }
        
        // Call Gemini API
        Task {
            do {
                let response = try await GeminiService.shared.chat(
                    message: userText,
                    context: sessionContext,
                    userProfile: dataManager.userProfile
                )
                
                await MainActor.run {
                    isTyping = false
                    let botMessage = ChatMessage(text: response, isUser: false)
                    sessionContext.addMessageToActiveSession(botMessage)
                    
                    // Scroll to new message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let lastMessage = sessionContext.activeChatSession?.messages.last {
                            withAnimation {
                                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isTyping = false
                    let errorMessage = ChatMessage(
                        text: "Sorry, I encountered an error. Please try again.",
                        isUser: false
                    )
                    sessionContext.addMessageToActiveSession(errorMessage)
                }
            }
        }
    }
}

// MARK: - Chat Header

private struct ChatHeader: View {
    let showBackButton: Bool
    let isInChatMode: Bool
    var onMenuTap: () -> Void
    var onBackTap: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Menu button (Always shown in chat mode or as hamburger on landing)
            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.bwPrimary.opacity(0.1), radius: 8, y: 4)
                    )
            }
            .buttonStyle(.bwPressable)
            
            // Title
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.bwAccent, Color.bwCarbs],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("Recipe Assistant")
                    .font(BWTypography.cardTitle)
            }
            
            Spacer()
            
            // Exit button (only show when NOT in chat mode and showBackButton is true)
            if !isInChatMode && showBackButton {
                Button(action: onBackTap) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.8))
                        )
                }
                .buttonStyle(.bwPressable)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color.bwGradientCream, location: 0),
                    .init(color: Color.bwGradientCream, location: 0.7),
                    .init(color: Color.bwGradientCream.opacity(0), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Landing Content View

private struct LandingContentView: View {
    let mascotScale: CGFloat
    let mascotOpacity: Double
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)
                
                // Mascot circle with animated appearance
                MascotView()
                    .scaleEffect(mascotScale)
                    .opacity(mascotOpacity)
                
                // Greeting text
                VStack(spacing: 8) {
                    Text("How can I help you")
                        .font(BWTypography.sectionHeader)
                        .foregroundColor(.primary)
                    
                    Text("today?")
                        .font(BWTypography.sectionHeader)
                        .foregroundColor(.primary)
                }
                .multilineTextAlignment(.center)
                
                // Feature cards section
                VStack(alignment: .leading, spacing: 12) {
                    Text("What I can do")
                        .font(BWTypography.bodyEmphasis)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    // Horizontal scrolling feature cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            FeatureCard(
                                icon: "leaf.fill",
                                title: "Adjustments",
                                subtitle: "Modify recipes for dietary restrictions",
                                color: Color.bwPrimary
                            )
                            
                            FeatureCard(
                                icon: "arrow.triangle.2.circlepath",
                                title: "Substitutions",
                                subtitle: "Suggest ingredient swaps",
                                color: Color.bwAccent
                            )
                            
                            FeatureCard(
                                icon: "clock.fill",
                                title: "Adjust Servings",
                                subtitle: "Scale recipes up or down",
                                color: Color.bwProtein
                            )
                            
                            FeatureCard(
                                icon: "globe",
                                title: "Cuisines",
                                subtitle: "Explore world flavors",
                                color: Color.bwFats
                            )
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.top, 15)
                
                // Extra space for input bar and tab bar
                Spacer()
                    .frame(height: 180)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Mascot View

private struct MascotView: View {
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.bwAccent.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 35,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)
            
            // Main terracotta circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.bwAccent, Color.bwCarbs],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .shadow(color: Color.bwAccent.opacity(0.35), radius: 16, y: 8)
            
            // Sparkle icon
            Image(systemName: "sparkles")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.white)
            
            // Decorative stars
            Image(systemName: "sparkle")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.bwProtein)
                .offset(x: 55, y: -40)
            
            Image(systemName: "sparkle")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.bwProtein.opacity(0.6))
                .offset(x: 62, y: -22)
            
            Image(systemName: "sparkle")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color.bwPrimary.opacity(0.5))
                .offset(x: -50, y: 32)
        }
    }
}

// MARK: - Chat Messages View

private struct ChatMessagesView: View {
    let messages: [ChatMessage]
    let isTyping: Bool
    @Binding var scrollProxy: ScrollViewProxy?
    var onDismissKeyboard: () -> Void
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }
                    
                    // Typing indicator
                    if isTyping {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
            .onAppear {
                scrollProxy = proxy
                // Scroll to bottom on appear
                if let lastMessage = messages.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onTapGesture {
                onDismissKeyboard()
            }
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        if value.translation.height > 10 {
                            onDismissKeyboard()
                        }
                    }
            )
        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(BWTypography.bodyPrimary)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(subtitle)
                .font(BWTypography.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(width: 130)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Supporting Views (kept for backwards compatibility)

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.bwPrimary)
                .frame(width: 30, height: 30)
                .background(Color.bwPrimary.opacity(0.1))
                .cornerRadius(10)
            
            Text(text)
                .font(BWTypography.bodyPrimary)
                .foregroundColor(.primary)
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(Color.bwAccent)
                .frame(width: 6, height: 6)
            
            Text(text)
                .font(BWTypography.bodyPrimary)
                .foregroundColor(.primary)
        }
    }
}

#Preview("Landing State") {
    RecipeAIIntroView {
        print("Dismissed")
    }
}

#Preview("Chat State") {
    let _ = {
        // Create a test session with messages
        let session = DataManager.shared.createChatSession(title: "Test Chat")
        DataManager.shared.addMessageToChatSession(
            ChatMessage(text: "What can I make with chicken?", isUser: true),
            sessionId: session.id
        )
        DataManager.shared.addMessageToChatSession(
            ChatMessage(text: "You could make a delicious lemon herb chicken, or perhaps a creamy chicken alfredo!", isUser: false),
            sessionId: session.id
        )
        SessionContext.shared.loadChatSession(session.id)
    }()
    
    return RecipeAIIntroView {
        print("Dismissed")
    }
}
