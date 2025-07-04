import SwiftUI

struct UserProfileScreen: View {
    @State private var profile = UserProfile.dummy
    @State private var newPreference = ""
    @State private var newAllergy = ""
    var onDone: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Your Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Dietary preferences section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dietary Preferences")
                        .font(.headline)
                    
                    // Add preference field
                    HStack {
                        TextField("Add preference...", text: $newPreference)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: addPreference) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                                .imageScale(.large)
                        }
                        .disabled(newPreference.isEmpty)
                    }
                    
                    // Preferences list
                    FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                        ForEach(profile.dietaryPreferences, id: \.self) { preference in
                            HStack {
                                Text(preference)
                                
                                Button(action: { removePreference(preference) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .imageScale(.small)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 1)
                
                // Allergies section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Allergies & Intolerances")
                        .font(.headline)
                    
                    // Add allergy field
                    HStack {
                        TextField("Add allergy...", text: $newAllergy)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: addAllergy) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                                .imageScale(.large)
                        }
                        .disabled(newAllergy.isEmpty)
                    }
                    
                    // Allergies list
                    FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                        ForEach(profile.allergies, id: \.self) { allergy in
                            HStack {
                                Text(allergy)
                                
                                Button(action: { removeAllergy(allergy) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .imageScale(.small)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 1)
                
                // Macro goals section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Macro Goals")
                        .font(.headline)
                    
                    // Daily calories
                    HStack {
                        Text("Daily Calories")
                        Spacer()
                        Text("\(profile.macroGoals.dailyCalories) cal")
                            .bold()
                    }
                    
                    // Protein percentage
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Protein")
                            Spacer()
                            Text("\(Int(profile.macroGoals.proteinPercentage))%")
                        }
                        
                        ProgressView(value: profile.macroGoals.proteinPercentage, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.7, green: 0.9, blue: 0.7)))
                    }
                    
                    // Carbs percentage
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Carbs")
                            Spacer()
                            Text("\(Int(profile.macroGoals.carbsPercentage))%")
                        }
                        
                        ProgressView(value: profile.macroGoals.carbsPercentage, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.9, green: 0.9, blue: 0.9)))
                    }
                    
                    // Fats percentage
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Fats")
                            Spacer()
                            Text("\(Int(profile.macroGoals.fatsPercentage))%")
                        }
                        
                        ProgressView(value: profile.macroGoals.fatsPercentage, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.9, green: 0.9, blue: 0.7)))
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 1)
                
                // Done button
                Button(action: onDone) {
                    Text("Save Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.vertical)
            }
            .padding()
        }
        .background(Color.gray.opacity(0.05))
    }
    
    private func addPreference() {
        guard !newPreference.isEmpty else { return }
        profile.dietaryPreferences.append(newPreference.trimmingCharacters(in: .whitespacesAndNewlines))
        newPreference = ""
    }
    
    private func removePreference(_ preference: String) {
        profile.dietaryPreferences.removeAll { $0 == preference }
    }
    
    private func addAllergy() {
        guard !newAllergy.isEmpty else { return }
        profile.allergies.append(newAllergy.trimmingCharacters(in: .whitespacesAndNewlines))
        newAllergy = ""
    }
    
    private func removeAllergy(_ allergy: String) {
        profile.allergies.removeAll { $0 == allergy }
    }
}

#Preview {
    UserProfileScreen(onDone: {})
} 
 