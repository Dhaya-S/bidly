import { apiClient } from './client';
import type { Wallet, WalletTransaction, PageResponse } from '../types';
import { usersApi } from './users.api';

export const walletsApi = {
  getWallets: async (params?: any): Promise<PageResponse<Wallet>> => {
    try {
      // Reuse users cache instead of making a separate /admin/users call
      const rawUsers = await usersApi.getAllUsers();

      let wallets: Wallet[] = rawUsers.map((u: any) => ({
        id: `wall-${u.id}`,
        userId: u.id,
        user: {
          id: u.id,
          name: u.name || 'Bidly User',
          phone: u.phone || 'N/A',
          role: u.role || 'SELLER',
          active: u.active ?? true,
          identityVerified: u.identityVerified ?? false,
          createdAt: u.createdAt || new Date().toISOString(),
        },
        balance: u.walletBalance || 50000,
        reservedBalance: 0,
        availableBalance: u.walletBalance || 50000,
        status: u.active ? 'ACTIVE' : 'FROZEN',
        createdAt: u.createdAt || new Date().toISOString(),
      }));

      if (params?.search) {
        const q = params.search.toLowerCase();
        wallets = wallets.filter(
          (w) =>
            w.user?.name.toLowerCase().includes(q) ||
            w.user?.phone.includes(q)
        );
      }

      const page = params?.page || 0;
      const size = params?.size || 50;
      const start = page * size;
      const paginated = wallets.slice(start, start + size);

      return {
        content: paginated,
        totalElements: wallets.length,
        totalPages: Math.ceil(wallets.length / size) || 1,
        size,
        number: page,
        first: page === 0,
        last: start + size >= wallets.length,
      };
    } catch (err) {
      console.error('Failed to fetch real wallets:', err);
      return {
        content: [],
        totalElements: 0,
        totalPages: 0,
        size: 10,
        number: 0,
        first: true,
        last: true,
      };
    }
  },

  getWalletByUser: async (userId: string): Promise<Wallet | null> => {
    try {
      const allUsers = await usersApi.getAllUsers();
      const u = allUsers.find((item) => item.id === userId);
      if (u) {
        return {
          id: `wall-${u.id}`,
          userId: u.id,
          user: {
            id: u.id,
            name: u.name || 'Bidly User',
            phone: u.phone || 'N/A',
            role: u.role || 'SELLER',
            active: u.active ?? true,
            identityVerified: u.identityVerified ?? false,
            createdAt: u.createdAt || new Date().toISOString(),
          },
          balance: u.walletBalance || 50000,
          reservedBalance: 0,
          availableBalance: u.walletBalance || 50000,
          status: u.active ? 'ACTIVE' : 'FROZEN',
          createdAt: u.createdAt || new Date().toISOString(),
        };
      }
    } catch (err) {
      console.error('Failed to get user wallet:', err);
    }
    return null;
  },

  getTransactionsByUser: async (_userId: string): Promise<WalletTransaction[]> => {
    return [];
  },

  creditWallet: async (_userId: string, _amount: number, _description: string): Promise<void> => {
    // Call backend API when credit adjustment endpoint is wired
  },

  toggleFreezeWallet: async (_userId: string): Promise<void> => {
    // Call backend API when toggle freeze endpoint is wired
  },
};
