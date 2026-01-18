import Foundation

// MARK: - Scan Merge Mode

/// Defines how new scan results should be merged with existing fridge items
enum ScanMergeMode: String, CaseIterable, Codable {
    case askEveryTime = "Ask Every Time"
    case replace = "Replace All"
    case add = "Add to Existing"
    case smartMerge = "Smart Merge"
    
    var description: String {
        switch self {
        case .askEveryTime: return "Show options each time you scan"
        case .replace: return "Clear fridge and use only new items"
        case .add: return "Keep existing items, add new ones"
        case .smartMerge: return "Update quantities, resolve duplicates"
        }
    }
    
    var icon: String {
        switch self {
        case .askEveryTime: return "questionmark.circle"
        case .replace: return "arrow.triangle.2.circlepath"
        case .add: return "plus.circle"
        case .smartMerge: return "arrow.triangle.merge"
        }
    }
    
    /// Returns merge mode options (excludes askEveryTime for the modal picker)
    static var mergeModes: [ScanMergeMode] {
        [.smartMerge, .add, .replace]
    }
}

// MARK: - Duplicate Resolution

/// Represents a duplicate item found during smart merge
struct DuplicateItem: Identifiable {
    let id = UUID()
    let existingItem: FridgeItem
    let newItem: FridgeItem
    var resolution: DuplicateResolution = .replace
    
    enum DuplicateResolution: String, CaseIterable {
        case keepExisting = "Keep Existing"
        case replace = "Use New"
        case combine = "Combine"
        
        var description: String {
            switch self {
            case .keepExisting: return "Keep the existing item"
            case .replace: return "Replace with new scan"
            case .combine: return "Add quantities together"
            }
        }
    }
}

// MARK: - Fridge Item Model

/// Represents an item stored in the user's fridge with freshness tracking
struct FridgeItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var quantity: String
    var category: String  // protein, dairy, vegetable, fruit, condiment, other
    var dateAdded: Date   // when this item was scanned/added
    /// Staple items (like spices) are not deducted when cooking - fridge items default to false
    var isStaple: Bool = false
    
    init(id: UUID = UUID(), name: String, quantity: String = "", category: String = "other", dateAdded: Date = Date(), isStaple: Bool = false) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.category = category
        self.dateAdded = dateAdded
        self.isStaple = isStaple
    }
}

// MARK: - Category Helpers
extension FridgeItem {
    /// Common food categories for organization
    static let categories = [
        "protein",
        "dairy", 
        "vegetable",
        "fruit",
        "condiment",
        "beverage",
        "other"
    ]
    
    /// Get a display-friendly category name
    var categoryDisplayName: String {
        category.capitalized
    }
    
    /// Get an icon for the category
    var categoryIcon: String {
        switch category.lowercased() {
        case "protein": return "fork.knife"
        case "dairy": return "cup.and.saucer.fill"
        case "vegetable": return "leaf.fill"
        case "fruit": return "apple.logo"
        case "condiment": return "drop.fill"
        case "beverage": return "mug.fill"
        default: return "square.grid.2x2.fill"
        }
    }
}

// MARK: - Time Formatting
extension FridgeItem {
    /// Returns a human-readable string for how long ago this item was added
    var timeAgoString: String {
        return TimeFormatter.timeAgo(from: dateAdded)
    }
}

// MARK: - Smart Time Formatter
struct TimeFormatter {
    /// Formats a date as a human-readable "X ago" string
    static func timeAgo(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        // Handle future dates (shouldn't happen, but just in case)
        guard interval >= 0 else { return "just now" }
        
        let seconds = Int(interval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        let weeks = days / 7
        
        if seconds < 60 {
            return "just now"
        } else if minutes < 60 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else if hours < 24 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if days < 7 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if weeks < 4 {
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else {
            // For older items, show the actual date
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    /// Shorter version for compact displays
    static func shortTimeAgo(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        guard interval >= 0 else { return "now" }
        
        let seconds = Int(interval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        
        if seconds < 60 {
            return "now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            return "\(days)d ago"
        }
    }
}

