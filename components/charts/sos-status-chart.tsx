"use client";

import { useEffect, useState } from "react";
import {
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Tooltip,
  Legend,
} from "recharts";

const data = [
  { name: "Pending", value: 5, color: "#f59e0b" },
  { name: "Accepted", value: 8, color: "#3b82f6" },
  { name: "In Progress", value: 12, color: "#06b6d4" },
  { name: "Resolved", value: 70, color: "#10b981" },
  { name: "Cancelled", value: 10, color: "#f43f5e" },
];

export default function SosStatusChart() {
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

  const totalCases = data.reduce((sum, item) => sum + item.value, 0);

  return (
    <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-white/15 transition-all flex flex-col h-[400px]">
      <div className="mb-2">
        <h3 className="text-lg font-semibold text-white">SOS Case Status</h3>
        <p className="text-xs text-zinc-400">Distribution of all active and historical cases</p>
      </div>

      <div className="flex-1 w-full min-h-0 relative flex items-center justify-center">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie
              data={data}
              cx="50%"
              cy="50%"
              innerRadius={70}
              outerRadius={95}
              paddingAngle={4}
              dataKey="value"
            >
              {data.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={entry.color} stroke="transparent" />
              ))}
            </Pie>
            <Tooltip
              content={({ active, payload }) => {
                if (active && payload && payload.length) {
                  const item = payload[0].payload;
                  return (
                    <div className="rounded-2xl border border-white/10 bg-zinc-950/80 p-3 shadow-2xl backdrop-blur-md">
                      <div className="flex items-center gap-2 text-xs font-semibold text-white">
                        <span
                          className="h-2.5 w-2.5 rounded-full"
                          style={{ backgroundColor: item.color }}
                        />
                        <span>{item.name}:</span>
                        <span className="font-bold">{item.value} ({((item.value / totalCases) * 100).toFixed(1)}%)</span>
                      </div>
                    </div>
                  );
                }
                return null;
              }}
            />
            <Legend
              verticalAlign="bottom"
              height={36}
              content={({ payload }) => (
                <div className="flex flex-wrap justify-center gap-x-4 gap-y-2 mt-4">
                  {payload?.map((_, index) => {
                    const item = data[index];
                    if (!item) return null;
                    return (
                      <div key={`legend-${index}`} className="flex items-center gap-1.5 text-xs text-zinc-400 font-medium">
                        <span
                          className="h-2 w-2 rounded-full"
                          style={{ backgroundColor: item.color }}
                        />
                        <span>{item.name}</span>
                        <span className="text-zinc-500 font-bold">({item.value})</span>
                      </div>
                    );
                  })}
                </div>
              )}
            />
          </PieChart>
        </ResponsiveContainer>

        {/* Center Text displaying Total SOS Cases */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-[calc(50%+18px)] text-center pointer-events-none">
          <p className="text-3xl font-extrabold text-white tracking-tight">{totalCases}</p>
          <p className="text-[10px] uppercase font-bold text-zinc-500 tracking-widest mt-0.5">Total Cases</p>
        </div>
      </div>
    </div>
  );
}
