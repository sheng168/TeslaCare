//
//  CarDetailPagerView.swift
//  TeslaCare
//
//  Created by Jin on 6/4/26.
//

import SwiftUI
import SwiftData

struct CarDetailPagerView: View {
    let cars: [Car]
    @State private var selectedCarID: PersistentIdentifier

    init(cars: [Car], initialCar: Car) {
        self.cars = cars
        self._selectedCarID = State(initialValue: initialCar.persistentModelID)
    }

    var body: some View {
        TabView(selection: $selectedCarID) {
            ForEach(cars) { car in
                CarDetailView(car: car)
                    .tag(car.persistentModelID)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

#Preview {
    NavigationStack {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Car.self, Tire.self, TireMeasurement.self, TireRotationEvent.self,
            TireReplacementEvent.self, AirFilterChangeEvent.self, TPMSReading.self,
            MileageReading.self, NearbyCharger.self,
            configurations: config
        )

        let car1 = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
        container.mainContext.insert(car1)
        let car2 = Car(name: "Family Car", make: "Tesla", model: "Model Y", year: 2022)
        container.mainContext.insert(car2)
        let car3 = Car(name: "Cybertruck", make: "Tesla", model: "Cybertruck", year: 2024)
        container.mainContext.insert(car3)

        return CarDetailPagerView(cars: [car1, car2, car3], initialCar: car1)
            .modelContainer(container)
            .environment(LocationManager())
            .environment(CloudKitPublicService())
            .environmentObject(TeslaAuthManager())
    }
}
