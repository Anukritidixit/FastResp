export interface DbUser {
  id: string;
  name: string;
  email: string;
  phone?: string;
  blood_group?: string;
  role: 'User' | 'Volunteer' | 'Admin';
  status: 'Active' | 'Suspended';
  created_at: string;
  age?: number;
  gender?: string;
  address?: string;
  allergies?: string;
  medical_conditions?: string;
  special_notes?: string;
  profile_picture?: string;
}

export interface DbVolunteer {
  id: string;
  is_verified: 'Verified' | 'Pending' | 'Suspended';
  is_available: 'Available' | 'Busy' | 'Offline';
  rating: number;
  total_cases: number;
  latitude?: number;
  longitude?: number;
  joined_at: string;
  category: 'community' | 'ambulance' | 'hospital';
  government_id?: string;
  government_id_image?: string;
  profile_photo?: string;
  qualification?: string;
  skills?: string;
  successful_cases: number;
  response_time?: string;
}

export interface DbSosIncident {
  id: string;
  victim_id?: string;
  victim_name: string;
  phone: string;
  blood_group?: string;
  latitude: number;
  longitude: number;
  status: 'Pending' | 'In Progress' | 'Accepted' | 'Resolved' | 'Cancelled';
  created_at: string;
  resolved_at?: string | null;
  assigned_volunteer_id?: string | null;
  incident_type: string;
  severity: 'Critical' | 'High' | 'Medium' | 'Low';
  emergency_contact?: string;
  detection_type: 'manual' | 'impact' | 'fall' | 'speed_drop';
}

export interface DbIssue {
  id: string;
  user_id?: string;
  user_name: string;
  title: string;
  description?: string;
  priority: 'High' | 'Medium' | 'Low';
  status: 'Open' | 'In Progress' | 'Resolved' | 'Closed';
  created_at: string;
}

export interface DbEmergencyContact {
  id: string;
  user_id: string;
  name: string;
  phone: string;
  relation: string;
  created_at: string;
}
