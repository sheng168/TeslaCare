//
//  TireHistoryChartViews.swift
//  TeslaCare
//

import SwiftUI
import SwiftData
import Charts

struct TPMSHistoryChartView: View {
    let car: Car
    var chartHeight: CGFloat = 200

    private struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let psi: Double
        let label: String
    }

    private var dataPoints: [DataPoint] {
        let readings = (car.tpmsReadings ?? []).sorted { $0.date < $1.date }
        return readings.flatMap { reading in
            TirePosition.allCases.compactMap { position in
                guard let bar = reading.pressure(for: position) else { return nil }
                return DataPoint(date: reading.date, psi: bar * 14.504, label: position.abbreviation)
            }
        }
    }

    private var yDomain: ClosedRange<Double> {
        let values = dataPoints.map(\.psi)
        let lo = (values.min() ?? 30) - 3
        let hi = (values.max() ?? 50) + 3
        return lo...hi
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pressure History")
                .font(.headline)

            if dataPoints.isEmpty {
                Text("Sync your Tesla to build pressure history")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .multilineTextAlignment(.center)
            } else {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("PSI", point.psi)
                    )
                    .foregroundStyle(by: .value("Tire", point.label))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("PSI", point.psi)
                    )
                    .foregroundStyle(by: .value("Tire", point.label))
                    .symbolSize(25)
                }
                .chartYScale(domain: yDomain)
                .chartYAxis {
                    AxisMarks(values: .stride(by: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let psi = value.as(Double.self) {
                                Text("\(Int(psi))")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading)
                .frame(height: chartHeight)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4)
    }
}

struct TreadDepthHistoryChartView: View {
    let car: Car
    var chartHeight: CGFloat = 200

    private struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let depth: Double
        let label: String
    }

    private var dataPoints: [DataPoint] {
        (car.measurements ?? [])
            .sorted { $0.date < $1.date }
            .map { m in
                DataPoint(date: m.date, depth: m.treadDepth, label: m.position.abbreviation)
            }
    }

    private var yDomain: ClosedRange<Double> {
        let values = dataPoints.map(\.depth)
        let lo = max(0, (values.min() ?? 2) - 1)
        let hi = (values.max() ?? 10) + 1
        return lo...hi
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tread History")
                .font(.headline)

            if dataPoints.isEmpty {
                Text("Add measurements to build tread history")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .multilineTextAlignment(.center)
            } else {
                Chart {
                    ForEach(dataPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Depth", point.depth)
                        )
                        .foregroundStyle(by: .value("Tire", point.label))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Depth", point.depth)
                        )
                        .foregroundStyle(by: .value("Tire", point.label))
                        .symbolSize(25)
                    }

                    RuleMark(y: .value("Warning", 4.0))
                        .foregroundStyle(.orange.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    RuleMark(y: .value("Replace", 2.0))
                        .foregroundStyle(.red.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .chartYScale(domain: yDomain)
                .chartYAxis {
                    AxisMarks(values: .stride(by: 2)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let d = value.as(Double.self) {
                                Text("\(Int(d))")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartLegend(position: .bottom, alignment: .leading)
                .frame(height: chartHeight)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4)
    }
}

#Preview("TPMS History Chart — With Data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TPMSReading.self, configurations: config)

    let car = Car(name: "My Tesla", make: "Tesla", model: "Model 3", year: 2023)
    container.mainContext.insert(car)

    let syncDates: [TimeInterval] = [-42, -35, -28, -21, -14, -7, 0].map { $0 * 86400 }
    let flPsi: [Double] = [42, 41, 40, 38, 39, 41, 42]
    let frPsi: [Double] = [42, 41, 41, 39, 40, 41, 42]
    let rlPsi: [Double] = [40, 40, 39, 37, 38, 39, 40]
    let rrPsi: [Double] = [40, 39, 38, 36, 37, 39, 40]

    for i in syncDates.indices {
        let reading = TPMSReading(
            date: Date(timeIntervalSinceNow: syncDates[i]),
            frontLeft:  flPsi[i] / 14.504,
            frontRight: frPsi[i] / 14.504,
            rearLeft:   rlPsi[i] / 14.504,
            rearRight:  rrPsi[i] / 14.504
        )
        reading.car = car
        container.mainContext.insert(reading)
    }

    return TPMSHistoryChartView(car: car)
        .padding()
        .modelContainer(container)
}

#Preview("TPMS History Chart — Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Car.self, TPMSReading.self, configurations: config)
    let car = Car(name: "New Car", make: "Tesla", model: "Model Y", year: 2024)
    container.mainContext.insert(car)
    return TPMSHistoryChartView(car: car)
        .padding()
        .modelContainer(container)
}
