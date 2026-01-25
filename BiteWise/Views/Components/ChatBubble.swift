import SwiftUI
import MarkdownUI

struct ChatBubble: View {
    let message: ChatMessage
    var onRecipeTap: ((Recipe) -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
            } else {
                // AI avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.bwAdaptivePrimaryCoral(for: colorScheme).opacity(0.2), 
                                    Color.bwAdaptivePrimaryOrange(for: colorScheme).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.bwAdaptivePrimaryCoral(for: colorScheme))
                }
            }
            
            // Render content based on message type
            switch message.content {
            case .text(let text):
                // Use Markdown for AI responses, plain Text for user messages
                Group {
                    if message.isUser {
                        Text(text)
                            .font(.bwBody())
                    } else {
                        Markdown(text)
                            .markdownTheme(.biteWise)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    message.isUser
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    colorScheme == .dark ? Color(hex: "FF8A65") : Color.bwPrimaryCoral,
                                    colorScheme == .dark ? Color(hex: "FFAB91") : Color.bwPrimaryOrange
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : AnyShapeStyle(Color(.secondarySystemBackground))
                )
                .foregroundColor(message.isUser ? .white : .primary)
                .roundedCorner(20, corners: message.isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                
            case .recipeCard(let recipe):
                MiniRecipeCard(recipe: recipe, onTap: {
                    onRecipeTap?(recipe)
                })
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Mini Recipe Card
/// A compact recipe card for displaying in chat bubbles
struct MiniRecipeCard: View {
    let recipe: Recipe
    var onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isPressed = false
    
    // Determine recipe color based on title
    private var recipeColor: Color {
        if recipe.title.contains("Carbonara") || recipe.title.contains("Pasta") {
            return Color.bwCarbs
        } else if recipe.title.contains("Stir Fry") || recipe.title.contains("Chicken") {
            return Color.bwPrimary
        } else if recipe.title.contains("Risotto") || recipe.title.contains("Mushroom") {
            return Color.bwProtein
        } else {
            return Color.bwPrimary
        }
    }
    
    // Determine recipe icon
    private var recipeIcon: String {
        if recipe.title.contains("Carbonara") || recipe.title.contains("Pasta") {
            return "fork.knife"
        } else if recipe.title.contains("Stir Fry") {
            return "flame.fill"
        } else if recipe.title.contains("Salad") {
            return "leaf.fill"
        } else {
            return "fork.knife"
        }
    }
    
    var body: some View {
        Button(action: {
            BWHaptics.lightImpact()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // Recipe image placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [recipeColor.opacity(0.25), recipeColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 80)
                    
                    Image(systemName: recipeIcon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(recipeColor)
                }
                
                // Recipe title
                Text(recipe.title)
                    .font(BWTypography.bodyPrimary)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Macro badges row
                HStack(spacing: 6) {
                    MiniMacroBadge(value: Int(recipe.macros.protein), label: "P", color: Color.green.opacity(0.8))
                    MiniMacroBadge(value: Int(recipe.macros.carbs), label: "C", color: Color.blue.opacity(0.8))
                    MiniMacroBadge(value: Int(recipe.macros.fats), label: "F", color: Color.orange.opacity(0.8))
                }
                
                // Time and View Recipe button
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("\(recipe.prepTime + recipe.cookTime) min")
                            .font(BWTypography.captionSmall)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("View Recipe")
                        .font(BWTypography.captionSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(recipeColor)
                }
            }
            .padding(14)
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.tertiarySystemBackground))
            )
            .shadow(color: colorScheme == .dark ? .clear : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(recipeColor.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.bwPressable)
    }
}

// MARK: - Mini Macro Badge
/// A compact macro badge for use in mini recipe cards
struct MiniMacroBadge: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
            Text("\(value)g")
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - BiteWise Markdown Theme
extension MarkdownUI.Theme {
    /// Custom BiteWise theme for chat markdown rendering
    static let biteWise = Theme()
        .text {
            FontFamily(.system(.rounded))
            FontSize(16)
            ForegroundColor(.primary)
        }
        .strong {
            FontWeight(.semibold)
        }
        .heading1 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamily(.system(.rounded))
                    FontSize(20)
                    FontWeight(.bold)
                }
                .markdownMargin(top: 8, bottom: 4)
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamily(.system(.rounded))
                    FontSize(18)
                    FontWeight(.semibold)
                }
                .markdownMargin(top: 6, bottom: 4)
        }
        .heading3 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamily(.system(.rounded))
                    FontSize(16)
                    FontWeight(.semibold)
                }
                .markdownMargin(top: 4, bottom: 2)
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: 2, bottom: 2)
        }
        .code {
            FontFamily(.system(.monospaced))
            FontSize(14)
            BackgroundColor(Color.gray.opacity(0.1))
        }
        .link {
            ForegroundColor(Color.bwPrimary)
        }
}

// Extension for rounded specific corners
extension View {
    func roundedCorner(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview("Text Messages") {
    ZStack {
        BWGradients.backgroundGradient
            .ignoresSafeArea()
        
        VStack(spacing: 12) {
            ChatBubble(message: ChatMessage(text: "Hello! I'd like some recipe suggestions", isUser: true))
            ChatBubble(message: ChatMessage(text: "I can help with that. Would you like something high in protein?", isUser: false))
        }
        .padding()
    }
}

#Preview("Recipe Card") {
    ZStack {
        BWGradients.backgroundGradient
            .ignoresSafeArea()
        
        VStack(spacing: 12) {
            ChatBubble(message: ChatMessage(text: "Here's a great recipe for you:", isUser: false))
            ChatBubble(message: ChatMessage(recipe: Recipe.dummyData[0], isUser: false)) { recipe in
                print("Tapped recipe: \(recipe.title)")
            }
        }
        .padding()
    }
}
