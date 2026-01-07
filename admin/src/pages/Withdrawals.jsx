import { useState, useEffect } from 'react';
import { withdrawalsApi } from '../api/client';
import {
    Wallet,
    Check,
    X,
    Loader2,
    Clock,
    CheckCircle,
    XCircle,
    ChevronLeft,
    ChevronRight,
    Eye,
    User,
    Copy,
} from 'lucide-react';

export default function Withdrawals() {
    const [withdrawals, setWithdrawals] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('pending'); // pending, approved, completed, rejected
    const [pagination, setPagination] = useState({ page: 1, lastPage: 1, total: 0 });
    const [processingId, setProcessingId] = useState(null);
    const [completeModal, setCompleteModal] = useState(null);
    const [transactionId, setTransactionId] = useState('');
    const [rejectModal, setRejectModal] = useState(null);
    const [rejectReason, setRejectReason] = useState('');
    const [viewDetailsModal, setViewDetailsModal] = useState(null);
    const [loadingDetails, setLoadingDetails] = useState(false);

    useEffect(() => {
        loadWithdrawals();
    }, [pagination.page, filter]);

    const loadWithdrawals = async () => {
        setLoading(true);
        try {
            const response = filter === 'pending'
                ? await withdrawalsApi.pending()
                : await withdrawalsApi.list({ page: pagination.page, status: filter !== 'all' ? filter : undefined });

            const data = response.data.withdrawals;
            setWithdrawals(Array.isArray(data) ? data : data?.data || []);
            if (!Array.isArray(data) && data?.last_page) {
                setPagination({
                    page: data.current_page,
                    lastPage: data.last_page,
                    total: data.total,
                });
            }
        } catch (error) {
            console.error('Load withdrawals error:', error);
            // Mock data
            setWithdrawals([
                { id: 1, user: { name: 'Female User 1' }, amount: 500, status: 'pending', created_at: '2025-12-06' },
            ]);
        } finally {
            setLoading(false);
        }
    };

    const handleApprove = async (id) => {
        setProcessingId(id);
        try {
            await withdrawalsApi.approve(id);
            loadWithdrawals();
        } catch (error) {
            alert('Failed to approve withdrawal');
        } finally {
            setProcessingId(null);
        }
    };

    const handleComplete = async () => {
        if (!completeModal || !transactionId) return;

        setProcessingId(completeModal.id);
        try {
            await withdrawalsApi.complete(completeModal.id, transactionId);
            loadWithdrawals();
            setCompleteModal(null);
            setTransactionId('');
        } catch (error) {
            alert('Failed to complete withdrawal');
        } finally {
            setProcessingId(null);
        }
    };

    const handleReject = async () => {
        if (!rejectModal) return;

        setProcessingId(rejectModal.id);
        try {
            await withdrawalsApi.reject(rejectModal.id, rejectReason);
            loadWithdrawals();
            setRejectModal(null);
            setRejectReason('');
        } catch (error) {
            alert('Failed to reject withdrawal');
        } finally {
            setProcessingId(null);
        }
    };

    const handleViewDetails = async (id) => {
        setLoadingDetails(true);
        try {
            const response = await withdrawalsApi.get(id);
            setViewDetailsModal(response.data.withdrawal);
        } catch (error) {
            alert('Failed to load withdrawal details');
        } finally {
            setLoadingDetails(false);
        }
    };

    const getStatusBadge = (status) => {
        const config = {
            pending: { bg: 'bg-yellow-100', text: 'text-yellow-700', icon: Clock },
            approved: { bg: 'bg-blue-100', text: 'text-blue-700', icon: CheckCircle },
            completed: { bg: 'bg-green-100', text: 'text-green-700', icon: CheckCircle },
            rejected: { bg: 'bg-red-100', text: 'text-red-700', icon: XCircle },
        };
        return config[status] || config.pending;
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                    <h2 className="text-xl font-bold text-gray-900">Withdrawals</h2>
                    <p className="text-sm text-gray-500 mt-1">Manage withdrawal requests</p>
                </div>
            </div>

            {/* Filter Tabs */}
            <div className="flex gap-2 border-b border-gray-200">
                {['pending', 'approved', 'completed', 'rejected'].map((status) => (
                    <button
                        key={status}
                        onClick={() => { setFilter(status); setPagination(p => ({ ...p, page: 1 })); }}
                        className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors ${filter === status
                            ? 'border-[#6C5CE7] text-[#6C5CE7]'
                            : 'border-transparent text-gray-500 hover:text-gray-700'
                            }`}
                    >
                        {status.charAt(0).toUpperCase() + status.slice(1)}
                    </button>
                ))}
            </div>

            {/* Table */}
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                {loading ? (
                    <div className="flex items-center justify-center h-64">
                        <Loader2 className="w-8 h-8 animate-spin text-[#6C5CE7]" />
                    </div>
                ) : withdrawals.length === 0 ? (
                    <div className="p-12 text-center">
                        <Wallet className="w-12 h-12 text-gray-300 mx-auto" />
                        <p className="text-gray-500 mt-4">No {filter} withdrawal requests</p>
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead className="bg-gray-50 border-b border-gray-100">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">User</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Amount</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Requested</th>
                                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100">
                                {withdrawals.map((withdrawal) => {
                                    const statusConfig = getStatusBadge(withdrawal.status);
                                    const StatusIcon = statusConfig.icon;

                                    return (
                                        <tr key={withdrawal.id} className="hover:bg-gray-50">
                                            <td className="px-6 py-4 text-sm font-medium text-gray-900">
                                                #{withdrawal.id}
                                            </td>
                                            <td className="px-6 py-4">
                                                <p className="font-medium text-gray-900">{withdrawal.user?.name || 'Unknown'}</p>
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className="text-lg font-semibold text-green-600">
                                                    ₹{withdrawal.amount?.toLocaleString() || 0}
                                                </span>
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${statusConfig.bg} ${statusConfig.text}`}>
                                                    <StatusIcon className="w-3.5 h-3.5" />
                                                    {withdrawal.status}
                                                </span>
                                            </td>
                                            <td className="px-6 py-4 text-sm text-gray-500">
                                                {new Date(withdrawal.created_at).toLocaleDateString()}
                                            </td>
                                            <td className="px-6 py-4 text-right">
                                                <div className="flex items-center justify-end gap-2">
                                                    {withdrawal.status === 'pending' && (
                                                        <>
                                                            <button
                                                                onClick={() => setRejectModal(withdrawal)}
                                                                disabled={processingId === withdrawal.id}
                                                                className="p-2 text-red-600 hover:bg-red-50 rounded-lg"
                                                                title="Reject"
                                                            >
                                                                <X className="w-5 h-5" />
                                                            </button>
                                                            <button
                                                                onClick={() => handleApprove(withdrawal.id)}
                                                                disabled={processingId === withdrawal.id}
                                                                className="p-2 text-green-600 hover:bg-green-50 rounded-lg"
                                                                title="Approve"
                                                            >
                                                                {processingId === withdrawal.id ? (
                                                                    <Loader2 className="w-5 h-5 animate-spin" />
                                                                ) : (
                                                                    <Check className="w-5 h-5" />
                                                                )}
                                                            </button>
                                                        </>
                                                    )}
                                                    {withdrawal.status === 'approved' && (
                                                        <button
                                                            onClick={() => setCompleteModal(withdrawal)}
                                                            className="px-3 py-1.5 bg-[#6C5CE7] text-white text-sm font-medium rounded-lg hover:bg-[#5A4BD5]"
                                                        >
                                                            Mark Complete
                                                        </button>
                                                    )}
                                                    <button
                                                        onClick={() => handleViewDetails(withdrawal.id)}
                                                        className="p-2 text-gray-400 hover:bg-gray-100 rounded-lg"
                                                        title="View Details"
                                                    >
                                                        <Eye className="w-5 h-5" />
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    );
                                })}
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
                                className="p-2 rounded-lg border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
                            >
                                <ChevronLeft className="w-5 h-5" />
                            </button>
                            <button
                                onClick={() => setPagination(p => ({ ...p, page: p.page + 1 }))}
                                disabled={pagination.page === pagination.lastPage}
                                className="p-2 rounded-lg border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
                            >
                                <ChevronRight className="w-5 h-5" />
                            </button>
                        </div>
                    </div>
                )}
            </div>

            {/* Complete Modal */}
            {completeModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="bg-white rounded-xl p-6 w-full max-w-md mx-4">
                        <h3 className="text-lg font-semibold text-gray-900">Complete Withdrawal</h3>
                        <p className="text-sm text-gray-500 mt-1">
                            Enter the transaction reference ID for ₹{completeModal.amount}
                        </p>

                        <input
                            type="text"
                            value={transactionId}
                            onChange={(e) => setTransactionId(e.target.value)}
                            placeholder="Transaction ID / UTR Number"
                            className="w-full mt-4 px-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none"
                        />

                        <div className="flex gap-3 mt-6">
                            <button
                                onClick={() => { setCompleteModal(null); setTransactionId(''); }}
                                className="flex-1 py-2.5 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50"
                            >
                                Cancel
                            </button>
                            <button
                                onClick={handleComplete}
                                disabled={!transactionId || processingId === completeModal.id}
                                className="flex-1 py-2.5 bg-green-600 text-white rounded-lg font-medium hover:bg-green-700 disabled:opacity-50"
                            >
                                {processingId === completeModal.id ? 'Processing...' : 'Complete'}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Reject Modal */}
            {rejectModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="bg-white rounded-xl p-6 w-full max-w-md mx-4">
                        <h3 className="text-lg font-semibold text-gray-900">Reject Withdrawal</h3>
                        <p className="text-sm text-gray-500 mt-1">
                            Provide a reason for rejecting this withdrawal request
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
                                {processingId === rejectModal.id ? 'Rejecting...' : 'Reject'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
            {/* View Details Modal */}
            {viewDetailsModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 overflow-y-auto pt-10 pb-10">
                    <div className="bg-white rounded-xl w-full max-w-lg mx-4 my-auto">
                        <div className="flex items-center justify-between p-6 border-b border-gray-100">
                            <h3 className="text-xl font-bold text-gray-800">Withdrawal Details</h3>
                            <button onClick={() => setViewDetailsModal(null)} className="p-2 hover:bg-gray-100 rounded-full">
                                <X className="w-6 h-6 text-gray-400" />
                            </button>
                        </div>

                        <div className="p-6 space-y-6">
                            {/* User Info */}
                            <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl border border-gray-100">
                                <div className="w-12 h-12 bg-[#6C5CE7]/10 rounded-full flex items-center justify-center">
                                    <User className="w-6 h-6 text-[#6C5CE7]" />
                                </div>
                                <div className="flex-1">
                                    <h4 className="font-bold text-gray-900">{viewDetailsModal.user_name}</h4>
                                    <p className="text-sm text-gray-500">{viewDetailsModal.user_phone}</p>
                                </div>
                                <div className="text-right">
                                    <p className="text-xs text-gray-400 uppercase font-bold">Amount</p>
                                    <p className="text-lg font-bold text-green-600">₹{viewDetailsModal.amount}</p>
                                </div>
                            </div>

                            {/* Bank Details */}
                            <div className="space-y-4">
                                <h5 className="text-sm font-bold text-gray-800 uppercase tracking-wider">Recipient Bank Account</h5>

                                <div className="grid grid-cols-1 gap-4">
                                    <div className="p-4 border border-gray-100 rounded-xl space-y-3">
                                        <div className="flex justify-between items-center group">
                                            <div>
                                                <p className="text-[10px] text-gray-400 uppercase font-bold">Account Holder</p>
                                                <p className="text-sm font-medium text-gray-900 uppercase">{viewDetailsModal.bank_details?.account_name}</p>
                                            </div>
                                            <button
                                                onClick={() => {
                                                    navigator.clipboard.writeText(viewDetailsModal.bank_details?.account_name);
                                                    // Optional: add a toast
                                                }}
                                                className="p-1.5 opacity-0 group-hover:opacity-100 text-gray-400 hover:text-[#6C5CE7] transition-all"
                                            >
                                                <Copy className="w-4 h-4" />
                                            </button>
                                        </div>

                                        <div className="flex justify-between items-center group">
                                            <div>
                                                <p className="text-[10px] text-gray-400 uppercase font-bold">Account Number</p>
                                                <p className="text-base font-bold text-gray-900 font-mono tracking-widest">{viewDetailsModal.bank_details?.account_number}</p>
                                            </div>
                                            <button
                                                onClick={() => navigator.clipboard.writeText(viewDetailsModal.bank_details?.account_number)}
                                                className="p-1.5 opacity-0 group-hover:opacity-100 text-gray-400 hover:text-[#6C5CE7] transition-all"
                                            >
                                                <Copy className="w-4 h-4" />
                                            </button>
                                        </div>

                                        <div className="grid grid-cols-2 gap-4 pt-2 border-t border-gray-50">
                                            <div>
                                                <p className="text-[10px] text-gray-400 uppercase font-bold">IFSC Code</p>
                                                <p className="text-sm font-medium text-gray-900">{viewDetailsModal.bank_details?.ifsc}</p>
                                            </div>
                                            <div>
                                                <p className="text-[10px] text-gray-400 uppercase font-bold">Bank Name</p>
                                                <p className="text-sm font-medium text-gray-900">{viewDetailsModal.bank_details?.bank_name}</p>
                                            </div>
                                        </div>

                                        {viewDetailsModal.bank_details?.upi_id && (
                                            <div className="pt-2 border-t border-gray-50 flex justify-between items-center group">
                                                <div>
                                                    <p className="text-[10px] text-gray-400 uppercase font-bold">UPI ID</p>
                                                    <p className="text-sm font-medium text-[#6C5CE7]">{viewDetailsModal.bank_details?.upi_id}</p>
                                                </div>
                                                <button
                                                    onClick={() => navigator.clipboard.writeText(viewDetailsModal.bank_details?.upi_id)}
                                                    className="p-1.5 opacity-0 group-hover:opacity-100 text-gray-400 hover:text-[#6C5CE7] transition-all"
                                                >
                                                    <Copy className="w-4 h-4" />
                                                </button>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </div>

                            {/* Meta Info */}
                            <div className="grid grid-cols-2 gap-4 text-xs text-gray-500 pt-2">
                                <div>
                                    <p className="font-semibold uppercase text-gray-400 text-[10px]">Requested On</p>
                                    <p>{new Date(viewDetailsModal.created_at).toLocaleString()}</p>
                                </div>
                                <div>
                                    <p className="font-semibold uppercase text-gray-400 text-[10px]">Current Status</p>
                                    <p className="capitalize font-bold text-[#6C5CE7]">{viewDetailsModal.status}</p>
                                </div>
                            </div>

                            {viewDetailsModal.admin_notes && (
                                <div className="p-3 bg-red-50 border border-red-100 rounded-lg">
                                    <p className="text-[10px] text-red-400 uppercase font-bold">Rejection Reason</p>
                                    <p className="text-xs text-red-700 mt-0.5">{viewDetailsModal.admin_notes}</p>
                                </div>
                            )}
                        </div>

                        <div className="flex justify-end gap-3 p-6 border-t border-gray-100 bg-gray-50 rounded-b-xl">
                            <button
                                onClick={() => setViewDetailsModal(null)}
                                className="px-6 py-2.5 bg-white border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-100 transition-colors shadow-sm"
                            >
                                Close
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Loading Overlay for Details */}
            {loadingDetails && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/20">
                    <div className="bg-white p-6 rounded-xl shadow-xl flex items-center gap-4">
                        <Loader2 className="w-6 h-6 animate-spin text-[#6C5CE7]" />
                        <p className="font-medium text-gray-700">Loading details...</p>
                    </div>
                </div>
            )}
        </div>
    );
}
