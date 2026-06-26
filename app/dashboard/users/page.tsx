"use client";

import { useState, useEffect } from "react";
import {
  Search,
  UserMinus,
  UserCheck,
  Trash2,
  Eye,
  Edit,
  X,
  ChevronLeft,
  ChevronRight,
  Filter,
} from "lucide-react";
import { 
  getUsers, 
  toggleUserStatus, 
  updateUser, 
  deleteUser, 
  UserData 
} from "@/services/supabase/users";

export default function UsersPage() {
  const [users, setUsers] = useState<UserData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const [search, setSearch] = useState("");
  const [roleFilter, setRoleFilter] = useState("All");
  const [statusFilter, setStatusFilter] = useState("All");
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 5;

  // Modals state
  const [selectedUser, setSelectedUser] = useState<UserData | null>(null);
  const [isViewModalOpen, setIsViewModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editFormData, setEditFormData] = useState<Partial<UserData>>({
    name: "",
    email: "",
    phone: "",
    bloodGroup: "",
    role: "User",
  });

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const data = await getUsers();
      setUsers(data);
      setError(null);
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : "Failed to load users.";
      setError(errMsg);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    Promise.resolve().then(() => {
      fetchUsers();
    });
  }, []);

  // Handle Search and Filters
  const filteredUsers = users.filter((user) => {
    const nameMatch = user.name ? user.name.toLowerCase().includes(search.toLowerCase()) : false;
    const emailMatch = user.email ? user.email.toLowerCase().includes(search.toLowerCase()) : false;
    const phoneMatch = user.phone ? user.phone.includes(search) : false;
    const matchesSearch = nameMatch || emailMatch || phoneMatch;
    const matchesRole = roleFilter === "All" || user.role === roleFilter;
    const matchesStatus = statusFilter === "All" || user.status === statusFilter;
    return matchesSearch && matchesRole && matchesStatus;
  });

  // Pagination
  const totalPages = Math.ceil(filteredUsers.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedUsers = filteredUsers.slice(startIndex, startIndex + itemsPerPage);

  const handlePageChange = (page: number) => {
    if (page >= 1 && page <= totalPages) {
      setCurrentPage(page);
    }
  };

  // Actions
  const handleToggleStatus = async (id: string) => {
    const userToToggle = users.find(u => u.id === id);
    if (!userToToggle) return;
    try {
      const updatedUser = await toggleUserStatus(id, userToToggle.status);
      setUsers(users.map((user) => (user.id === id ? updatedUser : user)));
      if (selectedUser && selectedUser.id === id) {
        setSelectedUser(updatedUser);
      }
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : "An error occurred";
      alert("Failed to toggle status: " + errMsg);
    }
  };

  const handleDeleteUser = async (id: string) => {
    if (confirm("Are you sure you want to delete this user? This action is irreversible.")) {
      try {
        await deleteUser(id);
        setUsers(users.filter((user) => user.id !== id));
        setIsViewModalOpen(false);
        setIsEditModalOpen(false);
      } catch (err) {
        const errMsg = err instanceof Error ? err.message : "An error occurred";
        alert("Failed to delete user: " + errMsg);
      }
    }
  };

  const handleOpenEdit = (user: UserData) => {
    setSelectedUser(user);
    setEditFormData({
      name: user.name,
      email: user.email,
      phone: user.phone,
      bloodGroup: user.bloodGroup || "",
      role: user.role,
    });
    setIsEditModalOpen(true);
  };

  const handleEditSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser?.id) return;
    try {
      const updatedUser = await updateUser(selectedUser.id, editFormData);
      setUsers(users.map((user) => (user.id === selectedUser.id ? updatedUser : user)));
      setIsEditModalOpen(false);
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : "An error occurred";
      alert("Failed to update user: " + errMsg);
    }
  };

  const handleOpenView = (user: UserData) => {
    setSelectedUser(user);
    setIsViewModalOpen(true);
  };

  return (
    <div className="space-y-6">

      {/* Controls: Search & Filters */}
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between rounded-3xl border border-white/10 bg-white/5 p-4 backdrop-blur-xl">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-zinc-400" />
          <input
            type="text"
            placeholder="Search by name, email or phone..."
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
            <span className="text-xs text-zinc-400 font-medium">Role:</span>
            <select
              value={roleFilter}
              onChange={(e) => {
                setRoleFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="bg-transparent text-xs text-white outline-none border-none cursor-pointer pr-2"
            >
              <option value="All" className="bg-[#18181b]">All Roles</option>
              <option value="User" className="bg-[#18181b]">User</option>
              <option value="Volunteer" className="bg-[#18181b]">Volunteer</option>
              <option value="Admin" className="bg-[#18181b]">Admin</option>
            </select>
          </div>

          <div className="flex items-center gap-2 rounded-2xl border border-white/10 bg-zinc-950/20 px-3 py-1.5">
            <Filter className="h-3.5 w-3.5 text-zinc-400" />
            <span className="text-xs text-zinc-400 font-medium">Status:</span>
            <select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value);
                setCurrentPage(1);
              }}
              className="bg-transparent text-xs text-white outline-none border-none cursor-pointer pr-2"
            >
              <option value="All" className="bg-[#18181b]">All Status</option>
              <option value="Active" className="bg-[#18181b]">Active</option>
              <option value="Suspended" className="bg-[#18181b]">Suspended</option>
            </select>
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div className="overflow-hidden rounded-3xl border border-white/10 bg-white/5 backdrop-blur-xl">
        <div className="overflow-x-auto">
          <table className="w-full border-collapse text-left text-sm text-zinc-300">
            <thead>
              <tr className="border-b border-white/10 bg-white/2 text-xs font-semibold uppercase tracking-wider text-zinc-400">
                <th className="px-6 py-4">Name</th>
                <th className="px-6 py-4">Email</th>
                <th className="px-6 py-4">Phone</th>
                <th className="px-6 py-4">Blood Group</th>
                <th className="px-6 py-4">Role</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4">Created At</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {loading ? (
                <tr>
                  <td colSpan={8} className="px-6 py-12 text-center text-zinc-400">
                    <div className="flex items-center justify-center gap-2.5">
                      <span className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-500 border-t-transparent" />
                      <span>Loading users from database...</span>
                    </div>
                  </td>
                </tr>
              ) : error ? (
                <tr>
                  <td colSpan={8} className="px-6 py-12 text-center text-rose-400 font-medium">
                    Error loading users: {error}
                  </td>
                </tr>
              ) : paginatedUsers.length > 0 ? (
                paginatedUsers.map((user) => (
                  <tr
                    key={user.id}
                    className="hover:bg-white/2 transition-colors duration-150"
                  >
                    <td className="whitespace-nowrap px-6 py-4 font-semibold text-white">
                      {user.name}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4">{user.email}</td>
                    <td className="whitespace-nowrap px-6 py-4 text-xs font-mono">
                      {user.phone}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-center">
                      <span className="rounded-lg bg-zinc-800 px-2.5 py-1 text-xs font-bold text-zinc-200">
                        {user.bloodGroup}
                      </span>
                    </td>
                    <td className="whitespace-nowrap px-6 py-4">
                      <span
                        className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${
                          user.role === "Admin"
                            ? "bg-purple-500/20 text-purple-400"
                            : user.role === "Volunteer"
                            ? "bg-indigo-500/20 text-indigo-400"
                            : "bg-zinc-500/20 text-zinc-400"
                        }`}
                      >
                        {user.role}
                      </span>
                    </td>
                    <td className="whitespace-nowrap px-6 py-4">
                      <span
                        className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold ${
                          user.status === "Active"
                            ? "bg-emerald-500/20 text-emerald-400"
                            : "bg-rose-500/20 text-rose-400"
                        }`}
                      >
                        <span
                          className={`h-1.5 w-1.5 rounded-full ${
                            user.status === "Active" ? "bg-emerald-400" : "bg-rose-400"
                          }`}
                        />
                        {user.status}
                      </span>
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-xs text-zinc-500">
                      {user.createdAt}
                    </td>
                    <td className="whitespace-nowrap px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => handleOpenView(user)}
                          className="rounded-lg p-1.5 text-zinc-400 hover:bg-white/5 hover:text-white transition-all"
                          title="View Details"
                        >
                          <Eye className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleOpenEdit(user)}
                          className="rounded-lg p-1.5 text-zinc-400 hover:bg-white/5 hover:text-white transition-all"
                          title="Edit User"
                        >
                          <Edit className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleToggleStatus(user.id!)}
                          className={`rounded-lg p-1.5 transition-all ${
                            user.status === "Active"
                              ? "text-amber-500 hover:bg-amber-500/10"
                              : "text-emerald-500 hover:bg-emerald-500/10"
                          }`}
                          title={user.status === "Active" ? "Suspend User" : "Activate User"}
                        >
                          {user.status === "Active" ? (
                            <UserMinus className="h-4 w-4" />
                          ) : (
                            <UserCheck className="h-4 w-4" />
                          )}
                        </button>
                        <button
                          onClick={() => handleDeleteUser(user.id!)}
                          className="rounded-lg p-1.5 text-rose-500 hover:bg-rose-500/10 transition-all"
                          title="Delete User"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={8} className="px-6 py-10 text-center text-zinc-500">
                    No users found matching the filter criteria.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Footer */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between border-t border-white/10 bg-white/2 px-6 py-4">
            <span className="text-xs text-zinc-500">
              Showing {startIndex + 1} to{" "}
              {Math.min(startIndex + itemsPerPage, filteredUsers.length)} of{" "}
              {filteredUsers.length} records
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

      {/* View Details Modal */}
      {isViewModalOpen && selectedUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm animate-fade-in">
          <div className="w-full max-w-md rounded-3xl border border-white/10 bg-zinc-950 p-6 shadow-2xl backdrop-blur-xl relative">
            <button
              onClick={() => setIsViewModalOpen(false)}
              className="absolute right-4 top-4 rounded-xl p-2 text-zinc-400 hover:bg-white/5 hover:text-white transition-all"
            >
              <X className="h-4 w-4" />
            </button>
            <h3 className="text-lg font-bold text-white mb-4">User Profile Details</h3>

            <div className="space-y-4">
              <div className="flex items-center gap-4">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 text-lg font-semibold text-white">
                  {selectedUser.name.charAt(0)}
                </div>
                <div>
                  <h4 className="font-bold text-white">{selectedUser.name}</h4>
                  <p className="text-xs text-zinc-400">{selectedUser.role}</p>
                </div>
              </div>

              <div className="my-2 h-px bg-white/5" />

              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Email</p>
                  <p className="text-zinc-300 font-medium break-all">{selectedUser.email}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Phone</p>
                  <p className="text-zinc-300 font-medium font-mono">{selectedUser.phone}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Blood Group</p>
                  <p className="text-zinc-300 font-bold">{selectedUser.bloodGroup}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Status</p>
                  <p className="text-zinc-300 font-medium">{selectedUser.status}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Age</p>
                  <p className="text-zinc-300 font-medium">{selectedUser.age || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Gender</p>
                  <p className="text-zinc-300 font-medium">{selectedUser.gender || 'N/A'}</p>
                </div>
                <div className="col-span-2">
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Address</p>
                  <p className="text-zinc-300 font-medium">{selectedUser.address || 'N/A'}</p>
                </div>
                <div className="col-span-2 my-1 h-px bg-white/5" />
                <div className="col-span-2">
                  <p className="text-xs text-indigo-400 uppercase font-bold text-[10px] tracking-wider">Medical Information</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Allergies</p>
                  <p className="text-rose-400 font-bold">{selectedUser.allergies || 'None'}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Conditions</p>
                  <p className="text-amber-400 font-bold">{selectedUser.medicalConditions || 'None'}</p>
                </div>
                <div className="col-span-2">
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Special Notes</p>
                  <p className="text-zinc-300 font-medium">{selectedUser.specialNotes || 'None'}</p>
                </div>
                <div className="col-span-2 my-1 h-px bg-white/5" />
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">Registered At</p>
                  <p className="text-zinc-300 font-medium">{selectedUser.createdAt}</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 uppercase font-semibold">User ID</p>
                  <p className="text-zinc-400 font-mono text-[10px] break-all">{selectedUser.id}</p>
                </div>
              </div>


              <div className="mt-6 flex justify-end gap-2 pt-2 border-t border-white/5">
                <button
                  onClick={() => selectedUser?.id && handleToggleStatus(selectedUser.id)}
                  className={`rounded-2xl px-4 py-2 text-xs font-semibold transition-all ${
                    selectedUser.status === "Active"
                      ? "border border-amber-500/20 bg-amber-500/10 text-amber-400 hover:bg-amber-500/20"
                      : "border border-emerald-500/20 bg-emerald-500/10 text-emerald-400 hover:bg-emerald-500/20"
                  }`}
                >
                  {selectedUser.status === "Active" ? "Suspend Account" : "Activate Account"}
                </button>
                <button
                  onClick={() => {
                    if (selectedUser) {
                      setIsViewModalOpen(false);
                      handleOpenEdit(selectedUser);
                    }
                  }}
                  className="rounded-2xl border border-white/10 bg-white/5 px-4 py-2 text-xs font-semibold text-white hover:bg-white/10 transition-all"
                >
                  Edit Profile
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Edit Modal */}
      {isEditModalOpen && selectedUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm animate-fade-in">
          <div className="w-full max-w-md rounded-3xl border border-white/10 bg-zinc-950 p-6 shadow-2xl backdrop-blur-xl relative">
            <button
              onClick={() => setIsEditModalOpen(false)}
              className="absolute right-4 top-4 rounded-xl p-2 text-zinc-400 hover:bg-white/5 hover:text-white transition-all"
            >
              <X className="h-4 w-4" />
            </button>
            <h3 className="text-lg font-bold text-white mb-4">Edit User Account</h3>

            <form onSubmit={handleEditSubmit} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-zinc-400 uppercase mb-1">Name</label>
                <input
                  type="text"
                  required
                  value={editFormData.name}
                  onChange={(e) => setEditFormData({ ...editFormData, name: e.target.value })}
                  className="w-full rounded-xl border border-white/10 bg-zinc-900 px-3.5 py-2 text-sm text-white focus:border-indigo-500/50 outline-none transition-all"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-zinc-400 uppercase mb-1">Email</label>
                <input
                  type="email"
                  required
                  value={editFormData.email}
                  onChange={(e) => setEditFormData({ ...editFormData, email: e.target.value })}
                  className="w-full rounded-xl border border-white/10 bg-zinc-900 px-3.5 py-2 text-sm text-white focus:border-indigo-500/50 outline-none transition-all"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-zinc-400 uppercase mb-1">Phone</label>
                <input
                  type="text"
                  required
                  value={editFormData.phone}
                  onChange={(e) => setEditFormData({ ...editFormData, phone: e.target.value })}
                  className="w-full rounded-xl border border-white/10 bg-zinc-900 px-3.5 py-2 text-sm text-white focus:border-indigo-500/50 outline-none transition-all font-mono"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-zinc-400 uppercase mb-1">Blood Group</label>
                  <select
                    value={editFormData.bloodGroup}
                    onChange={(e) => setEditFormData({ ...editFormData, bloodGroup: e.target.value })}
                    className="w-full rounded-xl border border-white/10 bg-zinc-900 px-3.5 py-2 text-sm text-white focus:border-indigo-500/50 outline-none transition-all cursor-pointer"
                  >
                    <option value="A+">A+</option>
                    <option value="A-">A-</option>
                    <option value="B+">B+</option>
                    <option value="B-">B-</option>
                    <option value="O+">O+</option>
                    <option value="O-">O-</option>
                    <option value="AB+">AB+</option>
                    <option value="AB-">AB-</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-zinc-400 uppercase mb-1">Role</label>
                  <select
                    value={editFormData.role}
                    onChange={(e) => setEditFormData({ ...editFormData, role: e.target.value as UserData['role'] })}
                    className="w-full rounded-xl border border-white/10 bg-zinc-900 px-3.5 py-2 text-sm text-white focus:border-indigo-500/50 outline-none transition-all cursor-pointer"
                  >
                    <option value="User">User</option>
                    <option value="Volunteer">Volunteer</option>
                    <option value="Admin">Admin</option>
                  </select>
                </div>
              </div>

              <div className="mt-6 flex justify-end gap-2 pt-4 border-t border-white/5">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="rounded-2xl border border-white/10 bg-transparent px-4 py-2 text-xs font-semibold text-zinc-400 hover:bg-white/5 hover:text-white transition-all"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="rounded-2xl bg-indigo-500 hover:bg-indigo-600 px-4 py-2 text-xs font-semibold text-white transition-all"
                >
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
