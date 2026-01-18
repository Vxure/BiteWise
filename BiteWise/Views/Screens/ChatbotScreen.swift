import SwiftUI

struct ChatbotScreen: View {
    @State private var newMessage = ""
    @State private var isTyping = false
    @FocusState private var isInputFocused: Bool
    @State private var scrollProxy: ScrollViewProxy?
    @State private var selectedRecipeForNavigation: Recipe?
    @ObservedObject private var sessionContext = SessionContext.shared
    @ObservedObject private var dataManager = DataManager.shared
    
    /// Optional recipe context - if provided, chat is about this specific recipe
    var recipe: Recipe?
    var onDone: () -> Void
    
    // Use the active session's messages
    private var messages: [ChatMessage] {
        sessionContext.activeChatSession?.messages ?? []
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            BWGradients.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.bwAccent, Color.bwCarbs],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text(recipe != nil ? "Recipe Help" : "Recipe Assistant")
                            .font(BWTypography.cardTitle)
                    }
                    
                    Spacer()
                    
                    Button(action: handleDone) {
                        Text("Done")
                            .font(BWTypography.buttonSmall)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.bwAccent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.bwPressable)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message) { tappedRecipe in
                                    // Handle recipe card tap - navigate to recipe detail
                                    selectedRecipeForNavigation = tappedRecipe
                                }
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
                        // Initial scroll to bottom
                        if let lastId = messages.last?.id {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: isTyping) { _, newValue in
                        if newValue {
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onChanged { value in
                                if value.translation.height > 10 {
                                    isInputFocused = false
                                }
                            }
                    )
                }
                
                // Chat input bar
                ChatInputBar(
                    message: $newMessage,
                    isTyping: isTyping,
                    isFocused: $isInputFocused,
                    onSend: sendMessage,
                    tabBarHeight: 0 // Modal doesn't have app tab bar
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
        }
        .onAppear {
            initializeChatSession()
        }
        .onDisappear {
            // Clear active session when leaving this screen
            sessionContext.clearActiveChatSession()
        }
        .sheet(item: $selectedRecipeForNavigation) { recipeToShow in
            NavigationStack {
                RecipeDetailScreen(recipe: recipeToShow, onFeedback: {})
            }
        }
    }
    
    /// Handle done button
    private func handleDone() {
        onDone()
    }
    
    /// Initialize or resume a chat session
    private func initializeChatSession() {
        if let recipe = recipe {
            // Look for existing recipe chat session
            let sessions = DataManager.shared.getChatSessions(for: recipe.id)
            if let existing = sessions.first {
                sessionContext.loadChatSession(existing.id)
            } else {
                // Start a new recipe-specific session
                let session = sessionContext.startNewChatSession(
                    title: recipe.title,
                    recipeId: recipe.id
                )
                // Add initial contextual message
                let welcome = ChatMessage(
                    text: "How would you like to switch up this \(recipe.title)?",
                    isUser: false
                )
                sessionContext.addMessageToActiveSession(welcome)
            }
        } else {
            // General assistant - use most recent general session or start new
            let sessions = DataManager.shared.generalChatSessions
            if let existing = sessions.first {
                sessionContext.loadChatSession(existing.id)
            } else {
                let session = sessionContext.startNewChatSession(title: "Recipe Assistant")
                let welcome = ChatMessage(
                    text: "Hi! I'm your Recipe Assistant. I can help you with cooking tips, ingredient substitutions, and recipe ideas. What's on your mind?",
                    isUser: false
                )
                sessionContext.addMessageToActiveSession(welcome)
            }
        }
    }
    
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isTyping else { return }
        
        let userText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        newMessage = ""
        
        // Ensure we have a session
        if sessionContext.activeChatSession == nil {
            sessionContext.startNewChatSession(
                title: recipe != nil ? recipe!.title : "New Chat",
                recipeId: recipe?.id
            )
        }
        
        // Add user message
        let userMessage = ChatMessage(text: userText, isUser: true)
        sessionContext.addMessageToActiveSession(userMessage)
        
        // Show typing indicator
        isTyping = true
        
        // Call Gemini API
        Task {
            // DEMO TRIGGER: If user types "show recipe", show a dummy recipe card
            if userText.lowercased().contains("show recipe") {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay
                await MainActor.run {
                    isTyping = false
                    let botMessage = ChatMessage(text: "Here's a great recipe for you to try:", isUser: false)
                    sessionContext.addMessageToActiveSession(botMessage)
                    let recipeMessage = ChatMessage(recipe: Recipe.dummyData[0], isUser: false)
                    sessionContext.addMessageToActiveSession(recipeMessage)
                }
                return
            }
            
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

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset(for: index))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            )
            
            Spacer()
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever()) {
                animationOffset = 1
            }
        }
    }
    
    private func animationOffset(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.2
        let progress = (animationOffset + CGFloat(delay)).truncatingRemainder(dividingBy: 1.0)
        return sin(progress * .pi) * -6
    }
}

#Preview("General Assistant") {
    ChatbotScreen(onDone: {})
}

#Preview("Recipe-Specific") {
    ChatbotScreen(recipe: Recipe.dummyData[0], onDone: {})
}
