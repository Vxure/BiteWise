import SwiftUI

struct FeedbackScreen: View {
    @State private var rating = 0
    @State private var enjoyedRecipe = false
    @State private var comments = ""
    @Environment(\.colorScheme) var colorScheme
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
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Send Feedback")
                            .font(.bwLargeTitle())
                        
                        Text("Help us improve BiteWise")
                            .font(.bwSubheadline())
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Star rating card
                    VStack(spacing: 16) {
                        Text("How would you rate the app?")
                            .font(.bwHeadline())
                        
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 36))
                                    .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.3))
                                    .scaleEffect(star <= rating ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)
                                    .onTapGesture {
                                        BWHaptics.lightImpact()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            rating = star
                                        }
                                    }
                            }
                        }
                        
                        if rating > 0 {
                            Text(ratingText)
                                .font(.bwSubheadline())
                                .foregroundColor(.secondary)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .bwCardStyle()
                    
                    // Enjoyed app toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("I enjoy using BiteWise")
                                .font(.bwHeadline())
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                            Text("Helps us understand satisfaction")
                                .font(.bwCaption())
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $enjoyedRecipe)
                            .toggleStyle(SwitchToggleStyle(tint: Color.bwAccentGreen))
                            .labelsHidden()
                    }
                    .bwCardStyle()
                    
                    // Comments section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Additional Comments")
                            .font(.bwHeadline())
                        
                        ZStack(alignment: .topLeading) {
                            if comments.isEmpty {
                                Text("Share your thoughts, suggestions, or report issues...")
                                    .font(.bwBody())
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(.top, 12)
                                    .padding(.leading, 12)
                            }
                            
                            TextEditor(text: $comments)
                                .font(.bwBody())
                                .frame(minHeight: 120)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.tertiarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bwCardStyle()
                    
                    // Submit button
                    GradientButton(
                        icon: "paperplane.fill",
                        text: "Submit Feedback",
                        action: {
                            BWHaptics.success()
                            onDone()
                        }
                    )
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .customNavigation()
    }
    
    private var ratingText: String {
        switch rating {
        case 1: return "Not great 😔"
        case 2: return "Could be better 🤔"
        case 3: return "It's okay 👍"
        case 4: return "Really good! 😊"
        case 5: return "Love it! 🌟"
        default: return ""
        }
    }
}

#Preview {
    FeedbackScreen(onDone: {})
}
