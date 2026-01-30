//
//  LoadingErrorViews.swift
//  BiteWise
//
//  Reusable loading and error state views.
//

import SwiftUI

// MARK: - Loading View

/// Full-screen loading view with animated spinner
struct BWLoadingView: View {
    var message: String = "Loading..."
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Spinner()
            
            Text(message)
                .font(BWTypography.bodySecondary)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Group {
                if colorScheme == .dark {
                    Color(.systemBackground)
                } else {
                    BWGradients.backgroundGradient
                }
            }
        )
    }
}

// MARK: - Inline Loading View

/// Compact loading indicator for inline use
struct BWInlineLoadingView: View {
    var message: String?
    
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.bwPrimary))
            
            if let message = message {
                Text(message)
                    .font(BWTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Error Banner

/// Dismissible error banner for top of screen
struct BWErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)?
    var onRetry: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color.bwError)
            
            Text(message)
                .font(BWTypography.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("Retry")
                        .font(BWTypography.buttonSmall)
                        .foregroundColor(Color.bwPrimary)
                }
            }
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.bwError.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.bwError.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Error View

/// Full-screen error view with retry option
struct BWErrorView: View {
    let title: String
    let message: String
    var onRetry: (() -> Void)?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            // Error icon
            ZStack {
                Circle()
                    .fill(Color.bwError.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(Color.bwError.opacity(0.7))
            }
            
            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(BWTypography.cardTitle)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(BWTypography.bodySecondary)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Retry button
            if let onRetry = onRetry {
                Button(action: {
                    BWHaptics.lightImpact()
                    onRetry()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Try Again")
                            .font(BWTypography.buttonSmall)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.bwPrimary)
                    )
                }
                .buttonStyle(.bwPressable)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Group {
                if colorScheme == .dark {
                    Color(.systemBackground)
                } else {
                    BWGradients.backgroundGradient
                }
            }
        )
    }
}

// MARK: - Sync Status Indicator

/// Small indicator showing sync status - auto-hides after successful sync
struct BWSyncStatusIndicator: View {
    @ObservedObject private var dataManager = DataManager.shared
    
    /// Tracks whether to show the "Synced" success state
    @State private var showSyncedState = false
    
    /// Duration to show "Synced" before auto-hiding (seconds)
    private let syncedDisplayDuration: Double = 2.5
    
    var body: some View {
        Group {
            if dataManager.isSyncing {
                HStack(spacing: 6) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.bwPrimary))
                        .scaleEffect(0.7)
                    
                    Text("Syncing...")
                        .font(BWTypography.captionSmall)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.bwPrimary.opacity(0.1))
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else if let _ = dataManager.syncError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.bwError)
                    
                    Text("Sync failed")
                        .font(BWTypography.captionSmall)
                        .foregroundColor(Color.bwError)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.bwError.opacity(0.1))
                )
                .onTapGesture {
                    BWHaptics.lightImpact()
                    dataManager.clearSyncError()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else if showSyncedState {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.icloud.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.bwPrimary)
                    
                    Text("Synced")
                        .font(BWTypography.captionSmall)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.bwPrimary.opacity(0.1))
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dataManager.isSyncing)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSyncedState)
        .onChange(of: dataManager.isSyncing) { wasSyncing, isSyncing in
            // When sync completes (transitions from true to false) and no error, show success briefly
            if wasSyncing && !isSyncing && dataManager.syncError == nil {
                withAnimation {
                    showSyncedState = true
                }
                // Auto-hide after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + syncedDisplayDuration) {
                    withAnimation {
                        showSyncedState = false
                    }
                }
            }
        }
    }
}

// MARK: - Skeleton Loading Views

/// Skeleton loading placeholder for list items
struct BWSkeletonRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 44, height: 44)
            
            // Text placeholders
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 80, height: 12)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .opacity(isAnimating ? 0.5 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

/// Skeleton loading placeholder for cards
struct BWSkeletonCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 80)
            
            // Text placeholders
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 60, height: 10)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.tertiarySystemBackground))
        )
        .opacity(isAnimating ? 0.5 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - View Modifier for Loading/Error States

/// View modifier that shows loading or error overlay
struct LoadingErrorModifier: ViewModifier {
    let isLoading: Bool
    let error: String?
    let loadingMessage: String
    var onRetry: (() -> Void)?
    var onDismissError: (() -> Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(isLoading ? 0.3 : 1.0)
                .disabled(isLoading)
            
            if isLoading {
                BWLoadingView(message: loadingMessage)
            }
        }
        .overlay(alignment: .top) {
            if let error = error, !isLoading {
                BWErrorBanner(
                    message: error,
                    onDismiss: onDismissError,
                    onRetry: onRetry
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 8)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: error)
    }
}

extension View {
    /// Apply loading and error state handling to a view
    func loadingErrorState(
        isLoading: Bool,
        error: String?,
        loadingMessage: String = "Loading...",
        onRetry: (() -> Void)? = nil,
        onDismissError: (() -> Void)? = nil
    ) -> some View {
        modifier(LoadingErrorModifier(
            isLoading: isLoading,
            error: error,
            loadingMessage: loadingMessage,
            onRetry: onRetry,
            onDismissError: onDismissError
        ))
    }
}

// MARK: - Previews

#Preview("Loading View") {
    BWLoadingView(message: "Loading recipes...")
}

#Preview("Error View") {
    BWErrorView(
        title: "Connection Error",
        message: "Unable to load your data. Please check your internet connection.",
        onRetry: {}
    )
}

#Preview("Error Banner") {
    VStack {
        BWErrorBanner(
            message: "Failed to sync. Changes saved locally.",
            onDismiss: {},
            onRetry: {}
        )
        Spacer()
    }
}

#Preview("Skeleton Row") {
    VStack(spacing: 12) {
        BWSkeletonRow()
        BWSkeletonRow()
        BWSkeletonRow()
    }
    .padding()
}
