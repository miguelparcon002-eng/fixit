-- Check if profile_setup_complete column exists and check existing users
SELECT id, email, full_name, profile_setup_complete 
FROM users 
WHERE email = 'fixitcustomer@gmail.com';

-- If the user exists but profile_setup_complete is false or null, update it
UPDATE users 
SET profile_setup_complete = true 
WHERE email = 'fixitcustomer@gmail.com' 
  AND created_at < NOW() - INTERVAL '1 day';

-- Verify the update
SELECT id, email, full_name, profile_setup_complete, created_at
FROM users 
WHERE email = 'fixitcustomer@gmail.com';
