import SwiftUI

struct UserProfileScreen: View {
    @State private var profile = UserProfile.dummy
    @State private var isEditingName = false
    @State private var isSaving = false
    
    // Password change state
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isChangingPassword = false
    @State private var passwordError: String?
    @State private var passwordSuccess = false
    
    // Delete account state
    @State private var deleteConfirmText = ""
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    
    @ObservedObject private var dataManager = DataManager.shared
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var isNameFocused: Bool
    @FocusState private var focusedPasswordField: PasswordField?
    
    var onDone: () -> Void
    
    private enum PasswordField {
        case current, new, confirm
    }
    
    // Computed property for user email
    private var userEmail: String {
        authService.currentUser?.email ?? profile.email
    }
    
    var body: some View {
        ZStack {
            // Adaptive background
            Group {
                if colorScheme == .dark {
                    Color(.systemBackground)
                } else {
                    BWGradients.backgroundGradient
                }
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Profile Header
                    profileHeaderSection
                        .staggeredAppear(index: 0)
                    
                    // MARK: - Account Info
                    accountInfoSection
                        .staggeredAppear(index: 1)
                    
                    // MARK: - Change Password (only for authenticated users)
                    if authService.isAuthenticated {
                        changePasswordSection
                            .staggeredAppear(index: 2)
                    }
                    
                    // MARK: - Save Button
                    GradientButton(
                        icon: isSaving ? nil : "checkmark.circle.fill",
                        text: isSaving ? "Saving..." : "Save Profile",
                        action: saveAndDone
                    )
                    .disabled(isSaving)
                    .opacity(isSaving ? 0.7 : 1.0)
                    .padding(.top, 8)
                    .staggeredAppear(index: 3)
                    
                    // MARK: - Delete Account (only for authenticated users)
                    if authService.isAuthenticated {
                        deleteAccountSection
                            .staggeredAppear(index: 4)
                            .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
        .customNavigation()
        .onAppear {
            // Load existing profile from DataManager
            profile = dataManager.userProfile
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isNameFocused = false
            focusedPasswordField = nil
            if isEditingName {
                isEditingName = false
            }
        }
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                // Show sync status if authenticated
                if authService.isAuthenticated {
                    BWSyncStatusIndicator()
                        .padding(.top, 60)
                }
                
                // Show sync error if present
                if let error = dataManager.syncError {
                    BWErrorBanner(
                        message: error,
                        onDismiss: { dataManager.clearSyncError() },
                        onRetry: {
                            Task {
                                await dataManager.loadFromCloud()
                            }
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dataManager.syncError)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dataManager.isSyncing)
        .confirmationDialog(
            "Delete Account",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete My Account", role: .destructive) {
                performAccountDeletion()
            }
            Button("Cancel", role: .cancel) {
                deleteConfirmText = ""
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Avatar with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.bwPrimary, Color.bwSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.bwPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                
                // User initial
                Text(String(profile.name.prefix(1)).uppercased())
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // User name with edit capability
            HStack(spacing: 8) {
                if isEditingName {
                    TextField("Your name", text: $profile.name)
                        .font(BWTypography.sectionHeader)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            isEditingName = false
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.tertiarySystemBackground))
                        )
                        .adaptiveShadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.bwAdaptivePrimary(for: colorScheme).opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Text(profile.name)
                        .font(BWTypography.sectionHeader)
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    BWHaptics.lightImpact()
                    if isEditingName {
                        // Save and close
                        isEditingName = false
                        isNameFocused = false
                    } else {
                        // Start editing
                        isEditingName = true
                        isNameFocused = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isEditingName ? Color.bwPrimary : Color.bwPrimary.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: isEditingName ? "checkmark" : "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isEditingName ? .white : Color.bwPrimary)
                    }
                }
                .buttonStyle(.bwPressable)
            }
            .animation(.bwSnappy, value: isEditingName)
        }
        .frame(maxWidth: .infinity)
        .bwCardStyle(padding: 24, cornerRadius: 24)
    }
    
    // MARK: - Account Info Section
    private var accountInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.bwAccentBlue.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.bwAccentBlue)
                }
                
                Text("Account Information")
                    .font(BWTypography.cardTitle)
            }
            
            // Email (read-only)
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(BWTypography.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(userEmail.isEmpty ? "Not signed in" : userEmail)
                            .font(BWTypography.bodySecondary)
                            .foregroundColor(userEmail.isEmpty ? .secondary : .primary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if authService.isEmailVerified {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                Text("Verified")
                                    .font(BWTypography.captionSmall)
                            }
                            .foregroundColor(Color.bwSuccess)
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.tertiarySystemBackground))
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle(padding: 20, cornerRadius: 24)
    }
    
    // MARK: - Change Password Section
    private var changePasswordSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.bwAccentGold.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.bwAccentGold)
                }
                
                Text("Change Password")
                    .font(BWTypography.cardTitle)
            }
            
            // Password fields
            VStack(spacing: 12) {
                // Current password
                secureField(
                    placeholder: "Current Password",
                    text: $currentPassword,
                    field: .current
                )
                
                // New password
                secureField(
                    placeholder: "New Password",
                    text: $newPassword,
                    field: .new
                )
                
                // Confirm password
                secureField(
                    placeholder: "Confirm New Password",
                    text: $confirmPassword,
                    field: .confirm
                )
            }
            
            // Password validation hint
            if !newPassword.isEmpty && newPassword.count < 6 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text("Password must be at least 6 characters")
                        .font(BWTypography.captionSmall)
                }
                .foregroundColor(Color.bwAccent)
            }
            
            // Password mismatch warning
            if !confirmPassword.isEmpty && newPassword != confirmPassword {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                    Text("Passwords do not match")
                        .font(BWTypography.captionSmall)
                }
                .foregroundColor(Color.bwError)
            }
            
            // Error message
            if let error = passwordError {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(BWTypography.captionSmall)
                }
                .foregroundColor(Color.bwError)
                .transition(.opacity)
            }
            
            // Success message
            if passwordSuccess {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Password changed successfully!")
                        .font(BWTypography.captionSmall)
                }
                .foregroundColor(Color.bwSuccess)
                .transition(.opacity)
            }
            
            // Change password button
            Button(action: changePassword) {
                HStack(spacing: 8) {
                    if isChangingPassword {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.bwPrimary))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "key.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(isChangingPassword ? "Changing..." : "Change Password")
                        .font(BWTypography.buttonSmall)
                }
                .foregroundColor(canChangePassword ? Color.bwPrimary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(canChangePassword ? Color.bwPrimary.opacity(0.1) : Color.gray.opacity(0.1))
                )
            }
            .disabled(!canChangePassword || isChangingPassword)
            .buttonStyle(.bwPressable)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle(padding: 20, cornerRadius: 24)
        .animation(.bwSnappy, value: passwordError)
        .animation(.bwSnappy, value: passwordSuccess)
    }
    
    private func secureField(placeholder: String, text: Binding<String>, field: PasswordField) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16))
                .foregroundColor(focusedPasswordField == field ? Color.bwAccentGold : .secondary)
            
            SecureField(placeholder, text: text)
                .font(BWTypography.bodyPrimary)
                .focused($focusedPasswordField, equals: field)
                .textContentType(field == .current ? .password : .newPassword)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(focusedPasswordField == field ? Color.bwAccentGold.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .animation(.bwSnappy, value: focusedPasswordField)
    }
    
    private var canChangePassword: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword
    }
    
    // MARK: - Delete Account Section
    private var deleteAccountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.bwError.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.bwError)
                }
                
                Text("Delete Account")
                    .font(BWTypography.cardTitle)
            }
            
            // Warning text
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.bwAccent)
                
                Text("This action is permanent and cannot be undone. All your data including recipes, preferences, and history will be permanently deleted.")
                    .font(BWTypography.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.bwAccent.opacity(0.08))
            )
            
            // Confirmation input
            VStack(alignment: .leading, spacing: 8) {
                Text("Type DELETE to confirm")
                    .font(BWTypography.caption)
                    .foregroundColor(.secondary)
                
                TextField("", text: $deleteConfirmText)
                    .font(BWTypography.bodyPrimary)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.tertiarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(deleteConfirmText == "DELETE" ? Color.bwError.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            }
            
            // Error message
            if let error = deleteError {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(BWTypography.captionSmall)
                }
                .foregroundColor(Color.bwError)
                .transition(.opacity)
            }
            
            // Delete button
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack(spacing: 8) {
                    if isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(isDeleting ? "Deleting..." : "Delete My Account")
                        .font(BWTypography.buttonSmall)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(canDelete ? Color.bwError : Color.gray.opacity(0.5))
                )
            }
            .disabled(!canDelete || isDeleting)
            .buttonStyle(.bwPressable)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .bwCardStyle(padding: 20, cornerRadius: 24)
        .animation(.bwSnappy, value: deleteError)
    }
    
    private var canDelete: Bool {
        deleteConfirmText == "DELETE"
    }
    
    // MARK: - Actions
    
    /// Save profile to DataManager and dismiss
    private func saveAndDone() {
        BWHaptics.success()
        isSaving = true
        
        dataManager.userProfile = profile
        dataManager.saveUserProfile()
        
        // Give a moment for the sync to start, then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSaving = false
            onDone()
        }
    }
    
    private func changePassword() {
        guard canChangePassword else { return }
        
        isChangingPassword = true
        passwordError = nil
        passwordSuccess = false
        focusedPasswordField = nil
        
        Task {
            do {
                try await authService.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword
                )
                
                await MainActor.run {
                    BWHaptics.success()
                    passwordSuccess = true
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    isChangingPassword = false
                    
                    // Clear success message after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        passwordSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    BWHaptics.error()
                    passwordError = error.localizedDescription
                    isChangingPassword = false
                }
            }
        }
    }
    
    private func performAccountDeletion() {
        guard canDelete else { return }
        
        isDeleting = true
        deleteError = nil
        
        Task {
            do {
                try await authService.deleteAccount()
                
                await MainActor.run {
                    BWHaptics.success()
                    // The auth state change will automatically navigate away
                    isDeleting = false
                }
            } catch {
                await MainActor.run {
                    BWHaptics.error()
                    deleteError = error.localizedDescription
                    isDeleting = false
                }
            }
        }
    }
}

#Preview {
    UserProfileScreen(onDone: {})
}
