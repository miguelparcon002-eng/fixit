# Booking Edit Feature Implementation

## Overview
Added the ability for technicians to edit active booking details, including adding technician notes and adjusting the price (increase or decrease) for additional services or discounts.

## Changes Made

### 1. Updated `lib/services/booking_service.dart`
**New Method: `updateBookingDetails()`**
- Allows updating booking with technician notes and price adjustments
- Parameters:
  - `bookingId` (required): The booking to update
  - `technicianNotes` (optional): Diagnostic notes about additional issues
  - `priceAdjustment` (optional): Amount to add/subtract from estimated cost
- Calculates new `final_cost` based on `estimated_cost + priceAdjustment`
- Saves to Supabase `bookings` table

### 2. Updated `lib/screens/technician/tech_jobs_screen_new.dart`
**Replaced `_addNotes()` with `_editBookingDetails()`**
- Enhanced edit dialog with two sections:
  1. **Technician Notes**: Multi-line text field for describing additional issues
  2. **Price Adjustment (₱)**: Numeric input for increasing/decreasing price
- Shows current price at top of dialog
- Info banner explaining adjustment usage:
  - Positive values increase price
  - Negative values decrease price (discount)
- Updates Supabase via `bookingService.updateBookingDetails()`
- Invalidates provider to refresh UI immediately

### 3. UI/UX Features
- Modern dialog design with rounded corners
- Color-coded sections:
  - Blue info box showing current price
  - Orange warning box with adjustment instructions
- Input validation for price adjustments
- Success/error feedback via SnackBars
- Immediate UI refresh after update

## Usage Flow

1. Technician has an active job (in_progress status)
2. Clicks the **Edit** (pencil) button on job card
3. Dialog opens showing:
   - Current price of the booking
   - Text field for technician notes
   - Numeric field for price adjustment
   - Helper text with examples
4. Technician can:
   - Add notes about additional issues found
   - Enter positive value to increase price (e.g., 200 for ₱200 extra)
   - Enter negative value for discount (e.g., -100 for ₱100 off)
5. Clicks "Update Booking"
6. Changes saved to Supabase
7. UI refreshes to show updated information

## Database Updates

### Supabase `bookings` Table Columns Used:
- `diagnostic_notes`: Stores technician notes
- `final_cost`: Updated with new calculated price
- `estimated_cost`: Original estimate (unchanged)

## Examples

### Scenario 1: Additional Parts Needed
- Original estimate: ₱500
- Technician finds battery also needs replacement (+₱200)
- Enters notes: "Battery also needs replacement"
- Enters adjustment: 200
- New final cost: ₱700

### Scenario 2: Issue Less Severe
- Original estimate: ₱800
- Issue is simpler than expected (-₱100 discount)
- Enters notes: "Only needed minor adjustment"
- Enters adjustment: -100
- New final cost: ₱700

### Scenario 3: Just Adding Notes
- No price change needed
- Enters notes: "Checked all components, working fine"
- Leaves price adjustment blank
- Final cost remains at estimated cost

## Benefits
1. **Transparency**: Customers see updated price and reason
2. **Flexibility**: Technicians can adjust pricing on-site
3. **Accuracy**: Final cost reflects actual work done
4. **Real-time**: Changes saved to Supabase immediately
5. **Reward Points**: Correct final cost used for customer rewards (1 point per ₱50)

## Technical Notes
- Price adjustment is relative to estimated cost, not cumulative
- If final_cost already exists, it gets recalculated from estimated_cost + new adjustment
- Negative adjustments clamped to ensure final_cost >= 0
- All monetary values stored as doubles in database
- Provider invalidation ensures immediate UI refresh across all screens
