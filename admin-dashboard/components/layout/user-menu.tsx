"use client";

import { useState, useEffect } from "react";
import { ChevronDown, LogOut, User, Settings, AlertTriangle } from "lucide-react";
import { useRouter } from "next/navigation";

export function UserMenu() {
  const [open, setOpen] = useState(false);
  const [email, setEmail] = useState("admin@resqlink.org");
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
  const router = useRouter();

  useEffect(() => {
    const sessionStr = localStorage.getItem("resqlink_session");
    if (sessionStr) {
      try {
        const user = JSON.parse(sessionStr);
        if (user?.email) {
          requestAnimationFrame(() => {
            setEmail(user.email);
          });
        }
      } catch (e) {
        console.error("Failed to parse user session:", e);
      }
    }
  }, []);

  const handleSignOutClick = () => {
    setOpen(false);
    setShowLogoutConfirm(true);
  };

  const confirmSignOut = () => {
    localStorage.removeItem("resqlink_session");
    setShowLogoutConfirm(false);
    router.push("/login");
  };

  const handleNavigate = (path: string) => {
    setOpen(false);
    router.push(path);
  };

  return (
    <div className="relative">
      <button
        onClick={() => setOpen(!open)}
        className="flex items-center gap-2 rounded-lg px-2 py-1.5 text-sm font-medium text-zinc-600 dark:text-zinc-300 transition-colors hover:bg-black/5 dark:hover:bg-white/5 hover:text-zinc-900 dark:hover:text-white"
      >
        <div className="flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 text-sm font-semibold text-white shadow-lg shadow-indigo-500/20">
          {email.charAt(0).toUpperCase()}
        </div>
        <span className="hidden md:inline">Admin</span>
        <ChevronDown className="h-3.5 w-3.5 text-zinc-500" />
      </button>

      {open && (
        <>
          <div
            className="fixed inset-0 z-40"
            onClick={() => setOpen(false)}
          />
          <div className="absolute right-0 top-full mt-2 w-56 rounded-xl border border-border bg-card p-1.5 shadow-2xl backdrop-blur-xl z-50">
            <div className="px-3 py-2 mb-1 border-b border-border">
              <p className="text-sm font-medium text-foreground">Admin User</p>
              <p className="text-xs text-zinc-500">{email}</p>
            </div>
            <button
              onClick={() => handleNavigate("/dashboard/settings")}
              className="flex w-full items-center gap-2.5 rounded-lg px-3 py-2 text-sm text-zinc-700 dark:text-zinc-300 transition-colors hover:bg-black/5 dark:hover:bg-white/5 hover:text-zinc-900 dark:hover:text-white"
            >
              <User className="h-4 w-4" />
              Profile
            </button>
            <button
              onClick={() => handleNavigate("/dashboard/settings")}
              className="flex w-full items-center gap-2.5 rounded-lg px-3 py-2 text-sm text-zinc-700 dark:text-zinc-300 transition-colors hover:bg-black/5 dark:hover:bg-white/5 hover:text-zinc-900 dark:hover:text-white"
            >
              <Settings className="h-4 w-4" />
              Settings
            </button>
            <div className="my-1 h-px bg-border" />
            <button
              onClick={handleSignOutClick}
              className="flex w-full items-center gap-2.5 rounded-lg px-3 py-2 text-sm font-medium text-red-600 dark:text-red-400 transition-colors hover:bg-black/5 dark:hover:bg-white/5 hover:text-red-700 dark:hover:text-red-300"
            >
              <LogOut className="h-4 w-4" />
              Sign Out
            </button>
          </div>
        </>
      )}

      {/* Confirmation Dialog Modal */}
      {showLogoutConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm animate-fade-in">
          <div className="w-full max-w-sm rounded-3xl border border-white/10 bg-zinc-950 p-6 shadow-2xl backdrop-blur-xl animate-scale-in">
            <div className="flex items-center gap-3 text-red-500 mb-4">
              <AlertTriangle className="h-6 w-6" />
              <h3 className="text-lg font-bold text-white">Confirm Logout</h3>
            </div>
            
            <p className="text-sm text-zinc-400 mb-6">
              Are you sure you want to logout?
            </p>
            
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setShowLogoutConfirm(false)}
                className="rounded-xl border border-white/10 hover:bg-white/5 px-4 py-2 text-xs font-semibold text-zinc-300 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={confirmSignOut}
                className="rounded-xl bg-red-600 hover:bg-red-700 px-4 py-2 text-xs font-semibold text-white transition-colors shadow-lg shadow-red-600/20"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}