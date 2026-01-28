import SwiftUI
import os.log

// MARK: - Scroll Offset Preference Key
private struct SettingsScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Settings View
struct SettingsView: View {
    var navigationState: AppNavigationState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @ObservedObject private var appSettings = AppSettings.shared
    @Environment(\.colorScheme) var colorScheme
    
    // Scroll tracking state for fading header
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerVisible: Bool = true
    
    // Header configuration
    private let headerHeight: CGFloat = 45
    
    // MARK: - Header Animation Calculations
    
    private var scrollProgress: CGFloat {
        min(1, max(0, -scrollOffset / headerHeight))
    }
    
    private var headerOpacity: Double {
        if headerVisible {
            return 1.0
        }
        return Double(1.0 - scrollProgress)
    }
    
    private var headerTranslateY: CGFloat {
        if headerVisible {
            return 0
        }
        return -headerHeight * scrollProgress
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Adaptive background
            Group {
                if colorScheme == .dark {
                    Color(.systemBackground)
                } else {
                    BWGradients.backgroundGradient
                }
            }
            .ignoresSafeArea()
            
            // Content ScrollView
            ScrollView {
                VStack(spacing: 16) {
                    // Invisible anchor for scroll offset tracking
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: SettingsScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("settingsScroll")).minY
                            )
                    }
                    .frame(height: 0)
                    
                    // Spacer for the floating header
                    Color.clear
                        .frame(height: headerHeight)
                    
                    // Appearance Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Appearance")
                            .font(.bwCaption())
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 4)
                        
                        AppearanceSettingsCard()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profile")
                            .font(.bwCaption())
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 4)
                        
                        SettingsRow(icon: "person.fill", title: "User Profile", color: Color.bwAccentBlue) {
                            navigationState.navigateTo(.userProfile)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences")
                            .font(.bwCaption())
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 4)
                        
                        VStack(spacing: 0) {
                            SettingsRow(icon: "list.bullet", title: "Edit Pantry Items", color: Color.bwAccentGreen, showDivider: true) {
                                navigationState.navigateTo(.pantrySetup)
                            }
                            
                            SettingsRow(icon: "arrow.counterclockwise", title: "Reset Onboarding", color: Color.bwAccentOrange) {
                                hasCompletedOnboarding = false
                            }
                        }
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .adaptiveShadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                    }
                    
                    // Scan Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Scan")
                            .font(.bwCaption())
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 4)
                        
                        ScanSettingsCard()
                    }
                    
                    // Fridge Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fridge")
                            .font(.bwCaption())
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 4)
                        
                        FridgeExpirySettingsCard()
                    }
                    
                    // Chat Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Chat")
                            .font(.bwCaption())
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 4)
                        
                        SettingsRow(icon: "bubble.left.and.bubble.right.fill", title: "Chat Settings", color: Color.bwPrimary) {
                            navigationState.navigateTo(.chatSettings)
                        }
                    }
                    
                    // Developer / API Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Developer")
                            .font(.bwCaption())
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 4)
                        
                        DemoModeToggleRow()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Feedback")
                            .font(.bwCaption())
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 4)
                        
                        SettingsRow(icon: "envelope.fill", title: "Send Feedback", color: Color.bwPrimaryCoral) {
                            navigationState.navigateTo(.feedback)
                        }
                    }
                    
                    // Account Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account")
                            .font(.bwCaption())
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 4)
                        
                        LogOutButton()
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .coordinateSpace(name: "settingsScroll")
            .onPreferenceChange(SettingsScrollOffsetPreferenceKey.self) { value in
                handleScrollChange(newOffset: value)
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 1)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 70)
            }
            
            // MARK: - Floating Header Overlay
            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BWGradients.headerFadeGradient(for: colorScheme))
            .offset(y: headerTranslateY)
            .opacity(headerOpacity)
            .animation(.easeOut(duration: 0.2), value: headerVisible)
        }
    }
    
    // MARK: - Scroll Handling
    
    private func handleScrollChange(newOffset: CGFloat) {
        let delta = newOffset - lastScrollOffset
        
        if delta > 2 {
            if !headerVisible {
                withAnimation(.easeOut(duration: 0.2)) {
                    headerVisible = true
                }
            }
        } else if delta < -2 {
            if headerVisible && newOffset < -10 {
                withAnimation(.easeOut(duration: 0.15)) {
                    headerVisible = false
                }
            }
        }
        
        if newOffset >= -5 {
            if !headerVisible {
                withAnimation(.easeOut(duration: 0.2)) {
                    headerVisible = true
                }
            }
        }
        
        scrollOffset = newOffset
        lastScrollOffset = newOffset
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Settings")
                .font(BWTypography.sectionHeader)
            
            Spacer()
        }
    }
}

// MARK: - Scan Settings Card
struct ScanSettingsCard: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with expand/collapse
            Button(action: {
                BWHaptics.lightImpact()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.bwAccentBlue.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.bwAccentBlue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Default Scan Behavior")
                            .font(.bwBody())
                            .foregroundColor(.primary)
                        
                        Text(appSettings.defaultScanMethod.rawValue)
                            .font(.bwCaption())
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded options
            if isExpanded {
                Divider()
                    .padding(.leading, 66)
                
                VStack(spacing: 0) {
                    ForEach(ScanMergeMode.allCases, id: \.self) { mode in
                        Button(action: {
                            BWHaptics.selection()
                            withAnimation(.bwSnappy) {
                                appSettings.defaultScanMethod = mode
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(appSettings.defaultScanMethod == mode ? Color.bwPrimary : .secondary)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mode.rawValue)
                                        .font(BWTypography.bodyPrimary)
                                        .foregroundColor(.primary)
                                    
                                    Text(mode.description)
                                        .font(BWTypography.captionSmall)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if appSettings.defaultScanMethod == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color.bwPrimary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                            .background(
                                appSettings.defaultScanMethod == mode ? Color.bwPrimary.opacity(0.06) : Color.clear
                            )
                        }
                        .buttonStyle(.plain)
                        
                        if mode != ScanMergeMode.allCases.last {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .adaptiveShadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Fridge Expiry Settings Card
struct FridgeExpirySettingsCard: View {
    @ObservedObject private var appSettings = AppSettings.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Auto-expire toggle
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.bwAccentBlue.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.bwAccentBlue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-expire Items")
                        .font(.bwBody())
                        .foregroundColor(.primary)
                    
                    Text(appSettings.fridgeAutoExpireEnabled 
                         ? "Items removed after \(appSettings.fridgeAutoExpireDays) days"
                         : "Swipe to delete items manually")
                        .font(.bwCaption())
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $appSettings.fridgeAutoExpireEnabled)
                    .labelsHidden()
                    .tint(Color.bwAccentBlue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            // Days picker (only shown when enabled)
            if appSettings.fridgeAutoExpireEnabled {
                Divider()
                    .padding(.leading, 66)
                
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.bwAccentGold.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.bwAccentGold)
                    }
                    
                    Text("Expire after")
                        .font(.bwBody())
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Days stepper
                    HStack(spacing: 8) {
                        Button(action: {
                            if appSettings.fridgeAutoExpireDays > 1 {
                                appSettings.fridgeAutoExpireDays -= 1
                                BWHaptics.lightImpact()
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(appSettings.fridgeAutoExpireDays > 1 ? Color.bwAccentBlue : Color.gray.opacity(0.3))
                        }
                        .disabled(appSettings.fridgeAutoExpireDays <= 1)
                        
                        HStack(spacing: 4) {
                            Text("\(appSettings.fridgeAutoExpireDays)")
                                .font(BWTypography.bodyPrimary)
                                .fontWeight(.semibold)
                                .frame(minWidth: 24)
                            
                            Text("days")
                                .font(BWTypography.caption)
                                .foregroundColor(.secondary)
                        }
                        .fixedSize()
                        
                        Button(action: {
                            if appSettings.fridgeAutoExpireDays < 30 {
                                appSettings.fridgeAutoExpireDays += 1
                                BWHaptics.lightImpact()
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(appSettings.fridgeAutoExpireDays < 30 ? Color.bwAccentBlue : Color.gray.opacity(0.3))
                        }
                        .disabled(appSettings.fridgeAutoExpireDays >= 30)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .adaptiveShadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: appSettings.fridgeAutoExpireEnabled)
    }
}

// MARK: - Appearance Settings Card
/// Theme picker for light/dark/system mode
struct AppearanceSettingsCard: View {
    @ObservedObject private var appSettings = AppSettings.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.bwAdaptivePrimary(for: colorScheme).opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: appSettings.appTheme.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.bwAdaptivePrimary(for: colorScheme))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Theme")
                        .font(.bwBody())
                        .foregroundColor(.primary)
                    
                    Text(appSettings.appTheme.displayName)
                        .font(.bwCaption())
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            Divider()
                .padding(.leading, 66)
            
            // Theme options
            HStack(spacing: 12) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeOptionButton(
                        theme: theme,
                        isSelected: appSettings.appTheme == theme,
                        currentScheme: colorScheme
                    ) {
                        BWHaptics.selection()
                        withAnimation(.bwSnappy) {
                            appSettings.appTheme = theme
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .adaptiveShadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Theme Option Button
/// Individual theme option button
struct ThemeOptionButton: View {
    let theme: AppTheme
    let isSelected: Bool
    let currentScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Theme preview circle
                ZStack {
                    Circle()
                        .fill(previewBackground)
                        .frame(width: 48, height: 48)
                    
                    Circle()
                        .stroke(
                            isSelected ? Color.bwAdaptivePrimary(for: currentScheme) : Color.clear,
                            lineWidth: 2.5
                        )
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: theme.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(previewIconColor)
                }
                
                Text(theme.displayName)
                    .font(BWTypography.captionSmall)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? Color.bwAdaptivePrimary(for: currentScheme) : .secondary)
                
                // Selected indicator
                Circle()
                    .fill(isSelected ? Color.bwAdaptivePrimary(for: currentScheme) : Color.clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.bwAdaptivePrimary(for: currentScheme).opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var previewBackground: Color {
        switch theme {
        case .system:
            // Half and half effect approximation
            return Color(.systemGray4)
        case .light:
            return Color.white
        case .dark:
            return Color(hex: "1C1C1E")
        }
    }
    
    private var previewIconColor: Color {
        switch theme {
        case .system:
            return .primary
        case .light:
            return Color(hex: "F4A261") // Warm sun color
        case .dark:
            return Color(hex: "60A5FA") // Soft blue moon
        }
    }
}

// MARK: - Demo Mode Toggle Row
/// Demo Mode Toggle Row - matches existing Settings style
struct DemoModeToggleRow: View {
    @ObservedObject private var appSettings = AppSettings.shared
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(appSettings.isDemoMode ? Color.bwAccentGold.opacity(0.15) : Color.bwAccentGreen.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: appSettings.isDemoMode ? "doc.text.fill" : "antenna.radiowaves.left.and.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(appSettings.isDemoMode ? Color.bwAccentGold : Color.bwAccentGreen)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Demo Mode")
                    .font(.bwBody())
                    .foregroundColor(.primary)
                
                Text(appSettings.apiStatusMessage)
                    .font(.bwCaption())
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $appSettings.isDemoMode)
                .labelsHidden()
                .tint(Color.bwAccentGold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .adaptiveShadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    var showDivider: Bool = false
    let action: () -> Void
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(color)
                    }
                    
                    Text(title)
                        .font(.bwBody())
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                if showDivider {
                    Divider()
                        .padding(.leading, 66)
                }
            }
        }
        .background(
            Group {
                if !showDivider {
                    Color(.secondarySystemBackground)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: showDivider ? 0 : 16))
        .adaptiveShadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Account Button (Sign In for guests, Log Out for authenticated users)
struct AccountButton: View {
    // Privacy-safe logger
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BiteWise", category: "Settings")
    
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var guestModeService = GuestModeService.shared
    @AppStorage("isGuestMode") private var isGuestMode: Bool = false
    @State private var isLoading = false
    @State private var showLogoutConfirmation = false
    @Environment(\.colorScheme) var colorScheme
    
    private var isGuest: Bool {
        !authService.isAuthenticated && isGuestMode
    }
    
    var body: some View {
        Button {
            if isGuest {
                // Guest wants to sign in - disable guest mode to show auth screen
                BWHaptics.lightImpact()
                isGuestMode = false
                guestModeService.disableGuestMode()
            } else {
                // Authenticated user wants to log out
                showLogoutConfirmation = true
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isGuest ? Color.bwPrimary.opacity(0.15) : Color.bwError.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.bwError))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isGuest ? "person.crop.circle.badge.plus" : "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isGuest ? Color.bwPrimary : Color.bwError)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(isGuest ? "Sign In" : "Log Out")
                        .font(.bwBody())
                        .foregroundColor(isGuest ? Color.bwPrimary : Color.bwError)
                    
                    if isGuest {
                        Text("Create an account to save your data")
                            .font(.bwCaption())
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isGuest {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .disabled(isLoading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .adaptiveShadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .confirmationDialog(
            "Log Out",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                performLogout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
    
    private func performLogout() {
        isLoading = true
        BWHaptics.mediumImpact()
        
        Task {
            do {
                try await AuthService.shared.signOut()
                // Also clear guest mode on logout - sync both @AppStorage and service state
                isGuestMode = false
                guestModeService.disableGuestMode()
                // AuthService will update isAuthenticated, triggering navigation
            } catch {
                BWHaptics.error()
                Self.logger.error("Logout error: \(error.localizedDescription, privacy: .public)")
            }
            isLoading = false
        }
    }
}

// MARK: - Legacy Log Out Button (keeping for compatibility)
struct LogOutButton: View {
    var body: some View {
        AccountButton()
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SettingsView(navigationState: AppNavigationState())
            .navigationBarHidden(true)
    }
}
