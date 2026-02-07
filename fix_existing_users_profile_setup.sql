-- Fix profile_setup_complete for existing users
-- This script marks all users created more than 1 day ago as having completed profile setup
-- This prevents the "Get Started" popup from appearing for existing customers

-- First, check current status
SELECT
  id,
  email,
  full_name,
  profile_setup_complete,
  created_at,
  CASE
    WHEN created_at < NOW() - INTERVAL '1 day' THEN 'Existing User'
    ELSE 'New User'
  END as user_type
FROM users
ORDER BY created_at DESC;

-- Update all existing users (created more than 1 day ago) to mark profile setup as complete
UPDATE users
SET profile_setup_complete = true
WHERE created_at < NOW() - INTERVAL '1 day'
  AND (profile_setup_complete IS NULL OR profile_setup_complete = false);

-- Verify the update
SELECT
  id,
  email,
  full_name,
  profile_setup_complete,
  created_at,
  CASE
    WHEN created_at < NOW() - INTERVAL '1 day' THEN 'Existing User (Should be true)'
    ELSE 'New User (Can be false)'
  END as user_type
FROM users
ORDER BY created_at DESC;
