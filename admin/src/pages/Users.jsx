import { useState, useEffect } from 'react';
import { usersApi } from '../api/client';
import {
    Search,
    Filter,
    MoreVertical,
    User,
    Coins,
    Wallet,
    Ban,
    Check,
    X,
    Pencil,
    Save,
    Loader2,
    ChevronLeft,
    ChevronRight,
} from 'lucide-react';

export default function Users() {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [filter, setFilter] = useState('all'); // all, male, female, active, suspended
    const [pagination, setPagination] = useState({ page: 1, lastPage: 1, total: 0 });
    const [selectedUser, setSelectedUser] = useState(null);
    const [actionMenu, setActionMenu] = useState(null);
    const [addCoinsModal, setAddCoinsModal] = useState(null);
    const [coinsAmount, setCoinsAmount] = useState('');
    const [userDetailsModal, setUserDetailsModal] = useState(null);
    const [loadingDetails, setLoadingDetails] = useState(false);
    const [editUserModal, setEditUserModal] = useState(null);
    const [editFormData, setEditFormData] = useState({});
    const [updating, setUpdating] = useState(false);

    useEffect(() => {
        loadUsers();
    }, [pagination.page, filter]);

    const loadUsers = async () => {
        setLoading(true);
        try {
            const response = await usersApi.list({
                page: pagination.page,
                search: search || undefined,
                user_type: filter === 'male' || filter === 'female' ? filter : undefined,
                account_status: filter === 'active' || filter === 'suspended' ? filter : undefined,
            });
            setUsers(Array.isArray(response.data.users) ? response.data.users : []);
            setPagination({
                page: response.data.pagination?.current_page || 1,
                lastPage: response.data.pagination?.last_page || 1,
                total: response.data.pagination?.total || 0,
            });
        } catch (error) {
            console.error('Load users error:', error);
            // Mock data for demo
            setUsers([
                { id: 1, name: 'Test Male User', user_type: 'male', phone: '99XXXXXX77', status: 'online', account_status: 'active', coin_balance: 100, created_at: '2025-12-06' },
                { id: 2, name: 'Test Female User', user_type: 'female', phone: '88XXXXXX66', status: 'online', account_status: 'pending', earning_balance: 0, created_at: '2025-12-06' },
            ]);
        } finally {
            setLoading(false);
        }
    };

    const handleSearch = (e) => {
        e.preventDefault();
        setPagination(p => ({ ...p, page: 1 }));
        loadUsers();
    };

    const handleStatusChange = async (userId, newStatus) => {
        try {
            await usersApi.updateStatus(userId, newStatus);
            loadUsers();
        } catch (error) {
            alert('Failed to update status');
        }
        setActionMenu(null);
    };

    const handleAddCoins = async () => {
        if (!coinsAmount || !addCoinsModal) return;

        try {
            await usersApi.addCoins(addCoinsModal.id, parseInt(coinsAmount), 'Admin added coins');
            loadUsers();
            setAddCoinsModal(null);
            setCoinsAmount('');
        } catch (error) {
            alert('Failed to add coins');
        }
    };

    const handleViewDetails = async (userId) => {
        setLoadingDetails(true);
        try {
            const response = await usersApi.get(userId);
            setUserDetailsModal(response.data.user);
        } catch (error) {
            alert('Failed to load user details');
        } finally {
            setLoadingDetails(false);
        }
    };

    const handleOpenEdit = async (userId) => {
        setLoadingDetails(true);
        try {
            const response = await usersApi.get(userId);
            const user = response.data.user;
            setEditUserModal(user);
            setEditFormData({
                name: user.name || '',
                phone: user.phone || '',
                age: user.age || '',
                bio: user.bio || '',
                coin_balance: user.coin_balance || 0,
                earning_balance: user.earning_balance || 0,
                bank_details: user.bank_details || {
                    account_name: '',
                    account_number: '',
                    ifsc: '',
                    bank_name: '',
                    upi_id: '',
                },
            });
        } catch (error) {
            alert('Failed to load user details for editing');
        } finally {
            setLoadingDetails(false);
        }
    };

    const handleUpdate = async (e) => {
        e.preventDefault();
        setUpdating(true);
        try {
            await usersApi.update(editUserModal.id, editFormData);
            alert('User updated successfully');
            setEditUserModal(null);
            loadUsers();
        } catch (error) {
            console.error('Update error:', error);
            alert(error.response?.data?.message || 'Failed to update user');
        } finally {
            setUpdating(false);
        }
    };

    const getStatusBadge = (status) => {
        const styles = {
            active: 'bg-green-100 text-green-700',
            pending: 'bg-yellow-100 text-yellow-700',
            suspended: 'bg-red-100 text-red-700',
        };
        return styles[status] || 'bg-gray-100 text-gray-700';
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                    <h2 className="text-xl font-bold text-gray-900">User Management</h2>
                    <p className="text-sm text-gray-500 mt-1">{pagination.total} total users</p>
                </div>
            </div>

            {/* Filters */}
            <div className="flex flex-col sm:flex-row gap-4">
                <form onSubmit={handleSearch} className="flex-1">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                        <input
                            type="text"
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                            placeholder="Search by name or phone..."
                            className="w-full pl-10 pr-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none"
                        />
                    </div>
                </form>

                <div className="flex items-center gap-2">
                    <Filter className="w-5 h-5 text-gray-400" />
                    <select
                        value={filter}
                        onChange={(e) => setFilter(e.target.value)}
                        className="px-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none bg-white"
                    >
                        <option value="all">All Users</option>
                        <option value="male">Males Only</option>
                        <option value="female">Females Only</option>
                        <option value="active">Active</option>
                        <option value="suspended">Suspended</option>
                    </select>
                </div>
            </div>

            {/* Table */}
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                {loading ? (
                    <div className="flex items-center justify-center h-64">
                        <Loader2 className="w-8 h-8 animate-spin text-[#6C5CE7]" />
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead className="bg-gray-50 border-b border-gray-100">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">User</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Balance</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Joined</th>
                                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase sticky right-0 bg-gray-50 z-10">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100">
                                {users.map((user) => (
                                    <tr key={user.id} className="group hover:bg-gray-50">
                                        <td className="px-6 py-4">
                                            <div className="flex items-center gap-3">
                                                <div className={`w-10 h-10 rounded-full flex items-center justify-center ${user.user_type === 'male' ? 'bg-blue-100' : 'bg-pink-100'}`}>
                                                    <User className={`w-5 h-5 ${user.user_type === 'male' ? 'text-blue-600' : 'text-pink-600'}`} />
                                                </div>
                                                <div>
                                                    <p className="font-medium text-gray-900">{user.name}</p>
                                                    <p className="text-sm text-gray-500">{user.phone}</p>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-medium ${user.user_type === 'male' ? 'bg-blue-100 text-blue-700' : 'bg-pink-100 text-pink-700'}`}>
                                                {user.user_type}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-medium ${getStatusBadge(user.account_status)}`}>
                                                {user.account_status}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-sm text-gray-900">
                                            {user.user_type === 'male'
                                                ? `${user.coin_balance || 0} coins`
                                                : `₹${user.earning_balance || 0}`
                                            }
                                        </td>
                                        <td className="px-6 py-4 text-sm text-gray-500">
                                            {new Date(user.created_at).toLocaleDateString()}
                                        </td>
                                        <td className="px-6 py-4 text-right sticky right-0 bg-white group-hover:bg-gray-50 z-10">
                                            <div className="relative">
                                                <button
                                                    onClick={() => setActionMenu(actionMenu === user.id ? null : user.id)}
                                                    className="p-2 hover:bg-gray-100 rounded-lg"
                                                >
                                                    <MoreVertical className="w-5 h-5 text-gray-400" />
                                                </button>

                                                {actionMenu === user.id && (
                                                    <>
                                                        <div className="fixed inset-0 z-40" onClick={() => setActionMenu(null)} />
                                                        <div className="absolute right-0 mt-1 w-48 bg-white rounded-lg shadow-lg border border-gray-200 py-1 z-50">
                                                            <button
                                                                onClick={() => { handleViewDetails(user.id); setActionMenu(null); }}
                                                                className="flex items-center gap-2 w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                                                            >
                                                                <User className="w-4 h-4" />
                                                                View Details
                                                            </button>
                                                            <button
                                                                onClick={() => { handleOpenEdit(user.id); setActionMenu(null); }}
                                                                className="flex items-center gap-2 w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                                                            >
                                                                <Pencil className="w-4 h-4" />
                                                                Edit Details
                                                            </button>
                                                            {user.user_type === 'male' && (
                                                                <button
                                                                    onClick={() => { setAddCoinsModal(user); setActionMenu(null); }}
                                                                    className="flex items-center gap-2 w-full px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                                                                >
                                                                    <Coins className="w-4 h-4" />
                                                                    Add Coins
                                                                </button>
                                                            )}
                                                            {user.account_status === 'active' ? (
                                                                <button
                                                                    onClick={() => handleStatusChange(user.id, 'suspended')}
                                                                    className="flex items-center gap-2 w-full px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                                                                >
                                                                    <Ban className="w-4 h-4" />
                                                                    Suspend User
                                                                </button>
                                                            ) : (
                                                                <button
                                                                    onClick={() => handleStatusChange(user.id, 'active')}
                                                                    className="flex items-center gap-2 w-full px-4 py-2 text-sm text-green-600 hover:bg-green-50"
                                                                >
                                                                    <Check className="w-4 h-4" />
                                                                    Activate User
                                                                </button>
                                                            )}
                                                        </div>
                                                    </>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}

                {/* Pagination */}
                {pagination.lastPage > 1 && (
                    <div className="flex items-center justify-between px-6 py-4 border-t border-gray-100">
                        <p className="text-sm text-gray-500">
                            Page {pagination.page} of {pagination.lastPage}
                        </p>
                        <div className="flex items-center gap-2">
                            <button
                                onClick={() => setPagination(p => ({ ...p, page: p.page - 1 }))}
                                disabled={pagination.page === 1}
                                className="p-2 rounded-lg border border-gray-300 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                            >
                                <ChevronLeft className="w-5 h-5" />
                            </button>
                            <button
                                onClick={() => setPagination(p => ({ ...p, page: p.page + 1 }))}
                                disabled={pagination.page === pagination.lastPage}
                                className="p-2 rounded-lg border border-gray-300 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                            >
                                <ChevronRight className="w-5 h-5" />
                            </button>
                        </div>
                    </div>
                )}
            </div>

            {/* Add/Subtract Coins Modal */}
            {addCoinsModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="bg-white rounded-xl p-6 w-full max-w-md mx-4">
                        <h3 className="text-lg font-semibold text-gray-900">
                            {parseInt(coinsAmount) < 0 ? 'Subtract Coins' : 'Add Coins'}
                        </h3>
                        <p className="text-sm text-gray-500 mt-1">
                            {parseInt(coinsAmount) < 0 ? 'Subtract' : 'Add'} coins {parseInt(coinsAmount) < 0 ? 'from' : 'to'} {addCoinsModal.name}'s account
                        </p>

                        <input
                            type="number"
                            value={coinsAmount}
                            onChange={(e) => setCoinsAmount(e.target.value)}
                            placeholder="Enter amount (use - for subtraction)"
                            className="w-full mt-4 px-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none"
                        />
                        <p className="text-[10px] text-gray-400 mt-1 italic">Example: 50 to add, -50 to subtract</p>

                        <div className="flex gap-3 mt-6">
                            <button
                                onClick={() => { setAddCoinsModal(null); setCoinsAmount(''); }}
                                className="flex-1 py-2.5 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50"
                            >
                                Cancel
                            </button>
                            <button
                                onClick={handleAddCoins}
                                className={`flex-1 py-2.5 text-white rounded-lg font-medium transition-colors ${parseInt(coinsAmount) < 0
                                    ? 'bg-red-600 hover:bg-red-700'
                                    : 'bg-[#6C5CE7] hover:bg-[#5A4BD5]'
                                    }`}
                            >
                                {parseInt(coinsAmount) < 0 ? 'Subtract' : 'Add'} Coins
                            </button>
                        </div>
                    </div>
                </div>
            )}
            {/* User Details Modal */}
            {userDetailsModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 overflow-y-auto pt-10 pb-10">
                    <div className="bg-white rounded-xl w-full max-w-2xl mx-4 my-auto">
                        <div className="flex items-center justify-between p-6 border-b border-gray-100">
                            <h3 className="text-xl font-bold text-gray-800">User Details</h3>
                            <button onClick={() => setUserDetailsModal(null)} className="p-2 hover:bg-gray-100 rounded-full">
                                <X className="w-6 h-6 text-gray-400" />
                            </button>
                        </div>

                        <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-8">
                            {/* Profile Info */}
                            <div className="space-y-4">
                                <div className="flex items-center gap-4 pb-4 border-b border-gray-50">
                                    <div className={`w-16 h-16 rounded-full flex items-center justify-center ${userDetailsModal.user_type === 'male' ? 'bg-blue-100' : 'bg-pink-100'}`}>
                                        <User className={`w-8 h-8 ${userDetailsModal.user_type === 'male' ? 'text-blue-600' : 'text-pink-600'}`} />
                                    </div>
                                    <div>
                                        <h4 className="text-lg font-bold text-gray-900">{userDetailsModal.name}</h4>
                                        <p className="text-gray-500">{userDetailsModal.phone}</p>
                                        <span className={`inline-flex px-2 py-0.5 mt-1 rounded-full text-xs font-semibold ${userDetailsModal.account_status === 'active' ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'}`}>
                                            {userDetailsModal.account_status}
                                        </span>
                                    </div>
                                </div>

                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <p className="text-xs text-gray-400 uppercase font-semibold">User Type</p>
                                        <p className="text-sm font-medium text-gray-800 capitalize">{userDetailsModal.user_type}</p>
                                    </div>
                                    <div>
                                        <p className="text-xs text-gray-400 uppercase font-semibold">Joined</p>
                                        <p className="text-sm font-medium text-gray-800">{new Date(userDetailsModal.created_at).toLocaleDateString()}</p>
                                    </div>
                                    <div>
                                        <p className="text-xs text-gray-400 uppercase font-semibold">Balance</p>
                                        <p className="text-sm font-medium text-gray-800">
                                            {userDetailsModal.user_type === 'male' ? `${userDetailsModal.coin_balance} coins` : `₹${userDetailsModal.earning_balance}`}
                                        </p>
                                    </div>
                                    <div>
                                        <p className="text-xs text-gray-400 uppercase font-semibold">Age</p>
                                        <p className="text-sm font-medium text-gray-800">{userDetailsModal.age || 'N/A'}</p>
                                    </div>
                                </div>

                                <div>
                                    <p className="text-xs text-gray-400 uppercase font-semibold">Bio</p>
                                    <p className="text-sm text-gray-700 italic">"{userDetailsModal.bio || 'No bio provided'}"</p>
                                </div>
                            </div>

                            {/* Bank Details / Stats */}
                            <div className="space-y-6">
                                {userDetailsModal.user_type === 'female' ? (
                                    <div className="bg-gray-50 rounded-xl p-5 border border-gray-100">
                                        <h5 className="text-sm font-bold text-gray-800 flex items-center gap-2 mb-4">
                                            <div className="p-1.5 bg-green-100 rounded-lg">
                                                <Wallet className="w-4 h-4 text-green-600" />
                                            </div>
                                            Bank Details
                                        </h5>

                                        {userDetailsModal.has_bank_details ? (
                                            <div className="space-y-3">
                                                <div>
                                                    <p className="text-[10px] text-gray-400 uppercase font-bold">Holder Name</p>
                                                    <p className="text-sm font-medium text-gray-900">{userDetailsModal.bank_details?.account_name}</p>
                                                </div>
                                                <div>
                                                    <p className="text-[10px] text-gray-400 uppercase font-bold">Account Number</p>
                                                    <p className="text-sm font-medium text-gray-900 font-mono tracking-wider">{userDetailsModal.bank_details?.account_number}</p>
                                                </div>
                                                <div className="grid grid-cols-2 gap-4">
                                                    <div>
                                                        <p className="text-[10px] text-gray-400 uppercase font-bold">IFSC Code</p>
                                                        <p className="text-sm font-medium text-gray-900">{userDetailsModal.bank_details?.ifsc}</p>
                                                    </div>
                                                    <div>
                                                        <p className="text-[10px] text-gray-400 uppercase font-bold">Bank Name</p>
                                                        <p className="text-sm font-medium text-gray-900">{userDetailsModal.bank_details?.bank_name}</p>
                                                    </div>
                                                </div>
                                                {userDetailsModal.bank_details?.upi_id && (
                                                    <div>
                                                        <p className="text-[10px] text-gray-400 uppercase font-bold">UPI ID</p>
                                                        <p className="text-sm font-medium text-[#6C5CE7]">{userDetailsModal.bank_details?.upi_id}</p>
                                                    </div>
                                                )}
                                            </div>
                                        ) : (
                                            <p className="text-sm text-gray-500 italic p-4 text-center">No bank details added yet.</p>
                                        )}
                                    </div>
                                ) : (
                                    <div className="bg-gray-50 rounded-xl p-5 border border-gray-100">
                                        <h5 className="text-sm font-bold text-gray-800 flex items-center gap-2 mb-4">
                                            <div className="p-1.5 bg-blue-100 rounded-lg">
                                                <Coins className="w-4 h-4 text-blue-600" />
                                            </div>
                                            Purchase Statistics
                                        </h5>
                                        <div className="space-y-3">
                                            <div className="flex justify-between items-center py-2 border-b border-gray-200">
                                                <span className="text-sm text-gray-500">Total Purchased</span>
                                                <span className="text-sm font-medium text-gray-900">{userDetailsModal.total_coins_purchased || 0} coins</span>
                                            </div>
                                            <div className="flex justify-between items-center py-2">
                                                <span className="text-sm text-gray-500">Total Spent</span>
                                                <span className="text-sm font-medium text-gray-900">{userDetailsModal.total_coins_spent || 0} coins</span>
                                            </div>
                                        </div>
                                    </div>
                                )}

                                <div className="bg-gray-50 rounded-xl p-5 border border-gray-100">
                                    <h5 className="text-sm font-bold text-gray-800 mb-4">Platform Activity</h5>
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="p-3 bg-white rounded-lg border border-gray-100 shadow-sm">
                                            <p className="text-[10px] text-gray-400 uppercase font-bold">Total Chats</p>
                                            <p className="text-lg font-bold text-gray-900">
                                                {userDetailsModal.user_type === 'male' ? userDetailsModal.chats_as_male_count : userDetailsModal.chats_as_female_count}
                                            </p>
                                        </div>
                                        <div className="p-3 bg-white rounded-lg border border-gray-100 shadow-sm">
                                            <p className="text-[10px] text-gray-400 uppercase font-bold">Reports</p>
                                            <p className="text-lg font-bold text-red-600">{userDetailsModal.reports_received_count || 0}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="flex justify-end gap-3 p-6 border-t border-gray-100 bg-gray-50 rounded-b-xl">
                            <button
                                onClick={() => setUserDetailsModal(null)}
                                className="px-6 py-2.5 bg-white border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition-colors shadow-sm"
                            >
                                Close
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Edit User Modal */}
            {editUserModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 overflow-y-auto pt-10 pb-10">
                    <div className="bg-white rounded-xl w-full max-w-2xl mx-4 my-auto">
                        <div className="flex items-center justify-between p-6 border-b border-gray-100">
                            <h3 className="text-xl font-bold text-gray-800 flex items-center gap-2">
                                <Pencil className="w-5 h-5 text-[#6C5CE7]" />
                                Edit User Profile
                            </h3>
                            <button onClick={() => setEditUserModal(null)} className="p-2 hover:bg-gray-100 rounded-full">
                                <X className="w-6 h-6 text-gray-400" />
                            </button>
                        </div>

                        <form onSubmit={handleUpdate}>
                            <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-6 max-h-[70vh] overflow-y-auto">
                                {/* Basic Information */}
                                <div className="space-y-4">
                                    <h4 className="text-sm font-bold text-gray-900 uppercase tracking-wider border-b pb-2">Basic Info</h4>
                                    <div>
                                        <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Full Name</label>
                                        <input
                                            type="text"
                                            value={editFormData.name}
                                            onChange={(e) => setEditFormData({ ...editFormData, name: e.target.value })}
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#6C5CE7] outline-none"
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Phone Number</label>
                                        <input
                                            type="text"
                                            value={editFormData.phone}
                                            onChange={(e) => setEditFormData({ ...editFormData, phone: e.target.value })}
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#6C5CE7] outline-none"
                                        />
                                    </div>
                                    <div className="grid grid-cols-2 gap-4">
                                        <div>
                                            <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Age</label>
                                            <input
                                                type="number"
                                                value={editFormData.age}
                                                onChange={(e) => setEditFormData({ ...editFormData, age: e.target.value })}
                                                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#6C5CE7] outline-none"
                                            />
                                        </div>
                                        <div>
                                            <label className="block text-xs font-bold text-gray-500 uppercase mb-1">
                                                {editUserModal.user_type === 'male' ? 'Coin Balance' : 'Earning Balance (₹)'}
                                            </label>
                                            <input
                                                type="number"
                                                value={editUserModal.user_type === 'male' ? editFormData.coin_balance : editFormData.earning_balance}
                                                onChange={(e) => {
                                                    const val = parseFloat(e.target.value);
                                                    if (editUserModal.user_type === 'male') {
                                                        setEditFormData({ ...editFormData, coin_balance: val });
                                                    } else {
                                                        setEditFormData({ ...editFormData, earning_balance: val });
                                                    }
                                                }}
                                                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#6C5CE7] outline-none"
                                            />
                                        </div>
                                    </div>
                                    <div>
                                        <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Bio</label>
                                        <textarea
                                            value={editFormData.bio}
                                            onChange={(e) => setEditFormData({ ...editFormData, bio: e.target.value })}
                                            rows={3}
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#6C5CE7] outline-none resize-none"
                                        />
                                    </div>
                                </div>

                                {/* Bank Details for Female Users */}
                                {editUserModal.user_type === 'female' && (
                                    <div className="space-y-4">
                                        <h4 className="text-sm font-bold text-gray-900 uppercase tracking-wider border-b pb-2">Bank Details</h4>
                                        <div>
                                            <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Account Holder Name</label>
                                            <input
                                                type="text"
                                                value={editFormData.bank_details?.account_name || ''}
                                                onChange={(e) => setEditFormData({
                                                    ...editFormData,
                                                    bank_details: { ...editFormData.bank_details, account_name: e.target.value }
                                                })}
                                                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#6C5CE7] outline-none"
                                            />
                                        </div>
                                        <div>
                                            <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Account Number</label>
                                            <input
                                                type="text"
                                                value={editFormData.bank_details?.account_number || ''}
                                                onChange={(e) => setEditFormData({
                                                    ...editFormData,
                                                    bank_details: { ...editFormData.bank_details, account_number: e.target.value }
                                                })}
                                                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#6C5CE7] outline-none"
                                            />
                                        </div>
                                        <div>
                                            <label className="block text-xs font-bold text-gray-500 uppercase mb-1">IFSC Code</label>
                                            <input
                                                type="text"
                                                value={editFormData.bank_details?.ifsc || ''}
                                                onChange={(e) => setEditFormData({
                                                    ...editFormData,
                                                    bank_details: { ...editFormData.bank_details, ifsc: e.target.value.toUpperCase() }
                                                })}
                                                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#6C5CE7] outline-none"
                                            />
                                        </div>
                                        <div>
                                            <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Bank Name</label>
                                            <input
                                                type="text"
                                                value={editFormData.bank_details?.bank_name || ''}
                                                onChange={(e) => setEditFormData({
                                                    ...editFormData,
                                                    bank_details: { ...editFormData.bank_details, bank_name: e.target.value }
                                                })}
                                                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#6C5CE7] outline-none"
                                            />
                                        </div>
                                        <div>
                                            <label className="block text-xs font-bold text-gray-500 uppercase mb-1">UPI ID</label>
                                            <input
                                                type="text"
                                                value={editFormData.bank_details?.upi_id || ''}
                                                onChange={(e) => setEditFormData({
                                                    ...editFormData,
                                                    bank_details: { ...editFormData.bank_details, upi_id: e.target.value }
                                                })}
                                                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#6C5CE7] outline-none"
                                            />
                                        </div>
                                    </div>
                                )}
                            </div>

                            <div className="flex justify-end gap-3 p-6 border-t border-gray-100 bg-gray-50 rounded-b-xl">
                                <button
                                    type="button"
                                    onClick={() => setEditUserModal(null)}
                                    className="px-6 py-2.5 bg-white border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition-colors shadow-sm"
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    disabled={updating}
                                    className="flex items-center gap-2 px-6 py-2.5 bg-[#6C5CE7] text-white rounded-lg font-medium hover:bg-[#5A4BD5] transition-colors shadow-sm disabled:opacity-50"
                                >
                                    {updating ? (
                                        <Loader2 className="w-4 h-4 animate-spin" />
                                    ) : (
                                        <Save className="w-4 h-4" />
                                    )}
                                    {updating ? 'Saving...' : 'Save Changes'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Loading Overlay for Details */}
            {loadingDetails && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/20">
                    <div className="bg-white p-6 rounded-xl shadow-xl flex items-center gap-4">
                        <Loader2 className="w-6 h-6 animate-spin text-[#6C5CE7]" />
                        <p className="font-medium text-gray-700">Loading user info...</p>
                    </div>
                </div>
            )}
        </div>
    );
}
