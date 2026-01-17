import SwiftUI

// MARK: - Standard Macro Badge (Pill Style)
struct MacroBadge: View {
    let label: String
    let value: Double
    let type: MacroType
    
    enum MacroType {
        case protein, carbs, fats
        
        var color: Color {
            switch self {
            case .protein: return Color.bwProtein
            case .carbs: return Color.bwCarbs
            case .fats: return Color.bwFats
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .protein: return Color.bwProtein.opacity(0.12)
            case .carbs: return Color.bwCarbs.opacity(0.12)
            case .fats: return Color.bwFats.opacity(0.12)
            }
        }
        
        var icon: String {
            switch self {
            case .protein: return "leaf.fill"
            case .carbs: return "bolt.fill"
            case .fats: return "drop.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Mini icon
            Image(systemName: type.icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(type.color)
            
            // Label
            Text(label)
                .font(BWTypography.badge)
                .foregroundColor(type.color)
            
            // Value with bold emphasis
            Text("\(Int(value))g")
                .font(BWTypography.badge)
                .fontWeight(.bold)
                .foregroundColor(type.color)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(type.backgroundColor)
        )
    }
}

// MARK: - Circular Progress Macro Badge
struct CircularMacroBadge: View {
    let label: String
    let value: Double
    let goal: Double
    let type: MacroBadge.MacroType
    var showLabel: Bool = true
    var size: CGFloat = 48
    
    private var progress: Double {
        min(value / goal, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Circular progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(type.color.opacity(0.15), lineWidth: 4)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        type.color,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                // Value inside
                VStack(spacing: 0) {
                    Text("\(Int(value))")
                        .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                        .foregroundColor(type.color)
                }
            }
            .frame(width: size, height: size)
            
            // Label below
            if showLabel {
                Text(label)
                    .font(BWTypography.captionSmall)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Compact Macro Indicator (for tight spaces)
struct CompactMacroBadge: View {
    let value: Double
    let type: MacroBadge.MacroType
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(type.color)
                .frame(width: 8, height: 8)
            
            Text("\(Int(value))g")
                .font(BWTypography.badge)
                .fontWeight(.semibold)
                .foregroundColor(type.color)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(type.backgroundColor)
        )
    }
}

// MARK: - Gradient Macro Badge (Premium Style)
struct GradientMacroBadge: View {
    let label: String
    let value: Double
    let type: MacroBadge.MacroType
    
    private var gradientColors: [Color] {
        switch type {
        case .protein: return [Color.bwProtein, Color.bwProtein.opacity(0.7)]
        case .carbs: return [Color.bwCarbs, Color.bwCarbs.opacity(0.7)]
        case .fats: return [Color.bwFats, Color.bwFats.opacity(0.7)]
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Label
            Text(label.prefix(1))
                .font(BWTypography.badge)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Value
            Text("\(Int(value))g")
                .font(BWTypography.badge)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: type.color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        // Standard badges
        Text("Standard Badges").font(.headline)
        HStack(spacing: 8) {
            MacroBadge(label: "P", value: 32, type: .protein)
            MacroBadge(label: "C", value: 45, type: .carbs)
            MacroBadge(label: "F", value: 12, type: .fats)
        }
        
        // Circular badges
        Text("Circular Progress").font(.headline)
        HStack(spacing: 16) {
            CircularMacroBadge(label: "Protein", value: 32, goal: 50, type: .protein)
            CircularMacroBadge(label: "Carbs", value: 45, goal: 100, type: .carbs)
            CircularMacroBadge(label: "Fats", value: 12, goal: 30, type: .fats)
        }
        
        // Compact badges
        Text("Compact Badges").font(.headline)
        HStack(spacing: 8) {
            CompactMacroBadge(value: 32, type: .protein)
            CompactMacroBadge(value: 45, type: .carbs)
            CompactMacroBadge(value: 12, type: .fats)
        }
        
        // Gradient badges
        Text("Gradient Badges").font(.headline)
        HStack(spacing: 8) {
            GradientMacroBadge(label: "Protein", value: 32, type: .protein)
            GradientMacroBadge(label: "Carbs", value: 45, type: .carbs)
            GradientMacroBadge(label: "Fats", value: 12, type: .fats)
        }
    }
    .padding()
    .bwBackground()
}
