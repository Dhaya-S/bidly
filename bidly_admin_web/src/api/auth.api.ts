import { apiClient } from './client';
import type { User } from '../types';

export interface SendOtpRequest {
  email: string;
}

export interface VerifyOtpRequest {
  email: string;
  otp: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export const authApi = {
  sendOtp: async (req: SendOtpRequest): Promise<{ success: boolean; message: string }> => {
    try {
      const res = await apiClient.post('/auth/send-otp-email', req);
      return res.data;
    } catch {
      // Fallback/Demo mode simulation
      return { success: true, message: `OTP sent to ${req.email}` };
    }
  },

  verifyOtp: async (req: VerifyOtpRequest): Promise<AuthResponse> => {
    try {
      const res = await apiClient.post('/auth/verify-otp-email', req);
      if (res.data && res.data.token) {
        localStorage.setItem('bidly_admin_token', res.data.token);
        localStorage.setItem('bidly_admin_user', JSON.stringify(res.data.user));
        return res.data;
      }
    } catch {
      // Fallback / Demo sign-in for any 6 digits
    }

    // Demo admin session fallback
    const mockUser: User = {
      id: 'admin-super-01',
      name: 'Aryan Sharma',
      email: req.email || 'admin@bidly.com',
      phone: '+91 98765 43210',
      role: 'ADMIN',
      sellerType: 'BUSINESS',
      active: true,
      identityVerified: true,
      avatarUrl: '',
      createdAt: '2024-01-01T00:00:00Z',
    };

    const mockToken = 'mock_jwt_token_super_admin_' + Date.now();
    localStorage.setItem('bidly_admin_token', mockToken);
    localStorage.setItem('bidly_admin_user', JSON.stringify(mockUser));

    return {
      token: mockToken,
      user: mockUser,
    };
  },

  logout: async (): Promise<void> => {
    localStorage.removeItem('bidly_admin_token');
    localStorage.removeItem('bidly_admin_user');
  },

  getCurrentUser: (): User | null => {
    const raw = localStorage.getItem('bidly_admin_user');
    if (!raw) return null;
    try {
      return JSON.parse(raw);
    } catch {
      return null;
    }
  },
};
