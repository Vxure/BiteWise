import SwiftUI

/// A reusable macro goals editor that can be used as a sheet or embedded in a screen
struct MacroGoalsEditorSheet: View {
    @Binding var macroGoals: UserProfile.MacroGoals
    @Binding var hasMacroGoals: Bool
    var isSheet: Bool = true
    var onSave: (() -> Void)?
    var onCancel: (() -> Void)?
    
    // Local editing state
    @State private var calories: Double = 2000
    @State private var proteinPercent: Double = 30
    @State private var carbsPercent: Double = 40
    @State private var fatsPercent: Double = 30
    
    // For direct number input
    @State private var showCalorieInput = false
    @State private var showProteinGramsInput = false
    @State private var calorieInputText = ""
    @State private var proteinGramsInputText = ""
    
    // Computed gram values
    private var proteinGrams: Int {
        Int((calories * proteinPercent / 100) / 4)
    }
    
    private var carbsGrams: Int {
        Int((calories * carbsPercent / 100) / 4)
    }
    
    private var fatsGrams: Int {
        Int((calories * fatsPercent / 100) / 9)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (only for sheet mode)
            if isSheet {
                sheetHeader
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    // Calorie Goal Section
                    calorieSection
                    
                    // Macro Distribution Bar
                    macroDistributionBar
                    
                    // Individual Macro Controls
                    macroControlsSection
                    
                    // Reset Button
                    resetButton
                    
                    if !isSheet {
                        Spacer(minLength: 20)
                    }
                }
                .padding(.horizontal, isSheet ? 20 : 0)
                .padding(.top, isSheet ? 8 : 0)
                .padding(.bottom, isSheet ? 100 : 20)
            }
            
            // Bottom buttons (only for sheet mode)
            if isSheet {
                bottomButtons
            }
        }
        .background {
            if isSheet {
                BWGradients.backgroundGradient
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            loadCurrentValues()
        }
        .alert("Set Daily Calories", isPresented: $showCalorieInput) {
            TextField("Calories", text: $calorieInputText)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) { }
            Button("Set") {
                if let value = Double(calorieInputText), value >= 1200, value <= 4000 {
                    calories = value
                    BWHaptics.selection()
                }
            }
        } message: {
            Text("Enter a value between 1200 and 4000")
        }
        .alert("Set Protein (grams)", isPresented: $showProteinGramsInput) {
            TextField("Protein grams", text: $proteinGramsInputText)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) { }
            Button("Set") {
                if let grams = Double(proteinGramsInputText) {
                    // Convert grams to percentage: grams * 4 cal/g / total calories * 100
                    let percent = (grams * 4 / calories) * 100
                    // Clamp to valid range
                    let clampedPercent = min(max(percent, 10), 60)
                    updateProteinPercent(clampedPercent)
                    BWHaptics.selection()
                }
            }
        } message: {
            // Calculate valid gram range based on current calories
            let minGrams = Int((calories * 10 / 100) / 4)
            let maxGrams = Int((calories * 60 / 100) / 4)
            Text("Enter a value between \(minGrams)g and \(maxGrams)g")
        }
    }
    
    // MARK: - Sheet Header
    private var sheetHeader: some View {
        VStack(spacing: 4) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            Text("Edit Macro Goals")
                .font(BWTypography.sectionSubheader)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
    }
    
    // MARK: - Calorie Section
    private var calorieSection: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.bwCalories.opacity(0.12))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.bwCalories)
                    }
                    
                    Text("Daily Calories")
                        .font(BWTypography.cardTitle)
                }
                
                Spacer()
                
                // Tappable calorie display
                Button(action: {
                    BWHaptics.lightImpact()
                    calorieInputText = "\(Int(calories))"
                    showCalorieInput = true
                }) {
                    HStack(spacing: 4) {
                        Text("\(Int(calories))")
                            .font(BWTypography.numericMedium)
                            .foregroundColor(Color.bwCalories)
                        
                        Text("cal")
                            .font(BWTypography.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.bwCalories.opacity(0.1))
                    )
                }
                .buttonStyle(.bwPressable)
            }
            
            // Calorie slider
            VStack(spacing: 8) {
                Slider(value: $calories, in: 1200...4000, step: 50)
                    .tint(Color.bwCalories)
                    .onChange(of: calories) { _, _ in
                        BWHaptics.selection()
                    }
                
                HStack {
                    Text("1200")
                        .font(BWTypography.captionSmall)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("4000")
                        .font(BWTypography.captionSmall)
                        .foregroundColor(.secondary)
                }
            }
        }
        .bwCardStyle(padding: 20, cornerRadius: 20)
    }
    
    // MARK: - Macro Distribution Bar
    private var macroDistributionBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macro Distribution")
                .font(BWTypography.cardTitle)
            
            // Segmented bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    // Protein segment
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.bwProtein)
                        .frame(width: max(geometry.size.width * CGFloat(proteinPercent / 100) - 2, 0))
                    
                    // Carbs segment
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.bwCarbs)
                        .frame(width: max(geometry.size.width * CGFloat(carbsPercent / 100) - 2, 0))
                    
                    // Fats segment
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.bwFats)
                        .frame(width: max(geometry.size.width * CGFloat(fatsPercent / 100) - 2, 0))
                }
                .animation(.bwSpring, value: proteinPercent)
            }
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Legend
            HStack(spacing: 16) {
                macroLegendItem(color: Color.bwProtein, label: "Protein", percent: Int(proteinPercent))
                macroLegendItem(color: Color.bwCarbs, label: "Carbs", percent: Int(carbsPercent))
                macroLegendItem(color: Color.bwFats, label: "Fats", percent: Int(fatsPercent))
            }
        }
        .bwCardStyle(padding: 20, cornerRadius: 20)
    }
    
    private func macroLegendItem(color: Color, label: String, percent: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text("\(label) \(percent)%")
                .font(BWTypography.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Macro Controls Section
    private var macroControlsSection: some View {
        VStack(spacing: 16) {
            // Protein control (editable)
            macroSliderCard(
                title: "Protein",
                emoji: "💪",
                percent: proteinPercent,
                grams: proteinGrams,
                color: Color.bwProtein,
                isEditable: true,
                onTap: {
                    proteinGramsInputText = "\(proteinGrams)"
                    showProteinGramsInput = true
                },
                onSliderChange: { newValue in
                    updateProteinPercent(newValue)
                }
            )
            
            // Carbs display (auto-calculated)
            macroDisplayCard(
                title: "Carbs",
                emoji: "⚡️",
                percent: Int(carbsPercent),
                grams: carbsGrams,
                color: Color.bwCarbs
            )
            
            // Fats display (auto-calculated)
            macroDisplayCard(
                title: "Fats",
                emoji: "🥑",
                percent: Int(fatsPercent),
                grams: fatsGrams,
                color: Color.bwFats
            )
            
            // Explanation
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.bwPrimary.opacity(0.6))
                
                Text("Adjust protein and carbs/fats will auto-balance to 100%")
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func macroSliderCard(
        title: String,
        emoji: String,
        percent: Double,
        grams: Int,
        color: Color,
        isEditable: Bool,
        onTap: @escaping () -> Void,
        onSliderChange: @escaping (Double) -> Void
    ) -> some View {
        VStack(spacing: 14) {
            HStack {
                HStack(spacing: 10) {
                    Text(emoji)
                        .font(.system(size: 20))
                    
                    Text(title)
                        .font(BWTypography.cardTitle)
                }
                
                Spacer()
                
                // Tappable value display - grams primary, percentage secondary
                Button(action: {
                    BWHaptics.lightImpact()
                    onTap()
                }) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 2) {
                            Text("\(grams)")
                                .font(BWTypography.numericSmall)
                                .foregroundColor(color)
                            Text("g")
                                .font(BWTypography.caption)
                                .foregroundColor(color.opacity(0.7))
                        }
                        
                        Text("\(Int(percent))%")
                            .font(BWTypography.captionSmall)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color.opacity(0.1))
                    )
                }
                .buttonStyle(.bwPressable)
            }
            
            // Slider
            Slider(value: Binding(
                get: { percent },
                set: { onSliderChange($0) }
            ), in: 10...60, step: 1)
            .tint(color)
        }
        .bwCardStyle(padding: 18, cornerRadius: 20)
    }
    
    private func macroDisplayCard(
        title: String,
        emoji: String,
        percent: Int,
        grams: Int,
        color: Color
    ) -> some View {
        HStack {
            HStack(spacing: 10) {
                Text(emoji)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(BWTypography.cardTitle)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Text("Auto")
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.1))
                    )
                
                // Grams primary, percentage secondary
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Text("\(grams)")
                            .font(BWTypography.numericSmall)
                            .foregroundColor(color)
                        Text("g")
                            .font(BWTypography.caption)
                            .foregroundColor(color.opacity(0.7))
                    }
                    
                    Text("\(percent)%")
                        .font(BWTypography.captionSmall)
                        .foregroundColor(.secondary)
                }
            }
        }
        .bwCardStyle(padding: 18, cornerRadius: 20)
    }
    
    // MARK: - Reset Button
    private var resetButton: some View {
        Button(action: resetToDefaults) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .medium))
                
                Text("Reset to Defaults")
                    .font(BWTypography.buttonSmall)
            }
            .foregroundColor(.secondary)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                Capsule()
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .buttonStyle(.bwPressable)
    }
    
    // MARK: - Bottom Buttons (Sheet Mode)
    private var bottomButtons: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Cancel button
                Button(action: {
                    BWHaptics.lightImpact()
                    onCancel?()
                }) {
                    Text("Cancel")
                        .font(BWTypography.buttonLabel)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.gray.opacity(0.1))
                        )
                }
                .buttonStyle(.bwPressable)
                
                // Save button
                Button(action: saveGoals) {
                    Text("Save")
                        .font(BWTypography.buttonLabel)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.bwPrimary, Color.bwSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(.bwPressable)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.bwSurface)
        }
    }
    
    // MARK: - Actions
    
    private func loadCurrentValues() {
        calories = Double(macroGoals.dailyCalories)
        proteinPercent = macroGoals.proteinPercentage
        carbsPercent = macroGoals.carbsPercentage
        fatsPercent = macroGoals.fatsPercentage
    }
    
    private func updateProteinPercent(_ newValue: Double) {
        proteinPercent = newValue
        
        // Calculate remaining percentage
        let remaining = 100 - newValue
        
        // If there was existing carbs/fats distribution, maintain their ratio
        let oldRemaining = carbsPercent + fatsPercent
        if oldRemaining > 0 {
            let carbsRatio = carbsPercent / oldRemaining
            let fatsRatio = fatsPercent / oldRemaining
            
            carbsPercent = remaining * carbsRatio
            fatsPercent = remaining * fatsRatio
        } else {
            // Default to 50/50 split
            carbsPercent = remaining / 2
            fatsPercent = remaining / 2
        }
        
        // Ensure they sum to 100
        let total = proteinPercent + carbsPercent + fatsPercent
        if abs(total - 100) > 0.01 {
            fatsPercent = 100 - proteinPercent - carbsPercent
        }
        
        BWHaptics.selection()
    }
    
    private func resetToDefaults() {
        BWHaptics.lightImpact()
        withAnimation(.bwSpring) {
            calories = 2000
            proteinPercent = 30
            carbsPercent = 40
            fatsPercent = 30
        }
    }
    
    func saveGoals() {
        BWHaptics.success()
        macroGoals = UserProfile.MacroGoals(
            dailyCalories: Int(calories),
            proteinPercentage: proteinPercent,
            carbsPercentage: carbsPercent,
            fatsPercentage: fatsPercent
        )
        hasMacroGoals = true
        onSave?()
    }
}

#Preview {
    MacroGoalsEditorSheet(
        macroGoals: .constant(UserProfile.MacroGoals(
            dailyCalories: 2000,
            proteinPercentage: 30,
            carbsPercentage: 40,
            fatsPercentage: 30
        )),
        hasMacroGoals: .constant(true),
        isSheet: true,
        onSave: {},
        onCancel: {}
    )
}

