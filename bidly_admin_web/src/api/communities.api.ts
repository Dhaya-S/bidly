import { apiClient } from './client';
import type { Community, CommunityMember, PageResponse } from '../types';

// ── Module-level cache ────────────────────────────────────────────────
let cachedCommunities: Community[] | null = null;
let cacheTimestamp = 0;
const CACHE_TTL_MS = 60_000;

async function getAllCommunitiesCached(): Promise<Community[]> {
  const now = Date.now();
  if (cachedCommunities && (now - cacheTimestamp) < CACHE_TTL_MS) {
    return cachedCommunities;
  }

  if (cachedCommunities) {
    // Stale cache: return immediately, refresh in background
    apiClient.get('/communities')
      .then((res) => {
        let list = res.data?.data || res.data || [];
        if (!Array.isArray(list)) list = res.data?.content || [];
        cachedCommunities = list;
        cacheTimestamp = Date.now();
      })
      .catch(() => {});
    return cachedCommunities;
  }

  const res = await apiClient.get('/communities');
  let list = res.data?.data || res.data || [];
  if (!Array.isArray(list)) list = res.data?.content || [];
  cachedCommunities = list;
  cacheTimestamp = Date.now();
  return list;
}

export const communitiesApi = {
  getCommunities: async (params?: any): Promise<PageResponse<Community>> => {
    try {
      let list = await getAllCommunitiesCached();

      if (params?.search) {
        const q = params.search.toLowerCase();
        list = list.filter((c) => c.name?.toLowerCase().includes(q) || c.city?.toLowerCase().includes(q));
      }

      return {
        content: list,
        totalElements: list.length,
        totalPages: 1,
        size: list.length || 10,
        number: 0,
        first: true,
        last: true,
      };
    } catch (err) {
      console.error('Failed to fetch communities from database:', err);
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

  getCommunityById: async (id: string): Promise<Community | null> => {
    try {
      const list = await getAllCommunitiesCached();
      return list.find((c) => c.id === id) || null;
    } catch (err) {
      console.error('Failed to fetch community:', err);
      return null;
    }
  },

  getMembers: async (communityId: string): Promise<CommunityMember[]> => {
    try {
      const res = await apiClient.get(`/communities/${communityId}/members`);
      return res.data?.data || res.data || [];
    } catch {
      return [];
    }
  },
};
