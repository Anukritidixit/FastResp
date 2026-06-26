import { LucideIcon } from "lucide-react";

interface StatCardProps {
  title: string;
  value: string;
  change: string;
  icon: LucideIcon;
}

export default function StatCard({
  title,
  value,
  change,
  icon: Icon,
}: StatCardProps) {
  return (
    <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-indigo-500/30 transition-all">

      <div className="flex items-center justify-between">

        <div>
          <p className="text-zinc-400 text-sm">
            {title}
          </p>

          <h2 className="mt-3 text-4xl font-bold text-white">
            {value}
          </h2>

          <p className="mt-2 text-green-400 text-sm">
            {change}
          </p>
        </div>

        <div className="rounded-2xl bg-indigo-500/20 p-4">
          <Icon className="h-6 w-6 text-indigo-400" />
        </div>

      </div>
    </div>
  );
}
