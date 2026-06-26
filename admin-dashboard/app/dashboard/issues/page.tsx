"use client";

import { useState, useEffect } from "react";
import {
  AlertTriangle,
  CheckCircle,
  User,
  Filter,
  Eye,
  Trash2,
  X,
  Play,
  Check,
} from "lucide-react";
import { 
  getIssues, 
  updateIssueStatus, 
  deleteIssue, 
  IssueData 
} from "@/services/supabase/issues";

export default function IssuesPage() {
  const [issues, setIssues] = useState<IssueData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [priorityFilter, setPriorityFilter] = useState("All");
  const [statusFilter, setStatusFilter] = useState("All");

  const [selectedIssue, setSelectedIssue] = useState<IssueData | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const fetchIssues = async () => {
    try {
      setLoading(true);
      const data = await getIssues();
      setIssues(data);
      setError(null);
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : "Failed to load support tickets.";
      setError(errMsg);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    Promise.resolve().then(() => {
      fetchIssues();
    });
  }, []);

  // Filtering
  const filteredIssues = issues.filter((issue) => {
    const matchesPriority = priorityFilter === "All" || issue.priority === priorityFilter;
    const matchesStatus = statusFilter === "All" || issue.status === statusFilter;
    return matchesPriority && matchesStatus;
  });

  const getPriorityStyle = (priority: string) => {
    switch (priority) {
      case "High":
        return "bg-rose-500/20 text-rose-400 border border-rose-500/30";
      case "Medium":
        return "bg-amber-500/20 text-amber-400 border border-amber-500/30";
      case "Low":
        return "bg-zinc-800 text-zinc-400 border border-zinc-700";
      default:
        return "bg-zinc-800 text-zinc-300";
    }
  };

  const getStatusStyle = (status: string) => {
    switch (status) {
      case "Open":
        return "bg-red-500/10 text-red-400 border border-red-500/20";
      case "In Progress":
        return "bg-cyan-500/10 text-cyan-400 border border-cyan-500/20";
      case "Resolved":
        return "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20";
      case "Closed":
        return "bg-zinc-800 text-zinc-500 border border-zinc-700";
      default:
        return "bg-zinc-800 text-zinc-300";
    }
  };

  // Actions
  const handleUpdateStatus = async (id: string, newStatus: IssueData['status']) => {
    try {
      const updatedIssue = await updateIssueStatus(id, newStatus);
      setIssues(issues.map((iss) => (iss.id === id ? updatedIssue : iss)));
      if (selectedIssue && selectedIssue.id === id) {
        setSelectedIssue(updatedIssue);
      }
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : "An error occurred";
      alert("Failed to update status: " + errMsg);
    }
  };

  const handleDeleteIssue = async (id: string) => {
    if (confirm("Are you sure you want to delete this issue ticket?")) {
      try {
        await deleteIssue(id);
        setIssues(issues.filter((iss) => iss.id !== id));
        setIsModalOpen(false);
      } catch (err) {
        const errMsg = err instanceof Error ? err.message : "An error occurred";
        alert("Failed to delete ticket: " + errMsg);
      }
    }
  };

  const handleOpenView = (issue: IssueData) => {
    setSelectedIssue(issue);
    setIsModalOpen(true);
  };

  return (
    <div className="space-y-6">

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3 rounded-3xl border border-white/10 bg-white/5 p-4 backdrop-blur-xl">
        <div className="flex items-center gap-2 rounded-2xl border border-white/10 bg-zinc-950/20 px-3 py-1.5">
          <Filter className="h-3.5 w-3.5 text-zinc-400" />
          <span className="text-xs text-zinc-400 font-medium">Priority:</span>
          <select
            value={priorityFilter}
            onChange={(e) => setPriorityFilter(e.target.value)}
            className="bg-transparent text-xs text-white outline-none border-none cursor-pointer pr-2"
          >
            <option value="All" className="bg-[#18181b]">All Priorities</option>
            <option value="High" className="bg-[#18181b]">High</option>
            <option value="Medium" className="bg-[#18181b]">Medium</option>
            <option value="Low" className="bg-[#18181b]">Low</option>
          </select>
        </div>

        <div className="flex items-center gap-2 rounded-2xl border border-white/10 bg-zinc-950/20 px-3 py-1.5">
          <Filter className="h-3.5 w-3.5 text-zinc-400" />
          <span className="text-xs text-zinc-400 font-medium">Status:</span>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="bg-transparent text-xs text-white outline-none border-none cursor-pointer pr-2"
          >
            <option value="All" className="bg-[#18181b]">All Status</option>
            <option value="Open" className="bg-[#18181b]">Open</option>
            <option value="In Progress" className="bg-[#18181b]">In Progress</option>
            <option value="Resolved" className="bg-[#18181b]">Resolved</option>
            <option value="Closed" className="bg-[#18181b]">Closed</option>
          </select>
        </div>
      </div>

      {/* Issues Table */}
      <div className="overflow-hidden rounded-3xl border border-white/10 bg-white/5 backdrop-blur-xl">
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-left text-sm text-zinc-300">
            <thead>
              <tr className="border-b border-white/10 bg-white/2 text-xs font-semibold uppercase tracking-wider text-zinc-400">
                <th className="px-6 py-4">Ticket</th>
                <th className="px-6 py-4">User</th>
                <th className="px-6 py-4">Title</th>
                <th className="px-6 py-4">Priority</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4">Created At</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {loading ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-zinc-400">
                    <div className="flex items-center justify-center gap-2.5">
                      <span className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
                      <span>Loading support tickets...</span>
                    </div>
                  </td>
                </tr>
              ) : error ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-rose-400 font-medium">
                    Error loading tickets: {error}
                  </td>
                </tr>
              ) : filteredIssues.length > 0 ? (
                filteredIssues.map((issue) => (
                  <tr key={issue.id} className="hover:bg-white/2 transition-colors duration-150">
                    <td className="whitespace-nowrap px-6 py-4 font-mono font-bold text-white">
                      {issue.id}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4">
                      <div className="flex items-center gap-2">
                        <User className="h-4 w-4 text-zinc-500" />
                        <span className="font-semibold text-zinc-200">{issue.userName}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 max-w-xs truncate font-medium text-white">
                      {issue.title}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4">
                      <span className={`rounded-lg px-2 py-0.5 text-xs font-semibold ${getPriorityStyle(issue.priority)}`}>
                        {issue.priority}
                      </span>
                    </td>
                    <td className="whitespace-nowrap px-6 py-4">
                      <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold ${getStatusStyle(issue.status)}`}>
                        {issue.status}
                      </span>
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-xs text-zinc-500 font-mono">
                      {issue.createdAt}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => handleOpenView(issue)}
                          className="rounded-lg p-1.5 text-zinc-400 hover:bg-white/5 hover:text-white transition-all"
                          title="View Details"
                        >
                          <Eye className="h-4 w-4" />
                        </button>
                        {issue.status === "Open" && (
                          <button
                            onClick={() => handleUpdateStatus(issue.id, "In Progress")}
                            className="rounded-lg p-1.5 text-cyan-400 hover:bg-cyan-500/10 transition-all"
                            title="Start Progress"
                          >
                            <Play className="h-4 w-4" />
                          </button>
                        )}
                        {(issue.status === "Open" || issue.status === "In Progress") && (
                          <button
                            onClick={() => handleUpdateStatus(issue.id, "Resolved")}
                            className="rounded-lg p-1.5 text-emerald-400 hover:bg-emerald-500/10 transition-all"
                            title="Mark Resolved"
                          >
                            <Check className="h-4 w-4" />
                          </button>
                        )}
                        {issue.status === "Resolved" && (
                          <button
                            onClick={() => handleUpdateStatus(issue.id, "Closed")}
                            className="rounded-lg p-1.5 text-zinc-400 hover:bg-zinc-500/10 transition-all"
                            title="Close Ticket"
                          >
                            <CheckCircle className="h-4 w-4" />
                          </button>
                        )}
                        <button
                          onClick={() => handleDeleteIssue(issue.id)}
                          className="rounded-lg p-1.5 text-rose-500 hover:bg-rose-500/10 transition-all"
                          title="Delete Ticket"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="px-6 py-10 text-center text-zinc-500">
                    No tickets found matching the criteria.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Ticket Details Modal */}
      {isModalOpen && selectedIssue && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm animate-fade-in">
          <div className="w-full max-w-lg rounded-3xl border border-white/10 bg-zinc-950 p-6 shadow-2xl backdrop-blur-xl relative animate-scale-up">
            <button
              onClick={() => setIsModalOpen(false)}
              className="absolute right-4 top-4 rounded-xl p-2 text-zinc-400 hover:bg-white/5 hover:text-white transition-all"
            >
              <X className="h-4 w-4" />
            </button>
            <div className="flex items-center gap-2 mb-2">
              <AlertTriangle className="h-5 w-5 text-amber-500" />
              <span className="text-xs font-bold font-mono text-zinc-500">TICKET: {selectedIssue.id}</span>
            </div>
            <h3 className="text-xl font-bold text-white mb-2">{selectedIssue.title}</h3>
            <p className="text-xs text-zinc-400 mb-4">Reported by: <span className="font-semibold text-zinc-300">{selectedIssue.userName}</span> at {selectedIssue.createdAt}</p>

            <div className="my-2 h-px bg-white/5" />

            <div className="space-y-4 py-2">
              <div>
                <p className="text-xs text-zinc-500 uppercase font-semibold mb-1">Issue Description</p>
                <p className="text-zinc-300 text-sm bg-white/2 border border-white/5 rounded-2xl p-4 leading-relaxed whitespace-pre-wrap">
                  {selectedIssue.description}
                </p>
              </div>

              <div className="grid grid-cols-2 gap-4 text-xs pt-2">
                <div>
                  <p className="text-zinc-500 font-semibold uppercase">Priority Level</p>
                  <span className={`inline-block rounded-lg px-2.5 py-0.5 mt-1 font-semibold ${getPriorityStyle(selectedIssue.priority)}`}>
                    {selectedIssue.priority}
                  </span>
                </div>
                <div>
                  <p className="text-zinc-500 font-semibold uppercase">Current Status</p>
                  <span className={`inline-block rounded-full px-2.5 py-0.5 mt-1 font-semibold ${getStatusStyle(selectedIssue.status)}`}>
                    {selectedIssue.status}
                  </span>
                </div>
              </div>
            </div>

            <div className="mt-6 flex justify-between gap-2 pt-4 border-t border-white/5">
              <button
                onClick={() => handleDeleteIssue(selectedIssue.id)}
                className="rounded-2xl border border-rose-500/20 bg-rose-500/10 px-4 py-2 text-xs font-semibold text-rose-400 hover:bg-rose-500/20 transition-all"
              >
                Delete Ticket
              </button>
              <div className="flex gap-2">
                {selectedIssue.status === "Open" && (
                  <button
                    onClick={() => handleUpdateStatus(selectedIssue.id, "In Progress")}
                    className="rounded-2xl bg-cyan-600 hover:bg-cyan-700 px-4 py-2 text-xs font-semibold text-white transition-all animate-pulse"
                  >
                    Start In-Progress
                  </button>
                )}
                {(selectedIssue.status === "Open" || selectedIssue.status === "In Progress") && (
                  <button
                    onClick={() => handleUpdateStatus(selectedIssue.id, "Resolved")}
                    className="rounded-2xl bg-emerald-500 hover:bg-emerald-600 px-4 py-2 text-xs font-semibold text-white transition-all"
                  >
                    Mark Resolved
                  </button>
                )}
                {selectedIssue.status === "Resolved" && (
                  <button
                    onClick={() => handleUpdateStatus(selectedIssue.id, "Closed")}
                    className="rounded-2xl bg-zinc-800 hover:bg-zinc-700 px-4 py-2 text-xs font-semibold text-zinc-300 transition-all"
                  >
                    Close Ticket
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
