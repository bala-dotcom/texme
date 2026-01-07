import { useState, useEffect } from 'react';
import { reportsApi } from '../api/client';
import {
    Flag,
    AlertTriangle,
    Ban,
    MessageSquare,
    Loader2,
    X,
    Eye,
    ChevronLeft,
    ChevronRight,
} from 'lucide-react';

export default function Reports() {
    const [reports, setReports] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('pending');
    const [pagination, setPagination] = useState({ page: 1, lastPage: 1, total: 0 });
    const [processingId, setProcessingId] = useState(null);
    const [actionModal, setActionModal] = useState(null);
    const [actionType, setActionType] = useState(null);
    const [actionInput, setActionInput] = useState('');

    useEffect(() => {
        loadReports();
    }, [pagination.page, filter]);

    const loadReports = async () => {
        setLoading(true);
        try {
            const response = filter === 'pending'
                ? await reportsApi.pending()
                : await reportsApi.list({ page: pagination.page, status: filter !== 'all' ? filter : undefined });

            const data = response.data.reports;
            setReports(Array.isArray(data) ? data : data?.data || []);
        } catch (error) {
            console.error('Load reports error:', error);
            // Mock data
            setReports([
                {
                    id: 1,
                    reporter: { name: 'User A' },
                    reported_user: { name: 'User B' },
                    reason: 'Inappropriate behavior',
                    description: 'Used offensive language',
                    status: 'pending',
                    created_at: '2025-12-06'
                },
            ]);
        } finally {
            setLoading(false);
        }
    };

    const handleDismiss = async (id) => {
        setProcessingId(id);
        try {
            await reportsApi.dismiss(id);
            loadReports();
        } catch (error) {
            alert('Failed to dismiss report');
        } finally {
            setProcessingId(null);
        }
    };

    const handleAction = async () => {
        if (!actionModal || !actionType) return;

        setProcessingId(actionModal.id);
        try {
            switch (actionType) {
                case 'warn':
                    await reportsApi.warn(actionModal.id, actionInput);
                    break;
                case 'suspend':
                    await reportsApi.suspend(actionModal.id, parseInt(actionInput) || 7);
                    break;
                case 'ban':
                    await reportsApi.ban(actionModal.id, actionInput);
                    break;
            }
            loadReports();
            setActionModal(null);
            setActionType(null);
            setActionInput('');
        } catch (error) {
            alert('Failed to take action');
        } finally {
            setProcessingId(null);
        }
    };

    const getStatusBadge = (status) => {
        const styles = {
            pending: 'bg-yellow-100 text-yellow-700',
            resolved: 'bg-green-100 text-green-700',
            dismissed: 'bg-gray-100 text-gray-700',
        };
        return styles[status] || 'bg-gray-100 text-gray-700';
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div>
                <h2 className="text-xl font-bold text-gray-900">User Reports</h2>
                <p className="text-sm text-gray-500 mt-1">Review and manage reported users</p>
            </div>

            {/* Filter Tabs */}
            <div className="flex gap-2 border-b border-gray-200">
                {['pending', 'resolved', 'dismissed'].map((status) => (
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
                ) : reports.length === 0 ? (
                    <div className="p-12 text-center">
                        <Flag className="w-12 h-12 text-gray-300 mx-auto" />
                        <p className="text-gray-500 mt-4">No {filter} reports</p>
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead className="bg-gray-50 border-b border-gray-100">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Reporter</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Reported User</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Reason</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100">
                                {reports.map((report) => (
                                    <tr key={report.id} className="hover:bg-gray-50">
                                        <td className="px-6 py-4 text-sm text-gray-900">
                                            {report.reporter?.name || 'Unknown'}
                                        </td>
                                        <td className="px-6 py-4 text-sm font-medium text-gray-900">
                                            {report.reported_user?.name || 'Unknown'}
                                        </td>
                                        <td className="px-6 py-4">
                                            <p className="text-sm text-gray-900">{report.reason}</p>
                                            {report.description && (
                                                <p className="text-xs text-gray-500 mt-1 line-clamp-1">{report.description}</p>
                                            )}
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-medium ${getStatusBadge(report.status)}`}>
                                                {report.status}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-sm text-gray-500">
                                            {new Date(report.created_at).toLocaleDateString()}
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            {report.status === 'pending' && (
                                                <div className="flex items-center justify-end gap-1">
                                                    <button
                                                        onClick={() => handleDismiss(report.id)}
                                                        disabled={processingId === report.id}
                                                        className="p-2 text-gray-500 hover:bg-gray-100 rounded-lg"
                                                        title="Dismiss"
                                                    >
                                                        <X className="w-4 h-4" />
                                                    </button>
                                                    <button
                                                        onClick={() => { setActionModal(report); setActionType('warn'); }}
                                                        className="p-2 text-yellow-600 hover:bg-yellow-50 rounded-lg"
                                                        title="Warn User"
                                                    >
                                                        <AlertTriangle className="w-4 h-4" />
                                                    </button>
                                                    <button
                                                        onClick={() => { setActionModal(report); setActionType('suspend'); }}
                                                        className="p-2 text-orange-600 hover:bg-orange-50 rounded-lg"
                                                        title="Suspend User"
                                                    >
                                                        <MessageSquare className="w-4 h-4" />
                                                    </button>
                                                    <button
                                                        onClick={() => { setActionModal(report); setActionType('ban'); }}
                                                        className="p-2 text-red-600 hover:bg-red-50 rounded-lg"
                                                        title="Ban User"
                                                    >
                                                        <Ban className="w-4 h-4" />
                                                    </button>
                                                </div>
                                            )}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Action Modal */}
            {actionModal && actionType && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="bg-white rounded-xl p-6 w-full max-w-md mx-4">
                        <h3 className="text-lg font-semibold text-gray-900">
                            {actionType === 'warn' && 'Warn User'}
                            {actionType === 'suspend' && 'Suspend User'}
                            {actionType === 'ban' && 'Ban User'}
                        </h3>
                        <p className="text-sm text-gray-500 mt-1">
                            Taking action on {actionModal.reported_user?.name}
                        </p>

                        {actionType === 'warn' && (
                            <textarea
                                value={actionInput}
                                onChange={(e) => setActionInput(e.target.value)}
                                placeholder="Warning message to send to user..."
                                rows={3}
                                className="w-full mt-4 px-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none resize-none"
                            />
                        )}

                        {actionType === 'suspend' && (
                            <input
                                type="number"
                                value={actionInput}
                                onChange={(e) => setActionInput(e.target.value)}
                                placeholder="Number of days (default: 7)"
                                className="w-full mt-4 px-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none"
                            />
                        )}

                        {actionType === 'ban' && (
                            <textarea
                                value={actionInput}
                                onChange={(e) => setActionInput(e.target.value)}
                                placeholder="Reason for permanent ban..."
                                rows={3}
                                className="w-full mt-4 px-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none resize-none"
                            />
                        )}

                        <div className="flex gap-3 mt-6">
                            <button
                                onClick={() => { setActionModal(null); setActionType(null); setActionInput(''); }}
                                className="flex-1 py-2.5 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50"
                            >
                                Cancel
                            </button>
                            <button
                                onClick={handleAction}
                                disabled={processingId === actionModal.id}
                                className={`flex-1 py-2.5 text-white rounded-lg font-medium disabled:opacity-50 ${actionType === 'ban' ? 'bg-red-600 hover:bg-red-700' : 'bg-[#6C5CE7] hover:bg-[#5A4BD5]'
                                    }`}
                            >
                                {processingId === actionModal.id ? 'Processing...' : 'Confirm'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
