-- ==========================================
-- Phase 2 Database Schema Updates
-- ==========================================

-- 1. Add new columns to public.users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS age INTEGER;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS allergies TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS medical_conditions TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS special_notes TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS profile_picture TEXT;

-- 2. Create public.emergency_contacts table
CREATE TABLE IF NOT EXISTS public.emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  relation TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for emergency_contacts
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable read/write for all users on emergency_contacts" ON public.emergency_contacts;
CREATE POLICY "Enable read/write for all users on emergency_contacts"
  ON public.emergency_contacts
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- 3. Add new columns to public.volunteers table
ALTER TABLE public.volunteers ADD COLUMN IF NOT EXISTS category TEXT CHECK (category IN ('community', 'ambulance', 'hospital')) DEFAULT 'community';
ALTER TABLE public.volunteers ADD COLUMN IF NOT EXISTS government_id TEXT;
ALTER TABLE public.volunteers ADD COLUMN IF NOT EXISTS government_id_image TEXT;
ALTER TABLE public.volunteers ADD COLUMN IF NOT EXISTS profile_photo TEXT;
ALTER TABLE public.volunteers ADD COLUMN IF NOT EXISTS qualification TEXT;
ALTER TABLE public.volunteers ADD COLUMN IF NOT EXISTS skills TEXT;
ALTER TABLE public.volunteers ADD COLUMN IF NOT EXISTS successful_cases INTEGER DEFAULT 0 CHECK (successful_cases >= 0);
ALTER TABLE public.volunteers ADD COLUMN IF NOT EXISTS response_time INTERVAL;

-- 4. Add new columns to public.sos_incidents table
ALTER TABLE public.sos_incidents ADD COLUMN IF NOT EXISTS detection_type TEXT CHECK (detection_type IN ('manual', 'impact', 'fall', 'speed_drop')) DEFAULT 'manual';

-- 5. Create public.sos_assignments table (Historical Dispatch Log)
CREATE TABLE IF NOT EXISTS public.sos_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sos_id TEXT REFERENCES public.sos_incidents(id) ON DELETE CASCADE,
  volunteer_id UUID REFERENCES public.volunteers(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'assigned',
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for sos_assignments
ALTER TABLE public.sos_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable read/write for all users on sos_assignments" ON public.sos_assignments;
CREATE POLICY "Enable read/write for all users on sos_assignments"
  ON public.sos_assignments
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- ==========================================
-- 6. Update get_dashboard_stats() RPC function
-- ==========================================
CREATE OR REPLACE FUNCTION public.get_dashboard_stats()
RETURNS JSONB AS $$
DECLARE
  v_total_users INTEGER;
  v_total_volunteers INTEGER;
  v_active_sos INTEGER;
  v_resolved_cases INTEGER;
  v_activities JSONB;
  result JSONB;
BEGIN
  SELECT count(*) INTO v_total_users FROM public.users;
  SELECT count(*) INTO v_total_volunteers FROM public.volunteers WHERE is_verified = 'Verified';
  SELECT count(*) INTO v_active_sos FROM public.sos_incidents WHERE status IN ('Pending', 'In Progress', 'Accepted');
  SELECT count(*) INTO v_resolved_cases FROM public.sos_incidents WHERE status = 'Resolved';
  
  SELECT json_agg(t) INTO v_activities FROM (
    SELECT type, message, timestamp FROM public.recent_activities
  ) t;

  result := jsonb_build_object(
    'total_users', v_total_users,
    'total_volunteers', v_total_volunteers,
    'active_sos', v_active_sos,
    'resolved_cases', v_resolved_cases,
    'recent_activities', COALESCE(v_activities, '[]'::jsonb)
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ==========================================
-- 7. Update seed data with sample values for verification
-- ==========================================

-- Seed details for Admin
UPDATE public.users 
SET 
  age = 35, 
  gender = 'Male', 
  address = 'Salt Lake City, Sector V, Kolkata', 
  allergies = 'None',
  medical_conditions = 'None',
  special_notes = 'System administrator account'
WHERE email = 'admin@resqlink.org';

-- Seed details for Arjun Mehta (User)
UPDATE public.users 
SET 
  age = 28, 
  gender = 'Male', 
  address = '24B Park Street, Kolkata', 
  allergies = 'Peanuts',
  medical_conditions = 'Asthma',
  special_notes = 'Carries inhaler at all times'
WHERE email = 'arjun.mehta@example.com';

-- Seed details for Priya Patel (Volunteer)
UPDATE public.users 
SET 
  age = 26, 
  gender = 'Female', 
  address = '10A Gariahat Road, Kolkata', 
  allergies = 'Penicillin',
  medical_conditions = 'None',
  special_notes = 'First aid certified'
WHERE email = 'priya.patel@example.com';

-- Update volunteers categories and mock government ID verification status
UPDATE public.volunteers
SET 
  category = 'community',
  government_id = 'Aadhar Card: XXXXXXXX9012',
  skills = 'First Aid, CPR, Basic Lifesaving',
  qualification = 'Red Cross CPR Certificate',
  successful_cases = 8
WHERE id = (SELECT id FROM public.users WHERE email = 'priya.patel@example.com');

UPDATE public.volunteers
SET 
  category = 'ambulance',
  government_id = 'Commercial License: WB-02-XXXX',
  skills = 'Emergency Driving, Trauma Support',
  qualification = 'Paramedic Level 1',
  successful_cases = 12
WHERE id = (SELECT id FROM public.users WHERE email = 'rahul.sharma@example.com');

UPDATE public.volunteers
SET 
  category = 'community',
  government_id = 'PAN Card: XXXXX1234X',
  skills = 'Basic Responder',
  qualification = 'First Aid Certified',
  successful_cases = 15
WHERE id = (SELECT id FROM public.users WHERE email = 'vikram.singh@example.com');

UPDATE public.volunteers
SET 
  category = 'community',
  government_id = 'Voter ID: XXX9876543',
  skills = 'Local Guide',
  qualification = 'None',
  successful_cases = 4
WHERE id = (SELECT id FROM public.users WHERE email = 'amit.k@example.com');

-- Update SOS incidents with detection types
UPDATE public.sos_incidents SET detection_type = 'manual' WHERE incident_type = 'Medical Emergency';
UPDATE public.sos_incidents SET detection_type = 'impact' WHERE incident_type = 'Road Accident';
UPDATE public.sos_incidents SET detection_type = 'speed_drop' WHERE incident_type = 'Fire Hazard';
