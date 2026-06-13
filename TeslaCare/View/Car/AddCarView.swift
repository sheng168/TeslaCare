//
//  AddCarView.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.teslacare", category: "AddCar")

struct AddCarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var make = "Tesla"
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var mileageText = ""
    @State private var vin = ""
    @State private var showingVINScanner = false
    @State private var photos: [UIImage] = []
    @State private var photoLabels: [ObjectIdentifier: CarPartLabel] = [:]
    @State private var photoMetadata: [ObjectIdentifier: PhotoCaptureMetadata] = [:]

    var body: some View {
        NavigationStack {
            Form {
                Section("Car Information") {
                    TextField("Name (optional)", text: $name)
                        .textContentType(.name)
                    
                    TextField("Make", text: $make)
                        .textContentType(.organizationName)
                    
                    TextField("Model", text: $model)
                    
                    Picker("Year", selection: $year) {
                        ForEach((1990...Calendar.current.component(.year, from: Date()) + 1).reversed(), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }

                    TextField("Mileage (optional)", text: $mileageText)
                        .keyboardType(.numberPad)
                }

                Section("VIN") {
                    HStack {
                        TextField("VIN (optional)", text: $vin)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: vin) { _, newValue in
                                let clean = newValue.uppercased()
                                if clean != newValue { vin = clean }
                                autofill(from: clean)
                            }

                        if !vin.isEmpty {
                            Button { vin = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            showingVINScanner = true
                        } label: {
                            Image(systemName: "camera.viewfinder")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }

                    if !vin.isEmpty && vin.count != 17 {
                        Text("VIN must be 17 characters (\(vin.count)/17)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Section("Photos") {
                    CarPhotoStrip(
                        items: photos.map { image in
                            let id = ObjectIdentifier(image)
                            return CarPhotoItem(image: image,
                                                caption: photoLabels[id]?.caption,
                                                date: photoMetadata[id]?.captureDate,
                                                coordinate: photoMetadata[id]?.coordinate)
                        },
                        onAdd: addPhoto,
                        onDelete: deletePhoto
                    )
                }

                Section {
                    Text("If you don't provide a name, the car will be identified as \"\(year, format: .number.grouping(.never)) \(make.isEmpty ? "Make" : make) \(model.isEmpty ? "Model" : model)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCar()
                    }
                    .disabled(make.isEmpty || model.isEmpty)
                }
            }
            .sheet(isPresented: $showingVINScanner) {
                VINScannerView { detected in
                    vin = detected
                    autofill(from: detected)
                }
            }
        }
    }
    
    private func autofill(from vin: String) {
        guard vin.count == 17 else { return }
        let detectedMake = vinMake(vin)
        if let m = detectedMake { make = m }
        if let detectedModel = vinModel(vin, make: detectedMake ?? make), model.isEmpty {
            model = detectedModel
        }
        if let detectedYear = vinYear(vin) { year = detectedYear }
    }

    private func vinMake(_ vin: String) -> String? {
        guard vin.count >= 3 else { return nil }
        let wmi = String(vin.prefix(3))
        let wmiMap: [String: String] = [
            // Tesla
            "5YJ": "Tesla", "7SA": "Tesla", "SFZ": "Tesla", "LRW": "Tesla",
            // Ford
            "1FA": "Ford", "1FB": "Ford", "1FC": "Ford", "1FD": "Ford",
            "1FM": "Ford", "1FT": "Ford", "1FV": "Ford",
            "2FA": "Ford", "2FB": "Ford", "2FM": "Ford", "2FT": "Ford",
            "3FA": "Ford", "3FE": "Ford", "WF0": "Ford", "VS6": "Ford",
            // Chevrolet
            "1G1": "Chevrolet", "1GC": "Chevrolet", "1GD": "Chevrolet",
            "1GN": "Chevrolet", "2G1": "Chevrolet", "3G1": "Chevrolet",
            // Buick
            "1G4": "Buick", "1GB": "Buick", "2G4": "Buick", "KL4": "Buick",
            // Cadillac
            "1G6": "Cadillac", "1GY": "Cadillac", "1GZ": "Cadillac",
            // GMC
            "1GK": "GMC", "1GT": "GMC", "2GT": "GMC",
            // Pontiac (defunct)
            "1G2": "Pontiac", "2G2": "Pontiac",
            // Oldsmobile (defunct)
            "1G3": "Oldsmobile",
            // Chrysler
            "1C3": "Chrysler", "1C8": "Chrysler",
            "2C3": "Chrysler", "2C4": "Chrysler",
            // Jeep
            "1C4": "Jeep", "1J4": "Jeep", "1J8": "Jeep",
            // Ram
            "1C6": "Ram", "3C6": "Ram", "3C4": "Ram",
            // Dodge
            "1B3": "Dodge", "1B4": "Dodge", "1B7": "Dodge",
            "1D3": "Dodge", "1D7": "Dodge", "1D8": "Dodge",
            "2B3": "Dodge", "2B4": "Dodge", "2B7": "Dodge",
            // Honda
            "1HG": "Honda", "2HG": "Honda", "2HK": "Honda", "2HM": "Honda",
            "19X": "Honda", "5FN": "Honda", "5FR": "Honda", "5J6": "Honda",
            "JHM": "Honda",
            // Acura
            "19U": "Acura", "JHL": "Acura", "2HH": "Acura",
            // Toyota
            "1NX": "Toyota",
            "4T1": "Toyota", "4T3": "Toyota", "4T4": "Toyota",
            "5TD": "Toyota", "5TF": "Toyota", "5TK": "Toyota", "5TT": "Toyota",
            "2T1": "Toyota", "JTD": "Toyota", "JTE": "Toyota", "JTF": "Toyota",
            "JTK": "Toyota", "JTL": "Toyota", "JTM": "Toyota", "JTN": "Toyota",
            "NMT": "Toyota",
            // Lexus
            "JTG": "Lexus", "JTH": "Lexus", "JTJ": "Lexus",
            "JT6": "Lexus", "2T2": "Lexus", "58A": "Lexus",
            // Nissan
            "1N4": "Nissan", "1N6": "Nissan",
            "3N1": "Nissan", "5N1": "Nissan",
            "JN1": "Nissan", "JN6": "Nissan", "JN8": "Nissan",
            // Infiniti
            "JNA": "Infiniti", "JNK": "Infiniti",
            // Mazda
            "JM1": "Mazda", "JM3": "Mazda", "JMZ": "Mazda",
            "1YV": "Mazda", "4F2": "Mazda", "4F4": "Mazda",
            // Subaru
            "JF1": "Subaru", "JF2": "Subaru",
            "4S3": "Subaru", "4S4": "Subaru",
            // Mitsubishi
            "JA3": "Mitsubishi", "JA4": "Mitsubishi",
            "4A3": "Mitsubishi", "4A4": "Mitsubishi",
            // Hyundai
            "KMH": "Hyundai", "KM8": "Hyundai",
            "5NP": "Hyundai", "5NM": "Hyundai",
            // Genesis
            "KMT": "Genesis",
            // Kia
            "KNA": "Kia", "KND": "Kia",
            "5XX": "Kia", "5XY": "Kia", "3KP": "Kia",
            // BMW
            "WBA": "BMW", "WBX": "BMW", "WBY": "BMW", "WBS": "BMW",
            "4US": "BMW", "5UX": "BMW", "5YM": "BMW",
            // Mercedes-Benz
            "WDB": "Mercedes-Benz", "WDC": "Mercedes-Benz", "WDD": "Mercedes-Benz",
            "4JG": "Mercedes-Benz", "55S": "Mercedes-Benz",
            // Audi
            "WAU": "Audi", "WA1": "Audi", "WA4": "Audi", "TRU": "Audi",
            // Volkswagen
            "WVW": "Volkswagen", "WV1": "Volkswagen", "WV2": "Volkswagen",
            "WVG": "Volkswagen", "1VW": "Volkswagen", "3VW": "Volkswagen",
            // Porsche
            "WP0": "Porsche", "WP1": "Porsche",
            // Volvo
            "YV1": "Volvo", "YV4": "Volvo", "LVY": "Volvo",
            // Jaguar
            "SAJ": "Jaguar",
            // Land Rover
            "SAL": "Land Rover",
            // Rolls-Royce / Bentley / Aston Martin / Lotus
            "SCA": "Rolls-Royce", "SCB": "Bentley",
            "SCF": "Aston Martin", "SCC": "Lotus",
            // Lamborghini / Ferrari / Alfa Romeo / Maserati
            "ZHW": "Lamborghini", "ZFF": "Ferrari",
            "ZAR": "Alfa Romeo", "ZAM": "Maserati",
            // MINI / Smart
            "WMW": "MINI", "WME": "Smart",
            // Saab (defunct)
            "YS3": "Saab",
            // Lincoln
            "1LN": "Lincoln", "5LM": "Lincoln",
            // Mercury (defunct)
            "1ME": "Mercury",
            // Rivian
            "7FC": "Rivian", "7JR": "Rivian",
            // Lucid
            "57X": "Lucid",
            // Polestar
            "YSM": "Polestar", "LRB": "Polestar",
            // Suzuki
            "JS1": "Suzuki", "JS2": "Suzuki", "JS3": "Suzuki",
            // SEAT
            "VSS": "SEAT",
            // Renault
            "VF1": "Renault", "VF2": "Renault",
            // Peugeot / Citroen
            "VF3": "Peugeot", "VF6": "Peugeot",
            "VF7": "Citroen", "VF8": "Citroen",
            // Lada
            "XTA": "Lada",
        ]
        return wmiMap[wmi]
    }

    private func vinModel(_ vin: String, make: String) -> String? {
        guard vin.count >= 4 else { return nil }
        switch make {
        case "Tesla":
            switch vin[vin.index(vin.startIndex, offsetBy: 3)] {
            case "S": return "Model S"
            case "X": return "Model X"
            case "3": return "Model 3"
            case "Y": return "Model Y"
            case "C": return "Cybertruck"
            case "R": return "Roadster"
            default:  return nil
            }
        default:
            return nil
        }
    }

    private func vinYear(_ vin: String) -> Int? {
        guard vin.count >= 10 else { return nil }
        let char = vin[vin.index(vin.startIndex, offsetBy: 9)]
        let currentYear = Calendar.current.component(.year, from: Date())
        // Letters encode years in 30-year cycles (no I, O, Q, U, Z used in VINs)
        let letterYears: [Character: (Int, Int)] = [
            "A": (1980, 2010), "B": (1981, 2011), "C": (1982, 2012),
            "D": (1983, 2013), "E": (1984, 2014), "F": (1985, 2015),
            "G": (1986, 2016), "H": (1987, 2017), "J": (1988, 2018),
            "K": (1989, 2019), "L": (1990, 2020), "M": (1991, 2021),
            "N": (1992, 2022), "P": (1993, 2023), "R": (1994, 2024),
            "S": (1995, 2025), "T": (1996, 2026), "V": (1997, 2027),
            "W": (1998, 2028), "X": (1999, 2029), "Y": (2000, 2030),
        ]
        // Digits encode 2001–2009 (2031–2039 are all future, unambiguous for now)
        let digitYears: [Character: Int] = [
            "1": 2001, "2": 2002, "3": 2003, "4": 2004, "5": 2005,
            "6": 2006, "7": 2007, "8": 2008, "9": 2009,
        ]
        if let (older, newer) = letterYears[char] {
            return newer <= currentYear + 1 ? newer : older
        }
        return digitYears[char]
    }

    private func addPhoto(_ image: UIImage, _ metadata: PhotoCaptureMetadata) {
        photos.append(image)
        photoMetadata[ObjectIdentifier(image)] = metadata
        // Label the part/side on-device as the photo is added (iOS 27+).
        if #available(iOS 27, *) {
            Task {
                if let label = await CarPhotoLabeler.label(image) {
                    photoLabels[ObjectIdentifier(image)] = label
                }
            }
        }
    }

    private func deletePhoto(at index: Int) {
        guard photos.indices.contains(index) else { return }
        let image = photos.remove(at: index)
        photoLabels[ObjectIdentifier(image)] = nil
        photoMetadata[ObjectIdentifier(image)] = nil
    }

    private func addCar() {
        logger.info("Adding car: \(year) \(make) \(model)")
        let newCar = Car(name: name, make: make, model: model, year: year)
        if !vin.isEmpty && vin.count == 17 { newCar.vin = vin }
        modelContext.insert(newCar)
        if let miles = Int(mileageText) {
            let reading = MileageReading(date: Date(), mileage: miles, source: "manual")
            reading.car = newCar
            modelContext.insert(reading)
            logger.info("Added initial mileage reading: \(miles) mi")
        }
        for (index, image) in photos.enumerated() {
            if let data = image.jpegData(compressionQuality: 0.7) {
                let photo = CarPhoto(data: data, sortIndex: index)
                photo.car = newCar
                if let label = photoLabels[ObjectIdentifier(image)] {
                    photo.part = label.part
                    photo.side = label.side
                }
                if let metadata = photoMetadata[ObjectIdentifier(image)] {
                    photo.apply(metadata)
                }
                modelContext.insert(photo)
            }
        }
        logger.info("Car added successfully: \(newCar.displayName) with \(photos.count) photo(s)")
        dismiss()
    }
}

#Preview {
    AddCarView()
        .modelContainer(for: Car.self, inMemory: true)
        .environment(LocationManager())
}
