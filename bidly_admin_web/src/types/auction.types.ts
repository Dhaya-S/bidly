import type { User } from './user.types';
import type { Listing } from './listing.types';

export type BidStatus = 'ACTIVE' | 'OUTBID' | 'WON' | 'LOST' | 'WITHDRAWN';

export interface Bid {
  id: string;
  listingId?: string;
  listing?: Listing;
  bidder: User;
  amount: number;
  deliveryAddressId?: string;
  clientBidId?: string;
  status: BidStatus;
  createdAt: string;
}

export interface AuctionSummary {
  id: string;
  title: string;
  category: string;
  sellerId: string;
  sellerName: string;
  sellerStoreName?: string;
  startPrice: number;
  currentBid: number;
  bidsCount: number;
  watchersCount: number;
  endsAt: string;
  status: 'LIVE' | 'ENDING_SOON' | 'UPCOMING' | 'COMPLETED';
}
