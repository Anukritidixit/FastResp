import { supabase } from '../../lib/supabase/client';

export interface DashboardStats {
  totalUsers: number;
  totalVolunteers: number;
  activeSos: number;
  resolvedCases: number;
  recentActivities: Array<{
    type: string;
    message: string;
    timestamp: string;
  }>;
}

interface RpcRecentActivity {
  type: string;
  message: string;
  timestamp: string;
}

interface RpcDashboardStats {
  total_users?: number;
  total_volunteers?: number;
  active_sos?: number;
  resolved_cases?: number;
  recent_activities?: RpcRecentActivity[];
}

export async function getDashboardStats(): Promise<DashboardStats> {
  const { data, error } = await supabase.rpc('get_dashboard_stats');
  
  if (error) {
    console.error('Error calling get_dashboard_stats RPC:', error);
    throw error;
  }
  
  const stats = data as RpcDashboardStats;
  
  return {
    totalUsers: stats.total_users || 0,
    totalVolunteers: stats.total_volunteers || 0,
    activeSos: stats.active_sos || 0,
    resolvedCases: stats.resolved_cases || 0,
    recentActivities: (stats.recent_activities || []).map((activity) => ({
      type: activity.type,
      message: activity.message,
      timestamp: activity.timestamp ? new Date(activity.timestamp).toLocaleString() : '',
    })),
  };
}
