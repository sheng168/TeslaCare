//
//  LogTireRepairView.swift
//  TeslaCare
//

import SwiftUI
import SwiftData
import PhotosUI
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "LogTireRepair")

struct LogTireRepairView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let tire: Tire

    @State private var date = Date()
    @State private var repairType: TireRepairType = .plug
    @State private var shopName = ""
    @State private var costText = ""
    @State private var includeCost = false
    @State private var mileageText = ""
    @State private var includeMileage = false
    @State private var notes = ""

    @State private var photos: [UIImage] = []
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var cameraCapture: UIImage?
    @State private var showingCamera = false
    @State private var showingPhotoSource = false
    @State private var showingPhotoPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Repair Information") {
                    LabeledContent("Tire Position") {
                        Label(tire.position.rawValue, systemImage: tire.position.systemImage)
                            .foregroundStyle(.blue)
                    }

                    Picker("Repair Type", selection: $repairType) {
                        ForEach(TireRepairType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.systemImage)
                                .tag(type)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Details") {
                    TextField("Shop / Technician (optional)", text: $shopName)

                    Toggle("Include Cost", isOn: $includeCost)
                    if includeCost {
                        HStack {
                            Text("$").foregroundStyle(.secondary)
                            TextField("Cost", text: $costText)
                                .keyboardType(.decimalPad)
                        }
                    }

                    Toggle("Include Mileage", isOn: $includeMileage)
                    if includeMileage {
                        TextField("Mileage", text: $mileageText)
                            .keyboardType(.numberPad)
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Photos") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(photos.indices, id: \.self) { index in
                                Image(uiImage: photos[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(alignment: .topTrailing) {
                                        Button {
                                            photos.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(.white)
                                                .background(Color.black.opacity(0.5), in: Circle())
                                        }
                                        .offset(x: 6, y: -6)
                                    }
                            }

                            Button {
                                showingPhotoSource = true
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "plus").font(.title2)
                                    Text("Add").font(.caption)
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
                }
            }
            .navigationTitle("Log Tire Repair")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: photoPickerItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            photos.append(image)
                        }
                    }
                    photoPickerItems = []
                }
            }
            .onChange(of: cameraCapture) { _, image in
                if let image {
                    photos.append(image)
                    cameraCapture = nil
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePickerView(sourceType: .camera, selectedImage: $cameraCapture)
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveRepair() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveRepair() {
        let cost = includeCost ? Double(costText) : nil
        let mileage = includeMileage ? Int(mileageText) : nil

        let event = TireRepairEvent(
            date: date,
            repairType: repairType,
            position: tire.position,
            shopName: shopName,
            cost: cost,
            mileage: mileage,
            notes: notes
        )
        event.tire = tire
        event.car = tire.car
        modelContext.insert(event)

        for (index, image) in photos.enumerated() {
            if let data = image.jpegData(compressionQuality: 0.8) {
                let photo = TireRepairPhoto(data: data, sortIndex: index)
                photo.repairEvent = event
                modelContext.insert(photo)
            }
        }

        logger.info("Saved tire repair: \(repairType.rawValue) at \(tire.position.rawValue)")
        dismiss()
    }
}
