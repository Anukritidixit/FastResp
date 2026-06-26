-- ==========================================
-- Priority Volunteer Assignment Engine & RLS
-- ==========================================

-- 1. Re-define the find_closest_volunteers function to match exact assignment priority
DROP FUNCTION IF EXISTS public.find_closest_volunteers(numeric, numeric, numeric, integer) CASCADE;
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
  rating NUMERIC,
  is_verified TEXT,
  response_time INTERVAL
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
    v.rating,
    v.is_verified,
    v.response_time
  FROM public.volunteers v
  JOIN public.users u ON v.id = u.id
  WHERE v.latitude IS NOT NULL
    AND v.longitude IS NOT NULL
    AND public.calculate_distance(p_latitude, p_longitude, v.latitude, v.longitude) <= p_max_distance_meters
  ORDER BY
    -- Priority 1: Nearest volunteer (distance)
    distance_meters ASC,
    -- Priority 2: Verified volunteer ('Verified' first)
    (CASE WHEN v.is_verified = 'Verified' THEN 0 ELSE 1 END) ASC,
    -- Priority 3: Available volunteer ('Available' first)
    (CASE WHEN v.is_available = 'Available' THEN 0 ELSE 1 END) ASC,
    -- Priority 4: Highest rating (5.0 down to 0.0)
    v.rating DESC,
    -- Priority 5: Lowest average response time (interval ascending)
    v.response_time ASC NULLS LAST
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Create the auto_assign_volunteer() trigger function
CREATE OR REPLACE FUNCTION public.auto_assign_volunteer()
RETURNS TRIGGER AS $$
DECLARE
  v_best_vol RECORD;
BEGIN
  -- We only run auto-assignment if the status is initialized as 'Pending'
  IF NEW.status = 'Pending' THEN
    -- Find the single best volunteer matching the criteria who is verified and available
    SELECT * INTO v_best_vol
    FROM public.find_closest_volunteers(NEW.latitude, NEW.longitude, 10000, 1)
    WHERE is_available = 'Available' AND is_verified = 'Verified';

    -- If a candidate is found, bind them immediately to the incident
    IF v_best_vol.volunteer_id IS NOT NULL THEN
      NEW.assigned_volunteer_id := v_best_vol.volunteer_id;
      NEW.status := 'In Progress';
      
      -- Update the volunteer table to set status to 'Busy'
      UPDATE public.volunteers
      SET is_available = 'Busy'
      WHERE id = v_best_vol.volunteer_id;
      
      -- Log/Mock SMS dispatch details (Edge Function mock)
      RAISE NOTICE '📱 SMS to Volunteer [% - %]: RESCUE DISPATCH: You are assigned to SOS [%]. Victim: %, Blood Group: %. Location: (%, %). Please respond immediately!',
        v_best_vol.volunteer_name, v_best_vol.volunteer_phone, NEW.id, NEW.victim_name, NEW.blood_group, NEW.latitude, NEW.longitude;
        
      -- Log/Mock SMS to Emergency Contacts
      IF NEW.emergency_contact IS NOT NULL AND NEW.emergency_contact <> '' THEN
        RAISE NOTICE '📱 SMS to Emergency Contact [%]: EMERGENCY UPDATE: SOS alert triggered by %. Volunteer % (%) is en route to their location.',
          NEW.emergency_contact, NEW.victim_name, v_best_vol.volunteer_name, v_best_vol.volunteer_phone;
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. Bind the trigger to public.sos_incidents table
DROP TRIGGER IF EXISTS tr_auto_assign_volunteer ON public.sos_incidents;
CREATE TRIGGER tr_auto_assign_volunteer
BEFORE INSERT ON public.sos_incidents
FOR EACH ROW EXECUTE FUNCTION public.auto_assign_volunteer();

-- 4. Enable Row Level Security (RLS) policies for assigned volunteers and victims to view exact details
ALTER TABLE public.sos_incidents ENABLE ROW LEVEL SECURITY;

-- Victim read policy (reads their own incidents)
DROP POLICY IF EXISTS "Victims can read their own incidents" ON public.sos_incidents;
CREATE POLICY "Victims can read their own incidents"
  ON public.sos_incidents
  FOR SELECT
  TO anon, authenticated
  USING (victim_id = auth.uid());

-- Assigned volunteer read policy (reads their assigned incidents with exact location)
DROP POLICY IF EXISTS "Assigned volunteers can read their assigned incidents" ON public.sos_incidents;
CREATE POLICY "Assigned volunteers can read their assigned incidents"
  ON public.sos_incidents
  FOR SELECT
  TO anon, authenticated
  USING (assigned_volunteer_id = auth.uid());
