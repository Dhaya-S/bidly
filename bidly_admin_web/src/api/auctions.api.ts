import { apiClient } from './client';
import type { Bid, AuctionSummary } from '../types';

export const auctionsApi = {
  getBidsForListing: async (listingId: string): Promise<Bid[]> => {
    try {
      const res = await apiClient.get(`/auctions/${listingId}`);
      const data = res.data?.data;
      if (!data || !data.recentBids) return [];
      return data.recentBids.map((b: any, index: number) => ({
        id: b.id || `bid-${index}`,
        listingId,
        bidder: {
          id: b.bidderId || 'bidder',
          name: b.bidderName || 'Bidder',
          phone: '',
          active: true,
          identityVerified: true,
          createdAt: b.timestamp || new Date().toISOString(),
        },
        amount: Number(b.amount) || 0,
        status: index === 0 ? 'ACTIVE' : 'OUTBID',
        createdAt: b.timestamp || new Date().toISOString(),
      }));
    } catch {
      return [];
    }
  },

  getActiveAuctions: async (): Promise<AuctionSummary[]> => {
    try {
      const res = await apiClient.get('/listings/search', { params: { method: 'AUCTION' } });
      const list: any[] = res.data?.data || res.data || [];

      return list.map((item) => {
        let status: 'LIVE' | 'ENDING_SOON' | 'UPCOMING' | 'COMPLETED' = 'LIVE';
        if (item.status === 'COMPLETED' || item.status === 'EXPIRED') {
          status = 'COMPLETED';
        } else if (item.auctionEndTime) {
          const remainingMs = new Date(item.auctionEndTime).getTime() - Date.now();
          if (remainingMs <= 0) {
            status = 'COMPLETED';
          } else if (remainingMs < 30 * 60 * 1000) {
            status = 'ENDING_SOON';
          }
        }

        return {
          id: item.id,
          title: item.title,
          category: item.categoryName || 'General',
          sellerId: item.sellerId,
          sellerName: item.sellerName,
          sellerStoreName: item.sellerName,
          startPrice: item.startingBid ? Number(item.startingBid) : Number(item.price) || 0,
          currentBid: item.currentBid ? Number(item.currentBid) : (item.startingBid ? Number(item.startingBid) : Number(item.price) || 0),
          bidsCount: item.bidsCount || 0,
          watchersCount: item.likesCount || 0,
          endsAt: item.auctionEndTime || new Date().toISOString(),
          status,
        };
      });
    } catch (err) {
      console.error('Failed to fetch realtime auctions:', err);
      return [];
    }
  },
};
