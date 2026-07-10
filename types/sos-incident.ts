export interface SosIncident {
  id: string;
  victimName: string;
  phone: string;
  bloodGroup: string;
  latitude: number;
  longitude: number;
  status: 'Pending' | 'In Progress' | 'Accepted' | 'Resolved' | 'Cancelled';
  createdTime: string;
  resolvedTime: string | null;
  assignedVolunteer: string | null;
  incidentType: string;
  severity: 'Critical' | 'High' | 'Medium' | 'Low';
  priority?: string;
  priorityScore?: number;
  emergencyContact: string;
  detectionType?: 'manual' | 'impact' | 'fall' | 'speed_drop';
}
