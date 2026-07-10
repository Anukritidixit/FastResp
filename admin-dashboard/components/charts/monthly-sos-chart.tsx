"use client";

import { useEffect, useState } from "react";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from "recharts";

const data = [
  { name: "Jan", Cases: 35 },
  { name: "Feb", Cases: 42 },
  { name: "Mar", Cases: 58 },
  { name: "Apr", Cases: 63 },
  { name: "May", Cases: 74 },
  { name: "Jun", Cases: 92 },
];

export default function MonthlySosChart() {
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
        <h3 className="text-lg font-semibold text-white">Monthly SOS Cases</h3>
        <p className="text-xs text-zinc-400">Total volume of SOS requests per month</p>
      </div>

      <div className="flex-1 w-full min-h-0">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart
            data={data}
            margin={{ top: 10, right: 10, left: -20, bottom: 0 }}
          >
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
                    <div className="rounded-2xl border border-white/10 bg-zinc-950/80 p-3 shadow-2xl backdrop-blur-md">
                      <p className="text-xs font-semibold text-zinc-400 mb-1">{label}</p>
                      <div className="flex items-center gap-2 text-sm font-bold text-white">
                        <span className="h-2 w-2 rounded-full bg-indigo-500" />
                        <span>Cases:</span>
                        <span>{payload[0].value}</span>
                      </div>
                    </div>
                  );
                }
                return null;
              }}
            />
            <Bar
              dataKey="Cases"
              fill="#6366f1"
              radius={[6, 6, 0, 0]}
              maxBarSize={45}
            />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
