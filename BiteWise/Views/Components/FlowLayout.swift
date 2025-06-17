import SwiftUI

// Flow layout for arranging items in a wrapping grid
public struct FlowLayout<T: Hashable, V: View>: View {
    let items: [T]
    let spacing: CGFloat
    @ViewBuilder let viewBuilder: (T) -> V
    @State private var height: CGFloat = 0
    
    public init(items: [T], spacing: CGFloat = 8, @ViewBuilder viewBuilder: @escaping (T) -> V) {
        self.items = items
        self.spacing = spacing
        self.viewBuilder = viewBuilder
    }
    
    public var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: max(height, 10))
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var localHeight = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                viewBuilder(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > geometry.size.width {
                            width = 0
                            localHeight -= d.height + spacing
                        }
                        
                        let result = width
                        if item == items.last! {
                            width = 0
                        } else {
                            width -= d.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = localHeight
                        if item == items.last! {
                            localHeight = 0
                        }
                        return result
                    }
            }
        }
        .background(viewHeightReader($height))
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}

#Preview {
    FlowLayout(items: ["SwiftUI", "Flow", "Layout", "Component", "Responsive", "Design"]) { item in
        Text(item)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.2))
            )
    }
    .padding()
} 