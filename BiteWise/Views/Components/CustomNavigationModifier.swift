import SwiftUI

struct CustomNavigationModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        BWHaptics.lightImpact()
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.bwPrimary)
                        }
                    }
                    .buttonStyle(.bwPressable)
                }
            }
    }
}

extension View {
    func customNavigation() -> some View {
        modifier(CustomNavigationModifier())
    }
}

