"use client";

import { useEffect, useState } from "react";
import { Star } from "lucide-react";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  Cell,
} from "recharts";

const data = [
  { name: "Rahul Sharma", Cases: 42, Rating: 4.9, color: "#10b981" },
  { name: "Priya Patel", Cases: 35, Rating: 4.8, color: "#3b82f6" },
  { name: "Amit Kumar", Cases: 29, Rating: 4.7, color: "#8b5cf6" },
  { name: "Sneha Reddy", Cases: 22, Rating: 4.9, color: "#ec4899" },
  { name: "Vikram Singh", Cases: 18, Rating: 4.6, color: "#f59e0b" },
];

export default function VolunteerActivityChart() {
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
      <div className="mb-4 flex items-center justify-between">
        <div>
          <h3 className="text-lg font-semibold text-white">Top Active Volunteers</h3>
          <p className="text-xs text-zinc-400">Ranked by resolved emergency cases</p>
        </div>
      </div>

      <div className="flex-1 w-full min-h-0">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart
            data={data}
            layout="vertical"
            margin={{ top: 5, right: 10, left: 30, bottom: 5 }}
          >
            <XAxis
              type="number"
              stroke="#71717a"
              fontSize={12}
              tickLine={false}
              axisLine={false}
            />
            <YAxis
              dataKey="name"
              type="category"
              stroke="#e4e4e7"
              fontSize={12}
              tickLine={false}
              axisLine={false}
              width={90}
            />
            <Tooltip
              content={({ active, payload }) => {
                if (active && payload && payload.length) {
                  const item = payload[0].payload;
                  return (
                    <div className="rounded-2xl border border-white/10 bg-zinc-950/80 p-3 shadow-2xl backdrop-blur-md">
                      <p className="text-xs font-semibold text-zinc-400 mb-1">{item.name}</p>
                      <div className="flex flex-col gap-1">
                        <div className="flex items-center gap-1.5 text-sm font-bold text-white">
                          <span className="h-2 w-2 rounded-full" style={{ backgroundColor: item.color }} />
                          <span>Cases Resolved: {item.Cases}</span>
                        </div>
                        <div className="flex items-center gap-1 text-xs text-amber-400 font-semibold">
                          <Star className="h-3.5 w-3.5 fill-current" />
                          <span>{item.Rating} Rating</span>
                        </div>
                      </div>
                    </div>
                  );
                }
                return null;
              }}
            />
            <Bar
              dataKey="Cases"
              radius={[0, 6, 6, 0]}
              barSize={20}
            >
              {data.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={entry.color} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
