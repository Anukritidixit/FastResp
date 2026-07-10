-- Remove Auto-Assignment Trigger and Function
-- We are transitioning to a Broadcast and Accept system

DROP TRIGGER IF EXISTS tr_auto_assign_volunteer ON public.sos_incidents;
DROP FUNCTION IF EXISTS public.auto_assign_volunteer();
