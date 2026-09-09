export interface Payment {
  id: string;
  orderId?: string;
  orderNumber?: string;
  userId: string;
  userName?: string;
  amount: number;
  currency: string;
  feeAmount: number;
  gateway: 'RAZORPAY' | 'STRIPE' | 'WALLET' | 'CASH';
  gatewayTransactionId?: string;
  status: 'SUCCESS' | 'PENDING' | 'FAILED' | 'REFUNDED';
  paymentMethod?: string;
  createdAt: string;
}
