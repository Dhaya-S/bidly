export interface DashboardKpis {
  totalUsers: number;
  usersTrendThisWeek: number;
  activeAuctions: number;
  auctionsEndingSoon: number;
  revenueMtd: number;
  revenueTrendPercent: number;
  pendingDisputes: number;
  criticalDisputes: number;
}

export interface UserGrowthStats {
  totalBuyers: number;
  buyersGrowthPercent: number;
  totalSellers: number;
  sellersGrowthPercent: number;
  newThisMonth: number;
  buyerSellerRatio: string;
  monthlyData: {
    month: string;
    buyers: number;
    sellers: number;
  }[];
}

export interface RevenueDataPoint {
  month: string;
  revenue: number;
  target?: number;
}

export interface AuctionActivityDataPoint {
  month: string;
  count?: number;
  total?: number;
  completed?: number;
}

export interface LiveActivityEvent {
  id: string;
  type: 'bid' | 'user' | 'listing' | 'order' | 'seller_verified';
  actor: string;
  action: string;
  timestamp: string;
}

export interface FraudAlertItem {
  id: string;
  title: string;
  description: string;
  severity: 'critical' | 'high' | 'warning';
  timestamp: string;
}

export interface DashboardAuctionItem {
  id: string;
  title: string;
  category: string;
  sellerName: string;
  currentBid: number;
  bidsCount: number;
  endsAt: string | null;
  status: string;
}

export interface FullDashboardData {
  kpis: DashboardKpis;
  revenueOverview: RevenueDataPoint[];
  auctionActivity: AuctionActivityDataPoint[];
  userGrowth: UserGrowthStats;
  liveActivities: LiveActivityEvent[];
  fraudAlerts: FraudAlertItem[];
  liveAuctions: DashboardAuctionItem[];
}
