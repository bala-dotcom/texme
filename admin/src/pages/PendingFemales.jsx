import { useState, useEffect } from 'react';
import { usersApi } from '../api/client';
import {
    User,
    Check,
    X,
    Loader2,
    Calendar,
    MapPin,
    Phone,
} from 'lucide-react';

export default function PendingFemales() {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [processingId, setProcessingId] = useState(null);
    const [rejectModal, setRejectModal] = useState(null);
    const [rejectReason, setRejectReason] = useState('');

    useEffect(() => {
        loadPendingFemales();
    }, []);

    const loadPendingFemales = async () => {
        setLoading(true);
        try {
            const response = await usersApi.pendingFemales();
            setUsers(response.data.users || []);
        } catch (error) {
            console.error('Load pending females error:', error);
            // Mock data
            setUsers([
                {
                    id: 3,
                    name: 'Test Female User',
                    phone: '88XXXXXX66',
                    age: 24,
                    bio: 'Hello there!',
                    avatar: null,
                    location: 'Mumbai',
                    created_at: '2025-12-06T08:45:00Z'
                },
            ]);
        } finally {
            setLoading(false);
        }
    };

    const handleApprove = async (userId) => {
        setProcessingId(userId);
        try {
            await usersApi.approveFemale(userId);
            setUsers(users.filter(u => u.id !== userId));
        } catch (error) {
            alert('Failed to approve user');
        } finally {
            setProcessingId(null);
        }
    };

    const handleReject = async () => {
        if (!rejectModal) return;

        setProcessingId(rejectModal.id);
        try {
            await usersApi.rejectFemale(rejectModal.id, rejectReason);
            setUsers(users.filter(u => u.id !== rejectModal.id));
            setRejectModal(null);
            setRejectReason('');
        } catch (error) {
            alert('Failed to reject user');
        } finally {
            setProcessingId(null);
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-96">
                <Loader2 className="w-8 h-8 animate-spin text-[#6C5CE7]" />
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div>
                <h2 className="text-xl font-bold text-gray-900">Pending Female Approvals</h2>
                <p className="text-sm text-gray-500 mt-1">
                    {users.length === 0
                        ? 'No pending approvals'
                        : `${users.length} profile${users.length > 1 ? 's' : ''} waiting for approval`
                    }
                </p>
            </div>

            {/* Empty State */}
            {users.length === 0 && (
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-12 text-center">
                    <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mx-auto">
                        <Check className="w-8 h-8 text-green-600" />
                    </div>
                    <h3 className="text-lg font-medium text-gray-900 mt-4">All caught up!</h3>
                    <p className="text-gray-500 mt-1">No pending female profiles to approve</p>
                </div>
            )}

            {/* Cards Grid */}
            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                {users.map((user) => (
                    <div key={user.id} className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                        {/* Avatar */}
                        <div className="aspect-square bg-gradient-to-br from-pink-100 to-purple-100 flex items-center justify-center">
                            {user.avatar ? (
                                <img src={user.avatar} alt={user.name} className="w-full h-full object-cover" />
                            ) : (
                                <User className="w-24 h-24 text-pink-300" />
                            )}
                        </div>

                        {/* Details */}
                        <div className="p-4">
                            <h3 className="font-semibold text-lg text-gray-900">{user.name}</h3>

                            <div className="mt-3 space-y-2">
                                {user.age && (
                                    <div className="flex items-center gap-2 text-sm text-gray-600">
                                        <Calendar className="w-4 h-4 text-gray-400" />
                                        {user.age} years old
                                    </div>
                                )}
                                {user.location && (
                                    <div className="flex items-center gap-2 text-sm text-gray-600">
                                        <MapPin className="w-4 h-4 text-gray-400" />
                                        {user.location}
                                    </div>
                                )}
                                <div className="flex items-center gap-2 text-sm text-gray-600">
                                    <Phone className="w-4 h-4 text-gray-400" />
                                    {user.phone}
                                </div>
                            </div>

                            {user.bio && (
                                <p className="mt-3 text-sm text-gray-600 line-clamp-3">{user.bio}</p>
                            )}

                            <p className="mt-3 text-xs text-gray-400">
                                Applied: {new Date(user.created_at).toLocaleDateString()}
                            </p>

                            {/* Actions */}
                            <div className="flex gap-3 mt-4">
                                <button
                                    onClick={() => setRejectModal(user)}
                                    disabled={processingId === user.id}
                                    className="flex-1 py-2.5 border border-red-300 text-red-600 rounded-lg font-medium hover:bg-red-50 disabled:opacity-50 flex items-center justify-center gap-2"
                                >
                                    <X className="w-4 h-4" />
                                    Reject
                                </button>
                                <button
                                    onClick={() => handleApprove(user.id)}
                                    disabled={processingId === user.id}
                                    className="flex-1 py-2.5 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 disabled:opacity-50 flex items-center justify-center gap-2"
                                >
                                    {processingId === user.id ? (
                                        <Loader2 className="w-4 h-4 animate-spin" />
                                    ) : (
                                        <Check className="w-4 h-4" />
                                    )}
                                    Approve
                                </button>
                            </div>
                        </div>
                    </div>
                ))}
            </div>

            {/* Reject Modal */}
            {rejectModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="bg-white rounded-xl p-6 w-full max-w-md mx-4">
                        <h3 className="text-lg font-semibold text-gray-900">Reject Profile</h3>
                        <p className="text-sm text-gray-500 mt-1">
                            Provide a reason for rejecting {rejectModal.name}'s profile
                        </p>

                        <textarea
                            value={rejectReason}
                            onChange={(e) => setRejectReason(e.target.value)}
                            placeholder="Enter rejection reason..."
                            rows={3}
                            className="w-full mt-4 px-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none resize-none"
                        />

                        <div className="flex gap-3 mt-6">
                            <button
                                onClick={() => { setRejectModal(null); setRejectReason(''); }}
                                className="flex-1 py-2.5 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50"
                            >
                                Cancel
                            </button>
                            <button
                                onClick={handleReject}
                                disabled={processingId === rejectModal.id}
                                className="flex-1 py-2.5 bg-red-600 text-white rounded-lg font-medium hover:bg-red-700 disabled:opacity-50"
                            >
                                {processingId === rejectModal.id ? 'Rejecting...' : 'Reject Profile'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
