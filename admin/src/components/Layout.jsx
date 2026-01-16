import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import {
    LayoutDashboard,
    Users,
    UserCheck,
    Wallet,
    Flag,
    CreditCard,
    Settings,
    LogOut,
    Menu,
    X,
    Bell,
    ChevronDown,
    Mic,
} from 'lucide-react';

const navigation = [
    { name: 'Dashboard', href: '/', icon: LayoutDashboard },
    { name: 'Users', href: '/users', icon: Users },
    { name: 'Pending Approval', href: '/pending-females', icon: UserCheck },
    { name: 'Voice Verifications', href: '/voice-verifications', icon: Mic },
    { name: 'Withdrawals', href: '/withdrawals', icon: Wallet },
    { name: 'Reports', href: '/reports', icon: Flag },
    { name: 'Transactions', href: '/transactions', icon: CreditCard },
    { name: 'Settings', href: '/settings', icon: Settings },
];

export default function Layout({ children }) {
    const [sidebarOpen, setSidebarOpen] = useState(false);
    const [userMenuOpen, setUserMenuOpen] = useState(false);
    const location = useLocation();
    const navigate = useNavigate();
    const { user, logout } = useAuth();

    const handleLogout = async () => {
        await logout();
        navigate('/login');
    };

    return (
        <div className="min-h-screen bg-gray-50">
            {/* Mobile sidebar overlay */}
            {sidebarOpen && (
                <div
                    className="fixed inset-0 z-40 bg-black/50 lg:hidden"
                    onClick={() => setSidebarOpen(false)}
                />
            )}

            {/* Sidebar */}
            <aside className={`
        fixed inset-y-0 left-0 z-50 w-64 bg-white shadow-lg transform transition-transform duration-200
        ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}
        lg:translate-x-0
      `}>
                {/* Logo */}
                <div className="flex items-center justify-between h-16 px-6 border-b border-gray-200">
                    <Link to="/" className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-lg bg-[#6C5CE7] flex items-center justify-center">
                            <span className="text-white font-bold text-sm">T</span>
                        </div>
                        <span className="font-semibold text-lg text-gray-900">Texme Admin</span>
                    </Link>
                    <button
                        className="lg:hidden p-1 rounded hover:bg-gray-100"
                        onClick={() => setSidebarOpen(false)}
                    >
                        <X className="w-5 h-5" />
                    </button>
                </div>

                {/* Navigation */}
                <nav className="p-4 space-y-1">
                    {navigation.map((item) => {
                        const isActive = location.pathname === item.href;
                        return (
                            <Link
                                key={item.name}
                                to={item.href}
                                onClick={() => setSidebarOpen(false)}
                                className={`
                  flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors
                  ${isActive
                                        ? 'bg-[#6C5CE7] text-white'
                                        : 'text-gray-700 hover:bg-gray-100'
                                    }
                `}
                            >
                                <item.icon className="w-5 h-5" />
                                {item.name}
                            </Link>
                        );
                    })}
                </nav>
            </aside>

            {/* Main content */}
            <div className="lg:pl-64">
                {/* Top header */}
                <header className="sticky top-0 z-30 bg-white border-b border-gray-200">
                    <div className="flex items-center justify-between h-16 px-4 lg:px-8">
                        {/* Mobile menu button */}
                        <button
                            className="lg:hidden p-2 rounded-lg hover:bg-gray-100"
                            onClick={() => setSidebarOpen(true)}
                        >
                            <Menu className="w-5 h-5" />
                        </button>

                        {/* Page title (on larger screens) */}
                        <div className="hidden lg:block">
                            <h1 className="text-lg font-semibold text-gray-900">
                                {navigation.find(n => n.href === location.pathname)?.name || 'Dashboard'}
                            </h1>
                        </div>

                        {/* Right side */}
                        <div className="flex items-center gap-4">
                            {/* Notifications */}
                            <button className="p-2 rounded-lg hover:bg-gray-100 relative">
                                <Bell className="w-5 h-5 text-gray-600" />
                                <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full" />
                            </button>

                            {/* User menu */}
                            <div className="relative">
                                <button
                                    onClick={() => setUserMenuOpen(!userMenuOpen)}
                                    className="flex items-center gap-2 p-1.5 rounded-lg hover:bg-gray-100"
                                >
                                    <div className="w-8 h-8 rounded-full bg-[#6C5CE7] flex items-center justify-center">
                                        <span className="text-white text-sm font-medium">
                                            {user?.name?.charAt(0)?.toUpperCase() || 'A'}
                                        </span>
                                    </div>
                                    <span className="hidden sm:block text-sm font-medium text-gray-700">
                                        {user?.name || 'Admin'}
                                    </span>
                                    <ChevronDown className="w-4 h-4 text-gray-500" />
                                </button>

                                {userMenuOpen && (
                                    <>
                                        <div
                                            className="fixed inset-0 z-40"
                                            onClick={() => setUserMenuOpen(false)}
                                        />
                                        <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-gray-200 py-1 z-50">
                                            <div className="px-4 py-2 border-b border-gray-100">
                                                <p className="text-sm font-medium text-gray-900">{user?.name}</p>
                                                <p className="text-xs text-gray-500">{user?.email}</p>
                                            </div>
                                            <button
                                                onClick={handleLogout}
                                                className="flex items-center gap-2 w-full px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                                            >
                                                <LogOut className="w-4 h-4" />
                                                Logout
                                            </button>
                                        </div>
                                    </>
                                )}
                            </div>
                        </div>
                    </div>
                </header>

                {/* Page content */}
                <main className="p-4 lg:p-8">
                    {children}
                </main>
            </div>
        </div>
    );
}
