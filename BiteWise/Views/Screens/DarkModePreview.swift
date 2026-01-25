//
//  DarkModePreview.swift
//  BiteWise
//
//  Created by Regan on 2026-01-18.
//

import SwiftUI

// MARK: - Main Preview Container
struct DarkModeConceptPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Light vs. Dark Mode Concept")
                .font(.headline)
                .padding(.top)
            
            HStack(spacing: 0) {
                // LEFT COLUMN: LIGHT MODE
                VStack {
                    Text("Light Mode").font(.caption).bold()
                    SimulatedAppScreen()
                }
                .environment(\.colorScheme, .light)
                
                // RIGHT COLUMN: DARK MODE
                VStack {
                    Text("Dark Mode").font(.caption).bold()
                        .foregroundStyle(.white)
                    SimulatedAppScreen()
                }
                .environment(\.colorScheme, .dark)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 10)
            .padding()
        }
        .background(Color.gray.opacity(0.2))
    }
}

// MARK: - Simulated App Screen Content
struct SimulatedAppScreen: View {
    // Grab the current scheme to apply logic
    @Environment(\.colorScheme) var scheme
    
    var body: some View {
        ZStack {
            // 1. Main Background Layer (Adaptive)
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // SECTION 1: STANDARD LIST ROWS (Pantry/Fridge)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My Pantry")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        VStack(spacing: 1) {
                            MockListRow(icon: "archivebox.fill", title: "Pasta Box", subtitle: "Staple")
                            MockListRow(icon: "can.fill", title: "Canned Beans", subtitle: "2 cans")
                        }
                        .background(Color(.secondarySystemBackground)) // The Card Layer
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // SECTION 2: ADAPTIVE MACRO PILLS (The Pastel Fix)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Macro Badges (Adaptive)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HStack {
                            // Green Pill (High Protein)
                            AdaptiveMacroPill(text: "High Protein", color: .green)
                            // Yellow Pill (High Fat)
                            AdaptiveMacroPill(text: "High Fat", color: .orange)
                        }
                    }
                    
                    // SECTION 3: BENTO CARD (Gradient in Dark Mode)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recipe Card")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        MockBentoCard()
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - MOCK COMPONENTS

// 1. Standard List Row
struct MockListRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Environment(\.colorScheme) var scheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon Container
            ZStack {
                // Slightly different gray depending on mode for contrast
                Color(scheme == .light ? .systemGray6 : .tertiarySystemFill)
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary) // White in dark, black in light
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary) // Light gray in dark, dark gray in light
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
    }
}

// 2. Adaptive Macro Pill (The complex logic fix)
struct AdaptiveMacroPill: View {
    let text: String
    let color: Color
    @Environment(\.colorScheme) var scheme
    
    var body: some View {
        Text(text)
            .font(.caption.bold())
            // Text Color Logic: Dark text in light mode, White text in dark mode
            .foregroundStyle(scheme == .light ? color.opacity(0.8) : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            // Background Logic: Solid pastel in light mode, translucent neon in dark mode
            .background(
                Capsule()
                    .fill(scheme == .light ? color.opacity(0.2) : color.opacity(0.3))
            )
            // Border Logic: Subtle border in dark mode to make it pop
            .overlay(
                Capsule()
                    .strokeBorder(color.opacity(scheme == .dark ? 0.5 : 0.0), lineWidth: 1)
            )
    }
}

// 3. Mock Bento Card (Showing gradient survival)
struct MockBentoCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // The Gradient just works in both modes
            LinearGradient(
                colors: [Color.teal, Color.blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Abstract Watermark
            Image(systemName: "frying.pan.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .rotationEffect(.degrees(-20))
                .opacity(0.05)
                .offset(x: 80, y: 20)
            
            VStack(alignment: .leading, spacing: 6) {
                AdaptiveMacroPill(text: "Balanced", color: .blue)
                
                Text("Mediterranean Quinoa Bowl")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    // Essential shadow for readability on bright gradients
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                HStack {
                    Image(systemName: "clock")
                    Text("20 min • Missing 2 items")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
            }
            .padding(20)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    DarkModeConceptPreview()
}
