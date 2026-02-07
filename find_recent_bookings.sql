-- Find your most recent bookings to add discount info to
-- Run this in Supabase SQL Editor first

SELECT
  id,
  status,
  customer_id,
  technician_id,
  estimated_cost,
  final_cost,
  LEFT(diagnostic_notes, 100) as notes_preview,
  created_at
FROM bookings
ORDER BY created_at DESC
LIMIT 10;

-- Look for bookings with status 'in_progress' or 'accepted'
-- Then use the booking ID in the add_discount_to_booking.sql script
