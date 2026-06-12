//
//  CarPhotoStrip.swift
//  TeslaCare
//

import SwiftUI
import PhotosUI

/// A car photo plus its optional on-device-generated part/side caption.
struct CarPhotoItem {
    let image: UIImage
    var caption: String?
}

/// Horizontal strip of car photos with camera/library capture, mirroring the photo
/// capture flow used for tire measurements. Each thumbnail shows the FoundationModels
/// part/side label beneath it once available. Operates on plain values so it can back
/// both an in-memory list (adding a new car) and persisted `CarPhoto` models.
struct CarPhotoStrip: View {
    let items: [CarPhotoItem]
    let onAdd: (UIImage) -> Void
    let onDelete: (Int) -> Void

    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var cameraCapture: UIImage?
    @State private var showingCamera = false
    @State private var showingPhotoSource = false
    @State private var showingPhotoPicker = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(items.indices, id: \.self) { index in
                    VStack(spacing: 4) {
                        Image(uiImage: items[index].image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    onDelete(index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.white)
                                        .background(Color.black.opacity(0.5), in: Circle())
                                }
                                .offset(x: 6, y: -6)
                            }

                        Text(items[index].caption ?? " ")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2, reservesSpace: true)
                            .frame(width: 100)
                    }
                }

                Button {
                    showingPhotoSource = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.title2)
                        Text("Add")
                            .font(.caption)
                    }
                    .frame(width: 100, height: 100)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .onChange(of: photoPickerItems) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        onAdd(image)
                    }
                }
                photoPickerItems = []
            }
        }
        .onChange(of: cameraCapture) { _, image in
            if let image {
                onAdd(image)
                cameraCapture = nil
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePickerView(sourceType: .camera, selectedImage: $cameraCapture, showTireOverlay: false)
                .ignoresSafeArea()
        }
        .confirmationDialog("Add Photo", isPresented: $showingPhotoSource) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { showingCamera = true }
            }
            Button("Choose from Library") { showingPhotoPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $photoPickerItems,
                      maxSelectionCount: 10, matching: .images)
    }
}

#Preview {
    @Previewable @State var items: [CarPhotoItem] = []
    return Form {
        Section("Photos") {
            CarPhotoStrip(
                items: items,
                onAdd: { items.append(CarPhotoItem(image: $0, caption: "Front Bumper • Front Left")) },
                onDelete: { items.remove(at: $0) }
            )
        }
    }
}
