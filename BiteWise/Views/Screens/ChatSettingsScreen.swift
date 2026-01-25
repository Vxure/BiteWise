import SwiftUI

struct ChatSettingsScreen: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var dataManager = DataManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var showClearConfirmation = false
    var onDone: () -> Void
    
    var body: some View {
        ZStack {
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
                VStack(spacing: 20) {
                    // Header
                    headerSection
                        .staggeredAppear(index: 0)
                    
                    // Auto-clear section
                    autoClearSection
                        .staggeredAppear(index: 1)
                    
                    // Recipe chats section
                    recipeChatsSection
                        .staggeredAppear(index: 2)
                    
                    // Chat statistics
                    chatStatsSection
                        .staggeredAppear(index: 3)
                    
                    // Clear all button
                    clearAllSection
                        .staggeredAppear(index: 4)
                    
                    // Done button
                    GradientButton(
                        icon: "checkmark.circle.fill",
                        text: "Done",
                        action: {
                            BWHaptics.success()
                            onDone()
                        }
                    )
                    .padding(.top, 8)
                    .staggeredAppear(index: 5)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
        .customNavigation()
        .alert("Clear All Chat History?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                clearAllChats()
            }
        } message: {
            Text("This will permanently delete all chat sessions and messages, including recipe-specific conversations. This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.bwPrimary, Color.bwSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.bwPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text("Chat Settings")
                .font(.bwLargeTitle())
            
            Text("Manage your conversation history")
                .font(.bwSubheadline())
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .bwCardStyle(padding: 24, cornerRadius: 24)
    }
    
    // MARK: - Auto-Clear Section
    private var autoClearSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.bwPrimary.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.bwPrimary)
                }
                
                Text("Auto-Clear")
                    .font(BWTypography.cardTitle)
            }
            
            // Toggle row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto-clear chat history")
                        .font(.bwHeadline())
                    Text("Removes old messages automatically")
                        .font(.bwCaption())
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.chatAutoExpireEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color.bwAccentGreen))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.tertiarySystemBackground))
            )
            
            // Days selector (only show when enabled)
            if settings.chatAutoExpireEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Text("Clear after")
                            .font(.bwBody())
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                BWHaptics.lightImpact()
                                if settings.generalChatExpireDays > 1 {
                                    settings.generalChatExpireDays -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(settings.generalChatExpireDays > 1 ? Color.bwAdaptivePrimary(for: colorScheme) : Color.secondary.opacity(0.3))
                            }
                            .buttonStyle(.bwPressable)
                            .disabled(settings.generalChatExpireDays <= 1)
                            
                            Text("\(settings.generalChatExpireDays)")
                                .font(.bwTitle2())
                                .frame(minWidth: 40)
                            
                            Button(action: {
                                BWHaptics.lightImpact()
                                if settings.generalChatExpireDays < 90 {
                                    settings.generalChatExpireDays += 1
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(settings.generalChatExpireDays < 90 ? Color.bwAdaptivePrimary(for: colorScheme) : Color.secondary.opacity(0.3))
                            }
                            .buttonStyle(.bwPressable)
                            .disabled(settings.generalChatExpireDays >= 90)
                        }
                        
                        Text("days")
                            .font(.bwBody())
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.tertiarySystemBackground))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle(padding: 20, cornerRadius: 24)
        .animation(.bwSnappy, value: settings.chatAutoExpireEnabled)
    }
    
    // MARK: - Recipe Chats Section
    private var recipeChatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.bwSecondary.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "fork.knife")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.bwSecondary)
                }
                
                Text("Recipe Chats")
                    .font(BWTypography.cardTitle)
            }
            
            // Toggle row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keep recipe chats longer")
                        .font(.bwHeadline())
                    Text("Separate retention for recipe conversations")
                        .font(.bwCaption())
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $settings.keepRecipeChatsLonger)
                    .toggleStyle(SwitchToggleStyle(tint: Color.bwAccentGreen))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.tertiarySystemBackground))
            )
            
            // Recipe days selector (only show when enabled)
            if settings.keepRecipeChatsLonger {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Text("Keep for")
                            .font(.bwBody())
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                BWHaptics.lightImpact()
                                if settings.recipeChatExpireDays > 1 {
                                    settings.recipeChatExpireDays -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(settings.recipeChatExpireDays > 1 ? Color.bwAdaptiveSecondary(for: colorScheme) : Color.secondary.opacity(0.3))
                            }
                            .buttonStyle(.bwPressable)
                            .disabled(settings.recipeChatExpireDays <= 1)
                            
                            Text("\(settings.recipeChatExpireDays)")
                                .font(.bwTitle2())
                                .frame(minWidth: 40)
                            
                            Button(action: {
                                BWHaptics.lightImpact()
                                if settings.recipeChatExpireDays < 90 {
                                    settings.recipeChatExpireDays += 1
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(settings.recipeChatExpireDays < 90 ? Color.bwAdaptiveSecondary(for: colorScheme) : Color.secondary.opacity(0.3))
                            }
                            .buttonStyle(.bwPressable)
                            .disabled(settings.recipeChatExpireDays >= 90)
                        }
                        
                        Text("days")
                            .font(.bwBody())
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.tertiarySystemBackground))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Info text
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text(settings.keepRecipeChatsLonger 
                    ? "Recipe chats will be kept for \(settings.recipeChatExpireDays) days"
                    : "Recipe chats cleared after \(settings.generalChatExpireDays) days (same as general)")
                    .font(.bwCaption())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle(padding: 20, cornerRadius: 24)
        .animation(.bwSnappy, value: settings.keepRecipeChatsLonger)
    }
    
    // MARK: - Chat Statistics Section
    private var chatStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.bwAccent.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.bwAccent)
                }
                
                Text("Chat Statistics")
                    .font(BWTypography.cardTitle)
            }
            
            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(
                    title: "Chat Sessions",
                    value: "\(dataManager.chatSessions.count)",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: Color.bwPrimary
                )
                
                statCard(
                    title: "Recipe Conversations",
                    value: "\(dataManager.recipeChatHistories.count)",
                    icon: "fork.knife",
                    color: Color.bwSecondary
                )
                
                statCard(
                    title: "Total Messages",
                    value: "\(totalMessageCount)",
                    icon: "text.bubble.fill",
                    color: Color.bwAccent
                )
                
                statCard(
                    title: "Oldest Chat",
                    value: oldestChatAge,
                    icon: "clock.fill",
                    color: Color.bwProtein
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle(padding: 20, cornerRadius: 24)
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.bwTitle2())
                .foregroundColor(.primary)
            
            Text(title)
                .font(.bwCaption())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemBackground))
        )
        .adaptiveShadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Clear All Section
    private var clearAllSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.red)
                }
                
                Text("Clear Data")
                    .font(BWTypography.cardTitle)
            }
            
            // Clear button
            Button(action: {
                BWHaptics.warning()
                showClearConfirmation = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Clear All Chat History")
                        .font(.bwHeadline())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.bwPressable)
            
            // Warning text
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                
                Text("This action cannot be undone")
                    .font(.bwCaption())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle(padding: 20, cornerRadius: 24)
    }
    
    // MARK: - Computed Properties
    
    private var totalMessageCount: Int {
        // Count messages in chat sessions
        let sessionMessageCount = dataManager.chatSessions.reduce(0) { $0 + $1.messages.count }
        // Also count legacy chat history
        let generalCount = dataManager.generalChatHistory.count
        let recipeCount = dataManager.recipeChatHistories.values.reduce(0) { $0 + $1.count }
        return sessionMessageCount + generalCount + recipeCount
    }
    
    private var oldestChatAge: String {
        var oldestDate: Date?
        
        // Check chat sessions
        if let oldest = dataManager.chatSessions.min(by: { $0.createdAt < $1.createdAt }) {
            oldestDate = oldest.createdAt
        }
        
        // Check legacy general chat
        if let oldest = dataManager.generalChatHistory.min(by: { $0.timestamp < $1.timestamp }) {
            if oldestDate == nil || oldest.timestamp < oldestDate! {
                oldestDate = oldest.timestamp
            }
        }
        
        // Check legacy recipe chats
        for messages in dataManager.recipeChatHistories.values {
            if let oldest = messages.min(by: { $0.timestamp < $1.timestamp }) {
                if oldestDate == nil || oldest.timestamp < oldestDate! {
                    oldestDate = oldest.timestamp
                }
            }
        }
        
        guard let date = oldestDate else { return "None" }
        return TimeFormatter.timeAgo(from: date)
    }
    
    // MARK: - Actions
    
    private func clearAllChats() {
        BWHaptics.success()
        // Clear chat sessions (new system)
        dataManager.clearAllChatSessions()
        SessionContext.shared.clearActiveChatSession()
        
        // Clear legacy chat histories
        dataManager.clearAllChatHistories()
        SessionContext.shared.clearAllSessionData()
    }
}

#Preview {
    ChatSettingsScreen(onDone: {})
}

