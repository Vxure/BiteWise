import SwiftUI

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Cooking Phase

private enum CookingPhase: Equatable {
    case preparation
    case cooking
    case celebration
}

// MARK: - Main Cooking Instructions Screen

struct CookingInstructionsScreen: View {
    let recipe: Recipe
    var onDismiss: () -> Void
    
    @State private var phase: CookingPhase = .preparation
    @State private var currentStep: Int = 0
    @Environment(\.colorScheme) var colorScheme
    
    private var adaptiveBackground: Color {
        colorScheme == .dark ? Color(.systemBackground) : Color.bwGradientCream
    }
    
    var body: some View {
        ZStack {
            adaptiveBackground
                .ignoresSafeArea()
            
            switch phase {
            case .preparation:
                IngredientPreparationView(
                    recipe: recipe,
                    colorScheme: colorScheme,
                    onStartCooking: { phase = .cooking },
                    onDismiss: onDismiss
                )
                .transition(.opacity)
                
            case .cooking:
                CookingStepView(
                    recipe: recipe,
                    currentStep: $currentStep,
                    colorScheme: colorScheme,
                    onComplete: { phase = .celebration },
                    onDismiss: onDismiss
                )
                .transition(.opacity)
                
            case .celebration:
                CookingCelebrationView(
                    recipe: recipe,
                    colorScheme: colorScheme,
                    onDismiss: onDismiss
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: phase)
    }
}

// MARK: - Cooking Header View

private struct CookingHeaderView: View {
    let recipeName: String
    let currentStep: Int
    let totalSteps: Int
    let stepTitles: [String]
    let colorScheme: ColorScheme
    var showBackButton: Bool = true
    var onDismiss: () -> Void
    
    @State private var isExpanded = false
    
    private var adaptivePrimary: Color {
        Color.bwAdaptivePrimary(for: colorScheme)
    }
    
    private var headerBackground: Color {
        colorScheme == .dark ? Color(.systemBackground) : Color.bwGradientCream
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main header bar
            VStack(spacing: 0) {
                HStack {
                    if showBackButton {
                        Button(action: {
                            BWHaptics.lightImpact()
                            onDismiss()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(width: 40, height: 40)
                                    .adaptiveShadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(adaptivePrimary)
                            }
                        }
                        .buttonStyle(.bwPressable)
                    }
                    
                    Spacer()
                    
                    Text(recipeName)
                        .font(BWTypography.cardTitle)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                // Segmented progress bar
                Button(action: {
                    BWHaptics.lightImpact()
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isExpanded.toggle()
                    }
                }) {
                    VStack(spacing: 8) {
                        HStack(spacing: 3) {
                            ForEach(0..<totalSteps, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(segmentColor(for: i))
                                    .frame(height: 5)
                                    .shadow(
                                        color: i == currentStep ? adaptivePrimary.opacity(0.4) : .clear,
                                        radius: 4, x: 0, y: 2
                                    )
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                        .padding(.horizontal, 20)
                        
                        HStack(spacing: 4) {
                            Text(currentStep == -1 ? "Ready to start" : "Step \(currentStep + 1) of \(totalSteps)")
                                .font(BWTypography.captionSmall)
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                .animation(.easeInOut(duration: 0.3), value: isExpanded)
                        }
                        .padding(.bottom, 8)
                    }
                }
                .buttonStyle(.plain)
            }
            .background(headerBackground)
            
            // Expanded step list with height animation
            VStack(spacing: 0) {
                if isExpanded {
                    Divider()
                    
                    VStack(spacing: 10) {
                        ForEach(Array(stepTitles.enumerated()), id: \.offset) { index, title in
                            HStack(spacing: 12) {
                                if index < currentStep {
                                    ZStack {
                                        Circle()
                                            .fill(adaptivePrimary)
                                            .frame(width: 28, height: 28)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(index == currentStep ? adaptivePrimary : Color(.systemGray4))
                                            .frame(width: 28, height: 28)
                                        Text("\(index + 1)")
                                            .font(BWTypography.captionSmall)
                                            .fontWeight(.semibold)
                                            .foregroundColor(index == currentStep ? .white : .secondary)
                                    }
                                }
                                
                                Text(title)
                                    .font(BWTypography.bodySecondary)
                                    .foregroundColor(index == currentStep ? .primary : .secondary)
                                    .lineLimit(2)
                                
                                Spacer()
                                
                                if index == currentStep {
                                    Text("Current")
                                        .font(BWTypography.captionSmall)
                                        .fontWeight(.medium)
                                        .foregroundColor(adaptivePrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(adaptivePrimary.opacity(0.12))
                                        .clipShape(Capsule())
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(x: -16)),
                                removal: .opacity
                            ))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    Button(action: {
                        BWHaptics.lightImpact()
                        withAnimation(.easeInOut(duration: 0.4)) { isExpanded = false }
                    }) {
                        HStack(spacing: 4) {
                            Text("Collapse")
                                .font(BWTypography.captionSmall)
                            Image(systemName: "chevron.up")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .background(headerBackground)
            .clipped()
        }
        .adaptiveShadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private func segmentColor(for index: Int) -> Color {
        if index < currentStep {
            return adaptivePrimary.opacity(0.7)
        } else if index == currentStep {
            return adaptivePrimary
        } else {
            return Color(.systemGray4)
        }
    }
}

// MARK: - Ingredient Preparation View

private struct IngredientPreparationView: View {
    let recipe: Recipe
    let colorScheme: ColorScheme
    var onStartCooking: () -> Void
    var onDismiss: () -> Void
    
    private var adaptivePrimary: Color {
        Color.bwAdaptivePrimary(for: colorScheme)
    }
    
    private var adaptiveAccent: Color {
        Color.bwAdaptiveAccent(for: colorScheme)
    }
    
    private var headerBackground: Color {
        colorScheme == .dark ? Color(.systemBackground) : Color.bwGradientCream
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Color.clear.frame(height: 100)
                    
                    Text(recipe.description)
                        .font(BWTypography.bodyPrimary)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .staggeredAppear(index: 0)
                    
                    // Stats pills
                    HStack(spacing: 8) {
                        StatPill(
                            icon: "clock",
                            text: "\(recipe.prepTime + recipe.cookTime) min",
                            bgColor: adaptivePrimary.opacity(0.1),
                            fgColor: adaptivePrimary
                        )
                        
                        StatPill(
                            icon: "flame",
                            text: "\(recipe.macros.calories) kcal",
                            bgColor: adaptiveAccent.opacity(0.1),
                            fgColor: adaptiveAccent
                        )
                        
                        StatPill(
                            icon: "fork.knife",
                            text: "\(Int(recipe.macros.protein))g protein",
                            bgColor: Color.bwAdaptiveAccentGold(for: colorScheme).opacity(0.1),
                            fgColor: Color.bwAdaptiveAccentGold(for: colorScheme)
                        )
                    }
                    .staggeredAppear(index: 1)
                    
                    // Ingredients card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Ingredients")
                            .font(BWTypography.cardTitle)
                        
                        ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(adaptivePrimary)
                                    .frame(width: 6, height: 6)
                                
                                Text(ingredient)
                                    .font(BWTypography.bodyPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                            }
                        }
                    }
                    .bwCardStyle(padding: 16, cornerRadius: 24)
                    .staggeredAppear(index: 2)
                    
                    // Steps overview card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Steps Overview")
                            .font(BWTypography.cardTitle)
                        
                        let stepCount = recipe.cookingSteps?.count ?? recipe.steps.count
                        ForEach(0..<stepCount, id: \.self) { index in
                            let cookingStep = recipe.cookingSteps?[safe: index]
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [adaptivePrimary, adaptivePrimary.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 30, height: 30)
                                    
                                    Text("\(index + 1)")
                                        .font(BWTypography.captionSmall)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    if let title = cookingStep?.title {
                                        Text(title)
                                            .font(BWTypography.bodyEmphasis)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Text(cookingStep?.instruction ?? recipe.steps[safe: index] ?? "")
                                        .font(BWTypography.bodyPrimary)
                                        .foregroundColor(cookingStep != nil ? .secondary : .primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    if let duration = cookingStep?.durationMinutes, duration > 0 {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 10, weight: .medium))
                                            Text("\(duration) min")
                                                .font(BWTypography.captionSmall)
                                        }
                                        .foregroundColor(adaptivePrimary.opacity(0.8))
                                        .padding(.top, 2)
                                    }
                                }
                                .padding(.top, 4)
                                
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .bwCardStyle(padding: 16, cornerRadius: 24)
                    .staggeredAppear(index: 3)
                    
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
            
            CookingHeaderView(
                recipeName: recipe.title,
                currentStep: -1,
                totalSteps: recipe.cookingSteps?.count ?? recipe.steps.count,
                stepTitles: recipe.cookingSteps?.map { $0.title } ?? recipe.steps,
                colorScheme: colorScheme,
                onDismiss: onDismiss
            )
            
            // Fixed bottom button
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    Button(action: {
                        BWHaptics.mediumImpact()
                        onStartCooking()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Start Cooking")
                                .font(BWTypography.buttonLabel)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(BWGradients.primaryGradient(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .adaptiveShadow(color: Color.bwPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.bwPressable)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    headerBackground.opacity(0.8)
                        .background(.ultraThinMaterial)
                )
            }
        }
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let icon: String
    let text: String
    let bgColor: Color
    let fgColor: Color
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
            Text(text)
                .font(BWTypography.captionSmall)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .foregroundColor(fgColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(bgColor)
        .clipShape(Capsule())
    }
}

// MARK: - Cooking Step View

private struct CookingStepView: View {
    let recipe: Recipe
    @Binding var currentStep: Int
    let colorScheme: ColorScheme
    var onComplete: () -> Void
    var onDismiss: () -> Void
    
    @State private var timeRemaining: Int = 120
    @State private var totalTime: Int = 120
    @State private var isTimerRunning = false
    @State private var isDone = false
    @State private var stepContentId = UUID()
    
    private var adaptivePrimary: Color {
        Color.bwAdaptivePrimary(for: colorScheme)
    }
    
    private var adaptiveAccent: Color {
        Color.bwAdaptiveAccent(for: colorScheme)
    }
    
    private var headerBackground: Color {
        colorScheme == .dark ? Color(.systemBackground) : Color.bwGradientCream
    }
    
    private var currentCookingStep: CookingStep? {
        guard let cookingSteps = recipe.cookingSteps,
              currentStep < cookingSteps.count else { return nil }
        return cookingSteps[currentStep]
    }
    
    private var totalStepCount: Int {
        recipe.cookingSteps?.count ?? recipe.steps.count
    }
    
    private var stepInstruction: String {
        currentCookingStep?.instruction ?? recipe.steps[currentStep]
    }
    
    private var stepTitle: String? {
        currentCookingStep?.title
    }
    
    private var timerProgress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }
    
    private var chefTip: String {
        if let tip = currentCookingStep?.chefTip, !tip.isEmpty {
            return tip
        }
        let fallbackTips = [
            "Take your time -- good cooking is never rushed.",
            "Taste as you go to build layers of flavor.",
            "Keep your workspace clean for a smoother flow.",
            "Trust the process -- each step builds on the last.",
            "Let ingredients reach room temperature for even cooking.",
            "A sharp knife is safer and more effective than a dull one.",
            "Don't overcrowd the pan -- cook in batches if needed.",
            "Season gradually -- you can always add more, but can't take it away."
        ]
        return fallbackTips[currentStep % fallbackTips.count]
    }
    
    private var stepIngredients: [String] {
        if let ingredients = currentCookingStep?.ingredients, !ingredients.isEmpty {
            return ingredients
        }
        return ingredientsForStepFallback(currentStep)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 20) {
                    Color.clear.frame(height: 100)
                    
                    // Animated step content (crossfade on step change)
                    VStack(spacing: 20) {
                        circularTimer
                        
                        VStack(spacing: 4) {
                            Text("Step \(currentStep + 1)")
                                .font(BWTypography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            if let title = stepTitle {
                                Text(title)
                                    .font(BWTypography.cardTitle)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Instructions card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Instructions")
                                .font(BWTypography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [adaptiveAccent, Color.bwPrimaryOrange],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 26, height: 26)
                                    
                                    Text("\(currentStep + 1)")
                                        .font(BWTypography.captionSmall)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                
                                Text(stepInstruction)
                                    .font(BWTypography.bodyPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 2)
                                
                                Spacer(minLength: 0)
                            }
                        }
                        .bwCardStyle(padding: 18, cornerRadius: 24)
                        
                        // Chef tip
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(adaptivePrimary)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Chef Tip")
                                    .font(BWTypography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(adaptivePrimary)
                                
                                Text(chefTip)
                                    .font(BWTypography.bodySecondary)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer(minLength: 0)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(adaptivePrimary.opacity(0.08))
                        )
                        
                        // Ingredients for this step
                        if !stepIngredients.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ingredients for this step")
                                    .font(BWTypography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                ForEach(stepIngredients, id: \.self) { ingredient in
                                    HStack(spacing: 10) {
                                        Circle()
                                            .fill(adaptiveAccent)
                                            .frame(width: 5, height: 5)
                                        Text(ingredient)
                                            .font(BWTypography.bodyPrimary)
                                        Spacer()
                                    }
                                }
                            }
                            .bwCardStyle(padding: 18, cornerRadius: 24)
                        }
                    }
                    .id(stepContentId)
                    .transition(.opacity)
                    
                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal, 20)
            }
            
            CookingHeaderView(
                recipeName: recipe.title,
                currentStep: currentStep,
                totalSteps: totalStepCount,
                stepTitles: recipe.cookingSteps?.map { $0.title } ?? recipe.steps,
                colorScheme: colorScheme,
                onDismiss: onDismiss
            )
            
            // Bottom controls
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        BWHaptics.mediumImpact()
                        toggleTimer()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .contentTransition(.symbolEffect(.replace))
                            Text(isTimerRunning ? "Pause" : "Start")
                                .font(BWTypography.buttonLabel)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.bwPressable)
                    
                    Button(action: {
                        BWHaptics.mediumImpact()
                        handleDone()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isDone ? "arrow.right" : "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .contentTransition(.symbolEffect(.replace))
                            Text(isDone ? (currentStep == totalStepCount - 1 ? "Finish" : "Next") : "Done")
                                .font(BWTypography.buttonLabel)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            isDone
                                ? BWGradients.primaryGradient(for: colorScheme)
                                : BWGradients.accentGradient(for: colorScheme)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .adaptiveShadow(
                            color: isDone ? Color.bwPrimary.opacity(0.3) : Color.bwAccent.opacity(0.3),
                            radius: 10, x: 0, y: 5
                        )
                    }
                    .buttonStyle(.bwPressable)
                    .animation(.easeInOut(duration: 0.3), value: isDone)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    headerBackground.opacity(0.8)
                        .background(.ultraThinMaterial)
                )
            }
        }
        .onAppear { resetTimerForStep() }
        .onChange(of: currentStep) { _, _ in resetTimerForStep() }
        .onReceive(
            Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        ) { _ in
            guard isTimerRunning, timeRemaining > 0 else {
                if timeRemaining == 0 { isTimerRunning = false }
                return
            }
            timeRemaining -= 1
        }
    }
    
    // MARK: - Circular Timer
    
    private var circularTimer: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 10)
                .frame(width: 180, height: 180)
            
            Circle()
                .trim(from: 0, to: timerProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.bwAdaptiveAccent(for: colorScheme),
                            Color.bwAdaptivePrimaryOrange(for: colorScheme)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 180, height: 180)
                .animation(.linear(duration: 1), value: timerProgress)
            
            VStack(spacing: 6) {
                Text(formatTime(timeRemaining))
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.3), value: timeRemaining)
                
                Text(isTimerRunning ? "Cooking..." : "Ready")
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: isTimerRunning)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func toggleTimer() {
        if timeRemaining == 0 {
            timeRemaining = totalTime
            isTimerRunning = true
        } else {
            isTimerRunning.toggle()
        }
    }
    
    private func handleDone() {
        if !isDone {
            isDone = true
            isTimerRunning = false
        } else {
            if currentStep >= totalStepCount - 1 {
                BWHaptics.success()
                onComplete()
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    stepContentId = UUID()
                    currentStep += 1
                    isDone = false
                }
            }
        }
    }
    
    private func resetTimerForStep() {
        let perStep: Int
        if let cookingStep = currentCookingStep {
            perStep = max(30, cookingStep.durationMinutes * 60)
        } else {
            let totalCookTime = (recipe.prepTime + recipe.cookTime) * 60
            perStep = max(60, totalCookTime / max(recipe.steps.count, 1))
        }
        totalTime = perStep
        timeRemaining = perStep
        isTimerRunning = false
        isDone = false
    }
    
    private func ingredientsForStepFallback(_ step: Int) -> [String] {
        let count = recipe.ingredients.count
        let steps = recipe.steps.count
        guard count > 0, steps > 0 else { return recipe.ingredients }
        
        let perStep = max(1, count / steps)
        let start = min(step * perStep, count)
        let end = min(start + perStep + (step == steps - 1 ? count - start : 0), count)
        
        guard start < end else {
            return [recipe.ingredients.last ?? "Check previous steps"]
        }
        return Array(recipe.ingredients[start..<end])
    }
}

// MARK: - Cooking Celebration View

private struct CookingCelebrationView: View {
    let recipe: Recipe
    let colorScheme: ColorScheme
    var onDismiss: () -> Void
    
    @ObservedObject private var dataManager = DataManager.shared
    @State private var hasMarkedAsCooked = false
    @State private var deductedItems: [String] = []
    @State private var showDeductionInfo = false
    
    @State private var showConfetti = true
    @State private var iconScale: CGFloat = 0
    @State private var iconRotation: Double = -180
    @State private var contentScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var statsOpacity: Double = 0
    @State private var statsOffsetY: CGFloat = 20
    @State private var buttonsOpacity: Double = 0
    @State private var buttonsOffsetY: CGFloat = 20
    @State private var ring1Scale: CGFloat = 1.0
    @State private var ring1Opacity: Double = 0.5
    @State private var ring2Scale: CGFloat = 1.0
    @State private var ring2Opacity: Double = 0.5
    
    private var adaptivePrimary: Color {
        Color.bwAdaptivePrimary(for: colorScheme)
    }
    
    private var isAlreadyCooked: Bool {
        dataManager.isCooked(recipe)
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)
                    
                    ZStack {
                        Circle()
                            .stroke(adaptivePrimary.opacity(0.3), lineWidth: 3)
                            .frame(width: 130, height: 130)
                            .scaleEffect(ring1Scale)
                            .opacity(ring1Opacity)
                        
                        Circle()
                            .stroke(adaptivePrimary.opacity(0.3), lineWidth: 3)
                            .frame(width: 130, height: 130)
                            .scaleEffect(ring2Scale)
                            .opacity(ring2Opacity)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [adaptivePrimary, adaptivePrimary.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: adaptivePrimary.opacity(0.4), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "frying.pan.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50)
                            .foregroundColor(.white)
                    }
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))
                    .padding(.bottom, 32)
                    
                    VStack(spacing: 10) {
                        Text("Bon Appetit!")
                            .font(BWTypography.displayLarge)
                            .foregroundColor(.primary)
                        
                        Text("Your ")
                            .font(BWTypography.bodyPrimary)
                            .foregroundColor(.secondary)
                        +
                        Text(recipe.title)
                            .font(BWTypography.bodyEmphasis)
                            .foregroundColor(adaptivePrimary)
                        +
                        Text(" is ready!")
                            .font(BWTypography.bodyPrimary)
                            .foregroundColor(.secondary)
                        
                        Text("Time to enjoy your creation")
                            .font(BWTypography.bodySecondary)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
                    .padding(.bottom, 32)
                    
                    HStack(spacing: 12) {
                        CelebrationStat(
                            value: "\(recipe.cookingSteps?.count ?? recipe.steps.count)",
                            label: "Steps",
                            color: adaptivePrimary
                        )
                        
                        CelebrationStat(
                            value: "\(recipe.prepTime + recipe.cookTime)",
                            label: "Minutes",
                            color: Color.bwAdaptiveAccent(for: colorScheme)
                        )
                        
                        CelebrationStat(
                            value: "\(recipe.macros.calories)",
                            label: "kcal",
                            color: Color.bwAdaptiveAccentGold(for: colorScheme)
                        )
                    }
                    .padding(.horizontal, 20)
                    .opacity(statsOpacity)
                    .offset(y: statsOffsetY)
                    .padding(.bottom, 40)
                    
                    VStack(spacing: 12) {
                        // Mark as Cooked button
                        Button(action: {
                            guard !hasMarkedAsCooked && !isAlreadyCooked else { return }
                            BWHaptics.success()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dataManager.markAsCooked(recipe)
                                deductedItems = dataManager.deductIngredients(for: recipe)
                                hasMarkedAsCooked = true
                            }
                            if !deductedItems.isEmpty {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showDeductionInfo = true
                                }
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: (hasMarkedAsCooked || isAlreadyCooked) ? "checkmark.circle.fill" : "checkmark.circle")
                                    .font(.system(size: 18, weight: .semibold))
                                    .contentTransition(.symbolEffect(.replace))
                                Text((hasMarkedAsCooked || isAlreadyCooked) ? "Marked as Cooked" : "Mark as Cooked")
                                    .font(BWTypography.buttonLabel)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                (hasMarkedAsCooked || isAlreadyCooked)
                                    ? BWGradients.primaryGradient(for: colorScheme)
                                    : BWGradients.accentGradient(for: colorScheme)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .adaptiveShadow(
                                color: (hasMarkedAsCooked || isAlreadyCooked)
                                    ? adaptivePrimary.opacity(0.3)
                                    : Color.bwAccent.opacity(0.3),
                                radius: 12, x: 0, y: 6
                            )
                        }
                        .buttonStyle(.bwPressable)
                        .disabled(hasMarkedAsCooked || isAlreadyCooked)
                        .opacity((hasMarkedAsCooked || isAlreadyCooked) ? 0.9 : 1.0)
                        
                        Button(action: {
                            BWHaptics.mediumImpact()
                            onDismiss()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back to Recipe")
                                    .font(BWTypography.buttonLabel)
                            }
                            .foregroundColor(adaptivePrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(adaptivePrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(adaptivePrimary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.bwPressable)
                    }
                    .padding(.horizontal, 20)
                    .opacity(buttonsOpacity)
                    .offset(y: buttonsOffsetY)
                    
                    Spacer().frame(height: 40)
                }
            }
            
            if showConfetti {
                CookingConfettiView(colorScheme: colorScheme)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            hasMarkedAsCooked = isAlreadyCooked
            startCelebrationAnimations()
        }
        .alert("Ingredients Removed", isPresented: $showDeductionInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            if deductedItems.isEmpty {
                Text("Marked as cooked! No matching ingredients were found in your inventory.")
            } else {
                Text("Marked as cooked!\n\nRemoved from ingredients:\n\(deductedItems.joined(separator: ", "))")
            }
        }
    }
    
    private func startCelebrationAnimations() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.2)) {
            contentScale = 1.0
            contentOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.65, dampingFraction: 0.5).delay(0.4)) {
            iconScale = 1.0
            iconRotation = 0
        }
        
        withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
            ring1Scale = 1.5
            ring1Opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                ring2Scale = 1.5
                ring2Opacity = 0
            }
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            textOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            statsOpacity = 1.0
            statsOffsetY = 0
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
            buttonsOpacity = 1.0
            buttonsOffsetY = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showConfetti = false
            }
        }
    }
}

// MARK: - Celebration Stat

private struct CelebrationStat: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(BWTypography.numericMedium)
                .foregroundColor(color)
            
            Text(label)
                .font(BWTypography.captionSmall)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .bwCardStyle(padding: 0, cornerRadius: 20)
    }
}

// MARK: - Confetti View

private struct CookingConfettiView: View {
    let colorScheme: ColorScheme
    
    @State private var particles: [ConfettiParticle] = []
    
    struct ConfettiParticle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let duration: Double
        let color: Color
        let size: CGFloat
        let rotation: Double
        var yOffset: CGFloat = -40
        var opacity: Double = 1.0
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x, y: particle.yOffset)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                generateParticles(in: geo.size)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    animateParticles(screenHeight: geo.size.height)
                }
            }
        }
    }
    
    private func generateParticles(in size: CGSize) {
        let colors: [Color] = [
            .bwAccent,
            .bwPrimaryOrange,
            .bwAccentGold,
            Color.bwAdaptivePrimary(for: colorScheme),
            Color.bwAdaptiveSecondary(for: colorScheme),
            .bwAccentBlue
        ]
        
        particles = (0..<50).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                delay: Double.random(in: 0...0.5),
                duration: Double.random(in: 2.0...4.0),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...10),
                rotation: Double.random(in: 0...360)
            )
        }
    }
    
    private func animateParticles(screenHeight: CGFloat) {
        for i in particles.indices {
            withAnimation(
                .linear(duration: particles[i].duration)
                .delay(particles[i].delay)
            ) {
                particles[i].yOffset = screenHeight + 40
            }
            
            // Fade out near the end
            withAnimation(
                .linear(duration: particles[i].duration * 0.3)
                .delay(particles[i].delay + particles[i].duration * 0.7)
            ) {
                particles[i].opacity = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CookingInstructionsScreen(
        recipe: Recipe.dummyData[3],
        onDismiss: {}
    )
}
