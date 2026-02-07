-- Add discount information to an existing booking for testing
-- Run this in your Supabase SQL Editor

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
WHERE id = '22a7fe20-5741-462f-8494-438ac1b554e0';

-- Verify the update
SELECT id, diagnostic_notes, estimated_cost, final_cost
FROM bookings
WHERE id = '22a7fe20-5741-462f-8494-438ac1b554e0';
