import { supabase } from '../../lib/supabase/client';
import { DbVolunteer, DbUser } from '../../types/database';
import { VolunteerData } from '../../types/volunteer';

interface JoinedDbVolunteer extends DbVolunteer {
  users?: Partial<DbUser> | null;
}

const mapDbVolunteer = (vol: JoinedDbVolunteer): VolunteerData => {
  const user = vol.users || {};
  return {
    id: vol.id,
    name: user.name || 'Unknown',
    phone: user.phone || '',
    email: user.email || '',
    isVerified: vol.is_verified,
    isAvailable: vol.is_available,
    rating: vol.rating ? Number(vol.rating) : 0,
    totalCases: vol.total_cases ? Number(vol.total_cases) : 0,
    bloodGroup: user.blood_group || '',
    joinedAt: vol.joined_at ? new Date(vol.joined_at).toISOString().split('T')[0] : '',
    latitude: vol.latitude ? Number(vol.latitude) : undefined,
    longitude: vol.longitude ? Number(vol.longitude) : undefined,
    category: vol.category || 'community',
    governmentId: vol.government_id || '',
    governmentIdImage: vol.government_id_image || '',
    profilePhoto: vol.profile_photo || '',
    qualification: vol.qualification || '',
    skills: vol.skills || '',
    successfulCases: vol.successful_cases ? Number(vol.successful_cases) : 0,
    responseTime: vol.response_time || '',
  };
};

export async function getVolunteers(): Promise<VolunteerData[]> {
  const { data, error } = await supabase
    .from('volunteers')
    .select('*, users(name, phone, email, blood_group)')
    .order('joined_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching volunteers:', error);
    throw error;
  }
  
  return (data || []).map((row) => mapDbVolunteer(row as unknown as JoinedDbVolunteer));
}

export async function updateVolunteerVerification(
  volunteerId: string, 
  status: 'Verified' | 'Pending' | 'Suspended'
): Promise<VolunteerData> {
  const { data, error } = await supabase
    .from('volunteers')
    .update({ is_verified: status })
    .eq('id', volunteerId)
    .select('*, users(name, phone, email, blood_group)')
    .single();
  
  if (error) {
    console.error('Error updating volunteer verification:', error);
    throw error;
  }
  
  return mapDbVolunteer(data as unknown as JoinedDbVolunteer);
}

export async function updateVolunteerAvailability(
  volunteerId: string, 
  availability: 'Available' | 'Busy' | 'Offline'
): Promise<VolunteerData> {
  const { data, error } = await supabase
    .from('volunteers')
    .update({ is_available: availability })
    .eq('id', volunteerId)
    .select('*, users(name, phone, email, blood_group)')
    .single();
  
  if (error) {
    console.error('Error updating volunteer availability:', error);
    throw error;
  }
  
  return mapDbVolunteer(data as unknown as JoinedDbVolunteer);
}

export async function updateVolunteerLocation(
  volunteerId: string, 
  latitude: number, 
  longitude: number
): Promise<boolean> {
  const { error } = await supabase
    .from('volunteers')
    .update({ latitude, longitude })
    .eq('id', volunteerId);
  
  if (error) {
    console.error('Error updating volunteer location:', error);
    throw error;
  }
  
  return true;
}
export type { VolunteerData };
