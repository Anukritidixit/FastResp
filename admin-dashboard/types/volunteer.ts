export interface VolunteerData {
  id: string;
  name: string;
  phone: string;
  email: string;
  isVerified: 'Verified' | 'Pending' | 'Suspended';
  isAvailable: 'Available' | 'Busy' | 'Offline';
  rating: number;
  totalCases: number;
  bloodGroup: string;
  joinedAt: string;
  latitude?: number;
  longitude?: number;
  category?: 'community' | 'ambulance' | 'hospital';
  governmentId?: string;
  governmentIdImage?: string;
  profilePhoto?: string;
  qualification?: string;
  skills?: string;
  successfulCases?: number;
  responseTime?: string;
}
