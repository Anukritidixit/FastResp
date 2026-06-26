"use client";

import { useState, useEffect } from "react";
import {
  Search,
  CheckCircle,
  XCircle,
  UserX,
  UserCheck,
  Eye,
  Star,
  X,
  ChevronLeft,
  ChevronRight,
  Filter,
} from "lucide-react";
import { 
  getVolunteers, 
  updateVolunteerVerification, 
  VolunteerData 
} from "@/services/supabase/volunteers";

export default function VolunteersPage() {
  const [volunteers, setVolunteers] = useState<VolunteerData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("All");
  const [availFilter, setAvailFilter] = useState("All");
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 5;

  const [selectedVol, setSelectedVol] = useState<VolunteerData | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const fetchVolunteers = async () => {
    try {
      setLoading(true);
      const data = await getVolunteers();
      setVolunteers(data);
      setError(null);
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : "Failed to load volunteers.";
      setError(errMsg);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    Promise.resolve().then(() => {
      fetchVolunteers();
    });
  }, []);

  // Handle Filtering
  const filteredVolunteers = volunteers.filter((vol) => {
    const nameMatch = vol.name ? vol.name.toLowerCase().includes(search.toLowerCase()) : false;
    const phoneMatch = vol.phone ? vol.phone.includes(search) : false;
    const matchesSearch = nameMatch || phoneMatch;
    const matchesStatus = statusFilter === "All" || vol.isVerified === statusFilter;
    const matchesAvail = availFilter === "All" || vol.isAvailable === availFilter;
    return matchesSearch && matchesStatus && matchesAvail;
  });

  // Pagination
  const totalPages = Math.ceil(filteredVolunteers.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedVolunteers = filteredVolunteers.slice(startIndex, startIndex + itemsPerPage);

  const handlePageChange = (page: number) => {
    if (page >= 1 && page <= totalPages) {
      setCurrentPage(page);
    }
  };

  // Actions
  const handleVerify = async (id: string) => {
    try {
      const updatedVol = await updateVolunteerVerification(id, "Verified");
      setVolunteers(volunteers.map((v) => (v.id === id ? updatedVol : v)));
      if (selectedVol && selectedVol.id === id) {
        setSelectedVol(updatedVol);
      }
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : "An error occurred";
      alert("Failed to verify volunteer: " + errMsg);
    }
  };

  const handleReject = async (id: string) => {
    if (confirm("Are you sure you want to reject this volunteer request?")) {
      try {
        const updatedVol = await updateVolunteerVerification(id, "Suspended");
        setVolunteers(volunteers.map((v) => (v.id === id ? updatedVol : v)));
        if (selectedVol && selectedVol.id === id) {
          setSelectedVol(updatedVol);
        }
      } catch (err) {
        const errMsg = err instanceof Error ? err.message : "An error occurred";
        alert("Failed to reject volunteer: " + errMsg);
      }
    }
  };

  const handleToggleSuspend = async (id: string) => {
    const vol = volunteers.find((v) => v.id === id);
    if (!vol) return;
    const newStatus = vol.isVerified === "Suspended" ? "Verified" : "Suspended";
    try {
      const updatedVol = await updateVolunteerVerification(id, newStatus);
      setVolunteers(volunteers.map((v) => (v.id === id ? updatedVol : v)));
      if (selectedVol && selectedVol.id === id) {
        setSelectedVol(updatedVol);
      }
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : "An error occurred";
      alert("Failed to toggle suspension: " + errMsg);
    }
  };

  const handleOpenDetails = (vol: VolunteerData) => {
    setSelectedVol(vol);
    setIsModalOpen(true);
  };

  return (
    <div className="space-y-6">

      {/* Search & Filters */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between rounded-3xl border border-white/10 bg-white/5 p-4 backdrop-blur-xl">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-zinc-400" />
          <input
            type="text"
            placeholder="Search volunteers by name or phone..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setCurrentPage(1);
            }}
            className="w-full rounded-2xl border border-white/10 bg-zinc-950/40 py-2.5 pl-10 pr-4 text-sm text-white placeholder-zinc-500 outline-none focus:border-indigo-500/50 focus:ring-1 focus:ring-indigo-500/30 transition-all"
          />
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-2 rounded-2xl border border-white/10 bg-zinc-950/20 px-3 py-1.5">
            <Filter className="h-3.5 w-3.5 text-zinc-400" />
            <span className="text-xs text-zinc-400 font-medium">Verification:</span>
            <select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="bg-transparent text-xs text-white outline-none border-none cursor-pointer pr-2"
            >
              <option value="All" className="bg-[#18181b]">All Status</option>
              <option value="Verified" className="bg-[#18181b]">Verified</option>
              <option value="Pending" className="bg-[#18181b]">Pending</option>
              <option value="Suspended" className="bg-[#18181b]">Suspended</option>
              <option value="Rejected" className="bg-[#18181b]">Rejected</option>
            </select>
          </div>

          <div className="flex items-center gap-2 rounded-2xl border border-white/10 bg-zinc-950/20 px-3 py-1.5">
            <Filter className="h-3.5 w-3.5 text-zinc-400" />
            <span className="text-xs text-zinc-400 font-medium">Availability:</span>
            <select
              value={availFilter}
              onChange={(e) => {
                setAvailFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="bg-transparent text-xs text-white outline-none border-none cursor-pointer pr-2"
            >
              <option value="All" className="bg-[#18181b]">All Availability</option>
              <option value="Available" className="bg-[#18181b]">Available</option>
              <option value="Offline" className="bg-[#18181b]">Offline</option>
            </select>
          </div>
        </div>
      </div>

      {/* Volunteers Table */}
      <div className="overflow-hidden rounded-3xl border border-white/10 bg-white/5 backdrop-blur-xl">
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-left text-sm text-zinc-300">
            <thead>
              <tr className="border-b border-white/10 bg-white/2 text-xs font-semibold uppercase tracking-wider text-zinc-400">
                <th className="px-6 py-4">Name</th>
                <th className="px-6 py-4">Phone</th>
                <th className="px-6 py-4">Verification</th>
                <th className="px-6 py-4">Availability</th>
                <th className="px-6 py-4 text-center">Rating</th>
                <th className="px-6 py-4 text-center">Total Cases</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {loading ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-zinc-400">
                    <div className="flex items-center justify-center gap-2.5">
                      <span className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
                      <span>Loading volunteers from database...</span>
                    </div>
                  </td>
                </tr>
              ) : error ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-rose-400 font-medium">
                    Error loading volunteers: {error}
                  </td>
                </tr>
              ) : paginatedVolunteers.length > 0 ? (
                paginatedVolunteers.map((vol) => (
                  <tr key={vol.id} className="hover:bg-white/2 transition-colors duration-150">
                    <td className="whitespace-nowrap px-6 py-4 font-semibold text-white">
                      {vol.name}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 font-mono text-xs">{vol.phone}</td>
                    <td className="whitespace-nowrap px-6 py-4">
                      <span
                        className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${
                          vol.isVerified === "Verified"
                            ? "bg-emerald-500/20 text-emerald-400"
                            : vol.isVerified === "Pending"
                            ? "bg-amber-500/20 text-amber-400"
                            : vol.isVerified === "Suspended"
                            ? "bg-rose-500/20 text-rose-400"
                            : "bg-zinc-500/20 text-zinc-400"
                        }`}
                      >
                        {vol.isVerified}
                      </span>
                    </td>
                    <td className="whitespace-nowrap px-6 py-4">
                      <span className="flex items-center gap-1.5">
                        <span
                          className={`h-1.5 w-1.5 rounded-full ${
                            vol.isAvailable === "Available" ? "bg-emerald-400 animate-pulse" : "bg-zinc-500"
                          }`}
                        />
                        <span className="text-xs text-zinc-400 font-medium">{vol.isAvailable}</span>
                      </span>
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-center">
                      {vol.rating > 0 ? (
                        <div className="flex items-center justify-center gap-1 text-xs text-amber-400 font-bold">
                          <Star className="h-3.5 w-3.5 fill-current" />
                          <span>{vol.rating.toFixed(1)}</span>
                        </div>
                      ) : (
                        <span className="text-xs text-zinc-500">Unrated</span>
                      )}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-center font-bold text-white">
                      {vol.totalCases}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => handleOpenDetails(vol)}
                          className="rounded-lg p-1.5 text-zinc-400 hover:bg-white/5 hover:text-white transition-all"
                          title="View Details"
                        >
                          <Eye className="h-4 w-4" />
                        </button>
                        {vol.isVerified === "Pending" && (
                          <>
                            <button
                              onClick={() => handleVerify(vol.id)}
                              className="rounded-lg p-1.5 text-emerald-500 hover:bg-emerald-500/10 transition-all"
                              title="Verify Volunteer"
                            >
                              <CheckCircle className="h-4 w-4" />
                            </button>
                            <button
                              onClick={() => handleReject(vol.id)}
                              className="rounded-lg p-1.5 text-rose-500 hover:bg-rose-500/10 transition-all"
                              title="Reject Request"
                            >
                              <XCircle className="h-4 w-4" />
                            </button>
                          </>
                        )}
                        {vol.isVerified !== "Pending" && (
                          <button
                            onClick={() => handleToggleSuspend(vol.id)}
                            className={`rounded-lg p-1.5 transition-all ${
                              vol.isVerified === "Suspended"
                                ? "text-emerald-500 hover:bg-emerald-500/10"
                                : "text-rose-500 hover:bg-rose-500/10"
                            }`}
                            title={vol.isVerified === "Suspended" ? "Activate Volunteer" : "Suspend Volunteer"}
                          >
                            {vol.isVerified === "Suspended" ? (
                              <UserCheck className="h-4 w-4" />
                            ) : (
                              <UserX className="h-4 w-4" />
                            )}
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="px-6 py-10 text-center text-zinc-500">
                    No volunteers found matching the filters.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between border-t border-white/10 bg-white/2 px-6 py-4">
            <span className="text-xs text-zinc-500">
              Showing {startIndex + 1} to{" "}
              {Math.min(startIndex + itemsPerPage, filteredVolunteers.length)} of{" "}
              {filteredVolunteers.length} volunteers
            </span>
            <div className="flex items-center gap-2">
              <button
                onClick={() => handlePageChange(currentPage - 1)}
                disabled={currentPage === 1}
                className="rounded-xl border border-white/10 p-2 text-zinc-400 hover:bg-white/5 hover:text-white disabled:opacity-40 disabled:hover:bg-transparent transition-all"
              >
                <ChevronLeft className="h-4 w-4" />
              </button>
              <span className="text-xs text-white font-medium px-2">
                Page {currentPage} of {totalPages}
              </span>
              <button
                onClick={() => handlePageChange(currentPage + 1)}
                disabled={currentPage === totalPages}
                className="rounded-xl border border-white/10 p-2 text-zinc-400 hover:bg-white/5 hover:text-white disabled:opacity-40 disabled:hover:bg-transparent transition-all"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Volunteer Details Modal */}
      {isModalOpen && selectedVol && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm animate-fade-in">
          <div className="w-full max-w-md rounded-3xl border border-white/10 bg-zinc-950 p-6 shadow-2xl backdrop-blur-xl relative">
            <button
              onClick={() => setIsModalOpen(false)}
              className="absolute right-4 top-4 rounded-xl p-2 text-zinc-400 hover:bg-white/5 hover:text-white transition-all"
            >
              <X className="h-4 w-4" />
            </button>
            <h3 className="text-lg font-bold text-white mb-4">Volunteer Profile Info</h3>

            <div className="space-y-4">
              <div className="flex items-center gap-4">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 text-lg font-semibold text-white">
                  {selectedVol.name.charAt(0)}
                </div>
                <div>
                  <h4 className="font-bold text-white">{selectedVol.name}</h4>
                  <p className="text-xs text-zinc-400">Joined: {selectedVol.joinedAt}</p>
                </div>
              </div>

              <div className="my-2 h-px bg-white/5" />

              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Email</p>
                  <p className="text-zinc-300 font-medium break-all">{selectedVol.email}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Phone</p>
                  <p className="text-zinc-300 font-medium font-mono">{selectedVol.phone}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Category</p>
                  <p className="text-indigo-400 font-bold uppercase text-xs">{selectedVol.category || 'community'}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Blood Group</p>
                  <p className="text-zinc-300 font-bold">{selectedVol.bloodGroup}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Rating</p>
                  {selectedVol.rating > 0 ? (
                    <div className="flex items-center gap-1 text-sm text-amber-400 font-bold">
                      <Star className="h-4 w-4 fill-current" />
                      <span>{selectedVol.rating.toFixed(1)}</span>
                    </div>
                  ) : (
                    <span className="text-zinc-400">Unrated</span>
                  )}
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Availability</p>
                  <p className="text-zinc-300 font-medium">{selectedVol.isAvailable}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Verification Status</p>
                  <p className="text-zinc-300 font-bold">{selectedVol.isVerified}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Government ID</p>
                  <p className="text-zinc-300 font-medium font-mono text-xs">{selectedVol.governmentId || 'Not Provided'}</p>
                </div>
                <div className="col-span-2 my-1 h-px bg-white/5" />
                <div className="col-span-2">
                  <p className="text-xs text-indigo-400 uppercase font-bold text-[10px] tracking-wider">Qualifications & Experience</p>
                </div>
                <div className="col-span-2">
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Skills</p>
                  <p className="text-zinc-300 font-medium">{selectedVol.skills || 'None Listed'}</p>
                </div>
                <div className="col-span-2">
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Qualification Details</p>
                  <p className="text-zinc-300 font-medium">{selectedVol.qualification || 'None Listed'}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Assigned Cases</p>
                  <p className="text-zinc-300 font-bold">{selectedVol.totalCases}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Successful Saves</p>
                  <p className="text-emerald-400 font-extrabold text-base">{selectedVol.successfulCases || 0}</p>
                </div>
              </div>


              <div className="mt-6 flex justify-end gap-2 pt-2 border-t border-white/5">
                {selectedVol.isVerified === "Pending" ? (
                  <>
                    <button
                      onClick={() => handleReject(selectedVol.id)}
                      className="rounded-2xl border border-rose-500/20 bg-rose-500/10 px-4 py-2 text-xs font-semibold text-rose-400 hover:bg-rose-500/20 transition-all"
                    >
                      Reject Application
                    </button>
                    <button
                      onClick={() => handleVerify(selectedVol.id)}
                      className="rounded-2xl bg-emerald-500 hover:bg-emerald-600 px-4 py-2 text-xs font-semibold text-white transition-all"
                    >
                      Approve & Verify
                    </button>
                  </>
                ) : (
                  <button
                    onClick={() => handleToggleSuspend(selectedVol.id)}
                    className={`rounded-2xl px-4 py-2 text-xs font-semibold transition-all ${
                      selectedVol.isVerified === "Suspended"
                        ? "border border-emerald-500/20 bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500/20"
                        : "border border-rose-500/20 bg-rose-500/10 text-rose-400 hover:bg-rose-500/20"
                    }`}
                  >
                    {selectedVol.isVerified === "Suspended" ? "Activate Volunteer" : "Suspend Volunteer"}
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
