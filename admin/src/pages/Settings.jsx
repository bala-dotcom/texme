import { useState, useEffect } from 'react';
import { settingsApi } from '../api/client';
import {
    Settings as SettingsIcon,
    Save,
    Loader2,
    Coins,
    Percent,
    CreditCard,
    FileText,
} from 'lucide-react';

export default function Settings() {
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [activeTab, setActiveTab] = useState('general');

    // Settings state
    const [coinsPerMinute, setCoinsPerMinute] = useState(10);
    const [femaleEarningPerMinute, setFemaleEarningPerMinute] = useState(3.0);
    const [minimumWithdrawal, setMinimumWithdrawal] = useState(100);

    // Legal state
    const [privacyPolicy, setPrivacyPolicy] = useState('');
    const [termsOfService, setTermsOfService] = useState('');

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
                setFemaleEarningPerMinute(data.female_earning_per_minute || 3.0);
                setMinimumWithdrawal(data.minimum_withdrawal || 100);
                setPrivacyPolicy(data.privacy_policy_content || '');
                setTermsOfService(data.terms_of_service_content || '');
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
                female_earning_per_minute: femaleEarningPerMinute,
                minimum_withdrawal: minimumWithdrawal,
            });
            alert('Settings saved successfully');
        } catch (error) {
            alert('Failed to save settings');
        } finally {
            setSaving(false);
        }
    };

    const handleSaveLegal = async () => {
        setSaving(true);
        try {
            await settingsApi.updateLegal({
                privacy_policy_content: privacyPolicy,
                terms_of_service_content: termsOfService,
            });
            alert('Legal pages saved successfully');
        } catch (error) {
            alert('Failed to save legal pages');
        } finally {
            setSaving(false);
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
                <h2 className="text-xl font-bold text-gray-900">Settings</h2>
                <p className="text-sm text-gray-500 mt-1">Configure app settings and rates</p>
            </div>

            {/* Tabs */}
            <div className="flex gap-2 border-b border-gray-200">
                {[
                    { id: 'general', label: 'General', icon: SettingsIcon },
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

                        {/* Female earning per minute */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                Female Earning per Minute (₹)
                            </label>
                            <div className="relative">
                                <CreditCard className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                                <input
                                    type="number"
                                    step="0.5"
                                    min="0"
                                    value={femaleEarningPerMinute}
                                    onChange={(e) => setFemaleEarningPerMinute(parseFloat(e.target.value) || 0)}
                                    className="w-full pl-10 pr-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none"
                                />
                            </div>
                            <p className="text-xs text-gray-500 mt-1">
                                Amount in ₹ the female earns per minute of chat
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

            {/* Legal Settings */}
            {activeTab === 'legal' && (
                <div className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                    <h3 className="text-lg font-semibold text-gray-900 mb-6">Legal Pages Content</h3>

                    <div className="space-y-6 max-w-2xl">
                        {/* Privacy Policy */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                Privacy Policy (HTML supported)
                            </label>
                            <textarea
                                value={privacyPolicy}
                                onChange={(e) => setPrivacyPolicy(e.target.value)}
                                rows={10}
                                className="w-full px-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none font-mono text-sm"
                                placeholder="<h3>Privacy Policy</h3><p>...</p>"
                            />
                        </div>

                        {/* Terms of Service */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                Terms of Service (HTML supported)
                            </label>
                            <textarea
                                value={termsOfService}
                                onChange={(e) => setTermsOfService(e.target.value)}
                                rows={10}
                                className="w-full px-4 py-2.5 rounded-lg border border-gray-300 focus:ring-2 focus:ring-[#6C5CE7] focus:border-transparent outline-none font-mono text-sm"
                                placeholder="<h3>Terms of Service</h3><p>...</p>"
                            />
                        </div>

                        <button
                            onClick={handleSaveLegal}
                            disabled={saving}
                            className="flex items-center gap-2 px-6 py-2.5 bg-[#6C5CE7] text-white font-medium rounded-lg hover:bg-[#5A4BD5] disabled:opacity-50"
                        >
                            {saving ? <Loader2 className="w-5 h-5 animate-spin" /> : <Save className="w-5 h-5" />}
                            Save Pages
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}
