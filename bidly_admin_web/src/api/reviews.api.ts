import { apiClient } from './client';
import type { Review, PageResponse } from '../types';

// ── Module-level cache ────────────────────────────────────────────────
let cachedReviews: Review[] | null = null;
let cacheTimestamp = 0;
const CACHE_TTL_MS = 60_000;

export const reviewsApi = {
  getReviews: async (): Promise<PageResponse<Review>> => {
    try {
      const now = Date.now();
      if (cachedReviews && (now - cacheTimestamp) < CACHE_TTL_MS) {
        return {
          content: cachedReviews,
          totalElements: cachedReviews.length,
          totalPages: Math.ceil(cachedReviews.length / 10) || 1,
          size: 10,
          number: 0,
          first: true,
          last: true,
        };
      }

      // Fetch top sellers first to get their reviews
      const sellersRes = await apiClient.get('/listings/top-sellers');
      const sellers: any[] = sellersRes.data?.data || sellersRes.data || [];
      const allReviews: Review[] = [];

      // Fetch reviews for top 5 sellers in PARALLEL (not sequential N+1)
      const reviewPromises = sellers.slice(0, 5).map(async (seller) => {
        if (!seller.id) return [];
        try {
          const revRes = await apiClient.get(`/reviews/seller/${seller.id}`);
          const revs = revRes.data?.data || revRes.data || [];
          if (Array.isArray(revs)) {
            return revs.map((r: any) => ({
              id: r.id || `rev-${Math.random()}`,
              reviewerId: r.reviewer?.id || '',
              reviewerName: r.reviewer?.name || 'Customer',
              targetUserId: seller.id,
              targetUserName: seller.name || 'Seller',
              rating: r.rating || 5,
              comment: r.comment || '',
              status: 'PUBLISHED' as const,
              createdAt: r.createdAt || new Date().toISOString(),
            }));
          }
        } catch {
          // Ignore if seller has no reviews
        }
        return [];
      });

      const results = await Promise.all(reviewPromises);
      results.forEach((revs) => allReviews.push(...(revs as Review[])));

      cachedReviews = allReviews;
      cacheTimestamp = Date.now();

      return {
        content: allReviews,
        totalElements: allReviews.length,
        totalPages: Math.ceil(allReviews.length / 10) || 1,
        size: 10,
        number: 0,
        first: true,
        last: true,
      };
    } catch {
      return {
        content: cachedReviews || [],
        totalElements: cachedReviews?.length || 0,
        totalPages: 0,
        size: 10,
        number: 0,
        first: true,
        last: true,
      };
    }
  },
};
