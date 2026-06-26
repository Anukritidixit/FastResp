"use client";

import { useEffect, useState } from "react";
import {
  TrendingUp,
  Clock,
  CheckCircle2,
  Users2,
  Calendar,
} from "lucide-react";
import {
  ResponsiveContainer,
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ComposedChart,
  RadarChart,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  Radar,
} from "recharts";

// Mock Growth Data
const growthData = [
  { month: "Jan", Users: 400, Volunteers: 120 },
  { month: "Feb", Users: 600, Volunteers: 160 },
  { month: "Mar", Users: 750, Volunteers: 210 },
  { month: "Apr", Users: 900, Volunteers: 250 },
  { month: "May", Users: 1100, Volunteers: 290 },
  { month: "Jun", Users: 1250, Volunteers: 325 },
];

// Mock SOS Success vs Volume
const sosVolumeData = [
  { month: "Jan", TotalCases: 35, Resolved: 32 },
  { month: "Feb", TotalCases: 42, Resolved: 39 },
  { month: "Mar", TotalCases: 58, Resolved: 53 },
  { month: "Apr", TotalCases: 63, Resolved: 58 },
  { month: "May", TotalCases: 74, Resolved: 68 },
  { month: "Jun", TotalCases: 92, Resolved: 85 },
];

// Mock Response Time Trends (in minutes)
const responseTimeData = [
  { name: "Week 1", AvgTime: 6.2 },
  { name: "Week 2", AvgTime: 5.8 },
  { name: "Week 3", AvgTime: 5.1 },
  { name: "Week 4", AvgTime: 4.5 },
  { name: "Week 5", AvgTime: 4.2 },
];

// Mock Incident Category distribution
const incidentCategoryData = [
  { category: "Cardiac Emergency", count: 45, fullMark: 50 },
  { category: "Accident / Injury", count: 32, fullMark: 50 },
  { category: "Severe Asthma", count: 28, fullMark: 50 },
  { category: "Fainting", count: 15, fullMark: 50 },
  { category: "Fire / Burns", count: 8, fullMark: 50 },
];

export default function AnalyticsPage() {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    requestAnimationFrame(() => {
      setMounted(true);
    });
  }, []);

  if (!mounted) {
    return (
      <div className="space-y-6 animate-pulse">
        <div className="h-20 bg-white/5 rounded-3xl" />
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-28 bg-white/5 rounded-3xl" />
          ))}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="h-80 bg-white/5 rounded-3xl" />
          <div className="h-80 bg-white/5 rounded-3xl" />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-8">

      {/* Analytics KPI grid */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-white/15 transition-all">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-zinc-400 font-semibold uppercase">Avg Response Time</p>
              <h3 className="mt-2 text-3xl font-extrabold text-white">4.2 min</h3>
              <p className="mt-1.5 text-xs text-emerald-400 flex items-center gap-1 font-medium">
                <TrendingUp className="h-3 w-3" />
                <span>-2.1m from last month</span>
              </p>
            </div>
            <div className="rounded-2xl bg-indigo-500/20 p-3.5 text-indigo-400">
              <Clock className="h-5 w-5" />
            </div>
          </div>
        </div>

        <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-white/15 transition-all">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-zinc-400 font-semibold uppercase">SOS Success Rate</p>
              <h3 className="mt-2 text-3xl font-extrabold text-white">92.4%</h3>
              <p className="mt-1.5 text-xs text-emerald-400 flex items-center gap-1 font-medium">
                <TrendingUp className="h-3 w-3" />
                <span>+0.8% increase</span>
              </p>
            </div>
            <div className="rounded-2xl bg-emerald-500/20 p-3.5 text-emerald-400">
              <CheckCircle2 className="h-5 w-5" />
            </div>
          </div>
        </div>

        <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-white/15 transition-all">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-zinc-400 font-semibold uppercase">Active Responders</p>
              <h3 className="mt-2 text-3xl font-extrabold text-white">68.5%</h3>
              <p className="mt-1.5 text-xs text-zinc-500 font-medium">
                222 out of 325 available
              </p>
            </div>
            <div className="rounded-2xl bg-purple-500/20 p-3.5 text-purple-400">
              <Users2 className="h-5 w-5" />
            </div>
          </div>
        </div>

        <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-white/15 transition-all">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-zinc-400 font-semibold uppercase">Cases This Month</p>
              <h3 className="mt-2 text-3xl font-extrabold text-white">92 cases</h3>
              <p className="mt-1.5 text-xs text-indigo-400 flex items-center gap-1 font-medium">
                <TrendingUp className="h-3 w-3" />
                <span>+24% vs. May</span>
              </p>
            </div>
            <div className="rounded-2xl bg-amber-500/20 p-3.5 text-amber-400">
              <Calendar className="h-5 w-5" />
            </div>
          </div>
        </div>
      </div>

      {/* Detailed Charts Grid 1 */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Chart A: Registration trajectories */}
        <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-white/15 transition-all flex flex-col h-[400px]">
          <div className="mb-4">
            <h3 className="text-lg font-semibold text-white">User vs. Volunteer Sign-ups</h3>
            <p className="text-xs text-zinc-400">Growth trajectory comparison</p>
          </div>
          <div className="flex-1 w-full min-h-0">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={growthData} margin={{ top: 5, right: 10, left: -20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                <XAxis dataKey="month" stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} />
                <Tooltip
                  content={({ active, payload, label }) => {
                    if (active && payload && payload.length) {
                      return (
                        <div className="rounded-2xl border border-white/10 bg-zinc-950/80 p-3 shadow-2xl backdrop-blur-md">
                          <p className="text-xs font-semibold text-zinc-500 mb-1.5">{label}</p>
                          <div className="flex flex-col gap-1">
                            <div className="text-sm font-bold text-indigo-400">Users: {payload[0].value}</div>
                            <div className="text-sm font-bold text-purple-400">Volunteers: {payload[1].value}</div>
                          </div>
                        </div>
                      );
                    }
                    return null;
                  }}
                />
                <Legend />
                <Line type="monotone" dataKey="Users" stroke="#6366f1" strokeWidth={3} dot={{ r: 4 }} activeDot={{ r: 6 }} />
                <Line type="monotone" dataKey="Volunteers" stroke="#a855f7" strokeWidth={3} dot={{ r: 4 }} activeDot={{ r: 6 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Chart B: SOS case Success rates vs total cases */}
        <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-white/15 transition-all flex flex-col h-[400px]">
          <div className="mb-4">
            <h3 className="text-lg font-semibold text-white">SOS Volume & Resolution</h3>
            <p className="text-xs text-zinc-400">Total cases vs. successfully resolved incidents</p>
          </div>
          <div className="flex-1 w-full min-h-0">
            <ResponsiveContainer width="100%" height="100%">
              <ComposedChart data={sosVolumeData} margin={{ top: 5, right: 10, left: -20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                <XAxis dataKey="month" stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} />
                <Tooltip
                  content={({ active, payload, label }) => {
                    if (active && payload && payload.length) {
                      return (
                        <div className="rounded-2xl border border-white/10 bg-zinc-950/80 p-3 shadow-2xl backdrop-blur-md">
                          <p className="text-xs font-semibold text-zinc-500 mb-1.5">{label}</p>
                          <div className="flex flex-col gap-1">
                            <div className="text-sm font-bold text-white">Total Cases: {payload[0].value}</div>
                            <div className="text-sm font-bold text-emerald-400">Resolved: {payload[1].value}</div>
                          </div>
                        </div>
                      );
                    }
                    return null;
                  }}
                />
                <Legend />
                <Bar dataKey="TotalCases" name="Total SOS Cases" fill="#6366f1" opacity={0.4} radius={[4, 4, 0, 0]} maxBarSize={40} />
                <Line type="monotone" name="Resolved Cases" dataKey="Resolved" stroke="#10b981" strokeWidth={3} dot={{ r: 4 }} />
              </ComposedChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Detailed Charts Grid 2 */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Chart C: Average response time trend */}
        <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-white/15 transition-all flex flex-col h-[400px]">
          <div className="mb-4">
            <h3 className="text-lg font-semibold text-white">Dispatch Response Times</h3>
            <p className="text-xs text-zinc-400">Average response times in minutes (last 5 weeks)</p>
          </div>
          <div className="flex-1 w-full min-h-0">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={responseTimeData} margin={{ top: 5, right: 10, left: -20, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                <XAxis dataKey="name" stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis stroke="#71717a" fontSize={12} tickLine={false} axisLine={false} />
                <Tooltip
                  content={({ active, payload, label }) => {
                    if (active && payload && payload.length) {
                      return (
                        <div className="rounded-2xl border border-white/10 bg-zinc-950/80 p-3 shadow-2xl backdrop-blur-md">
                          <p className="text-xs font-semibold text-zinc-500 mb-1">{label}</p>
                          <div className="text-sm font-bold text-rose-400">
                            Avg Response: {payload[0].value} mins
                          </div>
                        </div>
                      );
                    }
                    return null;
                  }}
                />
                <Bar dataKey="AvgTime" name="Response Time" fill="#f43f5e" radius={[6, 6, 0, 0]} maxBarSize={45} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Chart D: Radar Chart for Incident Categories */}
        <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-white/15 transition-all flex flex-col h-[400px]">
          <div className="mb-4">
            <h3 className="text-lg font-semibold text-white">Incident Types Breakdown</h3>
            <p className="text-xs text-zinc-400">Distribution frequency across emergency categories</p>
          </div>
          <div className="flex-1 w-full min-h-0 flex items-center justify-center">
            <ResponsiveContainer width="100%" height="100%">
              <RadarChart cx="50%" cy="50%" outerRadius="70%" data={incidentCategoryData}>
                <PolarGrid stroke="rgba(255,255,255,0.08)" />
                <PolarAngleAxis dataKey="category" stroke="#a1a1aa" fontSize={11} />
                <PolarRadiusAxis angle={30} domain={[0, 50]} stroke="#71717a" fontSize={10} />
                <Radar name="Emergency Type" dataKey="count" stroke="#a855f7" fill="#a855f7" fillOpacity={0.25} />
              </RadarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
}
