//
//  PublishListingView.swift
//  TeslaCare
//
//  Created by Jin on 5/14/26.
//

import SwiftUI
import SwiftData

struct PublishListingView: View {
    let car: Car
    @Environment(CloudKitPublicService.self) private var cloudKitService
    @Environment(\.dismiss) private var dismiss

    @State private var listingType: ListingType = .forSale
    @State private var listingURLText = ""
    @State private var isPublishing = false
    @State private var errorMessage: String?

    private var listingURL: URL? {
        let trimmed = listingURLText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let raw = trimmed.lowercased().hasPrefix("http") ? trimmed : "https://\(trimmed)"
        return URL(string: raw)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Listing Type") {
                    Picker("Type", selection: $listingType) {
                        ForEach(ListingType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    TextField("", text: $listingURLText)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("External Link (optional)")
                } footer: {
                    Text("Link to your listing on Craigslist, Facebook Marketplace, AutoTrader, etc.")
                }

                Section {
                    Label("Make, model, mileage, tire condition", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Label("VIN (if synced from Tesla)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Label("Approximate location (city, state)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Label("Exact GPS coordinates", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                } header: {
                    Text("What's shared")
                }
                .font(.subheadline)
            }
            .navigationTitle(car.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isPublishing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isPublishing {
                        ProgressView()
                    } else {
                        Button("Publish") { publish() }
                    }
                }
            }
            .alert("Publish Failed", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func publish() {
        isPublishing = true
        Task {
            do {
                try await cloudKitService.publishCar(car, listingType: listingType, listingURL: listingURL)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isPublishing = false
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, configurations: config)
    let car = Car(name: "My Model 3", make: "Tesla", model: "Model 3", year: 2022)
    container.mainContext.insert(car)
    return PublishListingView(car: car)
        .modelContainer(container)
        .environment(CloudKitPublicService())
}
