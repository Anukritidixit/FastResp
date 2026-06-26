"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import {
  LayoutDashboard,
  Users,
  UserCheck,
  Siren,
  AlertTriangle,
  BarChart3,
  Settings,
} from "lucide-react";

const routes = [
  { href: "/dashboard", label: "Overview", icon: LayoutDashboard },
  { href: "/dashboard/users", label: "Users", icon: Users },
  { href: "/dashboard/volunteers", label: "Volunteers", icon: UserCheck },
  { href: "/dashboard/sos-incidents", label: "SOS Incidents", icon: Siren },
  { href: "/dashboard/issues", label: "Issues", icon: AlertTriangle },
  { href: "/dashboard/analytics", label: "Analytics", icon: BarChart3 },
  { href: "/dashboard/settings", label: "Settings", icon: Settings },
];

export function SidebarNav() {
  const pathname = usePathname();

  return (
    <nav className="space-y-1">
      {routes.map((route) => {
        const Icon = route.icon;
        const isActive =
          pathname === route.href ||
          (route.href !== "/dashboard" && pathname.startsWith(route.href));

        return (
          <Link
            key={route.href}
            href={route.href}
            className={cn(
              "flex items-center gap-3 rounded-xl px-3 py-2.5 text-8*1 font-medium transition-all duration-200",
              isActive
                ? "bg-gradient-to-r from-indigo-500/15 to-purple-500/15 text-indigo-600 dark:text-white"
                : "text-zinc-500 dark:text-zinc-400 hover:bg-black/5 dark:hover:bg-white/5 hover:text-zinc-900 dark:hover:text-white"
            )}
          >
            <Icon className={cn("h-5 w-5", isActive ? "text-indigo-600 dark:text-indigo-400" : "text-zinc-400")} />
            {route.label}
          </Link>
        );
      })}
    </nav>
  );
}