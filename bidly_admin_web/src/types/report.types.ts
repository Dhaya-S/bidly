import type { User } from './user.types';
import type { Order } from './order.types';

export type ReportStatus = 'PENDING_REVIEW' | 'REVIEWED' | 'RESOLVED' | 'DISMISSED';

export interface OrderReport {
  id: string;
  orderId: string;
  order?: Order;
  orderNumber?: string;
  reporterId: string;
  reporter?: User;
  reason: string;
  details: string;
  status: ReportStatus;
  priority?: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
  adminNotes?: string;
  createdAt: string;
  updatedAt?: string;
}
