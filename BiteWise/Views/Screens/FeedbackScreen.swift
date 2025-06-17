import SwiftUI

struct FeedbackScreen: View {
    @State private var rating = 0
    @State private var enjoyedRecipe = false
    @State private var comments = ""
    var onDone: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Recipe Feedback")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("How would you rate this recipe?")
                    .font(.title3)
                
                // Star rating
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title)
                            .foregroundColor(star <= rating ? .yellow : .gray)
                            .onTapGesture {
                                rating = star
                            }
                    }
                }
                .padding()
                
                // Enjoyed recipe toggle
                Toggle(isOn: $enjoyedRecipe) {
                    Text("I enjoyed this recipe")
                        .font(.headline)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Comments section
                VStack(alignment: .leading) {
                    Text("Comments")
                        .font(.headline)
                    
                    TextEditor(text: $comments)
                        .frame(minHeight: 100)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding()
                
                // Submit button
                Button(action: onDone) {
                    Text("Submit Feedback")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    FeedbackScreen(onDone: {})
} 