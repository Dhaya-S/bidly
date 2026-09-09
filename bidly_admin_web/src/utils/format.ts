import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';

dayjs.extend(relativeTime);

export const formatRupee = (amount?: number | null, compact: boolean = false): string => {
  if (amount === undefined || amount === null) return '₹0';

  if (compact) {
    if (Math.abs(amount) >= 10000000) {
      return `₹${(amount / 10000000).toFixed(2)}Cr`;
    }
    if (Math.abs(amount) >= 100000) {
      return `₹${(amount / 100000).toFixed(2)}L`;
    }
    if (Math.abs(amount) >= 1000) {
      return `₹${(amount / 1000).toFixed(1)}K`;
    }
  }

  // Indian Rupee formatting (e.g., ₹2,34,000)
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(amount);
};

export const formatDate = (dateStr?: string | null): string => {
  if (!dateStr) return '-';
  return dayjs(dateStr).format('YYYY-MM-DD');
};

export const formatDateTime = (dateStr?: string | null): string => {
  if (!dateStr) return '-';
  return dayjs(dateStr).format('YYYY-MM-DD HH:mm');
};

export const formatTimeAgo = (dateStr?: string | null): string => {
  if (!dateStr) return '-';
  return dayjs(dateStr).fromNow();
};

export const getInitials = (name?: string): string => {
  if (!name) return 'U';
  const parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return name.slice(0, 2).toUpperCase();
};

// Generates consistent pleasing background colors for avatar initials
export const getAvatarColor = (name: string): string => {
  const colors = [
    '#0D9488', // Teal
    '#3B82F6', // Blue
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#F59E0B', // Amber
    '#10B981', // Emerald
    '#6366F1', // Indigo
    '#F97316', // Orange
  ];
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return colors[Math.abs(hash) % colors.length];
};
