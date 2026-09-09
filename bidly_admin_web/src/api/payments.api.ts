import { apiClient } from './client';
import type { Payment, PageResponse } from '../types';
import { ordersApi } from './orders.api';

export const paymentsApi = {
  getPayments: async (params?: any): Promise<PageResponse<Payment>> => {
    try {
      // Reuse orders cache instead of making a separate network call
      const allOrders = await ordersApi.getAllOrders();

      let payments: Payment[] = allOrders.map((o: any) => ({
        id: `pay-${o.id}`,
        orderId: o.id,
        orderNumber: o.orderNumber || `ORD-${o.id?.slice(0, 8)}`,
        userId: o.buyer?.id || '',
        userName: o.buyer?.name || 'Buyer',
        amount: o.totalAmount || o.amount || 0,
        currency: 'INR',
        feeAmount: o.platformFee || 0,
        gateway: 'WALLET',
        status: o.paymentStatus === 'RELEASED' ? 'SUCCESS' : o.paymentStatus === 'IN_ESCROW' ? 'PENDING' : 'FAILED',
        paymentMethod: 'UPI',
        createdAt: o.createdAt || new Date().toISOString(),
      }));

      if (params?.status && params.status !== 'ALL') {
        payments = payments.filter((p) => p.status === params.status);
      }

      return {
        content: payments,
        totalElements: payments.length,
        totalPages: Math.ceil(payments.length / 10) || 1,
        size: 10,
        number: 0,
        first: true,
        last: true,
      };
    } catch {
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
};
