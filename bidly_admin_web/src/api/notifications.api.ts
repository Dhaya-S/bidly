import type { AdminNotification } from '../types';

export const mockNotifications: AdminNotification[] = [
  {
    id: 'notif-1',
    title: 'Critical Dispute Filed',
    message: 'Buyer Priya Singh filed an urgent dispute on Order ORD-2024-9841.',
    type: 'DISPUTE',
    read: false,
    targetUrl: '/reports',
    createdAt: '15 mins ago',
  },
  {
    id: 'notif-2',
    title: 'Auction Ending Soon',
    message: 'Vintage Gibson Les Paul 1959 is ending in under 20 minutes.',
    type: 'ALERT',
    read: false,
    targetUrl: '/marketplace/auctions',
    createdAt: '25 mins ago',
  },
  {
    id: 'notif-3',
    title: 'High Value Order Placed',
    message: 'Order ORD-2024-9843 for ₹1,60,000 confirmed into escrow.',
    type: 'ORDER',
    read: true,
    targetUrl: '/orders',
    createdAt: '2 hours ago',
  },
];

export const notificationsApi = {
  getNotifications: async (): Promise<AdminNotification[]> => {
    return mockNotifications;
  },
  markAsRead: async (id: string): Promise<void> => {
    const n = mockNotifications.find((item) => item.id === id);
    if (n) n.read = true;
  },
};
