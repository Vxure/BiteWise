import Foundation

// MARK: - Message Content Type
/// Defines the type of content in a chat message
enum MessageContent: Codable, Equatable {
    case text(String)
    case recipeCard(Recipe)
    
    // Custom Codable implementation for enum with associated values
    private enum CodingKeys: String, CodingKey {
        case type, textValue, recipeValue
    }
    
    private enum ContentType: String, Codable {
        case text, recipeCard
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)
        
        switch type {
        case .text:
            let text = try container.decode(String.self, forKey: .textValue)
            self = .text(text)
        case .recipeCard:
            let recipe = try container.decode(Recipe.self, forKey: .recipeValue)
            self = .recipeCard(recipe)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .text(let text):
            try container.encode(ContentType.text, forKey: .type)
            try container.encode(text, forKey: .textValue)
        case .recipeCard(let recipe):
            try container.encode(ContentType.recipeCard, forKey: .type)
            try container.encode(recipe, forKey: .recipeValue)
        }
    }
}

struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    var content: MessageContent
    var isUser: Bool
    var timestamp: Date = Date()
    
    /// Convenience property for backward compatibility - returns text if content is text type
    var text: String {
        if case .text(let str) = content {
            return str
        }
        return ""
    }
    
    /// Check if this message contains a recipe card
    var isRecipeCard: Bool {
        if case .recipeCard = content {
            return true
        }
        return false
    }
    
    /// Get the recipe if this is a recipe card message
    var recipe: Recipe? {
        if case .recipeCard(let recipe) = content {
            return recipe
        }
        return nil
    }
    
    // MARK: - Initializers
    
    /// Initialize with text content
    init(text: String, isUser: Bool) {
        self.content = .text(text)
        self.isUser = isUser
    }
    
    /// Initialize with recipe card content
    init(recipe: Recipe, isUser: Bool = false) {
        self.content = .recipeCard(recipe)
        self.isUser = isUser
    }
    
    /// Initialize with explicit content type
    init(id: UUID = UUID(), content: MessageContent, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// Dummy chat data
extension ChatMessage {
    static var dummyData: [ChatMessage] = [
        ChatMessage(text: "I'd like to make something with my ingredients", isUser: true),
        ChatMessage(text: "I've found several recipes that match your ingredients. Here's a great option:", isUser: false),
        ChatMessage(recipe: Recipe.dummyData[0], isUser: false),
        ChatMessage(text: "That looks great! Any other options?", isUser: true),
        ChatMessage(text: "Of course! Here's another recipe you might enjoy:", isUser: false),
        ChatMessage(recipe: Recipe.dummyData[3], isUser: false)
    ]
    
    /// Sample messages including a recipe card for testing
    static var dummyDataWithRecipe: [ChatMessage] = [
        ChatMessage(text: "I'd like a high-protein recipe", isUser: true),
        ChatMessage(text: "Here's a great high-protein option for you:", isUser: false),
        ChatMessage(recipe: Recipe.dummyData[0], isUser: false),
        ChatMessage(text: "That looks great! Any other options?", isUser: true)
    ]
} 