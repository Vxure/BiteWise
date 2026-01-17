import SwiftUI
import MarkdownUI

struct ChatBubble: View {
    let message: ChatMessage
    
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
                                colors: [Color.bwPrimaryCoral.opacity(0.2), Color.bwPrimaryOrange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.bwPrimaryCoral)
                }
            }
            
            // Use Markdown for AI responses, plain Text for user messages
            Group {
                if message.isUser {
                    Text(message.text)
                        .font(.bwBody())
                } else {
                    Markdown(message.text)
                        .markdownTheme(.biteWise)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                message.isUser
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [Color.bwPrimaryCoral, Color.bwPrimaryOrange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(Color.white.opacity(0.9))
            )
            .foregroundColor(message.isUser ? .white : .primary)
            .roundedCorner(20, corners: message.isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
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

#Preview {
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
