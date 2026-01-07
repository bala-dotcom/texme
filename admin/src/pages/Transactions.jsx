import { useState, useEffect } from 'react';
import { transactionsApi } from '../api/client';
import {
    CreditCard,
    Download,
    Loader2,
    ChevronLeft,
    ChevronRight,
    ArrowUpRight,
    ArrowDownRight,
} from 'lucide-react';

export default function Transactions() {
    const [transactions, setTransactions] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState('all'); // all, purchase, spend, earning
    const [pagination, setPagination] = useState({ page: 1, lastPage: 1, total: 0 });
    const [summary, setSummary] = useState(null);

    useEffect(() => {
        loadTransactions();
        loadSummary();
    }, [pagination.page, filter]);

    const loadTransactions = async () => {
        setLoading(true);
        try {
            const response = await transactionsApi.list({
                page: pagination.page,
                type: filter !== 'all' ? filter : undefined,
            });

            const data = response.data.transactions;
            setTransactions(data?.data || []);
            setPagination({
                page: data?.current_page || 1,
                lastPage: data?.last_page || 1,
                total: data?.total || 0,
            });
        } catch (error) {
            console.error('Load transactions error:', error);
            // Mock data
            setTransactions([
                { id: 1, user: { name: 'Test User' }, type: 'purchase', coins: 100, amount: 99, created_at: '2025-12-06' },
            ]);
        } finally {
            setLoading(false);
        }
    };

    const loadSummary = async () => {
        try {
            const response = await transactionsApi.summary({});
            setSummary(response.data);
        } catch (error) {
            // Mock
            setSummary({
                total_purchases: 45600,
                total_spent: 32000,
                total_earnings: 11520,
                transaction_count: 1250,
            });
        }
    };

    const handleExport = async () => {
        try {
            const response = await transactionsApi.export({ type: filter !== 'all' ? filter : undefined });
            const url = window.URL.createObjectURL(new Blob([response.data]));
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', `transactions-${Date.now()}.csv`);
            document.body.appendChild(link);
            link.click();
            link.remove();
        } catch (error) {
            alert('Failed to export transactions');
        }
    };

    const getTypeBadge = (type) => {
        const config = {
            purchase: { bg: 'bg-green-100', text: 'text-green-700', icon: ArrowUpRight },
            spend: { bg: 'bg-red-100', text: 'text-red-700', icon: ArrowDownRight },
            earning: { bg: 'bg-blue-100', text: 'text-blue-700', icon: ArrowUpRight },
        };
        return config[type] || config.purchase;
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                    <h2 className="text-xl font-bold text-gray-900">Transactions</h2>
                    <p className="text-sm text-gray-500 mt-1">{pagination.total} total transactions</p>
                </div>
                <button
                    onClick={handleExport}
                    className="flex items-center gap-2 px-4 py-2.5 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50"
                >
                    <Download className="w-5 h-5" />
                    Export CSV
                </button>
            </div>

            {/* Summary Cards */}
            {summary && (
                <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                    <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
                        <p className="text-sm text-gray-500">Total Purchases</p>
                        <p className="text-2xl font-bold text-green-600 mt-1">₹{summary.total_purchases?.toLocaleString()}</p>
                    </div>
                    <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
                        <p className="text-sm text-gray-500">Total Spent</p>
                        <p className="text-2xl font-bold text-red-600 mt-1">{summary.total_spent?.toLocaleString()} coins</p>
                    </div>
                    <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
                        <p className="text-sm text-gray-500">Total Earnings</p>
                        <p className="text-2xl font-bold text-blue-600 mt-1">₹{summary.total_earnings?.toLocaleString()}</p>
                    </div>
                    <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
                        <p className="text-sm text-gray-500">Transaction Count</p>
                        <p className="text-2xl font-bold text-gray-900 mt-1">{summary.transaction_count?.toLocaleString()}</p>
                    </div>
                </div>
            )}

            {/* Filter Tabs */}
            <div className="flex gap-2 border-b border-gray-200">
                {['all', 'purchase', 'spend', 'earning'].map((type) => (
                    <button
                        key={type}
                        onClick={() => { setFilter(type); setPagination(p => ({ ...p, page: 1 })); }}
                        className={`px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors ${filter === type
                                ? 'border-[#6C5CE7] text-[#6C5CE7]'
                                : 'border-transparent text-gray-500 hover:text-gray-700'
                            }`}
                    >
                        {type.charAt(0).toUpperCase() + type.slice(1)}
                    </button>
                ))}
            </div>

            {/* Table */}
            <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                {loading ? (
                    <div className="flex items-center justify-center h-64">
                        <Loader2 className="w-8 h-8 animate-spin text-[#6C5CE7]" />
                    </div>
                ) : transactions.length === 0 ? (
                    <div className="p-12 text-center">
                        <CreditCard className="w-12 h-12 text-gray-300 mx-auto" />
                        <p className="text-gray-500 mt-4">No transactions found</p>
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead className="bg-gray-50 border-b border-gray-100">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">User</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Coins</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Amount</th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100">
                                {transactions.map((tx) => {
                                    const typeConfig = getTypeBadge(tx.type);
                                    const TypeIcon = typeConfig.icon;

                                    return (
                                        <tr key={tx.id} className="hover:bg-gray-50">
                                            <td className="px-6 py-4 text-sm font-medium text-gray-900">
                                                #{tx.id}
                                            </td>
                                            <td className="px-6 py-4 text-sm text-gray-900">
                                                {tx.user?.name || 'Unknown'}
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium ${typeConfig.bg} ${typeConfig.text}`}>
                                                    <TypeIcon className="w-3 h-3" />
                                                    {tx.type}
                                                </span>
                                            </td>
                                            <td className="px-6 py-4 text-sm text-gray-900">
                                                {tx.coins ? `${tx.type === 'spend' ? '-' : '+'}${tx.coins}` : '-'}
                                            </td>
                                            <td className="px-6 py-4 text-sm font-medium text-gray-900">
                                                {tx.amount ? `₹${tx.amount.toLocaleString()}` : '-'}
                                            </td>
                                            <td className="px-6 py-4 text-sm text-gray-500">
                                                {new Date(tx.created_at).toLocaleString()}
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
        </div>
    );
}
