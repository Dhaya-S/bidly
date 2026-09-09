import { create } from 'zustand';
import type { User } from '../types';
import { authApi } from '../api';

interface AuthState {
  token: string | null;
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, otp: string) => Promise<void>;
  logout: () => void;
  initialize: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  token: localStorage.getItem('bidly_admin_token'),
  user: authApi.getCurrentUser(),
  isAuthenticated: !!localStorage.getItem('bidly_admin_token'),
  isLoading: false,

  initialize: () => {
    const token = localStorage.getItem('bidly_admin_token');
    const user = authApi.getCurrentUser();
    set({
      token,
      user,
      isAuthenticated: !!token,
    });
  },

  login: async (email: string, otp: string) => {
    set({ isLoading: true });
    try {
      const res = await authApi.verifyOtp({ email, otp });
      set({
        token: res.token,
        user: res.user,
        isAuthenticated: true,
        isLoading: false,
      });
    } catch (err) {
      set({ isLoading: false });
      throw err;
    }
  },

  logout: () => {
    authApi.logout();
    set({
      token: null,
      user: null,
      isAuthenticated: false,
    });
  },
}));
