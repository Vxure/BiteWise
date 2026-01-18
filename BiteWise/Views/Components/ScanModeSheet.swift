import SwiftUI

/// Sheet for selecting how to merge new scan results with existing fridge items
struct ScanModeSheet: View {
    let existingItemCount: Int
    let newItemCount: Int
    @Binding var selectedMode: ScanMergeMode
    @State private var rememberChoice: Bool = false
    @ObservedObject private var appSettings = AppSettings.shared
    var onContinue: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.bwPrimary, Color.bwSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.bwPrimary.opacity(0.3), radius: 10, x: 0, y: 4)
                    
                    Image(systemName: "arrow.triangle.merge")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("How should we update?")
                    .font(.bwTitle2())
                
                Text("You have \(existingItemCount) items in your fridge.\nWe detected \(newItemCount) new items.")
                    .font(.bwSubheadline())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            
            // Mode options
            VStack(spacing: 12) {
                ForEach(ScanMergeMode.mergeModes, id: \.self) { mode in
                    ScanModeOptionRow(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        onSelect: {
                            BWHaptics.selection()
                            withAnimation(.bwSnappy) {
                                selectedMode = mode
                            }
                        }
                    )
                }
            }
            
            // Remember my choice toggle
            Button(action: {
                BWHaptics.selection()
                withAnimation(.bwSnappy) {
                    rememberChoice.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(rememberChoice ? Color.bwPrimary : Color.clear)
                            .frame(width: 24, height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(rememberChoice ? Color.bwPrimary : Color.gray.opacity(0.4), lineWidth: 2)
                            )
                        
                        if rememberChoice {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text("Remember my choice")
                        .font(BWTypography.bodyPrimary)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)
            
            // Action buttons
            VStack(spacing: 12) {
                GradientButton(
                    icon: "checkmark.circle.fill",
                    text: "Continue",
                    action: {
                        BWHaptics.success()
                        // Save preference if remember is checked
                        if rememberChoice {
                            appSettings.defaultScanMethod = selectedMode
                        }
                        onContinue()
                    }
                )
                
                Button(action: {
                    BWHaptics.lightImpact()
                    onCancel()
                }) {
                    Text("Cancel")
                        .font(.bwHeadline())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bwPressable)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bwBackgroundCream.ignoresSafeArea())
    }
}

/// Individual row for a scan mode option
struct ScanModeOptionRow: View {
    let mode: ScanMergeMode
    let isSelected: Bool
    var onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.bwPrimary.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: mode.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? Color.bwPrimary : .secondary)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.bwHeadline())
                        .foregroundColor(.primary)
                    
                    Text(mode.description)
                        .font(.bwCaption())
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.bwPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.bwPrimary)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.04), radius: isSelected ? 8 : 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.bwPrimary.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.bwPressable)
    }
}

#Preview {
    ScanModeSheet(
        existingItemCount: 8,
        newItemCount: 5,
        selectedMode: .constant(.smartMerge),
        onContinue: {},
        onCancel: {}
    )
}

