import SwiftUI

/// Slide-out drawer for chat history with session list
struct ChatHistoryDrawer: View {
    @Binding var isOpen: Bool
    @ObservedObject var sessionContext = SessionContext.shared
    @ObservedObject var dataManager = DataManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var onSelectSession: (ChatSession) -> Void
    var onNewChat: () -> Void
    
    // Drawer configuration
    private let drawerWidth: CGFloat = 300
    private let tabBarHeight: CGFloat = 100 // Updated to match the user's latest setting
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Backdrop
                if isOpen {
                    Color.black
                        .opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isOpen = false
                            }
                        }
                        .transition(.opacity)
                }
                
                // Drawer content - stops above tab bar
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        DrawerHeader(onNewChat: {
                            BWHaptics.mediumImpact()
                            onNewChat()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isOpen = false
                            }
                        })
                        
                        Divider()
                            .background(Color.bwPrimary.opacity(0.15))
                        
                        // Session list
                        if dataManager.chatSessions.isEmpty {
                            EmptySessionsView()
                        } else {
                            SessionListView(
                                sessions: dataManager.chatSessions,
                                activeSessionId: sessionContext.activeChatSession?.id,
                                onSelect: { session in
                                    BWHaptics.lightImpact()
                                    onSelectSession(session)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        isOpen = false
                                    }
                                },
                                onDelete: { session in
                                    BWHaptics.mediumImpact()
                                    sessionContext.deleteChatSession(session.id)
                                }
                            )
                        }
                        
                        Spacer(minLength: 0)
                        
//                        // Footer
//                        DrawerFooter()
                    }
                    .frame(width: drawerWidth)
                    // Stop above the tab bar with a small 16pt gap for aesthetics
                    .frame(maxHeight: geometry.size.height - tabBarHeight - 50)
                    .background(
                        // Fully opaque solid background to hide content underneath
                        colorScheme == .dark ? Color(.systemBackground) : Color(hex: "FEF9E0")
                    )
                    .clipShape(
                        RoundedCornerShape(radius: 24, corners: [.topRight, .bottomRight])
                    )
                    .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.2), radius: 24, x: 8, y: 0)
                    .shadow(color: colorScheme == .dark ? Color.clear : Color.bwPrimary.opacity(0.1), radius: 8, x: 2, y: 0)
                    .offset(x: isOpen ? 0 : -drawerWidth - 20)
                    
                    Spacer()
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isOpen)
    }
}

// MARK: - Drawer Header

private struct DrawerHeader: View {
    var onNewChat: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Logo/Title
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
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Chats")
                        .font(BWTypography.sectionSubheader)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            // New Chat Button
            Button(action: onNewChat) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("New Chat")
                        .font(BWTypography.buttonSmall)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.bwPrimary, Color.bwSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.bwPrimary.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.bwPressable)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60) // Account for safe area
        .padding(.bottom, 16)
    }
}

// MARK: - Session List View

private struct SessionListView: View {
    let sessions: [ChatSession]
    let activeSessionId: UUID?
    var onSelect: (ChatSession) -> Void
    var onDelete: (ChatSession) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                // Group sessions by time period
                let grouped = groupSessionsByTime(sessions)
                
                ForEach(grouped.keys.sorted(by: { $0.order < $1.order }), id: \.self) { period in
                    if let periodSessions = grouped[period], !periodSessions.isEmpty {
                        Section {
                            ForEach(periodSessions) { session in
                                SessionRow(
                                    session: session,
                                    isActive: session.id == activeSessionId,
                                    onSelect: { onSelect(session) },
                                    onDelete: { onDelete(session) }
                                )
                            }
                        } header: {
                            Text(period.title)
                                .font(BWTypography.captionSmall)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .padding(.bottom, 4)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func groupSessionsByTime(_ sessions: [ChatSession]) -> [TimePeriod: [ChatSession]] {
        var grouped: [TimePeriod: [ChatSession]] = [:]
        let calendar = Calendar.current
        let now = Date()
        
        for session in sessions {
            let period: TimePeriod
            
            if calendar.isDateInToday(session.updatedAt) {
                period = .today
            } else if calendar.isDateInYesterday(session.updatedAt) {
                period = .yesterday
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
                      session.updatedAt > weekAgo {
                period = .thisWeek
            } else if let monthAgo = calendar.date(byAdding: .month, value: -1, to: now),
                      session.updatedAt > monthAgo {
                period = .thisMonth
            } else {
                period = .older
            }
            
            if grouped[period] == nil {
                grouped[period] = []
            }
            grouped[period]?.append(session)
        }
        
        return grouped
    }
}

// MARK: - Time Period Enum

private enum TimePeriod: Hashable {
    case today
    case yesterday
    case thisWeek
    case thisMonth
    case older
    
    var title: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .older: return "Older"
        }
    }
    
    var order: Int {
        switch self {
        case .today: return 0
        case .yesterday: return 1
        case .thisWeek: return 2
        case .thisMonth: return 3
        case .older: return 4
        }
    }
}

// MARK: - Session Row

private struct SessionRow: View {
    let session: ChatSession
    let isActive: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isActive ? Color.bwAccent.opacity(0.15) : Color.bwPrimary.opacity(0.08))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: session.isRecipeChat ? "fork.knife" : "bubble.left.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isActive ? Color.bwAccent : Color.bwPrimary)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(session.title)
                        .font(BWTypography.caption)
                        .fontWeight(isActive ? .semibold : .medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(session.timeAgo)
                        .font(BWTypography.captionSmall)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isActive {
                    Circle()
                        .fill(Color.bwAccent)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle()) // Extend hitbox to entire row
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color(.secondarySystemBackground) : Color.clear)
                    .shadow(color: isActive && colorScheme == .light ? Color.black.opacity(0.05) : .clear, radius: 4, y: 2)
            )
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Chat", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Empty Sessions View

private struct EmptySessionsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.bwPrimary.opacity(0.08))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color.bwPrimary.opacity(0.5))
            }
            
            VStack(spacing: 6) {
                Text("No conversations yet")
                    .font(BWTypography.bodyPrimary)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Start a new chat to get recipe ideas and cooking tips")
                    .font(BWTypography.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// // MARK: - Drawer Footer
//
//private struct DrawerFooter: View {
//    var body: some View {
//        VStack(spacing: 0) {
//            Divider()
//                .background(Color.bwPrimary.opacity(0.15))
//            
//            HStack(spacing: 8) {
//                Image(systemName: "sparkles")
//                    .font(.system(size: 12, weight: .medium))
//                    .foregroundColor(Color.bwAccent)
//                
//                Text("Powered by AI")
//                    .font(BWTypography.captionSmall)
//                    .foregroundColor(.secondary)
//            }
//            .padding(.vertical, 16)
//        }
//        .frame(maxWidth: .infinity)
//        .background(Color(hex: "FEF9E0"))
//    }
//}

// MARK: - Preview

#Preview {
    ZStack {
        Color.bwGradientCream
            .ignoresSafeArea()
        
        ChatHistoryDrawer(
            isOpen: .constant(true),
            onSelectSession: { _ in },
            onNewChat: { }
        )
    }
}
