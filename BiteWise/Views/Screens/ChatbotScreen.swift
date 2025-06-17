import SwiftUI

struct ChatbotScreen: View {
    @State private var messages = ChatMessage.dummyData
    @State private var newMessage = ""
    var onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Recipe Assistant")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onDone) {
                    Text("Done")
                        .bold()
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Chat messages
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                    }
                }
                .padding(.vertical)
            }
            
            // Input area
            HStack(spacing: 12) {
                TextField("Type a message...", text: $newMessage)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(newMessage.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(20)
                }
                .disabled(newMessage.isEmpty)
            }
            .padding()
        }
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(text: newMessage, isUser: true)
        messages.append(userMessage)
        newMessage = ""
        
        // Simulate response - would connect to backend in real app
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let botResponses = [
                "I'll look for recipes with those ingredients.",
                "Would you prefer something quick to make?",
                "How about a pasta dish with these ingredients?",
                "I can suggest some healthy options if you'd like."
            ]
            let response = botResponses.randomElement() ?? "Sorry, I don't understand that."
            let botMessage = ChatMessage(text: response, isUser: false)
            messages.append(botMessage)
        }
    }
}

#Preview {
    ChatbotScreen(onDone: {})
} 