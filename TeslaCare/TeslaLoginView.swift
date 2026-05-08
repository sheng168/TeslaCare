//
//  TeslaLoginView.swift
//  TeslaCare
//
//  Created by Jin on 5/8/26.
//

import SwiftUI
import SwiftData

struct TeslaLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingVehicleSelection = false
    
    let authManager = TeslaAuthManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "bolt.car.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.top)
                        
                        Text("Connect Your Tesla Account")
                            .font(.title2)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                        
                        Text("Sign in to automatically import your Tesla vehicles and their information.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom)
                    }
                }
                .listRowBackground(Color.clear)
                
                Section("Tesla Account") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .disabled(isLoading)
                    
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                                .textContentType(.password)
                                .disabled(isLoading)
                        } else {
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .disabled(isLoading)
                        }
                        
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if let errorMessage {
                    Section {
                        Label {
                            Text(errorMessage)
                                .font(.callout)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await login()
                        }
                    } label: {
                        if isLoading {
                            HStack {
                                ProgressView()
                                Text("Signing In...")
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                }
                
                Section {
                    Text("Your credentials are only used to authenticate with Tesla's servers. We don't store your password.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Link("Privacy Policy", destination: URL(string: "https://www.tesla.com/legal/privacy")!)
                        .font(.caption)
                }
            }
            .navigationTitle("Tesla Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showingVehicleSelection) {
                TeslaVehicleSelectionView(vehicles: authManager.vehicles)
            }
        }
    }
    
    private func login() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authManager.login(email: email, password: password)
            
            // Successfully logged in and fetched vehicles
            if !authManager.vehicles.isEmpty {
                showingVehicleSelection = true
            } else {
                errorMessage = "No vehicles found in your Tesla account"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Vehicle Selection View

struct TeslaVehicleSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let vehicles: [TeslaVehicle]
    @State private var selectedVehicles = Set<Int64>()
    
    var body: some View {
        NavigationStack {
            List(vehicles) { vehicle in
                Button {
                    if selectedVehicles.contains(vehicle.id) {
                        selectedVehicles.remove(vehicle.id)
                    } else {
                        selectedVehicles.insert(vehicle.id)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vehicle.display_name ?? vehicle.modelName)
                                .font(.headline)
                            
                            Text("\(vehicle.year) • \(vehicle.modelName)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("VIN: \(vehicle.vin)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: selectedVehicles.contains(vehicle.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedVehicles.contains(vehicle.id) ? .blue : .secondary)
                            .font(.title2)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Vehicles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        importSelectedVehicles()
                    }
                    .disabled(selectedVehicles.isEmpty)
                }
            }
        }
    }
    
    private func importSelectedVehicles() {
        for vehicle in vehicles where selectedVehicles.contains(vehicle.id) {
            let car = Car(
                name: vehicle.display_name ?? vehicle.modelName,
                make: "Tesla",
                model: vehicle.modelName,
                year: vehicle.year
            )
            modelContext.insert(car)
        }
        
        // Dismiss both sheets
        dismiss()
        // Need to dismiss the parent login view too
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.dismiss(animated: true)
        }
    }
}

#Preview("Login View") {
    TeslaLoginView()
}

#Preview("Vehicle Selection") {
    TeslaVehicleSelectionView(vehicles: [
        TeslaVehicle(
            id: 1,
            vehicle_id: 123456789,
            vin: "5YJSA1E26MF123456",
            display_name: "My Model S",
            option_codes: "MS",
            color: "Red",
            state: "online"
        ),
        TeslaVehicle(
            id: 2,
            vehicle_id: 987654321,
            vin: "7SAYGDEE1NF123456",
            display_name: nil,
            option_codes: "MY",
            color: "Blue",
            state: "asleep"
        )
    ])
    .modelContainer(for: Car.self, inMemory: true)
}
