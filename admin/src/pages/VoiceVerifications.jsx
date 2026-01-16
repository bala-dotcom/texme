import { useState, useEffect, useRef } from 'react';
import api from '../api/client';

export default function VoiceVerifications() {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('pending'); // pending, verified, rejected
    const [playingId, setPlayingId] = useState(null);
    const audioRef = useRef(null);

    useEffect(() => {
        fetchUsers();
    }, [filter]);

    const fetchUsers = async () => {
        setLoading(true);
        try {
            const response = await api.get(`/admin/voice-verifications?status=${filter}`);
            if (response.data.success) {
                setUsers(response.data.data);
            }
        } catch (error) {
            console.error('Failed to fetch users:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleVerify = async (userId) => {
        try {
            const response = await api.post(`/admin/voice-verifications/${userId}/verify`);
            if (response.data.success) {
                fetchUsers();
            }
        } catch (error) {
            console.error('Failed to verify:', error);
            alert('Failed to verify user');
        }
    };

    const handleReject = async (userId) => {
        const reason = prompt('Enter rejection reason (optional):');
        try {
            const response = await api.post(`/admin/voice-verifications/${userId}/reject`, {
                reason: reason || 'Voice verification failed'
            });
            if (response.data.success) {
                fetchUsers();
            }
        } catch (error) {
            console.error('Failed to reject:', error);
            alert('Failed to reject user');
        }
    };

    const playAudio = (userId, audioUrl) => {
        if (playingId === userId) {
            // Stop playing
            audioRef.current?.pause();
            setPlayingId(null);
        } else {
            // Start playing
            if (audioRef.current) {
                audioRef.current.src = audioUrl;
                audioRef.current.play();
                setPlayingId(userId);
            }
        }
    };

    const handleAudioEnded = () => {
        setPlayingId(null);
    };

    const getStatusBadge = (status) => {
        switch (status) {
            case 'pending':
                return <span className="px-2 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-800">Pending</span>;
            case 'verified':
                return <span className="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">Verified</span>;
            case 'rejected':
                return <span className="px-2 py-1 text-xs font-medium rounded-full bg-red-100 text-red-800">Rejected</span>;
            default:
                return <span className="px-2 py-1 text-xs font-medium rounded-full bg-gray-100 text-gray-800">None</span>;
        }
    };

    return (
        <div className="p-6">
            {/* Hidden audio element */}
            <audio ref={audioRef} onEnded={handleAudioEnded} />

            {/* Header */}
            <div className="mb-6">
                <h1 className="text-2xl font-bold text-gray-900">Voice Verifications</h1>
                <p className="text-gray-600">Review and verify female user voice samples</p>
            </div>

            {/* Filter Tabs */}
            <div className="flex space-x-2 mb-6">
                <button
                    onClick={() => setFilter('pending')}
                    className={`px-4 py-2 rounded-lg font-medium transition-colors ${filter === 'pending'
                        ? 'bg-yellow-500 text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                        }`}
                >
                    Pending
                </button>
                <button
                    onClick={() => setFilter('verified')}
                    className={`px-4 py-2 rounded-lg font-medium transition-colors ${filter === 'verified'
                        ? 'bg-green-500 text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                        }`}
                >
                    Verified
                </button>
                <button
                    onClick={() => setFilter('rejected')}
                    className={`px-4 py-2 rounded-lg font-medium transition-colors ${filter === 'rejected'
                        ? 'bg-red-500 text-white'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                        }`}
                >
                    Rejected
                </button>
            </div>

            {/* Users Table */}
            {loading ? (
                <div className="flex justify-center py-12">
                    <div className="w-8 h-8 border-4 border-[#6C5CE7] border-t-transparent rounded-full animate-spin" />
                </div>
            ) : users.length === 0 ? (
                <div className="text-center py-12 bg-white rounded-lg shadow">
                    <svg className="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                    </svg>
                    <p className="text-gray-500">No {filter} voice verifications found</p>
                </div>
            ) : (
                <div className="bg-white rounded-lg shadow overflow-hidden">
                    <table className="min-w-full divide-y divide-gray-200">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    User
                                </th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Phone
                                </th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Voice Sample
                                </th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Status
                                </th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Submitted
                                </th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    Actions
                                </th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-gray-200">
                            {users.map((user) => (
                                <tr key={user.id} className="hover:bg-gray-50">
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="flex items-center">
                                            <div className="w-10 h-10 rounded-full bg-gray-200 overflow-hidden">
                                                {user.avatar ? (
                                                    <img src={user.avatar} alt={user.name} className="w-full h-full object-cover" />
                                                ) : (
                                                    <div className="w-full h-full flex items-center justify-center text-gray-400">
                                                        <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                                                            <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z" />
                                                        </svg>
                                                    </div>
                                                )}
                                            </div>
                                            <div className="ml-4">
                                                <div className="text-sm font-medium text-gray-900">{user.name}</div>
                                                <div className="text-sm text-gray-500">ID: {user.id}</div>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        {user.phone}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        {user.voice_verification_url ? (
                                            <button
                                                onClick={() => playAudio(user.id, user.voice_verification_url)}
                                                className={`flex items-center space-x-2 px-3 py-2 rounded-lg transition-colors ${playingId === user.id
                                                    ? 'bg-[#6C5CE7] text-white'
                                                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                                                    }`}
                                            >
                                                {playingId === user.id ? (
                                                    <>
                                                        <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                                                            <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z" />
                                                        </svg>
                                                        <span>Stop</span>
                                                    </>
                                                ) : (
                                                    <>
                                                        <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                                                            <path d="M8 5v14l11-7z" />
                                                        </svg>
                                                        <span>Play</span>
                                                    </>
                                                )}
                                            </button>
                                        ) : (
                                            <span className="text-gray-400 text-sm">No recording</span>
                                        )}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        {getStatusBadge(user.voice_status)}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        {new Date(user.created_at).toLocaleDateString()}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm">
                                        {filter === 'pending' && (
                                            <div className="flex space-x-2">
                                                <button
                                                    onClick={() => handleVerify(user.id)}
                                                    className="px-3 py-1 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors"
                                                >
                                                    Verify
                                                </button>
                                                <button
                                                    onClick={() => handleReject(user.id)}
                                                    className="px-3 py-1 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors"
                                                >
                                                    Reject
                                                </button>
                                            </div>
                                        )}
                                        {filter === 'verified' && (
                                            <span className="text-green-600 font-medium">✓ Approved</span>
                                        )}
                                        {filter === 'rejected' && (
                                            <button
                                                onClick={() => handleVerify(user.id)}
                                                className="px-3 py-1 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
                                            >
                                                Re-verify
                                            </button>
                                        )}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
}
