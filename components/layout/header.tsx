"use client";

import { usePathname } from "next/navigation";
import { Menu } from "lucide-react";
import { ThemeToggle } from "./theme-toggle";
import { UserMenu } from "./user-menu";

interface HeaderProps {
  onMenuClick: () => void;
}

export function Header({ onMenuClick }: HeaderProps) {
  const pathname = usePathname();

  const getPageTitle = (path: string) => {
    if (path === "/dashboard") return "Admin Dashboard";
    if (path.startsWith("/dashboard/users")) return "Users";
    if (path.startsWith("/dashboard/volunteers")) return "Volunteers";
    if (path.startsWith("/dashboard/sos-incidents")) return "SOS Incidents";
    if (path.startsWith("/dashboard/issues")) return "Issues";
    if (path.startsWith("/dashboard/analytics")) return "Analytics";
    if (path.startsWith("/dashboard/settings")) return "Settings";
    return "Admin Dashboard";
  };

  const title = getPageTitle(pathname);

  return (
    <header className="sticky top-0 z-30 flex h-26 items-center justify-between border-b border-border bg-background/60 px-4 backdrop-blur-xl md:px-6">
      <div className="flex items-center gap-3">
        <button
          onClick={onMenuClick}
          className="rounded-lg p-2 text-zinc-400 transition-colors hover:bg-white/5 hover:text-white lg:hidden"
        >
          <Menu className="h-5 w-5" />
        </button>
        <h2 className="text-xl md:text-4xl font-bold text-foreground tracking-tight">
          {title}
        </h2>
      </div>

      <div className="ml-auto flex items-center gap-2">
        <ThemeToggle />
        <UserMenu />
      </div>
    </header>
  );
}