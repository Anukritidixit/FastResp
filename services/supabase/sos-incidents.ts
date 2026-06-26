import { supabase } from '../../lib/supabase/client';
import { DbSosIncident, DbUser } from '../../types/database';
import { SosIncident } from '../../types/sos-incident';

interface JoinedDbIncident extends DbSosIncident {
  assigned_volunteer?: {
    users?: Partial<DbUser> | null;
  } | null;
}

const mapDbIncident = (inc: JoinedDbIncident): SosIncident => {
  const volunteerUser = inc.assigned_volunteer?.users || {};
  
  const formatTime = (isoString: string | null) => {
    if (!isoString) return null;
    const date = new Date(isoString);
    return date.toLocaleTimeString('en-US', { hour12: false });
  };

  return {
    id: inc.id,
    victimName: inc.victim_name,
    phone: inc.phone,
    bloodGroup: inc.blood_group || '',
    latitude: Number(inc.latitude),
    longitude: Number(inc.longitude),
    status: inc.status,
    createdTime: formatTime(inc.created_at) || '',
    resolvedTime: formatTime(inc.resolved_at || null),
    assignedVolunteer: volunteerUser.name || null,
    incidentType: inc.incident_type,
    severity: inc.severity,
    emergencyContact: inc.emergency_contact || '',
    detectionType: inc.detection_type || 'manual',
  };
};

export async function getIncidents(): Promise<SosIncident[]> {
  const { data, error } = await supabase
    .from('sos_incidents')
    .select('*, assigned_volunteer:volunteers(users(name))')
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching incidents:', error);
    throw error;
  }
  
  return (data || []).map((row) => mapDbIncident(row as unknown as JoinedDbIncident));
}

export async function updateIncidentStatus(
  incidentId: string, 
  status: SosIncident['status']
): Promise<boolean> {
  const payload: Partial<DbSosIncident> = { status };
  
  if (status === 'Resolved') {
    payload.resolved_at = new Date().toISOString();
  }
  
  const { error } = await supabase
    .from('sos_incidents')
    .update(payload)
    .eq('id', incidentId);
  
  if (error) {
    console.error('Error updating incident status:', error);
    throw error;
  }
  
  return true;
}

export async function assignVolunteer(incidentId: string, volunteerId: string): Promise<boolean> {
  const { error } = await supabase.functions.invoke('assign-volunteer', {
    body: { incident_id: incidentId, volunteer_id: volunteerId }
  });
  
  if (error) {
    console.error('Error calling assign-volunteer edge function:', error);
    throw error;
  }
  
  return true;
}

export async function createIncident(
  incidentData: Omit<SosIncident, 'id' | 'createdTime' | 'resolvedTime' | 'assignedVolunteer'>
): Promise<string> {
  const dbPayload = {
    victim_name: incidentData.victimName,
    phone: incidentData.phone,
    blood_group: incidentData.bloodGroup,
    latitude: incidentData.latitude,
    longitude: incidentData.longitude,
    incident_type: incidentData.incidentType,
    severity: incidentData.severity,
    emergency_contact: incidentData.emergencyContact,
    status: incidentData.status,
    detection_type: incidentData.detectionType || 'manual',
  };

  const { data, error } = await supabase
    .from('sos_incidents')
    .insert(dbPayload)
    .select('id')
    .single();

  if (error) {
    console.error('Error creating SOS incident:', error);
    throw error;
  }

  return data.id;
}
export type { SosIncident };
