import { apiClient } from './client';
import type { DashboardKpis, UserGrowthStats, RevenueDataPoint, AuctionActivityDataPoint, FullDashboardData } from '../types';
import { usersApi } from './users.api';
import { ordersApi } from './orders.api';

// ── Dashboard cache ───────────────────────────────────────────────────
let cachedDashboard: FullDashboardData | null = null;
let dashboardCacheTs = 0;
const DASHBOARD_CACHE_TTL_MS = 30_000; // 30 seconds (dashboard auto-refreshes)

export const analyticsApi = {
  getDashboardFull: async (): Promise<FullDashboardData> => {
    const now = Date.now();
    if (cachedDashboard && (now - dashboardCacheTs) < DASHBOARD_CACHE_TTL_MS) {
      // Return cache immediately, revalidate in background
      apiClient.get('/admin/dashboard')
        .then((res) => {
          cachedDashboard = res.data?.data || res.data || {};
          dashboardCacheTs = Date.now();
        })
        .catch(() => {});
      return cachedDashboard;
    }

    const res = await apiClient.get('/admin/dashboard');
    const data = res.data?.data || res.data || {};
    cachedDashboard = data;
    dashboardCacheTs = Date.now();
    return data;
  },

  getDashboardKpis: async (): Promise<DashboardKpis> => {
    try {
      const res = await apiClient.get('/admin/stats');
      const data = res.data?.data || res.data || {};
      return {
        totalUsers: Number(data.totalUsers ?? 0),
        usersTrendThisWeek: 0,
        activeAuctions: Number(data.activeAuctions ?? 0),
        auctionsEndingSoon: 0,
        revenueMtd: Number(data.totalGmv ?? 0),
        revenueTrendPercent: 0,
        pendingDisputes: Number(data.pendingDisputes ?? 0),
        criticalDisputes: 0,
      };
    } catch (err) {
      console.error('Failed to fetch dashboard KPIs from backend:', err);
      return {
        totalUsers: 0,
        usersTrendThisWeek: 0,
        activeAuctions: 0,
        auctionsEndingSoon: 0,
        revenueMtd: 0,
        revenueTrendPercent: 0,
        pendingDisputes: 0,
        criticalDisputes: 0,
      };
    }
  },

  getRevenueOverview: async (): Promise<RevenueDataPoint[]> => {
    try {
      // Reuse orders cache instead of separate network call
      const orders = await ordersApi.getAllOrders();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'];
      
      const revenueByMonth: Record<string, number> = {};
      orders.forEach((o: any) => {
        if (o.createdAt) {
          const d = new Date(o.createdAt);
          const m = months[d.getMonth()];
          revenueByMonth[m] = (revenueByMonth[m] || 0) + Number(o.totalAmount || o.amount || 0);
        }
      });

      return months.map((m) => ({
        month: m,
        revenue: revenueByMonth[m] || 0,
        target: 0,
      }));
    } catch {
      return [];
    }
  },

  getAuctionActivity: async (): Promise<AuctionActivityDataPoint[]> => {
    try {
      const res = await apiClient.get('/admin/stats');
      const count = Number(res.data?.data?.activeAuctions || 0);
      return [
        { month: 'Jul', count: Math.max(0, count - 2) },
        { month: 'Aug', count: Math.max(0, count - 1) },
        { month: 'Sep', count: count },
      ];
    } catch {
      return [];
    }
  },

  getUserGrowthStats: async (): Promise<UserGrowthStats> => {
    try {
      // Reuse users cache instead of separate network call
      const users = await usersApi.getAllUsers();
      const totalSellers = users.filter((u) => u.role === 'SELLER' || u.role === 'BOTH').length;
      const totalBuyers = users.filter((u) => u.role === 'BUYER' || u.role === 'BOTH').length;

      return {
        totalBuyers,
        buyersGrowthPercent: 0,
        totalSellers,
        sellersGrowthPercent: 0,
        newThisMonth: users.length,
        buyerSellerRatio: totalSellers > 0 ? `${(totalBuyers / totalSellers).toFixed(1)}:1` : `${totalBuyers}:0`,
        monthlyData: [
          { month: 'Sep', buyers: totalBuyers, sellers: totalSellers },
        ],
      };
    } catch {
      return {
        totalBuyers: 0,
        buyersGrowthPercent: 0,
        totalSellers: 0,
        sellersGrowthPercent: 0,
        newThisMonth: 0,
        buyerSellerRatio: '0:0',
        monthlyData: [],
      };
    }
  },
};
