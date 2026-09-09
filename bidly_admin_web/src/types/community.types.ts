export interface Community {
  id: string;
  name: string;
  description?: string;
  iconUrl?: string;
  bannerUrl?: string;
  type: 'NEIGHBORHOOD' | 'COLLEGE' | 'INTEREST' | 'COMPANY' | 'OTHER';
  category?: string;
  city?: string;
  state?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  radiusKm?: number;
  rules?: string;
  createdBy: string;
  membersCount: number;
  recentActivityText?: string;
  recentActivityTime?: string;
  active: boolean;
  createdAt: string;
  updatedAt?: string;
}

export interface CommunityMember {
  id: string;
  communityId: string;
  userId: string;
  name: string;
  avatarUrl?: string;
  role: 'ADMIN' | 'MODERATOR' | 'MEMBER';
  joinedAt: string;
}

export interface CommunityPost {
  id: string;
  communityId: string;
  userId: string;
  authorName: string;
  authorAvatar?: string;
  content: string;
  mediaUrls?: string[];
  likesCount: number;
  commentsCount?: number;
  createdAt: string;
}
