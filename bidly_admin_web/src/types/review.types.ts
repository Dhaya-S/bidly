export interface Review {
  id: string;
  reviewerId: string;
  reviewerName: string;
  reviewerAvatar?: string;
  targetUserId: string;
  targetUserName: string;
  orderId?: string;
  rating: number;
  comment: string;
  flagged?: boolean;
  flagReason?: string;
  status: 'PUBLISHED' | 'FLAGGED' | 'HIDDEN';
  createdAt: string;
}
