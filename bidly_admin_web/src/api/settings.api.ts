import type { PlatformSettings } from '../types';

export const mockSettings: PlatformSettings = {
  platformFeePercentage: 3.0,
  devWalletEnabled: true,
  maxVideoDurationSeconds: 60,
  maxVideoSizeMb: 50,
  autoApproveListings: false,
  minAuctionDurationHours: 1,
  defaultRadiusKm: 25,
  featureFlags: {
    communityPosts: true,
    directChat: true,
    walletTopup: true,
    auctionsLive: true,
  },
};

export const settingsApi = {
  getSettings: async (): Promise<PlatformSettings> => {
    return mockSettings;
  },
  updateSettings: async (updated: Partial<PlatformSettings>): Promise<PlatformSettings> => {
    Object.assign(mockSettings, updated);
    return mockSettings;
  },
};
