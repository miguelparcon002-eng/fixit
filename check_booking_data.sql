-- Check what's currently in booking 22a7fe20-5741-462f-8494-438ac1b554e0
-- Run this in Supabase SQL Editor to see the current data

SELECT
  id,
  status,
  diagnostic_notes,
  estimated_cost,
  final_cost,
  created_at
FROM bookings
WHERE id = '22a7fe20-5741-462f-8494-438ac1b554e0';

-- This will show you if the booking has discount information or not
-- If diagnostic_notes is NULL or doesn't contain "Promo Code:", the booking has no discount data
