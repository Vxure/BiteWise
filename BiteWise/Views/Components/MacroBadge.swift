import SwiftUI

struct MacroBadge: View {
    let label: String
    let value: Double
    let type: MacroType
    
    enum MacroType {
        case protein, carbs, fats
        
        var color: Color {
            switch self {
            case .protein: return Color(red: 0.7, green: 0.9, blue: 0.7) // Pastel green
            case .fats: return Color(red: 0.9, green: 0.9, blue: 0.7) // Pastel yellow
            case .carbs: return Color(red: 0.9, green: 0.9, blue: 0.9) // Neutral light gray
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .bold()
            
            Text("\(Int(value))g")
                .font(.caption)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(type.color)
        .cornerRadius(8)
    }
}

#Preview {
    HStack {
        MacroBadge(label: "Protein", value: 32, type: .protein)
        MacroBadge(label: "Carbs", value: 45, type: .carbs)
        MacroBadge(label: "Fats", value: 12, type: .fats)
    }
} 