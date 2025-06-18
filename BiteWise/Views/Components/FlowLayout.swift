import SwiftUI

struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat
    
    init(horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 8) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        
        var height: CGFloat = 0
        var width: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if rowWidth + subviewSize.width > maxWidth {
                // Start a new row
                width = max(width, rowWidth - horizontalSpacing)
                height += rowHeight + verticalSpacing
                rowWidth = subviewSize.width + horizontalSpacing
                rowHeight = subviewSize.height
            } else {
                // Add to the current row
                rowWidth += subviewSize.width + horizontalSpacing
                rowHeight = max(rowHeight, subviewSize.height)
            }
        }
        
        // Add the last row
        height += rowHeight
        width = max(width, rowWidth - horizontalSpacing)
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = proposal.width ?? bounds.width
        
        var rowX: CGFloat = bounds.minX
        var rowY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if rowX + subviewSize.width > bounds.minX + maxWidth {
                // Start a new row
                rowX = bounds.minX
                rowY += rowHeight + verticalSpacing
                rowHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: rowX, y: rowY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: subviewSize.width, height: subviewSize.height)
            )
            
            rowX += subviewSize.width + horizontalSpacing
            rowHeight = max(rowHeight, subviewSize.height)
        }
    }
}

// MARK: - Preview
struct FlowLayoutPreview: View {
    var body: some View {
        FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(1...10, id: \.self) { index in
                Text("Item \(index)")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemBackground))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding()
    }
}

#Preview {
    FlowLayoutPreview()
} 