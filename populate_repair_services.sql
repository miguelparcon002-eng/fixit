-- Populate services table with phone and laptop repair services
-- This script adds realistic repair services to the database
-- IMPORTANT: Make sure you have at least one technician user before running this!

-- Screen Repair Services
INSERT INTO public.services (service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active, technician_id)
SELECT 
  service_name,
  description,
  category,
  base_price,
  estimated_duration,
  parts_availability,
  warranty_terms,
  is_active,
  (SELECT id FROM public.users WHERE role = 'technician' LIMIT 1) as technician_id
FROM (VALUES
  ('iPhone Screen Replacement', 'Professional screen replacement for all iPhone models. High-quality OEM or aftermarket displays available.', 'Screen Repair', 2500, 45, 'in_stock', '90-day warranty on parts and labor', true),
  ('Samsung Screen Replacement', 'Expert screen repair for Samsung Galaxy devices. AMOLED and LCD screens available.', 'Screen Repair', 2200, 45, 'in_stock', '90-day warranty on parts and labor', true),
  ('iPad Screen Replacement', 'iPad screen repair with genuine quality parts. All models supported.', 'Screen Repair', 3500, 60, 'order_required', '90-day warranty on parts and labor', true),
  ('Laptop LCD Screen Replacement', 'Laptop screen replacement for all brands. LED and LCD displays.', 'Screen Repair', 4500, 90, 'order_required', '6-month warranty on parts', true),
  ('MacBook Screen Replacement', 'MacBook Retina and LCD screen replacement. Genuine Apple quality parts.', 'Screen Repair', 12000, 120, 'order_required', '6-month warranty on parts', true)
) AS t(service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active);

-- Battery Replacement Services
INSERT INTO public.services (service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active, technician_id)
SELECT 
  service_name,
  description,
  category,
  base_price,
  estimated_duration,
  parts_availability,
  warranty_terms,
  is_active,
  (SELECT id FROM public.users WHERE role = 'technician' LIMIT 1) as technician_id
FROM (VALUES
  ('iPhone Battery Replacement', 'Replace your old iPhone battery with a high-capacity replacement. Improves battery life significantly.', 'Battery Replacement', 1200, 30, 'in_stock', '1-year warranty on battery', true),
  ('Android Phone Battery Replacement', 'Battery replacement for Samsung, Xiaomi, OPPO, and other Android phones.', 'Battery Replacement', 800, 30, 'in_stock', '1-year warranty on battery', true),
  ('Laptop Battery Replacement', 'Laptop battery replacement for all brands. Original and compatible batteries available.', 'Battery Replacement', 2500, 45, 'order_required', '1-year warranty on battery', true),
  ('MacBook Battery Replacement', 'MacBook battery service with genuine quality cells. Restores full battery capacity.', 'Battery Replacement', 5500, 60, 'order_required', '1-year warranty on battery', true),
  ('iPad Battery Replacement', 'Professional iPad battery replacement service. Extends device lifespan.', 'Battery Replacement', 2800, 60, 'order_required', '1-year warranty on battery', true)
) AS t(service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active);

-- Water Damage Services
INSERT INTO public.services (service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active, technician_id)
SELECT 
  service_name,
  description,
  category,
  base_price,
  estimated_duration,
  parts_availability,
  warranty_terms,
  is_active,
  (SELECT id FROM public.users WHERE role = 'technician' LIMIT 1) as technician_id
FROM (VALUES
  ('Phone Water Damage Repair', 'Emergency water damage recovery for phones. Component cleaning, drying, and testing.', 'Water Damage', 1500, 120, 'in_stock', 'No warranty on water damage - best effort repair', true),
  ('Laptop Water Damage Repair', 'Laptop liquid damage repair. Motherboard cleaning and component replacement.', 'Water Damage', 3500, 180, 'order_required', 'No warranty on water damage - best effort repair', true),
  ('MacBook Water Damage Repair', 'MacBook liquid damage recovery service. Logic board cleaning and diagnostics.', 'Water Damage', 6000, 240, 'order_required', 'No warranty on water damage - best effort repair', true),
  ('Tablet Water Damage Repair', 'Water damage repair for iPads and Android tablets. Full diagnostics included.', 'Water Damage', 2500, 150, 'order_required', 'No warranty on water damage - best effort repair', true)
) AS t(service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active);

-- Software Issues Services
INSERT INTO public.services (service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active, technician_id)
SELECT 
  service_name,
  description,
  category,
  base_price,
  estimated_duration,
  parts_availability,
  warranty_terms,
  is_active,
  (SELECT id FROM public.users WHERE role = 'technician' LIMIT 1) as technician_id
FROM (VALUES
  ('Phone Software Troubleshooting', 'Fix software issues: boot loops, frozen screens, app crashes, and OS updates.', 'Software Issues', 500, 45, 'in_stock', '30-day software support', true),
  ('iPhone iOS Update & Restore', 'iOS update, restore, and backup service. Fixes software glitches and performance issues.', 'Software Issues', 600, 45, 'in_stock', '30-day software support', true),
  ('Android Factory Reset & Setup', 'Complete Android device reset, optimization, and setup. Removes malware and bloatware.', 'Software Issues', 500, 45, 'in_stock', '30-day software support', true),
  ('Laptop Virus Removal', 'Complete virus, malware, and spyware removal. Includes antivirus installation.', 'Software Issues', 800, 90, 'in_stock', '30-day virus protection guarantee', true),
  ('Windows OS Reinstallation', 'Fresh Windows installation with drivers. Includes data backup and transfer.', 'Software Issues', 1200, 120, 'in_stock', '30-day software support', true),
  ('MacOS Reinstallation', 'Clean macOS installation and setup. Data migration available.', 'Software Issues', 1500, 120, 'in_stock', '30-day software support', true)
) AS t(service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active);

-- Data Recovery Services
INSERT INTO public.services (service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active, technician_id)
SELECT 
  service_name,
  description,
  category,
  base_price,
  estimated_duration,
  parts_availability,
  warranty_terms,
  is_active,
  (SELECT id FROM public.users WHERE role = 'technician' LIMIT 1) as technician_id
FROM (VALUES
  ('Phone Data Recovery', 'Recover photos, contacts, messages from damaged or dead phones.', 'Data Recovery', 2000, 180, 'in_stock', 'Success-based - no recovery, no charge', true),
  ('Laptop Hard Drive Data Recovery', 'Recover data from failed hard drives, SSDs, and corrupted storage.', 'Data Recovery', 3500, 240, 'order_required', 'Success-based - no recovery, no charge', true),
  ('iPhone Data Recovery', 'Specialized iPhone data recovery from dead or damaged devices.', 'Data Recovery', 2500, 180, 'in_stock', 'Success-based - no recovery, no charge', true),
  ('SSD Data Recovery', 'Professional SSD data recovery service. Advanced techniques used.', 'Data Recovery', 4500, 300, 'order_required', 'Success-based - no recovery, no charge', true)
) AS t(service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active);

-- Hardware Upgrades Services
INSERT INTO public.services (service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active, technician_id)
SELECT 
  service_name,
  description,
  category,
  base_price,
  estimated_duration,
  parts_availability,
  warranty_terms,
  is_active,
  (SELECT id FROM public.users WHERE role = 'technician' LIMIT 1) as technician_id
FROM (VALUES
  ('Laptop RAM Upgrade', 'Upgrade laptop memory for better performance. All brands supported.', 'Hardware Upgrades', 1500, 45, 'order_required', '1-year warranty on parts', true),
  ('Laptop SSD Upgrade', 'Replace HDD with SSD for faster boot and performance. Includes data migration.', 'Hardware Upgrades', 2500, 90, 'order_required', '1-year warranty on parts', true),
  ('MacBook SSD Upgrade', 'Upgrade MacBook storage with high-speed SSD. Data transfer included.', 'Hardware Upgrades', 5000, 120, 'order_required', '1-year warranty on parts', true),
  ('Gaming Laptop GPU Upgrade', 'Graphics card upgrade for gaming laptops. Improves gaming performance.', 'Hardware Upgrades', 8000, 180, 'order_required', '6-month warranty on parts', true)
) AS t(service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active);

-- Diagnostics Services
INSERT INTO public.services (service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active, technician_id)
SELECT 
  service_name,
  description,
  category,
  base_price,
  estimated_duration,
  parts_availability,
  warranty_terms,
  is_active,
  (SELECT id FROM public.users WHERE role = 'technician' LIMIT 1) as technician_id
FROM (VALUES
  ('Phone Diagnostics', 'Complete phone diagnostics: battery health, screen, charging, sensors, etc.', 'Diagnostics', 300, 30, 'in_stock', 'Diagnostic report provided', true),
  ('Laptop Diagnostics', 'Full laptop hardware and software diagnostics. Identify all issues.', 'Diagnostics', 500, 60, 'in_stock', 'Detailed diagnostic report', true),
  ('MacBook Diagnostics', 'Professional MacBook diagnostics using Apple tools and techniques.', 'Diagnostics', 600, 60, 'in_stock', 'Detailed diagnostic report', true),
  ('Charging Port Inspection', 'Diagnose charging issues: port damage, battery problems, or charger faults.', 'Diagnostics', 200, 20, 'in_stock', 'Diagnostic report provided', true)
) AS t(service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active);

-- Accessories Services
INSERT INTO public.services (service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active, technician_id)
SELECT 
  service_name,
  description,
  category,
  base_price,
  estimated_duration,
  parts_availability,
  warranty_terms,
  is_active,
  (SELECT id FROM public.users WHERE role = 'technician' LIMIT 1) as technician_id
FROM (VALUES
  ('Charging Port Replacement', 'Replace damaged charging ports for phones and tablets.', 'Accessories', 800, 45, 'in_stock', '90-day warranty on parts', true),
  ('Camera Lens Replacement', 'Phone camera lens replacement. Fixes cracked or scratched camera glass.', 'Accessories', 600, 30, 'in_stock', '90-day warranty on parts', true),
  ('Speaker Repair', 'Fix loudspeaker, earpiece, or microphone issues on phones.', 'Accessories', 700, 45, 'in_stock', '90-day warranty on parts', true),
  ('Home Button Repair', 'iPhone/iPad home button replacement or repair service.', 'Accessories', 800, 45, 'order_required', '90-day warranty on parts', true),
  ('Laptop Keyboard Replacement', 'Replace broken or damaged laptop keyboards. All brands supported.', 'Accessories', 1800, 60, 'order_required', '6-month warranty on parts', true),
  ('Laptop Hinge Repair', 'Fix broken laptop hinges. Prevents further screen damage.', 'Accessories', 2000, 90, 'order_required', '6-month warranty on parts', true)
) AS t(service_name, description, category, base_price, estimated_duration, parts_availability, warranty_terms, is_active);

-- Success message
SELECT 'Successfully inserted ' || COUNT(*) || ' repair services!' as message
FROM public.services 
WHERE created_at > NOW() - INTERVAL '1 minute';
