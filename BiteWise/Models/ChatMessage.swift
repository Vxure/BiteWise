import Foundation

struct ChatMessage: Identifiable {
    var id = UUID()
    var text: String
    var isUser: Bool
    var timestamp: Date = Date()
}

// Dummy chat data
extension ChatMessage {
    static var dummyData: [ChatMessage] = [
        ChatMessage(text: "I'd like to make something with my ingredients", isUser: true),
        ChatMessage(text: "I've found several recipes that match your ingredients. Would you like something Italian?", isUser: false),
        ChatMessage(text: "Yes, Italian sounds good", isUser: true),
        ChatMessage(text: "Do you prefer high-protein options today?", isUser: false),
        ChatMessage(text: "Yes, I'm looking for something high in protein", isUser: true),
        ChatMessage(text: "I can also suggest a vegetarian option if you'd prefer that.", isUser: false)
    ]
} 