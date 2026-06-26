export interface UserData {
  id?: string;
  name: string;
  email: string;
  phone?: string;
  bloodGroup?: string;
  role: 'User' | 'Volunteer' | 'Admin';
  status: 'Active' | 'Suspended';
  createdAt?: string;
  age?: number;
  gender?: string;
  address?: string;
  allergies?: string;
  medicalConditions?: string;
  specialNotes?: string;
  profilePicture?: string;
}
