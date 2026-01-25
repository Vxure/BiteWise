import SwiftUI
import PhotosUI

// MARK: - Image Source Options

enum ImageSourceType {
    case camera
    case photoLibrary
}

// MARK: - UIKit Image Picker (Camera Support)

/// SwiftUI wrapper for UIImagePickerController to support camera
struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        
        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - PhotosPicker Wrapper (iOS 16+ Photo Library)

/// Modern photo picker using PhotosUI (iOS 16+)
struct PhotoLibraryPicker: View {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Text("Select Photo")
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Image Source Selection Sheet

/// A sheet that lets users choose between camera and photo library
struct ImageSourceSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Choose Image Source")
                    .font(.bwTitle3())
                    .padding(.top, 20)
                
                // Camera option
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button(action: {
                        showCamera = true
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.bwAdaptivePrimaryCoral(for: colorScheme).opacity(0.15))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.bwAdaptivePrimaryCoral(for: colorScheme))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Take Photo")
                                    .font(.bwHeadline())
                                    .foregroundColor(.primary)
                                
                                Text("Use your camera to capture ingredients")
                                    .font(.bwCaption())
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .adaptiveShadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                
                // Photo Library option
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.bwAdaptiveAccentBlue(for: colorScheme).opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 22))
                                .foregroundColor(Color.bwAdaptiveAccentBlue(for: colorScheme))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Choose from Library")
                                .font(.bwHeadline())
                                .foregroundColor(.primary)
                            
                            Text("Select an existing photo")
                                .font(.bwCaption())
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .adaptiveShadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4
                    )
                }
                .buttonStyle(.plain)
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                selectedImage = image
                                isPresented = false
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .background(BWGradients.backgroundGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.bwBody())
                }
            }
        }
        .presentationDetents([.medium])
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker(
                image: $selectedImage,
                isPresented: $showCamera,
                sourceType: .camera
            )
            .ignoresSafeArea()
            .onDisappear {
                if selectedImage != nil {
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ImageSourceSheet(
        isPresented: .constant(true),
        selectedImage: .constant(nil)
    )
}

