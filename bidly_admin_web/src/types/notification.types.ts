export interface AdminNotification {
  id: string;
  title: string;
  message: string;
  type: 'INFO' | 'WARNING' | 'ALERT' | 'ORDER' | 'DISPUTE';
  read: boolean;
  targetUrl?: string;
  createdAt: string;
}
