-- Create a service for Ethan Estino
-- Use this if you want to manually create the service

INSERT INTO public.services (
  technician_id,
  service_name,
  description,
  category,
  estimated_duration,
  is_active,
  created_at
)
VALUES (
  '04a72f58-1e79-404b-87c8-3698bd57a5a8',  -- Ethan's ID
  'General Repair',
  'Professional device repair service by Ethan Estino',
  'Repair',
  60,
  true,
  NOW()
)
ON CONFLICT DO NOTHING;

-- Verify it was created
SELECT id, service_name, technician_id, is_active, created_at
FROM public.services
WHERE technician_id = '04a72f58-1e79-404b-87c8-3698bd57a5a8';
