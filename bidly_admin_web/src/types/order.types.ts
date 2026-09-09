import type { User } from './user.types';
import type { Listing } from './listing.types';

export type OrderStatus =
  | 'AUCTION_WON'
  | 'ORDER_CONFIRMED'
  | 'SELLER_CONFIRMED'
  | 'PACKED'
  | 'SHIPPED'
  | 'DELIVERED'
  | 'CANCELLED';

export type PaymentStatus = 'PENDING' | 'IN_ESCROW' | 'RELEASED' | 'REFUNDED';

export type DeliveryType = 'COURIER' | 'IN_PERSON_MEETUP';

export interface OrderTrackingEvent {
  id?: string;
  status: OrderStatus;
  description: string;
  timestamp: string;
  location?: string;
}

export interface Order {
  id: string;
  orderNumber: string;
  listing: Listing;
  buyer: User;
  seller: User;
  winningBidId?: string;
  offerId?: string;
  orderSource: 'AUCTION' | 'DIRECT_SALE';
  deliveryType: DeliveryType;
  meetupLocation?: string;
  meetupTime?: string;
  meetupOtp?: string;
  meetupOtpVerified?: boolean;
  meetupNotes?: string;
  isMeetupConfirmed?: boolean;
  deliveryAddress?: any;
  amount: number;
  platformFee: number;
  totalAmount: number;
  status: OrderStatus;
  paymentStatus: PaymentStatus;
  courierPartner?: string;
  trackingNumber?: string;
  estimatedDeliveryDate?: string;
  deliveredAt?: string;
  trackingEvents?: OrderTrackingEvent[];
  createdAt: string;
  updatedAt?: string;
}
