-- Add discount information to ANY booking for testing
-- Instructions:
-- 1. Run find_recent_bookings.sql to find a booking ID
-- 2. Replace 'YOUR-BOOKING-ID-HERE' below with the actual booking ID
-- 3. Run this script in Supabase SQL Editor

UPDATE bookings
SET
  diagnostic_notes = 'Device: Mobile Phone
Model: iPhone 13 Pro
Problem: Screen cracked, needs replacement
Technician: Ethan Estino
Promo Code: FIRST20
Original Price: ₱5000.00
Discount: 20%',
  estimated_cost = 5000,
  final_cost = 4000
WHERE id = 'YOUR-BOOKING-ID-HERE';

-- Verify the update
SELECT id, status, diagnostic_notes, estimated_cost, final_cost
FROM bookings
WHERE id = 'YOUR-BOOKING-ID-HERE';

-- After running this:
-- 1. Refresh your technician app
-- 2. Go to Jobs screen
-- 3. Find this booking (it should show the discount info)
-- 4. Click Edit to test the discount maintenance
