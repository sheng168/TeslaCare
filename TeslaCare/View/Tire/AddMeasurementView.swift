//
//  AddMeasurementView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData
import PhotosUI
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "AddMeasurement")

struct AddMeasurementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let car: Car
    let preselectedPosition: TirePosition?

    @State private var selectedPosition: TirePosition
    @State private var treadDepth: Double = 8.0
    @State private var date = Date()
    @State private var notes = ""
    @State private var mileage = ""
    @State private var includeMileage = false

    // Multiple measurements for uneven wear — ordered innermost → outermost.
    @State private var useMultipleMeasurements = false
    @State private var multiPointDepths: [Double] = [8.0, 8.0, 8.0]

    private let minMultiPointCount = 2
    private let maxMultiPointCount = 7

    // Photos — originals saved; processedPhotos[i] is nil while cropping
    @State private var originalPhotos: [UIImage] = []
    @State private var processedPhotos: [UIImage?] = []
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var cameraCapture: UIImage?
    @State private var showingCamera = false
    @State private var showingPhotoSource = false
    @State private var showingPhotoPicker = false
    @State private var showingCoinScan = false
    
    init(car: Car, preselectedPosition: TirePosition? = nil) {
        self.car = car
        self.preselectedPosition = preselectedPosition
        let position = preselectedPosition ?? .frontLeft
        _selectedPosition = State(initialValue: position)
        
        // Prefill tread depth with latest measurement for the selected position
        if let latestMeasurement = car.latestMeasurement(for: position) {
            _treadDepth = State(initialValue: latestMeasurement.treadDepth)
            _multiPointDepths = State(initialValue: Array(repeating: latestMeasurement.treadDepth, count: 3))
        } else {
            _treadDepth = State(initialValue: 8.0)
            _multiPointDepths = State(initialValue: [8.0, 8.0, 8.0])
        }

        // Prefill mileage from car's latest reading
        if let carMileage = car.mileage {
            _mileage = State(initialValue: String(carMileage))
            _includeMileage = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tire Information") {
                    Picker("Tire Position", selection: $selectedPosition) {
                        ForEach(TirePosition.allCases, id: \.self) { position in
                            HStack {
                                Image(systemName: position.systemImage)
                                Text(position.rawValue)
                            }
                            .tag(position)
                        }
                    }
                    .onChange(of: selectedPosition) { oldValue, newValue in
                        // Update tread depth when position changes
                        if let latestMeasurement = car.latestMeasurement(for: newValue) {
                            treadDepth = latestMeasurement.treadDepth
                            multiPointDepths = Array(repeating: latestMeasurement.treadDepth, count: multiPointDepths.count)
                        } else {
                            treadDepth = 8.0
                            multiPointDepths = Array(repeating: 8.0, count: multiPointDepths.count)
                        }
                    }
                    
                    // Display tire ID/info if a tire exists at the selected position
                    if let tire = car.tires?.first(where: { $0.position == selectedPosition }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label {
                                Text(tire.displayName)
                                    .fontWeight(.medium)
                            } icon: {
                                Image(systemName: "car.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                            
                            if !tire.size.isEmpty {
                                Text("Size: \(tire.size)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if !tire.dotNumber.isEmpty {
                                Text("DOT: \(tire.dotNumber)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Show latest measurement info
                            if let latest = car.latestMeasurement(for: selectedPosition) {
                                Divider()
                                    .padding(.vertical, 4)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Last Measurement")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                    
                                    HStack {
                                        Text(latest.treadDepthFormatted)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(treadColor(for: latest.treadDepth))
                                        
                                        Text("•")
                                            .foregroundStyle(.secondary)
                                        
                                        Text(latest.date, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("No tire registered at this position")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Tread Depth") {
                    Toggle("Measure Multiple Points (Uneven Wear)", isOn: $useMultipleMeasurements)
                    
                    if useMultipleMeasurements {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Measure tread depth at multiple points across the tire width (innermost to outermost) to detect uneven wear patterns.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack {
                                Text("\(multiPointDepths.count) measurement points")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button {
                                    if multiPointDepths.count > minMultiPointCount {
                                        multiPointDepths.removeLast()
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                }
                                .buttonStyle(.borderless)
                                .disabled(multiPointDepths.count <= minMultiPointCount)

                                Button {
                                    if multiPointDepths.count < maxMultiPointCount {
                                        let seed = multiPointDepths.last ?? 8.0
                                        multiPointDepths.append(seed)
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                }
                                .buttonStyle(.borderless)
                                .disabled(multiPointDepths.count >= maxMultiPointCount)
                            }

                            ForEach(multiPointDepths.indices, id: \.self) { index in
                                let label = pointLabel(index: index, total: multiPointDepths.count)

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: pointIcon(index: index, total: multiPointDepths.count))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("\(label): ")
                                            .font(.subheadline)
                                        Text(String(format: "%.1f/32\"", multiPointDepths[index]))
                                            .fontWeight(.bold)
                                            .foregroundStyle(treadColor(for: multiPointDepths[index]))

                                        Spacer()

                                        if multiPointDepths[index] <= 2.0 {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundStyle(.red)
                                                .font(.caption)
                                        } else if multiPointDepths[index] <= 4.0 {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundStyle(.orange)
                                                .font(.caption)
                                        }
                                    }

                                    Slider(value: $multiPointDepths[index], in: 0...12, step: 0.5) {
                                        Text("\(label) Tread Depth")
                                    }
                                }
                                if index < multiPointDepths.count - 1 {
                                    Divider()
                                }
                            }

                            Divider()

                            // Average depth display
                            let avgDepth = multiPointDepths.reduce(0, +) / Double(multiPointDepths.count)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Average Depth")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)

                                HStack {
                                    Text(String(format: "%.1f/32\"", avgDepth))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundStyle(treadColor(for: avgDepth))

                                    Spacer()

                                    let wearDifference = (multiPointDepths.max() ?? 0) - (multiPointDepths.min() ?? 0)

                                    if wearDifference > 2.0 {
                                        VStack(alignment: .trailing, spacing: 2) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .foregroundStyle(.orange)
                                                Text("Uneven Wear")
                                                    .fontWeight(.medium)
                                            }
                                            .font(.caption)
                                            .foregroundStyle(.orange)

                                            Text("Difference: \(String(format: "%.1f/32\"", wearDifference))")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(.quaternary.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Text("Uneven wear may indicate alignment issues, improper inflation, or suspension problems. Inner/outer wear suggests alignment issues; center wear suggests over-inflation.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                    } else {
                        Button {
                            showingCoinScan = true
                        } label: {
                            HStack {
                                Label("Scan with Coin", systemImage: "camera.aperture")
                                Spacer()
                                Text("BETA")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.orange, in: Capsule())
                            }
                        }

                        // Single measurement mode (original)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Depth: ")
                                Text(String(format: "%.1f/32\"", treadDepth))
                                    .fontWeight(.bold)
                                    .foregroundStyle(treadColor(for: treadDepth))
                                
                                Spacer()
                                
                                if treadDepth <= 2.0 {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                    Text("Replace Now")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                } else if treadDepth <= 4.0 {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.orange)
                                    Text("Monitor Closely")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                            
                            // Stepper for precise adjustments
                            Stepper(value: $treadDepth, in: 0...12, step: 0.5) {
                                HStack {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(.secondary)
                                    Text("Adjust by 0.5/32\"")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            
                            Divider()
                            
                            // Slider for quick adjustments
                            Slider(value: $treadDepth, in: 0...12, step: 0.5) {
                                Text("Tread Depth")
                            } minimumValueLabel: {
                                Text("0")
                                    .font(.caption)
                            } maximumValueLabel: {
                                Text("12")
                                    .font(.caption)
                            }
                            
                            // Visual guide
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.red)
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.orange)
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.green)
                                    .frame(height: 4)
                            }
                            
                            HStack {
                                Text("Replace")
                                    .font(.caption2)
                                Spacer()
                                Text("Monitor")
                                    .font(.caption2)
                                Spacer()
                                Text("Good")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                        
                        Text("Use a tire tread depth gauge to measure the depth in 32nds of an inch. New tires typically start at 10-11/32\". Replace at 2/32\" or less.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Additional Information") {
                    Toggle("Include Mileage", isOn: $includeMileage)

                    if includeMileage {
                        TextField("Mileage", text: $mileage)
                            .keyboardType(.numberPad)
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Photos") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(originalPhotos.indices, id: \.self) { index in
                                VStack(spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(uiImage: originalPhotos[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 90)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))

                                        if let cropped = processedPhotos[index] {
                                            Image(uiImage: cropped)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 90)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color(.secondarySystemBackground))
                                                .frame(width: 80, height: 90)
                                                .overlay(ProgressView())
                                        }
                                    }

                                    HStack(spacing: 0) {
                                        Text("Original")
                                            .frame(width: 80)
                                        Text("Crop")
                                            .frame(width: 80)
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                }
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        originalPhotos.remove(at: index)
                                        processedPhotos.remove(at: index)
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
                }
            }
            .navigationTitle("Add Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: photoPickerItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            addPhoto(image)
                        }
                    }
                    photoPickerItems = []
                }
            }
            .onChange(of: cameraCapture) { _, image in
                if let image {
                    addPhoto(image)
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
            .sheet(isPresented: $showingCoinScan) {
                CoinScanView { depth in
                    treadDepth = depth
                    useMultipleMeasurements = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addMeasurement()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func addPhoto(_ image: UIImage) {
        let index = originalPhotos.count
        logger.info("Adding photo at index \(index), size: \(Int(image.size.width))x\(Int(image.size.height))")
        originalPhotos.append(image)
        processedPhotos.append(nil)
        Task {
            let cropped = await TireImageProcessor.process(image)
            processedPhotos[index] = cropped
            logger.info("Photo processed at index \(index)")
        }
    }

    private func treadColor(for depth: Double) -> Color {
        if depth <= 2.0 {
            return .red
        } else if depth <= 4.0 {
            return .orange
        } else {
            return .green
        }
    }

    /// Label for a measurement point — index 0 is innermost.
    private func pointLabel(index: Int, total: Int) -> String {
        switch total {
        case 2: return index == 0 ? "Inner Edge" : "Outer Edge"
        case 3: return ["Inner Edge", "Center", "Outer Edge"][index]
        case 4: return ["Inner Edge", "Mid-Inner", "Mid-Outer", "Outer Edge"][index]
        case 5: return ["Inner Edge", "Mid-Inner", "Center", "Mid-Outer", "Outer Edge"][index]
        default:
            if index == 0 { return "Inner Edge" }
            if index == total - 1 { return "Outer Edge" }
            return "Point \(index + 1)"
        }
    }

    private func pointIcon(index: Int, total: Int) -> String {
        if index == 0 { return "arrow.left" }
        if index == total - 1 { return "arrow.right" }
        return "arrow.up.and.down"
    }
    
    private func addMeasurement() {
        logger.info("Adding measurement: position=\(selectedPosition.rawValue), car=\(car.displayName), multiPoint=\(useMultipleMeasurements)")
        let mileageValue = includeMileage ? Int(mileage) : nil

        // Find or create a tire at the selected position
        let tire: Tire
        if let existingTire = car.tires?.first(where: { $0.position == selectedPosition }) {
            tire = existingTire
        } else {
            // Create a placeholder tire if none exists at this position
            logger.info("No tire at position \(selectedPosition.rawValue), creating placeholder")
            tire = Tire(brand: "", modelName: "", size: "", currentPosition: selectedPosition)
            tire.car = car
            modelContext.insert(tire)
        }
        
        let measurement: TireMeasurement
        
        if useMultipleMeasurements {
            // Calculate average depth for the main measurement
            let averageDepth = multiPointDepths.reduce(0, +) / Double(multiPointDepths.count)

            measurement = TireMeasurement(
                date: date,
                treadDepth: averageDepth,
                position: selectedPosition,
                tire: tire,
                notes: notes,
                mileage: mileageValue,
                treadDepths: multiPointDepths
            )
        } else {
            // Single measurement mode
            measurement = TireMeasurement(
                date: date,
                treadDepth: treadDepth,
                position: selectedPosition,
                tire: tire,
                notes: notes,
                mileage: mileageValue
            )
        }
        
        measurement.car = car
        modelContext.insert(measurement)
        for (index, image) in originalPhotos.enumerated() {
            if let data = image.jpegData(compressionQuality: 0.7) {
                let photo = TirePhoto(data: data, sortIndex: index)
                photo.measurement = measurement
                modelContext.insert(photo)
            }
        }
        NotificationManager.scheduleUpdateReminder(for: car)
        logger.info("Measurement saved with \(originalPhotos.count) photo(s)")
        dismiss()
    }
}

// MARK: - Coin Scan View

private struct CoinScanView: View {
    let onResult: (Double) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var coinType: CoinType = .quarter
    @State private var capturedImage: UIImage?
    @State private var scanResult: CoinTreadResult?
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var cameraImage: UIImage?

    var body: some View {
        NavigationStack {
            Group {
                if let result = scanResult {
                    coinResultContent(result: result)
                } else if capturedImage != nil, isAnalyzing {
                    analyzingContent
                } else {
                    instructionsContent
                }
            }
            .navigationTitle("Scan with Coin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePickerView(sourceType: .camera, selectedImage: $cameraImage)
                    .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showingPhotoPicker, selection: $photoPickerItem, matching: .images)
            .onChange(of: cameraImage) { _, image in
                if let image { processPhoto(image) }
            }
            .onChange(of: photoPickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        processPhoto(image)
                    }
                }
            }
        }
    }

    private var instructionsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("How to take the photo", systemImage: "info.circle")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 10) {
                        instructionStep(1, "Insert a \(coinType == .quarter ? "quarter" : "penny") upright into a tread groove")
                        instructionStep(2, "Position the camera at tread level, horizontal with the tire surface")
                        instructionStep(3, "Make sure the coin is well-lit and fills most of the frame")
                        instructionStep(4, "Take the photo")
                    }
                }
                .padding()
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let error = analysisError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }

                Picker("Coin Type", selection: $coinType) {
                    Text("Quarter (recommended)").tag(CoinType.quarter)
                    Text("Penny").tag(CoinType.penny)
                }
                .pickerStyle(.segmented)

                VStack(spacing: 12) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showingCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }

                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Label("Choose from Library", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
        }
    }

    private var analyzingContent: some View {
        VStack(spacing: 20) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            ProgressView("Analyzing photo...")
                .controlSize(.large)
        }
        .padding()
    }

    @ViewBuilder
    private func coinResultContent(result: CoinTreadResult) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(spacing: 8) {
                    Text("Estimated Tread Depth")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(result.depthFormatted)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(depthColor(for: result.estimatedDepth))
                    Text(result.depthCategory)
                        .font(.headline)
                        .foregroundStyle(depthColor(for: result.estimatedDepth))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(depthColor(for: result.estimatedDepth).opacity(0.15))
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 6) {
                    Image(systemName: confidenceIcon(for: result.confidence))
                    Text(result.confidenceLabel)
                        .font(.subheadline)
                }
                .foregroundStyle(confidenceColor(for: result.confidence))

                Text("Accuracy is approximately ±1/32\". Adjust the value with the slider after tapping Use Estimate.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Button {
                        onResult(result.estimatedDepth)
                        dismiss()
                    } label: {
                        Label("Use Estimate", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        capturedImage = nil
                        scanResult = nil
                        analysisError = nil
                        photoPickerItem = nil
                        cameraImage = nil
                    } label: {
                        Label("Try Again", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
        }
    }

    private func instructionStep(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(.blue, in: Circle())
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func processPhoto(_ image: UIImage) {
        capturedImage = image
        isAnalyzing = true
        scanResult = nil
        analysisError = nil
        Task {
            let result = await TireImageProcessor.analyzeCoinTread(image, coinType: coinType)
            isAnalyzing = false
            if let result {
                scanResult = result
            } else {
                capturedImage = nil
                analysisError = "No coin detected. Ensure the coin is clearly visible and try again."
            }
        }
    }

    private func depthColor(for depth: Double) -> Color {
        if depth <= 2.0 { return .red }
        if depth <= 4.0 { return .orange }
        return .green
    }

    private func confidenceIcon(for confidence: Double) -> String {
        if confidence >= 0.75 { return "checkmark.circle.fill" }
        if confidence >= 0.5  { return "exclamationmark.circle.fill" }
        return "questionmark.circle.fill"
    }

    private func confidenceColor(for confidence: Double) -> Color {
        if confidence >= 0.75 { return .green }
        if confidence >= 0.5  { return .orange }
        return .secondary
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TireMeasurement.self, Tire.self, configurations: config)
    
    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)
    
    // Add some tires to the car
    for position in TirePosition.allCases {
        let tire = Tire(brand: "Michelin", modelName: "Pilot Sport", size: "235/45R18", currentPosition: position)
        tire.car = car
        container.mainContext.insert(tire)
    }
    
    return AddMeasurementView(car: car)
        .modelContainer(container)
}
