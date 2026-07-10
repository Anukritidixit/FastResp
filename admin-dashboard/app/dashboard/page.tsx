"use client";

import { useState, useEffect } from "react";
import StatCard from "@/components/dashboard/stat-card";
import UserGrowthChart from "@/components/charts/user-growth-chart";
import SosStatusChart from "@/components/charts/sos-status-chart";
import MonthlySosChart from "@/components/charts/monthly-sos-chart";
import VolunteerActivityChart from "@/components/charts/volunteer-activity-chart";

import {
  Users,
  UserCheck,
  Siren,
  CheckCircle,
  Activity,
} from "lucide-react";
import { getDashboardStats, DashboardStats } from "@/services/supabase/dashboard";
import { supabase } from "@/lib/supabase/client";

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats>({
    totalUsers: 0,
    totalVolunteers: 0,
    activeSos: 0,
    resolvedCases: 0,
    recentActivities: [],
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchStats = async () => {
    try {
      const data = await getDashboardStats();
      setStats(data);
      setError(null);
    } catch (err) {
      console.error(err);
      const errMsg = err instanceof Error ? err.message : "Failed to load dashboard metrics.";
      setError(errMsg);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    Promise.resolve().then(() => {
      fetchStats();
    });

    // Subscribe to all changes in the public schema to keep metrics in sync in real time
    const channel = supabase
      .channel("dashboard_realtime_sync")
      .on(
        "postgres_changes",
        { event: "*", schema: "public" },
        () => {
          fetchStats();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  return (
    <div className="space-y-8 pb-8 animate-fade-in">

      {/* KPI Cards */}
      <div className="grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-4">
        <StatCard
          title="Total Users"
          value={loading ? "..." : stats.totalUsers.toLocaleString()}
          change="+12% this month"
          icon={Users}
        />
        <StatCard
          title="Total Volunteers"
          value={loading ? "..." : stats.totalVolunteers.toLocaleString()}
          change="+8% this month"
          icon={UserCheck}
        />
        <StatCard
          title="Active SOS Cases"
          value={loading ? "..." : stats.activeSos.toLocaleString()}
          change="Real-time live alert"
          icon={Siren}
        />
        <StatCard
          title="Resolved Cases"
          value={loading ? "..." : stats.resolvedCases.toLocaleString()}
          change="92% Success Rate"
          icon={CheckCircle}
        />
      </div>

      {/* Charts Grid 1: Trends */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <UserGrowthChart />
        <MonthlySosChart />
      </div>

      {/* Charts Grid 2: Breakdown & Standings */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <SosStatusChart />
        <VolunteerActivityChart />
      </div>

      {/* Recent Activity Section */}
      <div className="rounded-3xl border border-white/10 bg-white/5 p-8 backdrop-blur-xl hover:border-white/15 transition-all">
        <div className="flex items-center gap-2.5">
          <Activity className="h-5 w-5 text-indigo-400" />
          <h2 className="text-xl font-semibold text-white">
            Recent Activities (Real Time)
          </h2>
        </div>
        
        {loading ? (
          <p className="mt-4 text-zinc-500 text-sm">Loading activity feed...</p>
        ) : error ? (
          <p className="mt-4 text-rose-400 text-sm">Error: {error}</p>
        ) : stats.recentActivities.length > 0 ? (
          <div className="mt-6 space-y-4">
            {stats.recentActivities.map((act, idx) => (
              <div 
                key={idx} 
                className="flex items-center justify-between border-b border-white/5 pb-3.5 last:border-0 last:pb-0"
              >
                <div className="space-y-1">
                  <p className="text-sm font-semibold text-zinc-200">{act.message}</p>
                  <p className="text-[10px] text-zinc-500">{act.timestamp}</p>
                </div>
                <span className={`text-[10px] font-bold uppercase rounded-md px-2 py-0.5 ${
                  act.type === 'sos_triggered' ? 'bg-rose-500/20 text-rose-400' :
                  act.type === 'volunteer_verified' ? 'bg-indigo-500/20 text-indigo-400' :
                  act.type === 'user_registered' ? 'bg-blue-500/20 text-blue-400' : 'bg-zinc-800 text-zinc-400'
                }`}>
                  {act.type.replace('_', ' ')}
                </span>
              </div>
            ))}
          </div>
        ) : (
          <p className="mt-4 text-zinc-400 text-sm">
            No recent activities recorded. Live events will appear here in real time as they occur in the database.
          </p>
        )}
      </div>

    </div>
  );
}