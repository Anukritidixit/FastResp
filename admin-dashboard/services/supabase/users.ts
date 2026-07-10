import { supabase } from '../../lib/supabase/client';
import { DbUser } from '../../types/database';
import { UserData } from '../../types/user';

const mapDbUser = (user: DbUser): UserData => ({
  id: user.id,
  name: user.name,
  email: user.email,
  phone: user.phone,
  bloodGroup: user.blood_group,
  role: user.role,
  status: user.status,
  createdAt: user.created_at ? new Date(user.created_at).toISOString().split('T')[0] : '',
  age: user.age ? Number(user.age) : undefined,
  gender: user.gender || '',
  address: user.address || '',
  allergies: user.allergies || '',
  medicalConditions: user.medical_conditions || '',
  specialNotes: user.special_notes || '',
  profilePicture: user.profile_picture || '',
});


export async function getUsers(): Promise<UserData[]> {
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .order('created_at', { ascending: false });
  
  if (error) {
    console.error('Error fetching users:', error);
    throw error;
  }
  
  return (data || []).map((row) => mapDbUser(row as DbUser));
}

export async function toggleUserStatus(userId: string, currentStatus: string): Promise<UserData> {
  const newStatus = currentStatus === 'Active' ? 'Suspended' : 'Active';
  const { data, error } = await supabase
    .from('users')
    .update({ status: newStatus })
    .eq('id', userId)
    .select()
    .single();
  
  if (error) {
    console.error('Error toggling user status:', error);
    throw error;
  }
  
  return mapDbUser(data as DbUser);
}

export async function updateUser(userId: string, userData: Partial<UserData>): Promise<UserData> {
  const dbPayload: Partial<DbUser> = {
    name: userData.name,
    email: userData.email,
    phone: userData.phone,
    role: userData.role,
  };
  
  if (userData.bloodGroup !== undefined) {
    dbPayload.blood_group = userData.bloodGroup;
  }
  
  const { data, error } = await supabase
    .from('users')
    .update(dbPayload)
    .eq('id', userId)
    .select()
    .single();
  
  if (error) {
    console.error('Error updating user:', error);
    throw error;
  }
  
  return mapDbUser(data as DbUser);
}

export async function deleteUser(userId: string): Promise<boolean> {
  const { error } = await supabase
    .from('users')
    .delete()
    .eq('id', userId);
  
  if (error) {
    console.error('Error deleting user:', error);
    throw error;
  }
  
  return true;
}
export type { UserData };
