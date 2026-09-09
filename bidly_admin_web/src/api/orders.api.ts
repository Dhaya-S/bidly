import { apiClient } from './client';
import type { Order, PageResponse } from '../types';

// ── Module-level in-memory cache ──────────────────────────────────────
let cachedOrders: Order[] | null = null;
let cacheTimestamp = 0;
const CACHE_TTL_MS = 60_000; // 1 minute

function mapRawToOrder(o: any): Order {
  return {
    id: o.id,
    orderNumber: o.orderNumber || `ORD-${o.id?.slice(0, 8)}`,
    orderSource: o.orderSource || 'DIRECT_SALE',
    deliveryType: o.deliveryType || 'COURIER',
    amount: o.amount || 0,
    platformFee: o.platformFee || 0,
    totalAmount: o.totalAmount || o.amount || 0,
    status: o.status || 'PENDING',
    paymentStatus: o.paymentStatus || 'PENDING',
    courierPartner: o.courierPartner,
    trackingNumber: o.trackingNumber,
    createdAt: o.createdAt || new Date().toISOString(),
    buyer: o.buyer || {
      id: 'unknown',
      name: 'Buyer',
      phone: '',
      role: 'BUYER',
      active: true,
      identityVerified: false,
      createdAt: new Date().toISOString(),
    },
    seller: o.seller || {
      id: 'unknown',
      name: 'Seller',
      phone: '',
      role: 'SELLER',
      active: true,
      identityVerified: false,
      createdAt: new Date().toISOString(),
    },
    listing: o.listing || {
      id: 'unknown',
      title: 'Product',
      price: o.amount || 0,
      currency: 'INR',
      sellingMethod: 'DIRECT_BUY',
      status: 'SOLD',
      createdAt: new Date().toISOString(),
    },
  };
}

async function fetchAllOrdersFromNetwork(): Promise<Order[]> {
  const res = await apiClient.get('/admin/orders');
  let rawList: any[] = [];
  if (res.data && Array.isArray(res.data.data)) {
    rawList = res.data.data;
  } else if (Array.isArray(res.data)) {
    rawList = res.data;
  }
  return rawList.map(mapRawToOrder);
}

async function getAllOrdersCached(forceRefresh = false): Promise<Order[]> {
  const now = Date.now();
  const cacheIsFresh = cachedOrders !== null && (now - cacheTimestamp) < CACHE_TTL_MS;

  if (!forceRefresh && cacheIsFresh && cachedOrders) {
    return cachedOrders;
  }

  if (!forceRefresh && cachedOrders !== null) {
    // Return stale cache, revalidate in background
    fetchAllOrdersFromNetwork()
      .then((orders) => { cachedOrders = orders; cacheTimestamp = Date.now(); })
      .catch(() => {});
    return cachedOrders;
  }

  const orders = await fetchAllOrdersFromNetwork();
  cachedOrders = orders;
  cacheTimestamp = Date.now();
  return orders;
}

export const ordersApi = {
  getAllOrders: async (forceRefresh = false): Promise<Order[]> => {
    try {
      return await getAllOrdersCached(forceRefresh);
    } catch (err) {
      console.error('Failed to fetch orders:', err);
      return cachedOrders || [];
    }
  },

  getOrders: async (params?: any): Promise<PageResponse<Order>> => {
    try {
      const allOrders = await getAllOrdersCached();
      let filtered = [...allOrders];

      if (params?.status && params.status !== 'ALL') {
        filtered = filtered.filter((o) => o.status === params.status);
      }
      if (params?.search) {
        const q = params.search.toLowerCase();
        filtered = filtered.filter(
          (o) =>
            o.orderNumber.toLowerCase().includes(q) ||
            o.buyer?.name?.toLowerCase().includes(q) ||
            o.seller?.name?.toLowerCase().includes(q) ||
            o.listing?.title?.toLowerCase().includes(q)
        );
      }

      const page = params?.page || 0;
      const size = params?.size || 50;
      const start = page * size;
      const paginated = filtered.slice(start, start + size);

      return {
        content: paginated,
        totalElements: filtered.length,
        totalPages: Math.ceil(filtered.length / size) || 1,
        size,
        number: page,
        first: page === 0,
        last: start + size >= filtered.length,
      };
    } catch (err) {
      console.error('Failed to fetch real orders:', err);
      return {
        content: [],
        totalElements: 0,
        totalPages: 0,
        size: params?.size || 10,
        number: params?.page || 0,
        first: true,
        last: true,
      };
    }
  },

  getOrderById: async (id: string): Promise<Order | null> => {
    try {
      const allOrders = await getAllOrdersCached();
      return allOrders.find((o) => o.id === id || o.orderNumber === id) || null;
    } catch (err) {
      console.error('Error fetching order by ID:', err);
    }
    return null;
  },

  getOrdersByUser: async (userId: string): Promise<Order[]> => {
    try {
      const allOrders = await getAllOrdersCached();
      return allOrders.filter((o) => o.buyer?.id === userId || o.seller?.id === userId);
    } catch {
      return [];
    }
  },
};
