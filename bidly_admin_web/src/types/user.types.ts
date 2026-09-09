export type SellerType = 'INDIVIDUAL' | 'BUSINESS';

export interface User {
  id: string;
  phone: string;
  name: string;
  email?: string;
  sellerType?: SellerType;
  avatarUrl?: string;
  city?: string;
  state?: string;
  active: boolean;
  identityVerified: boolean;
  identityProvider?: string;
  trustScore?: number;
  address?: string;
  pincode?: string;
  latitude?: number;
  longitude?: number;
  searchRadiusKm?: number;
  onboardingCompleted?: boolean;
  interests?: string[];
  role?: 'BUYER' | 'SELLER' | 'BOTH' | 'ADMIN';
  walletBalance?: number;
  totalSpent?: number;
  totalSales?: number;
  totalBids?: number;
  auctionsWon?: number;
  activeListingsCount?: number;
  itemsSoldCount?: number;
  rating?: number;
  reviewCount?: number;
  preferredMeetingRadiusKm?: number;
  serviceRadiusKm?: number;
  category?: string;
  createdAt: string;
  updatedAt?: string;
  lastActiveAt?: string;
}

export interface UserFilterParams {
  role?: string;
  status?: string;
  search?: string;
  page?: number;
  size?: number;
}
