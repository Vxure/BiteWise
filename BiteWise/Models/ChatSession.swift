import Foundation

/// Represents a single chat conversation session
/// Can be a general chat or tied to a specific recipe
struct ChatSession: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date
    var recipeId: UUID?  // nil for general chats, set for recipe-specific chats
    
    /// Initialize a new chat session
    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        recipeId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.recipeId = recipeId
    }
    
    /// Check if this is a recipe-specific chat
    var isRecipeChat: Bool {
        recipeId != nil
    }
    
    /// Get a preview of the last message (for display in chat list)
    var lastMessagePreview: String? {
        messages.last?.text
    }
    
    /// Get the timestamp of the last activity
    var lastActivityDate: Date {
        messages.last?.timestamp ?? updatedAt
    }
    
    /// Auto-generate a title from the first user message
    /// Truncates to ~30 characters with ellipsis if needed
    static func generateTitle(from message: String) -> String {
        let cleaned = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.count <= 30 {
            return cleaned
        }
        // Find a good break point (space) near 30 chars
        let index = cleaned.index(cleaned.startIndex, offsetBy: 30)
        let substring = cleaned[..<index]
        if let lastSpace = substring.lastIndex(of: " ") {
            return String(cleaned[..<lastSpace]) + "..."
        }
        return String(substring) + "..."
    }
    
    /// Add a message to this session and update timestamp
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        updatedAt = Date()
        
        // Auto-generate title from first user message if still default
        if title == "New Chat", message.isUser {
            title = ChatSession.generateTitle(from: message.text)
        }
    }
    
    // MARK: - Equatable
    static func == (lhs: ChatSession, rhs: ChatSession) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Time Formatting Helper
extension ChatSession {
    /// Human-readable time since last activity
    var timeAgo: String {
        let now = Date()
        let interval = now.timeIntervalSince(lastActivityDate)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: lastActivityDate)
        }
    }
}

// MARK: - Dummy Data for Previews
extension ChatSession {
    static var dummyData: [ChatSession] {
        [
            ChatSession(
                title: "Pasta recipe ideas",
                messages: [
                    ChatMessage(text: "What pasta can I make with chicken?", isUser: true),
                    ChatMessage(text: "You could make a creamy chicken alfredo or a light lemon herb pasta!", isUser: false)
                ],
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: Date().addingTimeInterval(-1800)
            ),
            ChatSession(
                title: "Healthy breakfast options",
                messages: [
                    ChatMessage(text: "What's a good high-protein breakfast?", isUser: true),
                    ChatMessage(text: "Try a veggie omelette with feta cheese - it's packed with protein!", isUser: false)
                ],
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-86400)
            ),
            ChatSession(
                title: "Substituting ingredients",
                messages: [
                    ChatMessage(text: "Can I substitute butter with olive oil?", isUser: true),
                    ChatMessage(text: "Yes! Use about 3/4 the amount of olive oil as butter for most recipes.", isUser: false)
                ],
                createdAt: Date().addingTimeInterval(-172800),
                updatedAt: Date().addingTimeInterval(-172800)
            )
        ]
    }
}

