import { useState, useEffect } from 'react';
import { dashboardApi } from '../api/client';
import {
    Users,
    DollarSign,
    MessageSquare,
    TrendingUp,
    ArrowUpRight,
    ArrowDownRight,
    Loader2,
} from 'lucide-react';
import {
    LineChart,
    Line,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer,
    BarChart,
    Bar,
} from 'recharts';

function StatCard({ title, value, change, changeType, icon: Icon, color }) {
    const isPositive = changeType === 'positive';

    return (
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
            <div className="flex items-start justify-between">
                <div>
                    <p className="text-sm text-gray-500 font-medium">{title}</p>
                    <p className="text-2xl font-bold text-gray-900 mt-1">{value}</p>
                    {change && (
                        <div className={`flex items-center gap-1 mt-2 text-sm ${isPositive ? 'text-green-600' : 'text-red-600'}`}>
                            {isPositive ? <ArrowUpRight className="w-4 h-4" /> : <ArrowDownRight className="w-4 h-4" />}
                            <span>{change}</span>
                            <span className="text-gray-400">vs last week</span>
                        </div>
                    )}
                </div>
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${color}`}>
                    <Icon className="w-6 h-6 text-white" />
                </div>
            </div>
        </div>
    );
}

export default function Dashboard() {
    const [loading, setLoading] = useState(true);
    const [stats, setStats] = useState(null);
    const [revenueData, setRevenueData] = useState([]);
    const [userChartData, setUserChartData] = useState([]);
    const [recentActivities, setRecentActivities] = useState([]);

    useEffect(() => {
        loadDashboard();
    }, []);

    const loadDashboard = async () => {
        setLoading(true);
        try {
            const [overviewRes, revenueRes, userRes, recentRes] = await Promise.all([
                dashboardApi.overview(),
                dashboardApi.revenueChart(),
                dashboardApi.userChart(),
                dashboardApi.recentActivities(),
            ]);

            setStats(overviewRes.data);
            setRevenueData(revenueRes.data.data || []);
            setUserChartData(userRes.data.data || []);
            setRecentActivities(recentRes.data.activities || []);
        } catch (error) {
            console.error('Dashboard load error:', error);
            // Set mock data for demo
            setStats({
                total_users: 1250,
                total_revenue: 45600,
                active_chats: 34,
                total_chats: 5680,
                pending_females: 12,
                pending_withdrawals: 8,
            });
            setRevenueData([
                { date: 'Mon', revenue: 4500 },
                { date: 'Tue', revenue: 5200 },
                { date: 'Wed', revenue: 4800 },
                { date: 'Thu', revenue: 6100 },
                { date: 'Fri', revenue: 7200 },
                { date: 'Sat', revenue: 8500 },
                { date: 'Sun', revenue: 7800 },
            ]);
            setUserChartData([
                { date: 'Mon', males: 45, females: 23 },
                { date: 'Tue', males: 52, females: 31 },
                { date: 'Wed', males: 38, females: 28 },
                { date: 'Thu', males: 61, females: 35 },
                { date: 'Fri', males: 72, females: 42 },
                { date: 'Sat', males: 85, females: 51 },
                { date: 'Sun', males: 78, females: 48 },
            ]);
        } finally {
            setLoading(false);
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
            {/* Stats Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                <StatCard
                    title="Total Users"
                    value={stats?.total_users?.toLocaleString() || '0'}
                    change="+12%"
                    changeType="positive"
                    icon={Users}
                    color="bg-[#6C5CE7]"
                />
                <StatCard
                    title="Total Revenue"
                    value={`₹${(stats?.total_revenue || 0).toLocaleString()}`}
                    change="+8%"
                    changeType="positive"
                    icon={DollarSign}
                    color="bg-green-500"
                />
                <StatCard
                    title="Active Chats"
                    value={stats?.active_chats || '0'}
                    icon={MessageSquare}
                    color="bg-blue-500"
                />
                <StatCard
                    title="Total Chats"
                    value={(stats?.total_chats || 0).toLocaleString()}
                    change="+15%"
                    changeType="positive"
                    icon={TrendingUp}
                    color="bg-orange-500"
                />
            </div>

            {/* Alerts */}
            {(stats?.pending_females > 0 || stats?.pending_withdrawals > 0) && (
                <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
                    <div className="flex flex-wrap gap-4">
                        {stats?.pending_females > 0 && (
                            <span className="text-amber-800 text-sm font-medium">
                                ⚠️ {stats.pending_females} female profiles pending approval
                            </span>
                        )}
                        {stats?.pending_withdrawals > 0 && (
                            <span className="text-amber-800 text-sm font-medium">
                                💰 {stats.pending_withdrawals} withdrawal requests pending
                            </span>
                        )}
                    </div>
                </div>
            )}

            {/* Charts */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Revenue Chart */}
                <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
                    <h3 className="text-lg font-semibold text-gray-900 mb-4">Revenue (Last 7 Days)</h3>
                    <div className="h-64">
                        <ResponsiveContainer width="100%" height="100%">
                            <LineChart data={revenueData}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                                <XAxis dataKey="date" stroke="#9ca3af" fontSize={12} />
                                <YAxis stroke="#9ca3af" fontSize={12} tickFormatter={(v) => `₹${v / 1000}k`} />
                                <Tooltip
                                    formatter={(value) => [`₹${value.toLocaleString()}`, 'Revenue']}
                                    contentStyle={{ borderRadius: '8px', border: '1px solid #e5e7eb' }}
                                />
                                <Line
                                    type="monotone"
                                    dataKey="revenue"
                                    stroke="#6C5CE7"
                                    strokeWidth={2}
                                    dot={{ fill: '#6C5CE7', r: 4 }}
                                    activeDot={{ r: 6 }}
                                />
                            </LineChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                {/* User Registrations Chart */}
                <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
                    <h3 className="text-lg font-semibold text-gray-900 mb-4">New Users (Last 7 Days)</h3>
                    <div className="h-64">
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={userChartData}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                                <XAxis dataKey="date" stroke="#9ca3af" fontSize={12} />
                                <YAxis stroke="#9ca3af" fontSize={12} />
                                <Tooltip
                                    contentStyle={{ borderRadius: '8px', border: '1px solid #e5e7eb' }}
                                />
                                <Bar dataKey="males" name="Males" fill="#3B82F6" radius={[4, 4, 0, 0]} />
                                <Bar dataKey="females" name="Females" fill="#EC4899" radius={[4, 4, 0, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </div>
            </div>

            {/* Quick Stats Cards */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 text-center">
                    <p className="text-2xl font-bold text-[#6C5CE7]">{stats?.pending_females || 0}</p>
                    <p className="text-sm text-gray-500 mt-1">Pending Females</p>
                </div>
                <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 text-center">
                    <p className="text-2xl font-bold text-green-600">{stats?.pending_withdrawals || 0}</p>
                    <p className="text-sm text-gray-500 mt-1">Pending Withdrawals</p>
                </div>
                <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 text-center">
                    <p className="text-2xl font-bold text-orange-600">{stats?.pending_reports || 0}</p>
                    <p className="text-sm text-gray-500 mt-1">Pending Reports</p>
                </div>
                <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 text-center">
                    <p className="text-2xl font-bold text-blue-600">{stats?.todays_revenue || '₹0'}</p>
                    <p className="text-sm text-gray-500 mt-1">Today's Revenue</p>
                </div>
            </div>
        </div>
    );
}
