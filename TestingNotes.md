# TezCare – Testing Notes

## Overview
TezCare is an iOS 26 app for tracking Tesla vehicle maintenance, with a focus on tire health, mileage, and community car listings.

---

## Setup

- Requires iOS 26
- iCloud account recommended for sync (app uses SwiftData + iCloud)
- Tesla account optional — connect via Settings > Tesla Account to auto-import vehicles

---

## Features to Test

### Cars Tab
- [ ] Empty state shows "No Cars" with a prompt to add one
- [ ] Tap `+` → two options: "Add Car Manually" and "Connect Tesla Account"
- [ ] Add a car manually (name, make, model, year)
- [ ] Sort cars by: Last Modified, Date Added, Name, Mileage, Battery Level
- [ ] Pull-to-refresh syncs Tesla vehicles (shows error banner if unauthenticated or no vehicles found)
- [ ] Swipe-to-delete removes a car

### Car Detail
- [ ] Header shows year/make/model, drivetrain badge, FSD/Free SC badges if applicable
- [ ] Mileage row is tappable — opens "Update Mileage" sheet
- [ ] Battery level shows correct icon and color (green ≥50%, orange ≥20%, red <20%, blue if charging)
- [ ] Car location shows distance from user (requires location permission)
- [ ] Tire grid shows all 4 positions; tapping a position opens "Add Measurement" pre-filled to that position
- [ ] Action buttons: Rotate, Replace, Mileage all open correct sheets
- [ ] History charts (TPMS, tread depth) appear only when data exists
- [ ] Mileage chart appears only when mileage readings exist
- [ ] Tire pressure section appears only when TPMS data is synced from Tesla
- [ ] Nearby chargers section appears only when charger data exists (synced from Tesla)
- [ ] Rotation / Replacement / Repair / Air Filter history sections appear only when events have been logged
- [ ] All DisclosureGroups collapse/expand and persist state across app restarts
- [ ] Toolbar: `+` adds measurement, `…` menu has Edit Car, Log Air Filter, Update Mileage
- [ ] Publish/Unpublish to Community (requires iCloud)

### Tires Tab
- [ ] Lists all tires across all cars
- [ ] Tap a tire to view detail (tread measurements, photos, repair history)
- [ ] Add / edit tire info

### Community Tab
- [ ] Browse public car listings from other users (requires iCloud)
- [ ] Tap a listing to see detail
- [ ] Publish your own car listing from Car Detail view

### Settings
- [ ] Tread depth unit toggle (32nds of an inch vs. millimeters)
- [ ] iCloud status shows correct state (Available / Not Signed In / etc.)
- [ ] Tesla Account section: connect, shows green checkmark when authenticated, Sign Out button appears
- [ ] Notifications toggle — disabling removes all pending reminders
- [ ] "Configure Reminders" link appears only when notifications are enabled
- [ ] Replacement threshold slider (1.0–4.0)
- [ ] Warning threshold slider (3.0–6.0)
- [ ] Export Data / Import Data navigation links
- [ ] "Delete All Data" button (confirm it shows a confirmation before deleting — currently a known stub)

---

## Known Limitations / Not Yet Implemented

- "Delete All Data" button does not yet show a confirmation alert (no-op)
- Privacy Policy and Terms of Service links point to placeholder URLs
- Send Feedback opens a mailto link (may not work on simulator)

---

## Devices / Orientations

- Test on iPhone (primary target)
- Test on iPad — Car list uses NavigationSplitView (sidebar + detail column)
- Test both portrait and landscape

---

## Permissions

- **Location** — needed for "distance to car" in Car Detail and nearby charger distance
- **Notifications** — needed for tire update reminders
- **iCloud** — needed for data sync and Community features
