import { apiClient } from './client';
import type { User, UserFilterParams, PageResponse } from '../types';

// ── Module-level in-memory cache ──────────────────────────────────────
let cachedAllUsers: User[] | null = null;
let cacheTimestamp = 0;
const CACHE_TTL_MS = 60_000; // 1 minute

function mapRawToUser(u: any): User {
  return {
    id: u.id,
    name: u.name || 'Bidly User',
    phone: u.phone || 'N/A',
    email: u.email || undefined,
    role: u.role || (u.listingsCount > 0 ? 'SELLER' : 'BUYER'),
    sellerType: u.sellerType || 'INDIVIDUAL',
    city: u.city || 'Chennai',
    state: u.state || 'Tamil Nadu',
    address: u.address || undefined,
    active: u.active ?? true,
    identityVerified: u.identityVerified ?? false,
    trustScore: u.trustScore ?? 0,
    avatarUrl: u.avatarUrl || undefined,
    createdAt: u.createdAt || new Date().toISOString(),
    activeListingsCount: u.listingsCount || 0,
    walletBalance: u.walletBalance !== undefined && u.walletBalance !== null ? Number(u.walletBalance) : 0,
    lastActiveAt: u.lastActiveAt || undefined,
    totalSpent: 0,
    totalSales: 0,
    totalBids: 0,
    auctionsWon: 0,
    itemsSoldCount: 0,
    rating: u.trustScore ? Number((u.trustScore / 20).toFixed(1)) : 5.0,
    reviewCount: 0,
  };
}

async function fetchAllUsersFromNetwork(): Promise<User[]> {
  const res = await apiClient.get('/admin/users');
  let rawList: any[] = [];
  if (res.data && Array.isArray(res.data.data)) {
    rawList = res.data.data;
  } else if (Array.isArray(res.data)) {
    rawList = res.data;
  }
  return rawList.map(mapRawToUser);
}

/**
 * Returns all users — from cache if fresh, otherwise from network.
 * If cache exists but is stale, returns cache immediately and revalidates in background.
 */
async function getAllUsersCached(forceRefresh = false): Promise<User[]> {
  const now = Date.now();
  const cacheIsFresh = cachedAllUsers !== null && (now - cacheTimestamp) < CACHE_TTL_MS;

  if (!forceRefresh && cacheIsFresh && cachedAllUsers) {
    return cachedAllUsers;
  }

  // If we have a stale cache, return it and revalidate in background
  if (!forceRefresh && cachedAllUsers !== null) {
    fetchAllUsersFromNetwork()
      .then((users) => {
        cachedAllUsers = users;
        cacheTimestamp = Date.now();
      })
      .catch(() => {});
    return cachedAllUsers;
  }

  // No cache at all — must fetch
  const users = await fetchAllUsersFromNetwork();
  cachedAllUsers = users;
  cacheTimestamp = Date.now();
  return users;
}

export const usersApi = {
  /**
   * Returns ALL users (unfiltered) for stat card counts.
   * Uses the in-memory cache for instant response.
   */
  getAllUsers: async (forceRefresh = false): Promise<User[]> => {
    try {
      return await getAllUsersCached(forceRefresh);
    } catch (err) {
      console.error('Failed to fetch users:', err);
      return cachedAllUsers || [];
    }
  },

  /**
   * Returns a filtered + paginated page of users.
   * All filtering happens client-side — zero network calls after initial load.
   */
  getUsers: async (params?: UserFilterParams): Promise<PageResponse<User>> => {
    try {
      const allUsers = await getAllUsersCached();

      let filtered = [...allUsers];

      // Role filter
      if (params?.role && params.role !== 'ALL') {
        filtered = filtered.filter((u) => u.role === params.role);
      }

      // Status filter
      if (params?.status && params.status !== 'ALL') {
        if (params.status === 'ACTIVE') filtered = filtered.filter((u) => u.active);
        else if (params.status === 'SUSPENDED') filtered = filtered.filter((u) => !u.active);
        else if (params.status === 'VERIFIED') filtered = filtered.filter((u) => u.identityVerified);
      }

      // Search filter
      if (params?.search) {
        const q = params.search.toLowerCase();
        filtered = filtered.filter(
          (u) =>
            u.name.toLowerCase().includes(q) ||
            u.phone.toLowerCase().includes(q) ||
            (u.city && u.city.toLowerCase().includes(q)) ||
            (u.email && u.email.toLowerCase().includes(q))
        );
      }

      const page = params?.page || 0;
      const size = params?.size || 50;
      const start = page * size;
      const paginated = filtered.slice(start, start + size);

      return {
        content: paginated,
        totalElements: filtered.length,
        totalPages: Math.ceil(filtered.length / size) || 1,
        size,
        number: page,
        first: page === 0,
        last: start + size >= filtered.length,
      };
    } catch (err) {
      console.error('Failed to fetch real users from backend:', err);
      return {
        content: [],
        totalElements: 0,
        totalPages: 0,
        size: params?.size || 10,
        number: params?.page || 0,
        first: true,
        last: true,
      };
    }
  },

  getUserById: async (id: string): Promise<User | null> => {
    try {
      // Try cache first for instant response
      const allUsers = await getAllUsersCached();
      const cached = allUsers.find((u) => u.id === id);
      if (cached) return cached;

      // Fallback: fetch from network
      const res = await apiClient.get('/admin/users');
      const rawList: any[] = res.data?.data || res.data || [];
      const u = rawList.find((item: any) => item.id === id);
      if (u) {
        return mapRawToUser(u);
      }
    } catch (err) {
      console.error('Error fetching user details:', err);
    }
    return null;
  },

  getUserFullProfile: async (id: string): Promise<any> => {
    try {
      const res = await apiClient.get(`/admin/users/${id}/full-profile`);
      return res.data?.data || res.data || null;
    } catch (err) {
      console.error('Error fetching user full profile from Neon DB:', err);
      return null;
    }
  },

  toggleUserStatus: async (id: string, active?: boolean): Promise<boolean> => {
    try {
      await apiClient.post(`/admin/users/${id}/toggle-status`, { active });
      // Invalidate cache so next load reflects the change
      cachedAllUsers = null;
      return true;
    } catch (err) {
      console.error('Error updating user status:', err);
      return false;
    }
  },

  creditUserWallet: async (id: string, amount: number, note?: string): Promise<any> => {
    try {
      const res = await apiClient.post(`/admin/users/${id}/wallet/credit`, { amount, note });
      cachedAllUsers = null; // Invalidate cache
      return res.data?.data || res.data;
    } catch (err) {
      console.error('Error crediting user wallet:', err);
      throw err;
    }
  },

  toggleFreezeWallet: async (id: string): Promise<any> => {
    try {
      const res = await apiClient.post(`/admin/users/${id}/wallet/toggle-freeze`, {});
      cachedAllUsers = null; // Invalidate cache
      return res.data?.data || res.data;
    } catch (err) {
      console.error('Error toggling wallet freeze:', err);
      throw err;
    }
  },

  /** Force-clear the cache (e.g., after mutations) */
  invalidateCache: () => {
    cachedAllUsers = null;
    cacheTimestamp = 0;
  },
};
