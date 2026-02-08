//
//  GuestModeService.swift
//  BiteWise
//
//  Created by Regan on 2026-01-26.
//

import Foundation
import SwiftUI

// MARK: - Guest Mode Service
/// Manages guest mode state and provides UI prompts for upgrading to full account.
///
/// ## Guest Mode Limitations
///
/// When using BiteWise in guest mode, the following limitations apply:
///
/// 1. **Data Storage**: All data is stored locally on the device only.
///    - Fridge/pantry items, recipes, chat history are local only
///    - Data will be lost if the app is deleted
///
/// 2. **No Cloud Sync**: Data cannot sync across devices or be backed up.
///    - Supabase RLS policies require `auth.uid()` which is `NULL` for guests
///    - All database operations will fail for unauthenticated users
///
/// 3. **Feature Limitations**:
///    - Cannot share recipes with other users
///    - Cannot access recipes from multiple devices
///    - Limited to local AI chat (no cloud history)
///
/// ## Why This Approach?
///
/// Rather than adding `OR auth.uid() IS NULL` to RLS policies (which would be a
/// security risk), we:
/// - Store guest data locally using DataManager (UserDefaults)
/// - Skip all Supabase sync operations for guests
/// - Prompt users to create accounts when they try to use cloud features
///
@MainActor
final class GuestModeService: ObservableObject {
    
    static let shared = GuestModeService()
    
    /// UserDefaults key for guest mode
    private let guestModeKey = "isGuestMode"
    
    /// UserDefaults key for tracking pending guest migration
    private let wasInGuestModeKey = "wasInGuestModePendingMigration"
    
    /// Whether the user is currently in guest mode
    /// This is the SINGLE SOURCE OF TRUTH for guest mode state.
    /// All views should read from this property via GuestModeService.shared.
    @Published private(set) var isGuestMode: Bool {
        didSet {
            UserDefaults.standard.set(isGuestMode, forKey: guestModeKey)
        }
    }
    
    /// Tracks if user was in guest mode before signing in.
    /// Used to trigger data migration after successful auth.
    /// Persisted to UserDefaults to survive app restarts during sign-in flow.
    /// Reset when enableGuestMode() is called (user cancelled sign-in).
    @Published private(set) var wasInGuestMode: Bool {
        didSet {
            UserDefaults.standard.set(wasInGuestMode, forKey: wasInGuestModeKey)
        }
    }
    
    /// Show the account prompt sheet
    @Published var showAccountPrompt: Bool = false
    
    /// Context message for why account is needed
    @Published var accountPromptMessage: String = ""
    
    private init() {
        self.isGuestMode = UserDefaults.standard.bool(forKey: guestModeKey)
        self.wasInGuestMode = UserDefaults.standard.bool(forKey: wasInGuestModeKey)
    }
    
    /// Reset guest mode (for testing or when user creates account and logs out)
    func resetGuestMode() {
        isGuestMode = false
        wasInGuestMode = false
        showAccountPrompt = false
    }
    
    // MARK: - Mode Management
    
    /// Enable guest mode
    func enableGuestMode() {
        isGuestMode = true
        // Reset wasInGuestMode - user is still a guest, didn't complete auth
        // This handles the case where user clicks "Sign In" but then cancels
        wasInGuestMode = false
        // Reset name/email to prevent showing previous user's info
        // Preserves pantry items, macro goals, dietary preferences from onboarding
        DataManager.shared.resetUserIdentity()
    }
    
    /// Disable guest mode (usually when user creates account)
    func disableGuestMode() {
        // Remember that user was a guest before transitioning to auth
        // This flag is used to trigger data migration after successful auth
        wasInGuestMode = isGuestMode
        isGuestMode = false
        showAccountPrompt = false
    }
    
    /// Clear the wasInGuestMode flag after migration is complete
    func clearWasInGuestMode() {
        wasInGuestMode = false
    }
    
    // MARK: - Feature Guards
    
    /// Check if a cloud feature can be used, showing prompt if not.
    /// - Parameters:
    ///   - feature: Human-readable feature name for the prompt
    /// - Returns: `true` if the feature can be used, `false` if blocked (and prompt shown)
    func canUseCloudFeature(_ feature: String) -> Bool {
        if isGuestMode {
            showAccountPromptFor(feature)
            return false
        }
        return true
    }
    
    /// Check if cloud sync should be attempted
    /// - Returns: `true` if authenticated (not guest), `false` if guest
    func shouldSyncToCloud() -> Bool {
        return !isGuestMode && AuthService.shared.isAuthenticated
    }
    
    /// Show the account prompt with a contextual message
    func showAccountPromptFor(_ feature: String) {
        accountPromptMessage = "Create an account to \(feature)"
        showAccountPrompt = true
    }
    
    // MARK: - Common Feature Prompts
    
    /// Prompt for syncing data across devices
    func promptForCloudSync() {
        showAccountPromptFor("sync your data across devices")
    }
    
    /// Prompt for sharing recipes
    func promptForSharing() {
        showAccountPromptFor("share recipes with friends")
    }
    
    /// Prompt for cloud backup
    func promptForBackup() {
        showAccountPromptFor("back up your recipes and preferences")
    }
}

// MARK: - Guest Mode Account Prompt View

/// A sheet view prompting guest users to create an account
struct GuestModeAccountPromptView: View {
    @ObservedObject var guestModeService = GuestModeService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.bwPrimary.opacity(0.15),
                                Color.bwPrimary.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.bwPrimary, Color.bwSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.top, 20)
            
            // Title
            Text("Create an Account")
                .font(BWTypography.sectionHeader)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.bwPrimary, Color.bwSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Message
            Text(guestModeService.accountPromptMessage)
                .font(BWTypography.bodySecondary)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Benefits list
            VStack(alignment: .leading, spacing: 12) {
                benefitRow(icon: "icloud.fill", text: "Sync data across devices")
                benefitRow(icon: "arrow.triangle.2.circlepath", text: "Back up your recipes")
                benefitRow(icon: "square.and.arrow.up", text: "Share with friends")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Actions
            VStack(spacing: 12) {
                // Create Account button
                Button {
                    BWHaptics.lightImpact()
                    // Use GuestModeService as single source of truth
                    guestModeService.disableGuestMode()
                    dismiss()
                } label: {
                    Text("Create Account")
                        .font(BWTypography.buttonLabel)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.bwPrimary, Color.bwSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                // Continue as Guest button
                Button {
                    dismiss()
                } label: {
                    Text("Continue as Guest")
                        .font(BWTypography.buttonSmall)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.bwPrimary)
                .frame(width: 24)
            
            Text(text)
                .font(BWTypography.bodyPrimary)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - View Extension for Guest Mode Prompt

extension View {
    /// Adds the guest mode account prompt sheet to a view
    func guestModePrompt() -> some View {
        self.modifier(GuestModePromptModifier())
    }
}

/// ViewModifier to properly bind the guest mode prompt sheet
private struct GuestModePromptModifier: ViewModifier {
    @ObservedObject private var guestModeService = GuestModeService.shared
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $guestModeService.showAccountPrompt) {
                GuestModeAccountPromptView()
            }
    }
}
