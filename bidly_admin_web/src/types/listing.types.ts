import type { User } from './user.types';
import type { Category } from './category.types';

export type ListingCondition =
  | 'NEW'
  | 'LIKE_NEW'
  | 'EXCELLENT'
  | 'GOOD'
  | 'FAIR'
  | 'POOR'
  | 'USED'
  | 'REFURBISHED';

export type ListingStatus = 'ACTIVE' | 'SOLD' | 'EXPIRED' | 'DELETED' | 'SUSPENDED';

export type SellingMethod = 'DIRECT_BUY' | 'AUCTION';

export interface ListingMedia {
  id?: string;
  mediaType: 'IMAGE' | 'VIDEO';
  objectKey: string;
  url?: string;
  thumbnailKey?: string;
  isPrimary?: boolean;
  sortOrder?: number;
}

export interface Listing {
  id: string;
  title: string;
  description?: string;
  price: number;
  category?: Category;
  categoryId?: string;
  subcategory?: string;
  seller: User;
  sellerId?: string;
  city?: string;
  state?: string;
  locality?: string;
  condition: ListingCondition;
  purchaseDate?: string;
  hasDamage?: boolean;
  damageDetails?: string;
  status: ListingStatus;
  sellingMethod: SellingMethod;
  sellingScope?: string;
  communityId?: string;
  communityName?: string;
  targetRadiusKm?: number;
  startingBid?: number;
  currentBid?: number;
  bidIncrement?: number;
  auctionEndTime?: string;
  primaryImageUrl?: string;
  reelUrl?: string;
  mediaProcessingStatus?: 'PROCESSING' | 'READY' | 'FAILED';
  rating?: number;
  distanceKm?: number;
  featured?: boolean;
  viewsCount?: number;
  likesCount?: number;
  bidsCount?: number;
  watchersCount?: number;
  latitude?: number;
  longitude?: number;
  media?: ListingMedia[];
  createdAt: string;
  updatedAt?: string;
}

export interface ListingFilterParams {
  category?: string;
  status?: string;
  sellingMethod?: SellingMethod;
  search?: string;
  page?: number;
  size?: number;
}
