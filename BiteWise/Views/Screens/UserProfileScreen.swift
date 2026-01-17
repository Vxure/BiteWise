import SwiftUI

struct UserProfileScreen: View {
    @State private var profile = UserProfile.dummy
    @State private var newPreference = ""
    @State private var newAllergy = ""
    @State private var showMacroEditor = false
    @State private var isEditingName = false
    @ObservedObject private var dataManager = DataManager.shared
    @FocusState private var isPreferenceFocused: Bool
    @FocusState private var isAllergyFocused: Bool
    @FocusState private var isNameFocused: Bool
    var onDone: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            BWGradients.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Profile Header
                    profileHeaderSection
                        .staggeredAppear(index: 0)
                    
                    // MARK: - Dietary Preferences
                    dietaryPreferencesSection
                        .staggeredAppear(index: 1)
                    
                    // MARK: - Allergies
                    allergiesSection
                        .staggeredAppear(index: 2)
                    
                    // MARK: - Macro Goals
                    macroGoalsSection
                        .staggeredAppear(index: 3)
                    
                    // MARK: - Save Button
                    GradientButton(
                        icon: "checkmark.circle.fill",
                        text: "Save Profile",
                        action: saveAndDone
                    )
                    .padding(.top, 8)
                    .staggeredAppear(index: 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
        .customNavigation()
        .onAppear {
            // Load existing profile from DataManager
            profile = dataManager.userProfile
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isPreferenceFocused = false
            isAllergyFocused = false
            isNameFocused = false
            if isEditingName {
                isEditingName = false
            }
        }
        .sheet(isPresented: $showMacroEditor) {
            MacroGoalsEditorSheet(
                macroGoals: $profile.macroGoals,
                hasMacroGoals: $profile.hasMacroGoals,
                isSheet: true,
                onSave: {
                    showMacroEditor = false
                },
                onCancel: {
                    showMacroEditor = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Avatar with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.bwPrimary, Color.bwSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.bwPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                
                // User initial
                Text(String(profile.name.prefix(1)).uppercased())
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // User name with edit capability
            HStack(spacing: 8) {
                if isEditingName {
                    TextField("Your name", text: $profile.name)
                        .font(BWTypography.sectionHeader)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            isEditingName = false
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.bwPrimary.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Text(profile.name)
                        .font(BWTypography.sectionHeader)
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    BWHaptics.lightImpact()
                    if isEditingName {
                        // Save and close
                        isEditingName = false
                        isNameFocused = false
                    } else {
                        // Start editing
                        isEditingName = true
                        isNameFocused = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isEditingName ? Color.bwPrimary : Color.bwPrimary.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: isEditingName ? "checkmark" : "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isEditingName ? .white : Color.bwPrimary)
                    }
                }
                .buttonStyle(.bwPressable)
            }
            .animation(.bwSnappy, value: isEditingName)
            
            // Profile completeness badge
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.bwPrimary)
                
                Text("Profile Complete")
                    .font(BWTypography.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.bwPrimary.opacity(0.1))
            )
        }
        .frame(maxWidth: .infinity)
        .bwCardStyle(padding: 24, cornerRadius: 24)
    }
    
    // MARK: - Dietary Preferences Section
    private var dietaryPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.bwPrimary.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.bwPrimary)
                }
                
                Text("Dietary Preferences")
                    .font(BWTypography.cardTitle)
            }
            
            // Input field
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18))
                    .foregroundColor(isPreferenceFocused ? Color.bwPrimary : .secondary)
                
                TextField("Add a preference...", text: $newPreference)
                    .font(BWTypography.bodyPrimary)
                    .focused($isPreferenceFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        addPreference()
                    }
                
                if !newPreference.isEmpty {
                    Button(action: addPreference) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color.bwPrimary)
                    }
                    .buttonStyle(.bwPressable)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isPreferenceFocused ? Color.bwPrimary.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .animation(.bwSnappy, value: isPreferenceFocused)
            .animation(.bwSnappy, value: newPreference.isEmpty)
            
            // Tags
            if !profile.dietaryPreferences.isEmpty {
                FlowLayout(horizontalSpacing: 8, verticalSpacing: 10) {
                    ForEach(profile.dietaryPreferences, id: \.self) { preference in
                        preferenceTag(preference)
                    }
                }
            } else {
                emptyStateView(
                    icon: "leaf",
                    message: "No preferences added yet"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle(padding: 20, cornerRadius: 24)
    }
    
    private func preferenceTag(_ preference: String) -> some View {
        HStack(spacing: 6) {
            Text(preference)
                .font(BWTypography.bodySecondary)
                .foregroundColor(Color.bwPrimary)
            
            Button(action: {
                BWHaptics.lightImpact()
                withAnimation(.bwSpring) {
                    removePreference(preference)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.bwPrimary.opacity(0.6))
            }
            .buttonStyle(.bwPressable)
        }
        .padding(.vertical, 10)
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.bwPrimary.opacity(0.12), Color.bwPrimary.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(Color.bwPrimary.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Allergies Section
    private var allergiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.bwAccent.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.bwAccent)
                }
                
                Text("Allergies & Intolerances")
                    .font(BWTypography.cardTitle)
            }
            
            // Input field
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18))
                    .foregroundColor(isAllergyFocused ? Color.bwAccent : .secondary)
                
                TextField("Add an allergy...", text: $newAllergy)
                    .font(BWTypography.bodyPrimary)
                    .focused($isAllergyFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        addAllergy()
                    }
                
                if !newAllergy.isEmpty {
                    Button(action: addAllergy) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color.bwAccent)
                    }
                    .buttonStyle(.bwPressable)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isAllergyFocused ? Color.bwAccent.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .animation(.bwSnappy, value: isAllergyFocused)
            .animation(.bwSnappy, value: newAllergy.isEmpty)
            
            // Tags
            if !profile.allergies.isEmpty {
                FlowLayout(horizontalSpacing: 8, verticalSpacing: 10) {
                    ForEach(profile.allergies, id: \.self) { allergy in
                        allergyTag(allergy)
                    }
                }
            } else {
                emptyStateView(
                    icon: "checkmark.shield",
                    message: "No allergies added"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle(padding: 20, cornerRadius: 24)
    }
    
    private func allergyTag(_ allergy: String) -> some View {
        HStack(spacing: 6) {
            Text(allergy)
                .font(BWTypography.bodySecondary)
                .foregroundColor(Color.bwAccent)
            
            Button(action: {
                BWHaptics.lightImpact()
                withAnimation(.bwSpring) {
                    removeAllergy(allergy)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color.bwAccent.opacity(0.6))
            }
            .buttonStyle(.bwPressable)
        }
        .padding(.vertical, 10)
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.bwAccent.opacity(0.12), Color.bwAccent.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            Capsule()
                .stroke(Color.bwAccent.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Macro Goals Section
    private var macroGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with Edit button
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.bwProtein.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.bwProtein)
                    }
                    
                    Text("Macro Goals")
                        .font(BWTypography.cardTitle)
                }
                
                Spacer()
                
                // Edit button
                Button(action: {
                    BWHaptics.lightImpact()
                    showMacroEditor = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Edit")
                            .font(BWTypography.buttonSmall)
                    }
                    .foregroundColor(Color.bwPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.bwPrimary.opacity(0.1))
                    )
                }
                .buttonStyle(.bwPressable)
            }
            
            // Status badge for macro goals
            if profile.hasMacroGoals {
                // Daily calories badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                    Text("\(profile.macroGoals.dailyCalories) cal/day")
                        .font(BWTypography.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color.bwCalories)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.bwCalories.opacity(0.12))
                )
            } else {
                // Not set badge
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                    Text("Not configured - tap Edit to set goals")
                        .font(BWTypography.caption)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.08))
                )
            }
            
            // Macro cards grid (tappable to open editor)
            Button(action: {
                BWHaptics.lightImpact()
                showMacroEditor = true
            }) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    macroCard(
                        title: "Protein",
                        emoji: "💪",
                        percentage: profile.macroGoals.proteinPercentage,
                        color: Color.bwProtein
                    )
                    
                    macroCard(
                        title: "Carbs",
                        emoji: "⚡️",
                        percentage: profile.macroGoals.carbsPercentage,
                        color: Color.bwCarbs
                    )
                    
                    macroCard(
                        title: "Fats",
                        emoji: "🥑",
                        percentage: profile.macroGoals.fatsPercentage,
                        color: Color.bwFats
                    )
                    
                    // Summary card
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.25))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "equal.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Text("Total")
                            .font(BWTypography.captionSmall)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("100%")
                            .font(BWTypography.numericSmall)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.bwPrimary, Color.bwSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color.bwPrimary.opacity(0.3), radius: 6, x: 0, y: 3)
                }
            }
            .buttonStyle(.bwPressable)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle(padding: 20, cornerRadius: 24)
    }
    
    private func macroCard(title: String, emoji: String, percentage: Double, color: Color) -> some View {
        // Calculate grams based on calories and percentage
        let calories = Double(profile.macroGoals.dailyCalories)
        let divisor: Double = (title == "Fats") ? 9 : 4 // Fats = 9 cal/g, Protein & Carbs = 4 cal/g
        let grams = Int((calories * percentage / 100) / divisor)
        
        return VStack(spacing: 10) {
            // Circular progress
            ZStack {
                CircularProgressRing(
                    progress: percentage / 100,
                    lineWidth: 6,
                    backgroundColor: Color.white.opacity(0.25),
                    foregroundColor: .white,
                    animateOnAppear: true
                )
                .frame(width: 44, height: 44)
                
                Text(emoji)
                    .font(.system(size: 16))
            }
            
            Text(title)
                .font(BWTypography.captionSmall)
                .foregroundColor(.white.opacity(0.9))
            
            // Grams primary, percentage secondary
            VStack(spacing: 2) {
                Text("\(grams)g")
                    .font(BWTypography.numericSmall)
                    .foregroundColor(.white)
                
                Text("\(Int(percentage))%")
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Empty State View
    private func emptyStateView(icon: String, message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(BWTypography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.02))
                .strokeBorder(Color.black.opacity(0.05), style: StrokeStyle(lineWidth: 1, dash: [6]))
        )
    }
    
    // MARK: - Actions
    
    /// Save profile to DataManager and dismiss
    private func saveAndDone() {
        BWHaptics.success()
        dataManager.userProfile = profile
        dataManager.saveUserProfile()
        onDone()
    }
    
    private func addPreference() {
        guard !newPreference.isEmpty else { return }
        BWHaptics.lightImpact()
        withAnimation(.bwSpring) {
            profile.dietaryPreferences.append(newPreference.trimmingCharacters(in: .whitespacesAndNewlines))
            newPreference = ""
        }
    }
    
    private func removePreference(_ preference: String) {
        profile.dietaryPreferences.removeAll { $0 == preference }
    }
    
    private func addAllergy() {
        guard !newAllergy.isEmpty else { return }
        BWHaptics.lightImpact()
        withAnimation(.bwSpring) {
            profile.allergies.append(newAllergy.trimmingCharacters(in: .whitespacesAndNewlines))
            newAllergy = ""
        }
    }
    
    private func removeAllergy(_ allergy: String) {
        profile.allergies.removeAll { $0 == allergy }
    }
}

#Preview {
    UserProfileScreen(onDone: {})
}
