# TeslaCare - Tire Tread Tracking App

## Overview
TeslaCare is a tire tread depth tracking application that helps car owners monitor their tire health over time. The app uses SwiftUI and SwiftData for a modern, persistent data experience.

## Features

### 1. **Tesla Account Integration** ⚡️ NEW
- Connect your Tesla account to automatically import vehicles
- Secure OAuth authentication
- Automatic vehicle details (make, model, year, VIN)
- Sync vehicles on demand
- Manage connection from Settings
- [Full Documentation](TESLA_INTEGRATION.md)

### 2. **Car Management**
- Add multiple cars with make, model, year, and optional custom name
- View all cars in a list with tire health indicators
- Delete cars (cascading delete removes all associated measurements)

### 3. **Tire Tread Tracking**
- Track tread depth for all four tires (Front Left, Front Right, Rear Left, Rear Right)
- Measurements stored in 32nds of an inch (industry standard)
- Visual tire grid showing latest measurements for each position
- Color-coded health indicators:
  - **Green**: Good condition (above 4/32")
  - **Orange**: Warning - monitor closely (2-4/32")
  - **Red**: Danger - replace immediately (below 2/32")

### 4. **Measurement History**
- Complete history of all measurements sorted by date
- Add notes and mileage to each measurement
- Track trends over time

### 5. **Health Calculations**
- Overall tire health percentage based on latest measurements
- Average tread depth across all four tires
- Calculated using: (current depth - 2/32") / (10/32" - 2/32") * 100%
  - Assumes 10/32" as new tire baseline
  - 2/32" as legal minimum/replacement threshold

## Data Models

### Car
- **Properties**: name, make, model, year, dateAdded
- **Relationships**: One-to-many with TireMeasurement
- **Computed Properties**: 
  - `displayName`: Shows custom name or "Year Make Model"
  - `latestMeasurement(for:)`: Gets most recent measurement for a tire position
  - `averageTreadDepth`: Average across all four latest measurements
  - `tireHealthPercentage`: Overall tire health score

### TireMeasurement
- **Properties**: date, treadDepth, position, notes, mileage
- **Relationships**: Many-to-one with Car
- **Computed Properties**:
  - `treadDepthFormatted`: Display-friendly format (e.g., "7.5/32\"")
  - `isWarning`: True if <= 4/32"
  - `isDanger`: True if <= 2/32"

### TirePosition (Enum)
- frontLeft, frontRight, rearLeft, rearRight
- Includes system image icons for visual representation

## User Interface

### ContentView
- Main list of cars
- Each row shows:
  - Car name and details
  - Health progress bar
  - Overall health percentage
- Empty state with helpful message
- Add and delete functionality

### CarDetailView
- Car information header
- Overall health display with progress indicator
- Interactive tire grid (tap any tire to add measurement for that position)
- Complete measurement history
- Visual car icon showing tire positions

### AddCarView
- Simple form to add new cars
- Make and model are required
- Name is optional (auto-generates if empty)
- Year picker with sensible range

### AddMeasurementView
- Tire position picker with icons
- Date picker
- Tread depth slider (0-12/32")
- Real-time color-coded feedback
- Visual guide showing safe/warning/danger zones
- Optional mileage tracking
- Optional notes field
- Can be pre-filled with specific tire position when tapped from grid

## Best Practices Used

1. **SwiftData**: Modern persistence framework with relationships
2. **SwiftUI**: Declarative UI with native components
3. **NavigationSplitView**: Proper iPad/Mac split-view support
4. **ContentUnavailableView**: Native empty states
5. **Form**: Standard iOS form layout
6. **Color-coded feedback**: Intuitive visual health indicators
7. **Computed properties**: Clean separation of logic from UI
8. **Cascading deletes**: Proper data cleanup
9. **Preview providers**: Each view includes previews with sample data
10. **Async/await**: Modern concurrency for network calls
11. **@Observable**: SwiftUI state management

## Usage Guide

### Getting Started

#### Option 1: Connect Tesla Account (Recommended for Tesla owners)
1. Open the app for the first time
2. Tap **"Connect Tesla Account"** button
3. Enter your Tesla email and password
4. Select which vehicles to import
5. Start tracking tire health!

#### Option 2: Add Cars Manually
1. Tap the **+** button in the top-right
2. Select **"Add Car Manually"**
3. Fill in make, model, year, and optional name
4. Tap **"Add"**

### Managing Cars
1. **View car details**: Tap any car in the list
2. **Delete cars**: Swipe left or use Edit mode
3. **Sync Tesla vehicles**: Settings → Tesla Account → Sync Vehicles

### Tracking Tire Tread
1. **Add measurement**: 
   - Tap + in toolbar on car detail screen, OR
   - Tap any tire in the grid to pre-select that position
2. **Track progress**: Monitor health percentage and individual tire depths
3. **View history**: Scroll down to see all past measurements

### Settings & Account Management
1. Go to **Settings** tab
2. Manage Tesla account connection
3. Adjust measurement units
4. Configure notifications
5. Export/import data

## Safety Thresholds

- **New tires**: Typically 10-11/32"
- **Good condition**: Above 4/32"
- **Warning zone**: 2-4/32" (should plan for replacement)
- **Danger zone**: Below 2/32" (legal minimum in most areas, replace immediately)
- **Replace at**: 2/32" or less

## Future Enhancement Ideas

1. Notifications when tires reach warning threshold
2. Charts showing tread depth over time
3. Estimated tire lifespan based on wear rate
4. Photo attachment for tire condition
5. Rotation tracking and reminders
6. Integration with tire retailers for purchase options
7. Export measurements to PDF report
8. Multiple vehicle profiles for fleet management
9. Integration with car maintenance apps
10. Widget showing tire health at a glance
