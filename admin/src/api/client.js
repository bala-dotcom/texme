import axios from 'axios';

const API_BASE_URL = 'https://api.texme.online/api';

const client = axios.create({
    baseURL: API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    },
});

// Add auth token to requests
client.interceptors.request.use((config) => {
    const token = localStorage.getItem('admin_token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

// Handle 401 errors
client.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401) {
            localStorage.removeItem('admin_token');
            localStorage.removeItem('admin_user');
            window.location.href = '/login';
        }
        return Promise.reject(error);
    }
);

// Auth APIs
export const authApi = {
    login: (email, password) => client.post('/admin/login', { email, password }),
    logout: () => client.post('/admin/logout'),
    profile: () => client.get('/admin/profile'),
    changePassword: (data) => client.post('/admin/change-password', data),
};

// Dashboard APIs
export const dashboardApi = {
    overview: () => client.get('/admin/dashboard/overview'),
    revenueChart: (period = 'week') => client.get('/admin/dashboard/revenue-chart', { params: { period } }),
    userChart: (period = 'week') => client.get('/admin/dashboard/user-chart', { params: { period } }),
    recentActivities: () => client.get('/admin/dashboard/recent'),
};

// User Management APIs
export const usersApi = {
    list: (params) => client.get('/admin/users', { params }),
    pendingFemales: () => client.get('/admin/users/pending-females'),
    get: (id) => client.get(`/admin/users/${id}`),
    update: (id, data) => client.put(`/admin/users/${id}`, data),
    updateStatus: (id, accountStatus, reason) =>
        client.put(`/admin/users/${id}/status`, { account_status: accountStatus, reason }),
    approveFemale: (id) => client.post(`/admin/users/${id}/approve`),
    rejectFemale: (id, reason) => client.post(`/admin/users/${id}/reject`, { reason }),
    addCoins: (id, coins, reason) => client.post(`/admin/users/${id}/add-coins`, { coins, reason }),
};

// Withdrawal APIs
export const withdrawalsApi = {
    list: (params) => client.get('/admin/withdrawals', { params }),
    pending: () => client.get('/admin/withdrawals/pending'),
    get: (id) => client.get(`/admin/withdrawals/${id}`),
    approve: (id) => client.post(`/admin/withdrawals/${id}/approve`),
    complete: (id, transactionId) => client.post(`/admin/withdrawals/${id}/complete`, { transaction_id: transactionId }),
    reject: (id, reason) => client.post(`/admin/withdrawals/${id}/reject`, { reason }),
};

// Report APIs
export const reportsApi = {
    list: (params) => client.get('/admin/reports', { params }),
    pending: () => client.get('/admin/reports/pending'),
    get: (id) => client.get(`/admin/reports/${id}`),
    dismiss: (id) => client.post(`/admin/reports/${id}/dismiss`),
    warn: (id, message) => client.post(`/admin/reports/${id}/warn`, { message }),
    suspend: (id, days) => client.post(`/admin/reports/${id}/suspend`, { days }),
    ban: (id, reason) => client.post(`/admin/reports/${id}/ban`, { reason }),
};

// Transaction APIs
export const transactionsApi = {
    list: (params) => client.get('/admin/transactions', { params }),
    summary: (params) => client.get('/admin/transactions/summary', { params }),
    get: (id) => client.get(`/admin/transactions/${id}`),
    export: (params) => client.get('/admin/transactions/export', { params, responseType: 'blob' }),
};

// Settings APIs
export const settingsApi = {
    get: () => client.get('/admin/settings'),
    update: (data) => client.post('/admin/settings/update', data),
    updateCoinPackages: (packages) => client.post('/admin/settings/coin-packages', { packages }),
    updateRates: (rates) => client.post('/admin/settings/rates', rates),
    updatePaymentGateway: (gateway, config) => client.post('/admin/settings/payment-gateway', { gateway, config }),
};

// Coin Package APIs
export const coinPackagesApi = {
    list: () => client.get('/admin/coin-packages'),
    create: (data) => client.post('/admin/coin-packages', data),
    update: (id, data) => client.put(`/admin/coin-packages/${id}`, data),
    delete: (id) => client.delete(`/admin/coin-packages/${id}`),
};

export default client;
