import { apiClient, getMediaUrl } from './client';
import type { Listing, ListingFilterParams, PageResponse } from '../types';

export const listingsApi = {
  getListings: async (params?: ListingFilterParams): Promise<PageResponse<Listing>> => {
    try {
      const queryParams: any = {
        size: params?.size || 50,
        page: params?.page || 0,
      };
      if (params?.sellingMethod) queryParams.method = params.sellingMethod;
      if (params?.category && params.category !== 'All') queryParams.category = params.category;
      if (params?.search) queryParams.q = params.search;

      const res = await apiClient.get('/listings/search', { params: queryParams });
      const rawList: any[] = res.data?.data || res.data || [];

      const mappedList: Listing[] = rawList.map((item) => ({
        id: item.id,
        title: item.title,
        description: item.description,
        price: Number(item.price) || 0,
        startingBid: item.startingBid ? Number(item.startingBid) : undefined,
        currentBid: item.currentBid ? Number(item.currentBid) : (item.startingBid ? Number(item.startingBid) : Number(item.price) || 0),
        bidIncrement: item.bidIncrement ? Number(item.bidIncrement) : undefined,
        auctionEndTime: item.auctionEndTime,
        bidsCount: item.bidsCount || 0,
        watchersCount: item.likesCount || 0,
        category: {
          id: item.categoryName || 'general',
          name: item.categoryName || 'General',
          active: true,
        },
        subcategory: item.subcategory,
        seller: {
          id: item.sellerId || 'seller-0',
          name: item.sellerName || 'Marketplace Seller',
          phone: item.sellerPhone || '',
          active: true,
          identityVerified: true,
          createdAt: new Date().toISOString(),
        },
        sellerId: item.sellerId,
        city: item.city || 'Chennai',
        state: item.state || 'Tamil Nadu',
        locality: item.locality,
        condition: item.condition || 'EXCELLENT',
        status: item.status || 'ACTIVE',
        sellingMethod: item.sellingMethod || 'DIRECT_BUY',
        primaryImageUrl: getMediaUrl(item.primaryImageUrl),
        reelUrl: getMediaUrl(item.reelUrl),
        viewsCount: item.viewsCount || 0,
        likesCount: item.likesCount || 0,
        createdAt: item.createdAt || new Date().toISOString(),
      }));

      return {
        content: mappedList,
        totalElements: mappedList.length,
        totalPages: 1,
        size: mappedList.length || 10,
        number: 0,
        first: true,
        last: true,
      };
    } catch (err) {
      console.error('Failed to fetch realtime listings from database:', err);
      return {
        content: [],
        totalElements: 0,
        totalPages: 1,
        size: 10,
        number: 0,
        first: true,
        last: true,
      };
    }
  },

  getListingById: async (id: string): Promise<Listing | null> => {
    try {
      const res = await apiClient.get(`/listings/${id}`);
      const item = res.data?.data || res.data;
      if (!item) return null;
      return {
        id: item.id,
        title: item.title,
        description: item.description,
        price: Number(item.price) || 0,
        startingBid: item.startingBid ? Number(item.startingBid) : undefined,
        currentBid: item.currentBid ? Number(item.currentBid) : (item.startingBid ? Number(item.startingBid) : Number(item.price) || 0),
        bidIncrement: item.bidIncrement ? Number(item.bidIncrement) : undefined,
        auctionEndTime: item.auctionEndTime,
        bidsCount: item.bidsCount || 0,
        watchersCount: item.likesCount || 0,
        category: {
          id: item.categoryName || 'general',
          name: item.categoryName || 'General',
          active: true,
        },
        subcategory: item.subcategory,
        seller: {
          id: item.sellerId || 'seller-0',
          name: item.sellerName || 'Marketplace Seller',
          phone: item.sellerPhone || '',
          active: true,
          identityVerified: true,
          createdAt: new Date().toISOString(),
        },
        sellerId: item.sellerId,
        city: item.city,
        state: item.state,
        locality: item.locality,
        condition: item.condition || 'EXCELLENT',
        status: item.status || 'ACTIVE',
        sellingMethod: item.sellingMethod || 'DIRECT_BUY',
        primaryImageUrl: getMediaUrl(item.primaryImageUrl),
        reelUrl: getMediaUrl(item.reelUrl),
        viewsCount: item.viewsCount || 0,
        likesCount: item.likesCount || 0,
        createdAt: item.createdAt || new Date().toISOString(),
      };
    } catch (err) {
      console.error('Failed to fetch listing detail from database:', err);
      return null;
    }
  },

  getListingsBySeller: async (sellerId: string): Promise<Listing[]> => {
    try {
      const res = await apiClient.get(`/listings/search`);
      const rawList: any[] = res.data?.data || res.data || [];
      return rawList
        .filter((item) => item.sellerId === sellerId)
        .map((item) => ({
          id: item.id,
          title: item.title,
          description: item.description,
          price: Number(item.price) || 0,
          startingBid: item.startingBid ? Number(item.startingBid) : undefined,
          currentBid: item.currentBid ? Number(item.currentBid) : Number(item.price) || 0,
          condition: item.condition || 'EXCELLENT',
          status: item.status || 'ACTIVE',
          sellingMethod: item.sellingMethod || 'DIRECT_BUY',
          primaryImageUrl: getMediaUrl(item.primaryImageUrl),
          seller: {
            id: item.sellerId,
            name: item.sellerName,
            phone: '',
            active: true,
            identityVerified: true,
            createdAt: new Date().toISOString(),
          },
          createdAt: item.createdAt || new Date().toISOString(),
        }));
    } catch {
      return [];
    }
  },
};
