import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../shared/cors.ts'

interface VolunteerRpcResult {
  volunteer_id: string;
  volunteer_name: string;
  volunteer_phone: string;
  distance_meters: number;
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

    // Handle payload from either Webhook (insert) or direct API call
    const payload = await req.json()
    const incident = payload.record || payload // payload.record for webhook, direct object for API

    const { id, latitude, longitude, incident_type, severity } = incident

    if (!id || !latitude || !longitude) {
      return new Response(
        JSON.stringify({ error: 'Missing incident ID, latitude, or longitude' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Call find_closest_volunteers RPC function
    const { data: volunteers, error: rpcError } = await supabaseClient.rpc(
      'find_closest_volunteers',
      {
        p_latitude: latitude,
        p_longitude: longitude,
        p_max_distance_meters: 10000, // 10 km
        p_limit: 5
      }
    )

    if (rpcError) {
      throw rpcError
    }

    // Mock sending notifications (Simulated SMS Broadcast)
    const notifications = (volunteers || []).map((volunteer: VolunteerRpcResult) => {
      console.log(
        `📱 SMS BROADCAST: Emergency SOS [${id}] (Type: ${incident_type}) broadcasted to volunteer ${volunteer.volunteer_name} (${volunteer.volunteer_phone}) at distance ${Math.round(volunteer.distance_meters)}m.`
      )
      return {
        volunteer_id: volunteer.volunteer_id,
        name: volunteer.volunteer_name,
        phone: volunteer.volunteer_phone,
        distance_meters: volunteer.distance_meters,
        status: 'Sent'
      }
    })

    return new Response(
      JSON.stringify({
        message: `Successfully processed SOS alert [${id}]. Notified ${notifications.length} available volunteers.`,
        incident_id: id,
        notified_volunteers: notifications
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
