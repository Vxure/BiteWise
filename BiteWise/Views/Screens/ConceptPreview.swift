//
//  ConceptPreview.swift
//  BiteWise
//
//  Created by Regan on 2026-01-17.
//

import SwiftUI

// MARK: - PREVIEW CONTAINER
struct ConceptPreviews: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                
                // OPTION 1: THE INGREDIENT MOSAIC
                VStack(alignment: .leading) {
                    Text("Option 1: Ingredient Mosaic")
                        .font(.caption).bold().foregroundStyle(.gray)
                    MosaicCard()
                }
                
                // OPTION 2: THE BENTO TYPOGRAPHY
                VStack(alignment: .leading) {
                    Text("Option 2: Bento Typography")
                        .font(.caption).bold().foregroundStyle(.gray)
                    BentoCard()
                }
                
                // RECOMMENDATION: THE COMBO
                VStack(alignment: .leading) {
                    Text("Recommendation: Dynamic Combo")
                        .font(.caption).bold().foregroundStyle(.gray)
                    ComboCard()
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - OPTION 1: MOSAIC (Icons focus)
struct MosaicCard: View {
    var body: some View {
        VStack(spacing: 12) {
            // The "Image" Area
            ZStack {
                Color.gray.opacity(0.1) // Subtle grey bg
                
                // 2x2 Grid of Icons
                Grid(horizontalSpacing: 20, verticalSpacing: 20) {
                    GridRow {
                        VStack {
                            Image(systemName: "fish.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.blue.opacity(0.6))
                            Text("Salmon").font(.caption2).foregroundStyle(.secondary)
                        }
                        VStack {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.green.opacity(0.6))
                            Text("Spinach").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    GridRow {
                        VStack {
                            Image(systemName: "carrot.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.orange.opacity(0.6))
                            Text("Veg").font(.caption2).foregroundStyle(.secondary)
                        }
                        VStack {
                            Image(systemName: "drop.fill") // Oil/Sauce
                                .font(.system(size: 30))
                                .foregroundStyle(.yellow.opacity(0.8))
                            Text("Oil").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Text Details
            VStack(alignment: .leading) {
                Text("Baked Salmon Bowl")
                    .font(.headline)
                Text("Uses 4 ingredients from fridge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - OPTION 2: BENTO (Gradient & Type focus)
struct BentoCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Gradient (Dynamic based on Macros)
            LinearGradient(
                colors: [Color.orange.opacity(0.6), Color.red.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Overlay Content
            VStack(alignment: .leading, spacing: 4) {
                Spacer()
                
                // Hero Stat
                Text("24g Protein")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                
                Text("Spicy Chicken Stir-Fry")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .shadow(radius: 2)
                
                HStack {
                    Image(systemName: "clock")
                    Text("15 min")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding()
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - RECOMMENDATION: THE COMBO (Best of both)
struct ComboCard: View {
    var body: some View {
        VStack(spacing: 0) {
            // Top: Gradient + Icons
            ZStack {
                // Background: Soft Gradient based on ingredients (Green for Veggies)
                LinearGradient(
                    colors: [Color.green.opacity(0.3), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Center: Dynamic Icon Cluster
                HStack(spacing: 15) {
                    Image(systemName: "leaf.fill") // Main Base
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .padding(15)
                        .background(Color.green.opacity(0.6))
                        .clipShape(Circle())
                    
                    Image(systemName: "egg.fill") // Protein
                        .font(.system(size: 30))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                        .padding(12)
                        .background(Color.orange.opacity(0.6))
                        .clipShape(Circle())
                        .offset(y: 10) // Slight offset for "scattered" look
                }
                
                // Time Badge (Floating)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                            Text("10m")
                        }
                        .font(.caption2.bold())
                        .padding(6)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .padding(8)
                    }
                }
            }
            .frame(height: 140)
            
            // Bottom: Info
            HStack {
                VStack(alignment: .leading) {
                    Text("Spinach & Egg Scramble")
                        .font(.headline)
                    Text("High Protein • Low Carb")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ConceptPreviews()
}
