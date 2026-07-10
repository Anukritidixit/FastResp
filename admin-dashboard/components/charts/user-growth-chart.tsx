"use client";

import { useEffect, useState } from "react";
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from "recharts";

const chartData = [
  { name: "Jan", Users: 400, Volunteers: 120 },
  { name: "Feb", Users: 600, Volunteers: 160 },
  { name: "Mar", Users: 750, Volunteers: 210 },
  { name: "Apr", Users: 900, Volunteers: 250 },
  { name: "May", Users: 1100, Volunteers: 290 },
  { name: "Jun", Users: 1250, Volunteers: 325 },
];

interface TooltipPayloadEntry {
  name: string;
  value: string | number;
  color: string;
}

export default function UserGrowthChart() {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    requestAnimationFrame(() => {
      setMounted(true);
    });
  }, []);

  if (!mounted) {
    return (
      <div className="h-[300px] w-full rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl animate-pulse flex items-center justify-center">
        <span className="text-zinc-500 text-sm">Loading Chart...</span>
      </div>
    );
  }

  return (
    <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-white/15 transition-all flex flex-col h-[400px]">
      <div className="mb-4">
        <h3 className="text-lg font-semibold text-white">User & Volunteer Growth</h3>
        <p className="text-xs text-zinc-400">Monthly registrations overview</p>
      </div>

      <div className="flex-1 w-full min-h-0">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart
            data={chartData}
            margin={{ top: 10, right: 10, left: -20, bottom: 0 }}
          >
            <defs>
              <linearGradient id="colorUsers" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3} />
                <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
              </linearGradient>
              <linearGradient id="colorVolunteers" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#a855f7" stopOpacity={0.3} />
                <stop offset="95%" stopColor="#a855f7" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
            <XAxis
              dataKey="name"
              stroke="#71717a"
              fontSize={12}
              tickLine={false}
              axisLine={false}
            />
            <YAxis
              stroke="#71717a"
              fontSize={12}
              tickLine={false}
              axisLine={false}
            />
            <Tooltip
              content={({ active, payload, label }) => {
                if (active && payload && payload.length) {
                  return (
                    <div className="rounded-2xl border border-white/10 bg-zinc-950/80 p-4 shadow-2xl backdrop-blur-md">
                      <p className="text-sm font-semibold text-white mb-2">{label}</p>
                      {(payload as unknown as TooltipPayloadEntry[]).map((entry) => (
                        <div key={entry.name} className="flex items-center gap-2 text-xs text-zinc-300 py-0.5">
                          <span
                            className="h-2 w-2 rounded-full"
                            style={{ backgroundColor: entry.color }}
                          />
                          <span className="font-medium text-zinc-400">{entry.name}:</span>
                          <span className="font-bold text-white">{entry.value}</span>
                        </div>
                      ))}
                    </div>
                  );
                }
                return null;
              }}
            />
            <Area
              type="monotone"
              dataKey="Users"
              stroke="#6366f1"
              strokeWidth={2}
              fillOpacity={1}
              fill="url(#colorUsers)"
            />
            <Area
              type="monotone"
              dataKey="Volunteers"
              stroke="#a855f7"
              strokeWidth={2}
              fillOpacity={1}
              fill="url(#colorVolunteers)"
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
