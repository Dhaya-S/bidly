import { apiClient } from './client';
import type { OrderReport, PageResponse } from '../types';

// ── Module-level cache ────────────────────────────────────────────────
let cachedReports: OrderReport[] | null = null;
let cacheTimestamp = 0;
const CACHE_TTL_MS = 60_000;

function mapRawToReport(r: any): OrderReport {
  return {
    id: r.id,
    orderId: r.orderId || '',
    orderNumber: r.orderNumber || 'ORD-UNKNOWN',
    reporterId: r.reporterId || '',
    reason: r.reason || 'Report Reason',
    details: r.details || '',
    status: r.status || 'PENDING_REVIEW',
    priority: 'MEDIUM',
    createdAt: r.createdAt || new Date().toISOString(),
  };
}

async function getAllReportsCached(forceRefresh = false): Promise<OrderReport[]> {
  const now = Date.now();
  if (!forceRefresh && cachedReports && (now - cacheTimestamp) < CACHE_TTL_MS) {
    return cachedReports;
  }

  if (!forceRefresh && cachedReports) {
    apiClient.get('/admin/reports')
      .then((res) => {
        let rawList: any[] = [];
        if (res.data && Array.isArray(res.data.data)) rawList = res.data.data;
        else if (Array.isArray(res.data)) rawList = res.data;
        cachedReports = rawList.map(mapRawToReport);
        cacheTimestamp = Date.now();
      })
      .catch(() => {});
    return cachedReports;
  }

  const res = await apiClient.get('/admin/reports');
  let rawList: any[] = [];
  if (res.data && Array.isArray(res.data.data)) rawList = res.data.data;
  else if (Array.isArray(res.data)) rawList = res.data;
  cachedReports = rawList.map(mapRawToReport);
  cacheTimestamp = Date.now();
  return cachedReports;
}

export const reportsApi = {
  getReports: async (params?: any): Promise<PageResponse<OrderReport>> => {
    try {
      let filtered = await getAllReportsCached();

      if (params?.status && params.status !== 'ALL') {
        filtered = filtered.filter((r) => r.status === params.status);
      }

      return {
        content: filtered,
        totalElements: filtered.length,
        totalPages: Math.ceil(filtered.length / 10) || 1,
        size: 10,
        number: 0,
        first: true,
        last: true,
      };
    } catch (err) {
      console.error('Failed to fetch reports from backend:', err);
      return {
        content: [],
        totalElements: 0,
        totalPages: 0,
        size: 10,
        number: 0,
        first: true,
        last: true,
      };
    }
  },

  getReportById: async (id: string): Promise<OrderReport | null> => {
    try {
      const all = await getAllReportsCached();
      return all.find((r) => r.id === id) || null;
    } catch (err) {
      console.error('Error fetching report by ID:', err);
    }
    return null;
  },

  updateReportStatus: async (id: string, status: any, _adminNotes?: string): Promise<void> => {
    try {
      await apiClient.put(`/admin/reports/${id}/status`, { status });
      cachedReports = null; // Invalidate cache after mutation
    } catch (err) {
      console.error('Failed to update report status:', err);
    }
  },
};
