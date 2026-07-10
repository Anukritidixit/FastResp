"use client";

import { useState, useEffect, useCallback } from "react";
import {
  MapPin,
  User,
  CheckCircle,
  XCircle,
  Navigation,
  Check,
  ChevronDown,
  Phone,
  HeartHandshake,
} from "lucide-react";
import { 
  getIncidents, 
  updateIncidentStatus, 
  assignVolunteer,
  updateIncidentPriority,
  SosIncident 
} from "@/services/supabase/sos-incidents";
import { getVolunteers, VolunteerData } from "@/services/supabase/volunteers";
import { supabase } from "@/lib/supabase/client";

export default function SosIncidentsPage() {
  const [incidents, setIncidents] = useState<SosIncident[]>([]);
  const [volunteers, setVolunteers] = useState<VolunteerData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [activeIncident, setActiveIncident] = useState<SosIncident | null>(null);
  const [showAssignDropdown, setShowAssignDropdown] = useState(false);

  const fetchIncidents = useCallback(async (shouldSetFirstActive = false) => {
    try {
      const data = await getIncidents();
      setIncidents(data);
      if (data.length > 0) {
        if (shouldSetFirstActive || !activeIncident) {
          setActiveIncident(data[0]);
        } else {
          // Keep active incident updated with fresh database values
          const updatedActive = data.find(item => item.id === activeIncident.id);
          if (updatedActive) {
            setActiveIncident(updatedActive);
          }
        }
      }
    } catch (err) {
      console.error(err);
    }
  }, [activeIncident]);

  const fetchVolunteersData = useCallback(async () => {
    try {
      const data = await getVolunteers();
      setVolunteers(data);
    } catch (err) {
      console.error(err);
    }
  }, []);

  const initPage = useCallback(async () => {
    try {
      setLoading(true);
      await Promise.all([fetchIncidents(true), fetchVolunteersData()]);
      setError(null);
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : "Failed to load SOS Incidents.";
      setError(errMsg);
    } finally {
      setLoading(false);
    }
  }, [fetchIncidents, fetchVolunteersData]);

  useEffect(() => {
    Promise.resolve().then(() => {
      initPage();
    });

    // Subscribe to real-time database changes on the public.sos_incidents table
    const channel = supabase
      .channel("live_sos_incidents")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "sos_incidents" },
        () => {
          fetchIncidents();
          fetchVolunteersData();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [initPage, fetchIncidents, fetchVolunteersData]);

  // Filter available volunteers for the assignment dropdown
  const availableResponders = volunteers.filter(
    (v) => v.isAvailable === "Available" && v.isVerified === "Verified"
  );

  // Status Colors
  const getStatusStyle = (status: string) => {
    switch (status) {
      case "Pending":
        return "bg-amber-500/20 text-amber-400 border border-amber-500/30";
      case "Accepted":
        return "bg-blue-500/20 text-blue-400 border border-blue-500/30";
      case "In Progress":
        return "bg-cyan-500/20 text-cyan-400 border border-cyan-500/30";
      case "Resolved":
        return "bg-emerald-500/20 text-emerald-400 border border-emerald-500/30";
      case "Cancelled":
        return "bg-rose-500/20 text-rose-400 border border-rose-500/30";
      default:
        return "bg-zinc-500/20 text-zinc-400";
    }
  };

  // Severity Badge Style
  const getSeverityStyle = (severity: string) => {
    switch (severity) {
      case "Critical":
        return "bg-rose-500/30 text-rose-300 font-extrabold";
      case "High":
        return "bg-amber-500/30 text-amber-300 font-bold";
      default:
        return "bg-zinc-800 text-zinc-300";
    }
  };

  // Actions
  const handleUpdatePriority = async (id: string, priority: string) => {
    try {
      await updateIncidentPriority(id, priority);
      await fetchIncidents();
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : "An error occurred";
      alert("Failed to override priority: " + errMsg);
    }
  };

  const handleAssignVolunteer = async (volId: string) => {
    if (!activeIncident) return;
    try {
      await assignVolunteer(activeIncident.id, volId);
      // Refresh local incident and volunteers list
      await Promise.all([fetchIncidents(), fetchVolunteersData()]);
      setShowAssignDropdown(false);
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : "An error occurred";
      alert("Failed to assign responder: " + errMsg);
    }
  };

  const handleResolveCase = async (id: string) => {
    try {
      await updateIncidentStatus(id, "Resolved");
      await fetchIncidents();
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : "An error occurred";
      alert("Failed to resolve case: " + errMsg);
    }
  };

  const handleCancelCase = async (id: string) => {
    if (confirm("Are you sure you want to cancel this SOS incident?")) {
      try {
        await updateIncidentStatus(id, "Cancelled");
        await fetchIncidents();
      } catch (err) {
        const errMsg = err instanceof Error ? err.message : "An error occurred";
        alert("Failed to cancel case: " + errMsg);
      }
    }
  };

  const handleIncidentSelect = (inc: SosIncident) => {
    setActiveIncident(inc);
    setShowAssignDropdown(false);
  };

  return (
    <div className="space-y-6">

      {/* Main Panel layout: Left Table, Right Map/Details */}
      <div className="grid grid-cols-1 gap-6 xl:grid-cols-12">
        {/* Incidents Table (Left side) */}
        <div className="xl:col-span-7 flex flex-col rounded-3xl border border-white/10 bg-white/5 backdrop-blur-xl overflow-hidden h-[600px]">
          <div className="px-6 py-4 border-b border-white/10 bg-white/2">
            <h2 className="text-lg font-semibold text-white">Live Incidents Feed</h2>
            <p className="text-xs text-zinc-400">Click any row to expand details and view locator map</p>
          </div>

          <div className="flex-1 overflow-y-auto">
            <table className="w-full text-left text-sm text-zinc-300">
              <thead>
                <tr className="border-b border-white/10 bg-white/2 text-xs font-semibold uppercase tracking-wider text-zinc-400 sticky top-0 z-10 backdrop-blur-xl">
                  <th className="px-6 py-3">Case ID</th>
                  <th className="px-6 py-3">Victim</th>
                  <th className="px-6 py-3">Priority</th>
                  <th className="px-6 py-3">Status</th>
                  <th className="px-6 py-3">Assigned Responder</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {loading ? (
                  <tr>
                    <td colSpan={5} className="px-6 py-12 text-center text-zinc-400">
                      <div className="flex items-center justify-center gap-2.5">
                        <span className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
                        <span>Connecting to live emergency feed...</span>
                      </div>
                    </td>
                  </tr>
                ) : error ? (
                  <tr>
                    <td colSpan={5} className="px-6 py-12 text-center text-rose-400 font-medium">
                      Error: {error}
                    </td>
                  </tr>
                ) : incidents.length > 0 ? (
                  incidents.map((inc) => (
                    <tr
                      key={inc.id}
                      onClick={() => handleIncidentSelect(inc)}
                      className={`cursor-pointer transition-colors duration-150 ${
                        activeIncident?.id === inc.id
                          ? "bg-indigo-500/10 hover:bg-indigo-500/15"
                          : "hover:bg-white/2"
                      }`}
                    >
                      <td className="whitespace-nowrap px-6 py-4 font-mono font-bold text-white">
                        {inc.id}
                      </td>
                      <td className="whitespace-nowrap px-6 py-4">
                        <div className="font-semibold text-zinc-100">{inc.victimName}</div>
                        <div className="text-[10px] text-zinc-500 font-mono">Started: {inc.createdTime}</div>
                      </td>
                      <td className="whitespace-nowrap px-6 py-4">
                        <span className={`rounded-lg px-2 py-0.5 text-xs ${getSeverityStyle(inc.priority || inc.severity)}`}>
                          {inc.priority || inc.severity}
                        </span>
                        {inc.priorityScore !== undefined && (
                          <div className="text-[10px] text-zinc-500 mt-1 font-mono">Score: {inc.priorityScore}</div>
                        )}
                      </td>
                      <td className="whitespace-nowrap px-6 py-4">
                        <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold ${getStatusStyle(inc.status)}`}>
                          {inc.status}
                        </span>
                      </td>
                      <td className="whitespace-nowrap px-6 py-4 text-xs font-medium text-zinc-400">
                        {inc.assignedVolunteer ? (
                          <div className="flex items-center gap-1.5">
                            <User className="h-3.5 w-3.5 text-indigo-400" />
                            <span>{inc.assignedVolunteer}</span>
                          </div>
                        ) : (
                          <span className="text-zinc-600 italic">Unassigned</span>
                        )}
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={5} className="px-6 py-12 text-center text-zinc-500 italic">
                      No active emergency alerts recorded.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Live Details & GPS Locator Panel (Right side) */}
        <div className="xl:col-span-5 flex flex-col rounded-3xl border border-white/10 bg-white/5 backdrop-blur-xl overflow-hidden h-[600px]">
          {activeIncident ? (
            <div className="flex flex-col h-full">
              {/* Map Locator Viewport */}
              <div className="h-1/2 bg-slate-100 dark:bg-[#0c0c0e] relative border-b border-border overflow-hidden flex items-center justify-center">
                {/* Radar Grid Scanning Animation Mockup */}
                <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(99,102,241,0.15),transparent_60%)] pointer-events-none" />
                <div className="absolute w-[300px] h-[300px] rounded-full border border-indigo-500/10 animate-ping pointer-events-none" />
                <div className="absolute w-[200px] h-[200px] rounded-full border border-indigo-500/20 animate-pulse pointer-events-none" />

                {/* Radar Line Sweep */}
                <div className="absolute inset-0 bg-gradient-to-r from-transparent via-indigo-500/5 to-transparent skew-x-12 animate-pulse pointer-events-none" />

                {/* Coordinate Markers */}
                <div className="absolute text-center flex flex-col items-center">
                  <div className="rounded-full bg-rose-500/20 p-3 ring-4 ring-rose-500/30 animate-pulse">
                    <MapPin className="h-6 w-6 text-rose-500" />
                  </div>
                  <span className="mt-2 text-[10px] font-bold font-mono tracking-widest text-zinc-500 uppercase">
                    Lat: {activeIncident.latitude.toFixed(4)} | Long: {activeIncident.longitude.toFixed(4)}
                  </span>
                </div>

                <div className="absolute bottom-4 left-4 bg-zinc-950/80 px-3 py-1.5 rounded-xl border border-white/10 backdrop-blur-md flex items-center gap-2">
                  <Navigation className="h-3.5 w-3.5 text-indigo-400" />
                  <span className="text-xs font-semibold text-white">{activeIncident.incidentType}</span>
                </div>
              </div>

              {/* Case Details */}
              <div className="flex-1 p-6 flex flex-col justify-between overflow-y-auto">
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <span className="text-xs font-bold font-mono text-zinc-500">{activeIncident.id}</span>
                      <h3 className="text-xl font-bold text-white">{activeIncident.victimName}</h3>
                    </div>
                    <span className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-bold ${getStatusStyle(activeIncident.status)}`}>
                      {activeIncident.status}
                    </span>
                  </div>

                  <div className="grid grid-cols-2 gap-4 text-xs">
                    <div className="space-y-1">
                      <p className="text-zinc-500 font-semibold uppercase">Victim Contact</p>
                      <a
                        href={`tel:${activeIncident.phone}`}
                        className="flex items-center gap-1.5 text-indigo-400 hover:text-indigo-300 font-mono font-bold"
                      >
                        <Phone className="h-3.5 w-3.5" />
                        {activeIncident.phone}
                      </a>
                    </div>
                    <div className="space-y-1">
                      <p className="text-zinc-500 font-semibold uppercase">Blood Group</p>
                      <p className="text-white font-extrabold">{activeIncident.bloodGroup}</p>
                    </div>
                    <div className="space-y-1">
                      <p className="text-zinc-500 font-semibold uppercase">Detection Type</p>
                      <span className={`inline-flex items-center rounded-lg px-2 py-0.5 font-bold uppercase text-[9px] ${
                        activeIncident.detectionType === 'manual' ? 'bg-zinc-850 text-zinc-300 border border-white/10' :
                        activeIncident.detectionType === 'impact' ? 'bg-rose-500/20 text-rose-400 border border-rose-500/30' :
                        activeIncident.detectionType === 'fall' ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30' :
                        'bg-cyan-500/20 text-cyan-400 border border-cyan-500/30'
                      }`}>
                        {activeIncident.detectionType || 'manual'}
                      </span>
                    </div>
                    <div className="space-y-1">
                      <p className="text-zinc-500 font-semibold uppercase">Engine Priority (Score: {activeIncident.priorityScore})</p>
                      <select
                        value={activeIncident.priority || activeIncident.severity}
                        onChange={(e) => handleUpdatePriority(activeIncident.id, e.target.value)}
                        disabled={activeIncident.status === "Resolved" || activeIncident.status === "Cancelled"}
                        className="bg-black/30 border border-white/10 rounded-lg px-2 py-1 text-xs font-bold text-white outline-none focus:border-indigo-500 disabled:opacity-40"
                      >
                        <option value="Critical">Critical</option>
                        <option value="High">High</option>
                        <option value="Medium">Medium</option>
                        <option value="Low">Low</option>
                      </select>
                    </div>
                    <div className="col-span-2 space-y-1">
                      <p className="text-zinc-500 font-semibold uppercase">Emergency Contact</p>
                      <p className="text-zinc-300 font-medium">{activeIncident.emergencyContact}</p>
                    </div>
                  </div>


                  <div className="my-2 h-px bg-white/5" />

                  {/* Responder Allocation Controls */}
                  <div className="space-y-2">
                    <p className="text-xs font-semibold text-zinc-500 uppercase">Incident Dispatch Action</p>
                    <div className="flex items-center gap-3">
                      {activeIncident.assignedVolunteer ? (
                        <div className="flex items-center gap-2 rounded-2xl border border-indigo-500/20 bg-indigo-500/10 px-4 py-2 text-sm text-indigo-300 font-semibold">
                          <HeartHandshake className="h-4 w-4" />
                          <span>Assigned: {activeIncident.assignedVolunteer}</span>
                        </div>
                      ) : (
                        <div className="relative">
                          <button
                            onClick={() => setShowAssignDropdown(!showAssignDropdown)}
                            disabled={activeIncident.status === "Resolved" || activeIncident.status === "Cancelled"}
                            className="flex items-center gap-2 rounded-2xl border border-white/10 bg-white/5 px-4 py-2 text-xs font-bold text-white hover:bg-white/10 disabled:opacity-40 transition-all"
                          >
                            <span>Assign Responder</span>
                            <ChevronDown className="h-4 w-4" />
                          </button>

                          {showAssignDropdown && (
                            <>
                              <div
                                className="fixed inset-0 z-20"
                                onClick={() => setShowAssignDropdown(false)}
                              />
                              <div className="absolute bottom-full left-0 mb-2 w-56 rounded-2xl border border-white/10 bg-[#131313] p-1.5 shadow-2xl backdrop-blur-xl z-30">
                                <p className="text-[10px] font-bold text-zinc-500 uppercase px-3 py-1.5 border-b border-white/5">Available Responders</p>
                                {availableResponders.length > 0 ? (
                                  availableResponders.map((vol) => (
                                    <button
                                      key={vol.id}
                                      onClick={() => handleAssignVolunteer(vol.id)}
                                      className="flex w-full items-center justify-between rounded-xl px-3 py-2 text-xs text-zinc-300 hover:bg-white/5 hover:text-white transition-all text-left"
                                    >
                                      <span>{vol.name}</span>
                                      <Check className="h-3 w-3 text-emerald-400 opacity-0 group-hover:opacity-100" />
                                    </button>
                                  ))
                                ) : (
                                  <p className="text-xs text-zinc-500 px-3 py-2.5 italic">No available responders</p>
                                )}
                              </div>
                            </>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                {/* Operations Control Actions */}
                <div className="mt-6 flex gap-2 pt-4 border-t border-white/5">
                  {activeIncident.status !== "Resolved" && activeIncident.status !== "Cancelled" ? (
                    <>
                      <button
                        onClick={() => handleCancelCase(activeIncident.id)}
                        className="flex-1 flex items-center justify-center gap-2 rounded-2xl border border-rose-500/20 bg-rose-500/10 py-2.5 text-xs font-semibold text-rose-400 hover:bg-rose-500/20 transition-all"
                      >
                        <XCircle className="h-4 w-4" />
                        <span>Cancel SOS</span>
                      </button>
                      <button
                        onClick={() => handleResolveCase(activeIncident.id)}
                        className="flex-1 flex items-center justify-center gap-2 rounded-2xl bg-emerald-500 hover:bg-emerald-600 py-2.5 text-xs font-bold text-white transition-all shadow-lg shadow-emerald-500/10"
                      >
                        <CheckCircle className="h-4 w-4" />
                        <span>Mark Resolved</span>
                      </button>
                    </>
                  ) : (
                    <div className="w-full text-center text-xs text-zinc-500 italic py-2">
                      {activeIncident.status === "Resolved"
                        ? `Case resolved at ${activeIncident.resolvedTime}`
                        : "Case cancelled"}
                    </div>
                  )}
                </div>
              </div>
            </div>
          ) : (
            <div className="h-full flex items-center justify-center text-zinc-500 text-sm">
              Select an incident from the feed to view GPS mapping and details.
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
