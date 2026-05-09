//
//  TeslaCareSchema.swift
//  TeslaCare
//
//  Created by Jin on 5/9/26.
//

import SwiftData

// MARK: - V1: original schema (no Tesla fields on Car)

enum TeslaCareSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] = [
        Car.self,
        Tire.self,
        TireMeasurement.self,
        TireRotationEvent.self,
        TireReplacementEvent.self,
        AirFilterChangeEvent.self,
    ]
}

// MARK: - V2: adds vin, mileage, and TPMS fields to Car

enum TeslaCareSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] = [
        Car.self,
        Tire.self,
        TireMeasurement.self,
        TireRotationEvent.self,
        TireReplacementEvent.self,
        AirFilterChangeEvent.self,
    ]
}

// MARK: - Migration plan

enum TeslaCareMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        TeslaCareSchemaV1.self,
        TeslaCareSchemaV2.self,
    ]

    static var stages: [MigrationStage] = [
        .lightweight(fromVersion: TeslaCareSchemaV1.self, toVersion: TeslaCareSchemaV2.self),
    ]
}
