import { useState, useEffect } from 'react';
import { settingsApi } from '../api/client';
import {
    Settings as SettingsIcon,
    Save,
    Loader2,
    Coins,
    Percent,
    CreditCard,
} from 'lucide-react';

export default function Settings() {
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [activeTab, setActiveTab] = useState('general');

    // Settings state
    const [coinsPerMinute, setCoinsPerMinute] = useState(10);
    const [femaleEarningRatio, setFemaleEarningRatio] = useState(0.36);
    const [minimumWithdrawal, setMinimumWithdrawal] = useState(100);

    const [coinPackages, setCoinPackages] = useState([
        { coins: 40, price: 25, label: 'Starter' },
        { coins: 100, price: 59, label: 'Popular' },
        { coins: 200, price: 99, label: 'Best Value' },
        { coins: 500, price: 199, label: 'Premium' },
    ]);

    useEffect(() => {
        loadSettings();
    }, []);

    const loadSettings = async () => {
        setLoading(true);
        try {
            const response = await settingsApi.get();
            const data = response.data.settings;
            if (data) {
                setCoinsPerMinute(data.coins_per_minute || 10);
                setFemaleEarningRatio(data.female_earning_ratio || 0.36);
                setMinimumWithdrawal(data.minimum_withdrawal || 100);
                if (data.coin_packages) {
                    setCoinPackages(data.coin_packages);
                }
            }
        } catch (error) {
            console.error('Load settings error:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleSaveRates = async () => {
        setSaving(true);
        try {
            await settingsApi.updateRates({
                coins_per_minute: coinsPerMinute,
                female_earning_ratio: femaleEarningRatio,
                minimum_withdrawal: minimumWithdrawal,
            });
            alert('Settings saved successfully');
        } catch (error) {
            alert('Failed to save settings');
        } finally {
            setSaving(false);
        }
    };

    const handleSavePackages = async () => {
        setSaving(true);
        try {
            await settingsApi.updateCoinPackages(coinPackages);
            alert('Coin packages saved successfully');
        } catch (error) {
            alert('Failed to save packages');
        } finally {
            setSaving(false);
        }
    };

    const updatePackage = (index, field, value) => {
        const updated = [...coinPackages];
        updated[index] = { ...updated[index], [field]: value };
        setCoinPackages(updated);
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
                <h2 className="text-xl font-bold text-gray-900">Settings</h2>
                <p className="text-sm text-gray-500 mt-1">Configure app settings and rates</p>
            </div>

            {/* Tabs */}
            <div className="flex gap-2 border-b border-gray-200">
                {[
                    { id: 'general', label: 'General', icon: SettingsIcon },
                    { id: 'packages', label: 'Coin Packages', icon: Coins },
                    { id: 'payment', label: 'Payment', icon: CreditCard },
                ].map((tab) => (
                    <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id)}
                        className={`flex items-center gap-2 px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors ${activeTab === tab.id
                                ? 'border-[#6C5CE7] text-[#6C5CE7]'
                                : 'border-transparent text-gray-500 hover:text-gray-700'
                            }`}
                    >
                        <tab.icon className="w-4 h-4" />
                        {tab.label}
                    </button>
                ))}
            </div>

            {/* General Settings */}
            {activeTab === 'general' && (
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-6">Rate Settings</h3>

                    <div className="space-y-6 max-w-md">
                        {/* Coins per minute */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                Coins per Minute
                            </label>
                            <div className="relative">
                                <Coins className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                                <input
                                    type="number"
                                    value={coinsPerMinute}
                                    onChange={(e) => setCoinsPerMinute(parseInt(e.target.value) || 0)}
                                    className="w-full pl-10 pr-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none"
                                />
                            </div>
                            <p className="text-xs text-gray-500 mt-1">Number of coins deducted per minute of chat</p>
                        </div>

                        {/* Female earning ratio */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                Female Earning Ratio
                            </label>
                            <div className="relative">
                                <Percent className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                                <input
                                    type="number"
                                    step="0.01"
                                    min="0"
                                    max="1"
                                    value={femaleEarningRatio}
                                    onChange={(e) => setFemaleEarningRatio(parseFloat(e.target.value) || 0)}
                                    className="w-full pl-10 pr-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none"
                                />
                            </div>
                            <p className="text-xs text-gray-500 mt-1">
                                Percentage of coin value that goes to female (0.36 = 36%)
                            </p>
                        </div>

                        {/* Minimum withdrawal */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                Minimum Withdrawal (₹)
                            </label>
                            <input
                                type="number"
                                value={minimumWithdrawal}
                                onChange={(e) => setMinimumWithdrawal(parseInt(e.target.value) || 0)}
                                className="w-full px-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none"
                            />
                            <p className="text-xs text-gray-500 mt-1">Minimum amount required for withdrawal request</p>
                        </div>

                        <button
                            onClick={handleSaveRates}
                            disabled={saving}
                            className="flex items-center gap-2 px-6 py-2.5 bg-[#6C5CE7] text-white font-medium rounded-lg hover:bg-[#5A4BD5] disabled:opacity-50"
                        >
                            {saving ? <Loader2 className="w-5 h-5 animate-spin" /> : <Save className="w-5 h-5" />}
                            Save Changes
                        </button>
                    </div>
                </div>
            )}

            {/* Coin Packages */}
            {activeTab === 'packages' && (
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-6">Coin Packages</h3>

                    <div className="space-y-4">
                        {coinPackages.map((pkg, index) => (
                            <div key={index} className="flex gap-4 items-center p-4 bg-gray-50 rounded-lg">
                                <div className="flex-1">
                                    <label className="block text-xs text-gray-500 mb-1">Label</label>
                                    <input
                                        type="text"
                                        value={pkg.label}
                                        onChange={(e) => updatePackage(index, 'label', e.target.value)}
                                        className="w-full px-3 py-2 rounded-lg border border-gray-300 text-sm"
                                    />
                                </div>
                                <div className="w-24">
                                    <label className="block text-xs text-gray-500 mb-1">Coins</label>
                                    <input
                                        type="number"
                                        value={pkg.coins}
                                        onChange={(e) => updatePackage(index, 'coins', parseInt(e.target.value) || 0)}
                                        className="w-full px-3 py-2 rounded-lg border border-gray-300 text-sm"
                                    />
                                </div>
                                <div className="w-24">
                                    <label className="block text-xs text-gray-500 mb-1">Price (₹)</label>
                                    <input
                                        type="number"
                                        value={pkg.price}
                                        onChange={(e) => updatePackage(index, 'price', parseInt(e.target.value) || 0)}
                                        className="w-full px-3 py-2 rounded-lg border border-gray-300 text-sm"
                                    />
                                </div>
                            </div>
                        ))}
                    </div>

                    <button
                        onClick={handleSavePackages}
                        disabled={saving}
                        className="flex items-center gap-2 px-6 py-2.5 bg-[#6C5CE7] text-white font-medium rounded-lg hover:bg-[#5A4BD5] disabled:opacity-50 mt-6"
                    >
                        {saving ? <Loader2 className="w-5 h-5 animate-spin" /> : <Save className="w-5 h-5" />}
                        Save Packages
                    </button>
                </div>
            )}

            {/* Payment Settings */}
            {activeTab === 'payment' && (
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-6">Payment Gateway</h3>

                    <div className="space-y-6 max-w-md">
                        <div className="p-4 bg-gray-50 rounded-lg border border-gray-200">
                            <div className="flex items-center gap-3">
                                <div className="w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center">
                                    <span className="text-white font-bold text-sm">R</span>
                                </div>
                                <div>
                                    <p className="font-medium text-gray-900">Razorpay</p>
                                    <p className="text-sm text-green-600">Connected</p>
                                </div>
                            </div>
                        </div>

                        <div className="text-sm text-gray-500">
                            <p>To update payment gateway settings, modify the environment variables in the backend:</p>
                            <ul className="list-disc list-inside mt-2 space-y-1">
                                <li>RAZORPAY_KEY_ID</li>
                                <li>RAZORPAY_KEY_SECRET</li>
                                <li>RAZORPAY_WEBHOOK_SECRET</li>
                            </ul>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
