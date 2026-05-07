//
//  AppIconGenerator.swift
//  TeslaCare
//
//  Created by Jin on 5/7/26.
//

import SwiftUI

/// A view to generate the app icon design
/// To use: Run the app with this view, take a screenshot, and crop it to create your icon
struct AppIconGenerator: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.05, green: 0.05, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Tire design
            ZStack {
                // Outer tire ring
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.gray, Color(white: 0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 60
                    )
                    .frame(width: 400, height: 400)
                
                // Tire tread pattern
                ForEach(0..<16) { index in
                    Rectangle()
                        .fill(.gray)
                        .frame(width: 8, height: 50)
                        .offset(y: -200)
                        .rotationEffect(.degrees(Double(index) * 22.5))
                }
                
                // Inner hub with gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.4), Color(white: 0.2)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                // Hub details - spokes
                ForEach(0..<5) { index in
                    Capsule()
                        .fill(Color(white: 0.3))
                        .frame(width: 20, height: 80)
                        .offset(y: 0)
                        .rotationEffect(.degrees(Double(index) * 72))
                }
                
                // Center cap with checkmark for "health"
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, Color(red: 0, green: 0.6, blue: 0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                // Shine effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.3), Color.clear],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: 250
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blendMode(.overlay)
            }
        }
        .frame(width: 1024, height: 1024) // Standard app icon size
        .ignoresSafeArea()
    }
}

#Preview("App Icon") {
    AppIconGenerator()
}

// Alternative simpler design
struct AppIconGeneratorSimple: View {
    var body: some View {
        ZStack {
            // Background
            Color.black
            
            // Simple tire icon
            ZStack {
                // Tire
                Circle()
                    .strokeBorder(.gray, lineWidth: 45)
                    .frame(width: 300, height: 300)
                
                // Inner circle
                Circle()
                    .fill(.black)
                    .stroke(Color(white: 0.3), lineWidth: 3)
                    .frame(width: 150, height: 150)
                
                // Health indicator
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
            }
        }
        .frame(width: 1024, height: 1024)
        .ignoresSafeArea()
    }
}

#Preview("App Icon Simple") {
    AppIconGeneratorSimple()
}

// Modern minimal design
struct AppIconGeneratorModern: View {
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color(red: 0, green: 0.5, blue: 1), Color(red: 0, green: 0.3, blue: 0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: -20) {
                // Two tires side by side (like a car front view)
                HStack(spacing: 60) {
                    TireIcon()
                    TireIcon()
                }
            }
        }
        .frame(width: 1024, height: 1024)
        .ignoresSafeArea()
    }
}

struct TireIcon: View {
    var body: some View {
        ZStack {
            // Outer tire
            Circle()
                .strokeBorder(.white.opacity(0.9), lineWidth: 35)
                .frame(width: 200, height: 200)
            
            // Tread marks
            ForEach(0..<8) { index in
                Rectangle()
                    .fill(.white.opacity(0.6))
                    .frame(width: 4, height: 25)
                    .offset(y: -100)
                    .rotationEffect(.degrees(Double(index) * 45))
            }
            
            // Inner hub
            Circle()
                .fill(.white.opacity(0.3))
                .frame(width: 90, height: 90)
        }
    }
}

#Preview("App Icon Modern") {
    AppIconGeneratorModern()
}
