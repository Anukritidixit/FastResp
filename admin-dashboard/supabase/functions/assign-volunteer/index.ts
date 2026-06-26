import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../shared/cors.ts'

interface VolunteerUser {
  name?: string;
  phone?: string;
}

serve(async (req) => {
  // Handle CORS OPTIONS request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { incident_id, volunteer_id } = await req.json()

    if (!incident_id || !volunteer_id) {
      return new Response(
        JSON.stringify({ error: 'Missing incident_id or volunteer_id' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 1. Update the incident: set assigned volunteer and change status to 'In Progress'
    const { data: incident, error: incidentUpdateError } = await supabaseClient
      .from('sos_incidents')
      .update({
        assigned_volunteer_id: volunteer_id,
        status: 'In Progress'
      })
      .eq('id', incident_id)
      .select('*, victim_name, phone, blood_group, latitude, longitude, emergency_contact')
      .single()

    if (incidentUpdateError) {
      throw incidentUpdateError
    }

    // 2. Update the volunteer availability: set is_available = 'Busy'
    const { data: volunteer, error: volunteerUpdateError } = await supabaseClient
      .from('volunteers')
      .update({
        is_available: 'Busy'
      })
      .eq('id', volunteer_id)
      .select('*, users(name, phone)')
      .single()

    if (volunteerUpdateError) {
      throw volunteerUpdateError
    }

    const volunteerUser = volunteer.users as VolunteerUser
    const volunteerName = volunteerUser?.name || 'Assigned Volunteer'
    const volunteerPhone = volunteerUser?.phone || 'N/A'

    // 3. Mock notification logs (SMS / Alerts)
    
    // Notification to the volunteer
    console.log(
      `📱 SMS to Volunteer [${volunteerName} - ${volunteerPhone}]: "RESCUE DISPATCH: You are assigned to SOS [${incident_id}]. Victim: ${incident.victim_name} (${incident.phone}), Blood Group: ${incident.blood_group}. Location: (${incident.latitude}, ${incident.longitude}). Please respond immediately!"`
    )

    // Notification to the emergency contact (if exists)
    if (incident.emergency_contact) {
      console.log(
        `📱 SMS to Emergency Contact [${incident.emergency_contact}]: "EMERGENCY UPDATE: SOS alert triggered by ${incident.victim_name}. Volunteer ${volunteerName} (${volunteerPhone}) is en route to their location."`
      )
    }

    return new Response(
      JSON.stringify({
        message: `Successfully assigned volunteer ${volunteerName} to SOS incident ${incident_id}.`,
        incident: {
          id: incident_id,
          status: 'In Progress',
          assigned_volunteer_id: volunteer_id,
          assigned_volunteer_name: volunteerName
        },
        volunteer: {
          id: volunteer_id,
          is_available: 'Busy'
        }
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    const errMsg = error instanceof Error ? error.message : String(error)
    return new Response(
      JSON.stringify({ error: errMsg }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
