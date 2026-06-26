-- ==========================================
-- 0. Database Cleanup & Setup
-- ==========================================
DROP VIEW IF EXISTS public.recent_activities CASCADE;
DROP FUNCTION IF EXISTS public.get_dashboard_stats() CASCADE;
DROP FUNCTION IF EXISTS public.find_closest_volunteers(numeric, numeric, numeric, integer) CASCADE;
DROP FUNCTION IF EXISTS public.calculate_distance(numeric, numeric, numeric, numeric) CASCADE;
DROP FUNCTION IF EXISTS public.sync_volunteer_profile() CASCADE;
DROP FUNCTION IF EXISTS public.update_location_geography() CASCADE;

DROP TABLE IF EXISTS public.issues CASCADE;
DROP TABLE IF EXISTS public.sos_incidents CASCADE;
DROP TABLE IF EXISTS public.volunteers CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- 1. Sequences for Custom Identifiers
-- ==========================================

-- Sequence for SOS incident string IDs (e.g., SOS-802, SOS-803...)
CREATE SEQUENCE IF NOT EXISTS public.sos_incident_seq START WITH 802;

-- Sequence for Ticket string IDs (e.g., tkt-106, tkt-107...)
CREATE SEQUENCE IF NOT EXISTS public.issue_seq START WITH 106;

-- ==========================================
-- 2. Tables & Constraints
-- ==========================================

-- Users Table
CREATE TABLE public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  blood_group TEXT,
  role TEXT NOT NULL DEFAULT 'User' CHECK (role IN ('User', 'Volunteer', 'Admin')),
  status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Suspended')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Volunteers Table (Extension of Users table for Volunteers)
CREATE TABLE public.volunteers (
  id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  is_verified TEXT NOT NULL DEFAULT 'Pending' CHECK (is_verified IN ('Verified', 'Pending', 'Suspended')),
  is_available TEXT NOT NULL DEFAULT 'Offline' CHECK (is_available IN ('Available', 'Busy', 'Offline')),
  rating NUMERIC(3, 2) NOT NULL DEFAULT 0.0 CHECK (rating >= 0.0 AND rating <= 5.0),
  total_cases INTEGER NOT NULL DEFAULT 0 CHECK (total_cases >= 0),
  latitude NUMERIC(10, 8), -- Current GPS location latitude
  longitude NUMERIC(11, 8), -- Current GPS location longitude
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- SOS Incidents Table
CREATE TABLE public.sos_incidents (
  id TEXT PRIMARY KEY DEFAULT 'SOS-' || nextval('public.sos_incident_seq')::text,
  victim_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  victim_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  blood_group TEXT,
  latitude NUMERIC(10, 8) NOT NULL,
  longitude NUMERIC(11, 8) NOT NULL,
  status TEXT NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Accepted', 'Resolved', 'Cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ,
  assigned_volunteer_id UUID REFERENCES public.volunteers(id) ON DELETE SET NULL,
  incident_type TEXT NOT NULL,
  severity TEXT NOT NULL CHECK (severity IN ('Critical', 'High', 'Medium', 'Low')),
  emergency_contact TEXT
);

-- Issues (Support Tickets) Table
CREATE TABLE public.issues (
  id TEXT PRIMARY KEY DEFAULT 'tkt-' || nextval('public.issue_seq')::text,
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  user_name TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT NOT NULL DEFAULT 'Medium' CHECK (priority IN ('High', 'Medium', 'Low')),
  status TEXT NOT NULL DEFAULT 'Open' CHECK (status IN ('Open', 'In Progress', 'Resolved', 'Closed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ==========================================
-- 3. Query Indexes
-- ==========================================

CREATE INDEX IF NOT EXISTS idx_users_role ON public.users (role);
CREATE INDEX IF NOT EXISTS idx_users_status ON public.users (status);
CREATE INDEX IF NOT EXISTS idx_volunteers_availability ON public.volunteers (is_available, is_verified);
CREATE INDEX IF NOT EXISTS idx_sos_incidents_status ON public.sos_incidents (status);
CREATE INDEX IF NOT EXISTS idx_issues_status ON public.issues (status);

-- ==========================================
-- 4. Mathematical Proximity Functions
-- ==========================================

-- Haversine formula to calculate the distance between two sets of GPS coordinates in meters
CREATE OR REPLACE FUNCTION public.calculate_distance(
  lat1 NUMERIC, lon1 NUMERIC,
  lat2 NUMERIC, lon2 NUMERIC
)
RETURNS NUMERIC AS $$
DECLARE
  r_earth NUMERIC := 6371000; -- Earth's average radius in meters
  d_lat NUMERIC;
  d_lon NUMERIC;
  a NUMERIC;
  c NUMERIC;
BEGIN
  -- Handle null coordinates
  IF lat1 IS NULL OR lon1 IS NULL OR lat2 IS NULL OR lon2 IS NULL THEN
    RETURN NULL;
  END IF;

  d_lat := radians(lat2 - lat1);
  d_lon := radians(lon2 - lon1);
  
  a := sin(d_lat/2) * sin(d_lat/2) +
       cos(radians(lat1)) * cos(radians(lat2)) *
       sin(d_lon/2) * sin(d_lon/2);
  c := 2 * atan2(sqrt(a), sqrt(1-a));
  
  RETURN r_earth * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to find closest available volunteers to an incident location using the distance calculator
CREATE OR REPLACE FUNCTION public.find_closest_volunteers(
  p_latitude NUMERIC,
  p_longitude NUMERIC,
  p_max_distance_meters NUMERIC DEFAULT 10000,
  p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
  volunteer_id UUID,
  volunteer_name TEXT,
  volunteer_phone TEXT,
  blood_group TEXT,
  distance_meters NUMERIC,
  is_available TEXT,
  rating NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    v.id AS volunteer_id,
    u.name AS volunteer_name,
    u.phone AS volunteer_phone,
    u.blood_group,
    public.calculate_distance(p_latitude, p_longitude, v.latitude, v.longitude)::numeric AS distance_meters,
    v.is_available,
    v.rating
  FROM public.volunteers v
  JOIN public.users u ON v.id = u.id
  WHERE v.is_verified = 'Verified'
    AND v.is_available = 'Available'
    AND v.latitude IS NOT NULL
    AND v.longitude IS NOT NULL
    AND public.calculate_distance(p_latitude, p_longitude, v.latitude, v.longitude) <= p_max_distance_meters
  ORDER BY distance_meters ASC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ==========================================
-- 5. Automatically Managed Triggers
-- ==========================================

-- Trigger to sync user roles to volunteer table
CREATE OR REPLACE FUNCTION public.sync_volunteer_profile()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'Volunteer' THEN
    INSERT INTO public.volunteers (id, is_verified, is_available)
    VALUES (NEW.id, 'Pending', 'Offline')
    ON CONFLICT (id) DO NOTHING;
  ELSE
    DELETE FROM public.volunteers WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER tr_sync_volunteer_profile
AFTER INSERT OR UPDATE OF role ON public.users
FOR EACH ROW EXECUTE FUNCTION public.sync_volunteer_profile();

-- ==========================================
-- 6. Dashboards & Activity Feed Queries
-- ==========================================

-- Create view for recent activities feed
CREATE OR REPLACE VIEW public.recent_activities AS
(
  SELECT 
    'user_registered' AS type,
    name || ' registered as a new ' || lower(role) AS message,
    created_at AS timestamp
  FROM public.users
  UNION ALL
  SELECT 
    'volunteer_verified' AS type,
    u.name || ' is now a ' || lower(v.is_verified) || ' volunteer' AS message,
    v.joined_at AS timestamp
  FROM public.volunteers v
  JOIN public.users u ON v.id = u.id
  UNION ALL
  SELECT 
    'sos_triggered' AS type,
    'SOS Alert: ' || victim_name || ' (' || incident_type || ')' AS message,
    created_at AS timestamp
  FROM public.sos_incidents
  UNION ALL
  SELECT 
    'issue_created' AS type,
    'Ticket: ' || title || ' by ' || user_name AS message,
    created_at AS timestamp
  FROM public.issues
)
ORDER BY timestamp DESC
LIMIT 10;

-- RPC function to get main dashboard stats
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
-- 7. Row-Level Security (RLS) Policies
-- ==========================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sos_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins have full CRUD access on users"
  ON public.users
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Admins have full CRUD access on volunteers"
  ON public.volunteers
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Admins have full CRUD access on sos_incidents"
  ON public.sos_incidents
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Admins have full CRUD access on issues"
  ON public.issues
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);
