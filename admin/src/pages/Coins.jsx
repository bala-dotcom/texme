import { useState, useEffect } from 'react';
import { coinPackagesApi } from '../api/client';
import {
    Plus,
    Edit2,
    Trash2,
    Coins as CoinsIcon,
    Save,
    X,
    Loader2,
    ArrowUpDown,
    CheckCircle2,
    XCircle
} from 'lucide-react';

export default function Coins() {
    const [packages, setPackages] = useState([]);
    const [loading, setLoading] = useState(true);
    const [actionLoading, setActionLoading] = useState(false);
    const [showModal, setShowModal] = useState(false);
    const [currentPackage, setCurrentPackage] = useState(null);
    const [formData, setFormData] = useState({
        label: '',
        price: '',
        coins: '',
        bonus: 0,
        sort_order: 0,
        is_active: true
    });

    useEffect(() => {
        loadPackages();
    }, []);

    const loadPackages = async () => {
        setLoading(true);
        try {
            const response = await coinPackagesApi.list();
            setPackages(response.data.packages);
        } catch (error) {
            console.error('Failed to load packages:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleOpenModal = (pkg = null) => {
        if (pkg) {
            setCurrentPackage(pkg);
            setFormData({
                label: pkg.label,
                price: pkg.price,
                coins: pkg.coins,
                bonus: pkg.bonus,
                sort_order: pkg.sort_order,
                is_active: pkg.is_active
            });
        } else {
            setCurrentPackage(null);
            setFormData({
                label: '',
                price: '',
                coins: '',
                bonus: 0,
                sort_order: packages.length + 1,
                is_active: true
            });
        }
        setShowModal(true);
    };

    const handleCloseModal = () => {
        setShowModal(false);
        setCurrentPackage(null);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setActionLoading(true);
        try {
            if (currentPackage) {
                await coinPackagesApi.update(currentPackage.id, formData);
            } else {
                await coinPackagesApi.create(formData);
            }
            loadPackages();
            handleCloseModal();
        } catch (error) {
            console.error('Failed to save package:', error);
            alert('Failed to save package. Please check the data.');
        } finally {
            setActionLoading(false);
        }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Are you sure you want to delete this package?')) return;

        setActionLoading(true);
        try {
            await coinPackagesApi.delete(id);
            loadPackages();
        } catch (error) {
            console.error('Failed to delete package:', error);
            alert('Failed to delete package.');
        } finally {
            setActionLoading(true); // Should be false, fixed below
            setActionLoading(false);
        }
    };

    const toggleStatus = async (pkg) => {
        try {
            await coinPackagesApi.update(pkg.id, { is_active: !pkg.is_active });
            loadPackages();
        } catch (error) {
            console.error('Failed to update status:', error);
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
            <div className="flex items-center justify-between">
                <div>
                    <h2 className="text-xl font-bold text-gray-900">Coin Packages</h2>
                    <p className="text-sm text-gray-500 mt-1">Manage coin purchase options for male users</p>
                </div>
                <button
                    onClick={() => handleOpenModal()}
                    className="flex items-center gap-2 px-4 py-2 bg-[#6C5CE7] text-white font-medium rounded-lg hover:bg-[#5A4BD5] transition-colors"
                >
                    <Plus className="w-4 h-4" />
                    Add Package
                </button>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                <table className="w-full text-left border-collapse">
                    <thead>
                        <tr className="bg-gray-50 border-b border-gray-100">
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Order</th>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Label</th>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Price (₹)</th>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Coins</th>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Bonus</th>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase tracking-wider text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-50">
                        {packages.map((pkg) => (
                            <tr key={pkg.id} className="hover:bg-gray-50/50 transition-colors">
                                <td className="px-6 py-4 text-sm text-gray-600">{pkg.sort_order}</td>
                                <td className="px-6 py-4 font-medium text-gray-900">{pkg.label}</td>
                                <td className="px-6 py-4 text-sm font-semibold text-gray-900">₹{pkg.price}</td>
                                <td className="px-6 py-4 text-sm text-gray-600">
                                    <div className="flex items-center gap-1.5">
                                        <CoinsIcon className="w-4 h-4 text-yellow-500" />
                                        {pkg.coins}
                                    </div>
                                </td>
                                <td className="px-6 py-4 text-sm text-green-600">
                                    {pkg.bonus > 0 ? `+${pkg.bonus}` : '-'}
                                </td>
                                <td className="px-6 py-4">
                                    <button
                                        onClick={() => toggleStatus(pkg)}
                                        className={`flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${pkg.is_active
                                                ? 'bg-green-50 text-green-700'
                                                : 'bg-red-50 text-red-700'
                                            }`}
                                    >
                                        {pkg.is_active ? (
                                            <CheckCircle2 className="w-3.5 h-3.5" />
                                        ) : (
                                            <XCircle className="w-3.5 h-3.5" />
                                        )}
                                        {pkg.is_active ? 'Active' : 'Inactive'}
                                    </button>
                                </td>
                                <td className="px-6 py-4 text-right">
                                    <div className="flex justify-end gap-2">
                                        <button
                                            onClick={() => handleOpenModal(pkg)}
                                            className="p-1.5 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                                        >
                                            <Edit2 className="w-4 h-4" />
                                        </button>
                                        <button
                                            onClick={() => handleDelete(pkg.id)}
                                            className="p-1.5 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                        >
                                            <Trash2 className="w-4 h-4" />
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
                {packages.length === 0 && (
                    <div className="p-12 text-center text-gray-500">
                        No coin packages found. Click "Add Package" to create one.
                    </div>
                )}
            </div>

            {/* Modal */}
            {showModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50">
                    <div className="bg-white rounded-xl shadow-xl w-full max-w-md overflow-hidden">
                        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
                            <h3 className="font-bold text-gray-900">
                                {currentPackage ? 'Edit Package' : 'New Coin Package'}
                            </h3>
                            <button onClick={handleCloseModal} className="text-gray-400 hover:text-gray-600">
                                <X className="w-5 h-5" />
                            </button>
                        </div>
                        <form onSubmit={handleSubmit} className="p-6 space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1.5">Label</label>
                                <input
                                    type="text"
                                    required
                                    value={formData.label}
                                    onChange={(e) => setFormData({ ...formData, label: e.target.value })}
                                    className="w-full px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none"
                                    placeholder="e.g. Starter Pack"
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Price (₹)</label>
                                    <input
                                        type="number"
                                        required
                                        min="0"
                                        value={formData.price}
                                        onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                                        className="w-full px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Coins</label>
                                    <input
                                        type="number"
                                        required
                                        min="1"
                                        value={formData.coins}
                                        onChange={(e) => setFormData({ ...formData, coins: e.target.value })}
                                        className="w-full px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none"
                                    />
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Bonus Coins</label>
                                    <input
                                        type="number"
                                        min="0"
                                        value={formData.bonus}
                                        onChange={(e) => setFormData({ ...formData, bonus: e.target.value })}
                                        className="w-full px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Sort Order</label>
                                    <input
                                        type="number"
                                        value={formData.sort_order}
                                        onChange={(e) => setFormData({ ...formData, sort_order: e.target.value })}
                                        className="w-full px-4 py-2 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none"
                                    />
                                </div>
                            </div>
                            <div className="flex items-center gap-2 py-2">
                                <input
                                    type="checkbox"
                                    id="is_active"
                                    checked={formData.is_active}
                                    onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
                                    className="w-4 h-4 text-[#6C5CE7] rounded focus:ring-[#6C5CE7]"
                                />
                                <label htmlFor="is_active" className="text-sm text-gray-700">Display this package to users</label>
                            </div>
                            <div className="flex items-center gap-3 mt-6">
                                <button
                                    type="button"
                                    onClick={handleCloseModal}
                                    className="flex-1 px-4 py-2 border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    disabled={actionLoading}
                                    className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-[#6C5CE7] text-white font-medium rounded-lg hover:bg-[#5A4BD5] disabled:opacity-50 transition-colors"
                                >
                                    {actionLoading ? (
                                        <Loader2 className="w-5 h-5 animate-spin" />
                                    ) : (
                                        <Save className="w-5 h-5" />
                                    )}
                                    {currentPackage ? 'Update' : 'Create'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
