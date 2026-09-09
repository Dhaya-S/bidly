export interface PlatformSettings {
  platformFeePercentage: number;
  devWalletEnabled: boolean;
  maxVideoDurationSeconds: number;
  maxVideoSizeMb: number;
  autoApproveListings: boolean;
  minAuctionDurationHours: number;
  defaultRadiusKm: number;
  featureFlags: {
    communityPosts: boolean;
    directChat: boolean;
    walletTopup: boolean;
    auctionsLive: boolean;
  };
}
