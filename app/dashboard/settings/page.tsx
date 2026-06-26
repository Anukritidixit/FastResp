"use client";

import { useState } from "react";
import {
  User,
  Database,
  Bell,
  Lock,
  Check,
  Save,
  Volume2,
  RefreshCw,
} from "lucide-react";

export default function SettingsPage() {
  // Local profile state
  const [profile, setProfile] = useState({
    name: "Admin Coordinator",
    email: "admin@resqlink.com",
    role: "Super Admin",
  });

  // Local Supabase connection config
  const [supabaseConfig, setSupabaseConfig] = useState({
    url: "https://your-project-id.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6...",
  });

  // Local preferences toggles
  const [prefs, setPrefs] = useState({
    soundAlerts: true,
    autoRefresh: true,
    refreshInterval: 10, // seconds
    highSeverityAlertsOnly: false,
  });

  const [saveStatus, setSaveStatus] = useState<string | null>(null);

  const triggerSaveNotification = (sectionName: string) => {
    setSaveStatus(`${sectionName} saved successfully!`);
    setTimeout(() => {
      setSaveStatus(null);
    }, 3000);
  };

  const handleProfileSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    triggerSaveNotification("Profile settings");
  };

  const handleSupabaseSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    triggerSaveNotification("Supabase credentials");
  };

  const handlePrefsSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    triggerSaveNotification("System preferences");
  };

  return (
    <div className="space-y-6 max-w-4xl pb-8">

      {/* Floating Alert */}
      {saveStatus && (
        <div className="fixed bottom-6 right-6 z-50 rounded-2xl border border-emerald-500/20 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-400 backdrop-blur-xl shadow-2xl flex items-center gap-2 animate-bounce">
          <Check className="h-4 w-4" />
          <span className="font-semibold">{saveStatus}</span>
        </div>
      )}

      {/* 1. Profile Settings Card */}
      <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-white/15 transition-all">
        <div className="flex items-center gap-3 mb-6">
          <div className="rounded-2xl bg-indigo-500/20 p-2.5 text-indigo-400">
            <User className="h-5 w-5" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-white">Administrator Profile</h3>
            <p className="text-xs text-zinc-400">Update personal credentials and coordinator role</p>
          </div>
        </div>

        <form onSubmit={handleProfileSubmit} className="space-y-4">
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label className="block text-xs font-semibold text-zinc-400 uppercase mb-1">Full Name</label>
              <input
                type="text"
                required
                value={profile.name}
                onChange={(e) => setProfile({ ...profile, name: e.target.value })}
                className="w-full rounded-xl border border-white/10 bg-zinc-900 px-3.5 py-2.5 text-sm text-white focus:border-indigo-500/50 outline-none transition-all"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-zinc-400 uppercase mb-1">Email Address</label>
              <input
                type="email"
                required
                value={profile.email}
                onChange={(e) => setProfile({ ...profile, email: e.target.value })}
                className="w-full rounded-xl border border-white/10 bg-zinc-900 px-3.5 py-2.5 text-sm text-white focus:border-indigo-500/50 outline-none transition-all"
              />
            </div>
          </div>
          <div>
            <label className="block text-xs font-semibold text-zinc-400 uppercase mb-1">Access Role</label>
            <input
              type="text"
              disabled
              value={profile.role}
              className="w-full max-w-xs rounded-xl border border-white/10 bg-zinc-900/40 px-3.5 py-2.5 text-sm text-zinc-500 outline-none cursor-not-allowed font-semibold"
            />
          </div>

          <div className="pt-2 flex justify-end">
            <button
              type="submit"
              className="flex items-center gap-2 rounded-2xl bg-indigo-500 hover:bg-indigo-600 px-4 py-2.5 text-xs font-bold text-white transition-all"
            >
              <Save className="h-4 w-4" />
              <span>Save Profile</span>
            </button>
          </div>
        </form>
      </div>

      {/* 2. Supabase Integration Setup */}
      <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-white/15 transition-all">
        <div className="flex items-center gap-3 mb-6">
          <div className="rounded-2xl bg-emerald-500/20 p-2.5 text-emerald-400">
            <Database className="h-5 w-5" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-white">Database Credentials</h3>
            <p className="text-xs text-zinc-400">Configure connection strings to hook up the backend data tables</p>
          </div>
        </div>

        <form onSubmit={handleSupabaseSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-zinc-400 uppercase mb-1">Supabase URL</label>
            <input
              type="url"
              required
              placeholder="https://your-project-id.supabase.co"
              value={supabaseConfig.url}
              onChange={(e) => setSupabaseConfig({ ...supabaseConfig, url: e.target.value })}
              className="w-full rounded-xl border border-white/10 bg-zinc-900 px-3.5 py-2.5 text-sm text-white focus:border-indigo-500/50 outline-none transition-all font-mono"
            />
          </div>
          <div>
            <label className="block text-xs font-semibold text-zinc-400 uppercase mb-1">Supabase Anon Key</label>
            <textarea
              required
              rows={3}
              placeholder="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
              value={supabaseConfig.anonKey}
              onChange={(e) => setSupabaseConfig({ ...supabaseConfig, anonKey: e.target.value })}
              className="w-full rounded-xl border border-white/10 bg-zinc-900 px-3.5 py-2.5 text-sm text-white focus:border-indigo-500/50 outline-none transition-all font-mono resize-none"
            />
          </div>

          <div className="pt-2 flex justify-end">
            <button
              type="submit"
              className="flex items-center gap-2 rounded-2xl bg-emerald-500 hover:bg-emerald-600 px-4 py-2.5 text-xs font-bold text-white transition-all shadow-lg shadow-emerald-500/10"
            >
              <Save className="h-4 w-4" />
              <span>Connect Supabase</span>
            </button>
          </div>
        </form>
      </div>

      {/* 3. System preferences & Alert Toggles */}
      <div className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-xl hover:border-white/15 transition-all">
        <div className="flex items-center gap-3 mb-6">
          <div className="rounded-2xl bg-amber-500/20 p-2.5 text-amber-400">
            <Bell className="h-5 w-5" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-white">System Alerts & Automation</h3>
            <p className="text-xs text-zinc-400">Manage real-time dispatch alerts and auto-refresh cycles</p>
          </div>
        </div>

        <form onSubmit={handlePrefsSubmit} className="space-y-6">
          <div className="space-y-4">
            {/* Audio Alert Toggles */}
            <div className="flex items-center justify-between rounded-2xl border border-white/5 bg-zinc-950/25 p-4">
              <div className="flex items-start gap-3">
                <Volume2 className="h-4 w-4 text-zinc-400 mt-0.5" />
                <div>
                  <h4 className="text-sm font-semibold text-white">Audio Siren Tones</h4>
                  <p className="text-xs text-zinc-500">Play alarm siren tones when a new SOS case is requested</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={prefs.soundAlerts}
                onChange={(e) => setPrefs({ ...prefs, soundAlerts: e.target.checked })}
                className="h-4 w-4 accent-indigo-500 cursor-pointer"
              />
            </div>

            {/* Auto refresh toggles */}
            <div className="flex items-center justify-between rounded-2xl border border-white/5 bg-zinc-950/25 p-4">
              <div className="flex items-start gap-3">
                <RefreshCw className="h-4 w-4 text-zinc-400 mt-0.5" />
                <div>
                  <h4 className="text-sm font-semibold text-white">Auto-Refresh Feed</h4>
                  <p className="text-xs text-zinc-500">Automatically pull latest incidents and issue tickets</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={prefs.autoRefresh}
                onChange={(e) => setPrefs({ ...prefs, autoRefresh: e.target.checked })}
                className="h-4 w-4 accent-indigo-500 cursor-pointer"
              />
            </div>

            {/* Interval Configuration */}
            {prefs.autoRefresh && (
              <div className="pl-7 grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-zinc-400 uppercase mb-1">Refresh Cycle (seconds)</label>
                  <input
                    type="number"
                    min={5}
                    max={60}
                    value={prefs.refreshInterval}
                    onChange={(e) => setPrefs({ ...prefs, refreshInterval: parseInt(e.target.value) || 10 })}
                    className="w-full max-w-[150px] rounded-xl border border-white/10 bg-zinc-900 px-3.5 py-2 text-sm text-white focus:border-indigo-500/50 outline-none transition-all"
                  />
                </div>
              </div>
            )}

            {/* Filter Alarm */}
            <div className="flex items-center justify-between rounded-2xl border border-white/5 bg-zinc-950/25 p-4">
              <div className="flex items-start gap-3">
                <Lock className="h-4 w-4 text-zinc-400 mt-0.5" />
                <div>
                  <h4 className="text-sm font-semibold text-white">Critical Incidents Only</h4>
                  <p className="text-xs text-zinc-500">Only sound sirens for cases classified as &apos;Critical&apos; or &apos;High&apos; severity</p>
                </div>
              </div>
              <input
                type="checkbox"
                checked={prefs.highSeverityAlertsOnly}
                onChange={(e) => setPrefs({ ...prefs, highSeverityAlertsOnly: e.target.checked })}
                className="h-4 w-4 accent-indigo-500 cursor-pointer"
              />
            </div>
          </div>

          <div className="pt-2 flex justify-end">
            <button
              type="submit"
              className="flex items-center gap-2 rounded-2xl bg-indigo-500 hover:bg-indigo-600 px-4 py-2.5 text-xs font-bold text-white transition-all"
            >
              <Save className="h-4 w-4" />
              <span>Save Preferences</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
