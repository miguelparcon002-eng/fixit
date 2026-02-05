# Technician Screen Migration - Step by Step

## Issue
The technician jobs screen (`tech_jobs_screen.dart`) is using LocalBooking (local storage) while customers are now using Supabase. They're not connected!

## Solution Overview
Migrate the technician screen to use `technicianBookingsProvider` (Supabase) instead of `localBookingsProvider`.

## Changes Needed

### 1. Update all tab builders to use Supabase
- Replace `localBookingsProvider` with `technicianBookingsProvider`
- Handle AsyncValue (loading, error, data states)

### 2. Convert LocalBooking usage to BookingModel
- Update all widgets expecting LocalBooking to use BookingModel
- Map BookingModel fields to existing UI

### 3. Update booking actions to use BookingService
- Accept booking → call bookingService.acceptBooking()
- Update status → call bookingService.updateBookingStatus()
- Add notes → call bookingService.updateDiagnosticNotes()

## This is a LARGE refactor
The tech_jobs_screen.dart file is 1900+ lines and heavily uses LocalBooking throughout.

## Recommended Approach
Create a new simplified tech jobs screen that works with Supabase, or refactor in phases:

**Phase 1:** Get basic viewing working (Requested, Accepted, In Progress, Completed)
**Phase 2:** Add actions (Accept, Decline, Update Status)
**Phase 3:** Add advanced features (Edit booking, Add notes, etc.)
