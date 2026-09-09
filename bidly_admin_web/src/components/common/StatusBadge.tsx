import React from 'react';

export type BadgeVariant =
  | 'active'
  | 'suspended'
  | 'inactive'
  | 'verified'
  | 'live'
  | 'ending-soon'
  | 'upcoming'
  | 'warning'
  | 'info'
  | 'buyer'
  | 'seller'
  | 'both';

interface StatusBadgeProps {
  status: string;
  variant?: BadgeVariant;
  showDot?: boolean;
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({
  status,
  variant,
  showDot = true,
}) => {
  // Infer variant if not provided
  let determinedVariant: BadgeVariant = variant || 'inactive';
  const lower = status.toLowerCase();

  if (!variant) {
    if (['active', 'delivered', 'completed', 'success', 'won'].includes(lower)) {
      determinedVariant = 'active';
    } else if (['suspended', 'cancelled', 'deleted', 'outbid', 'lost'].includes(lower)) {
      determinedVariant = 'suspended';
    } else if (['live'].includes(lower)) {
      determinedVariant = 'live';
    } else if (['ending soon', 'ending_soon', 'critical'].includes(lower)) {
      determinedVariant = 'ending-soon';
    } else if (['upcoming', 'verified'].includes(lower)) {
      determinedVariant = 'verified';
    } else if (['pending', 'in_escrow', 'shipped', 'review'].includes(lower)) {
      determinedVariant = 'warning';
    } else if (['buyer'].includes(lower)) {
      determinedVariant = 'buyer';
    } else if (['seller'].includes(lower)) {
      determinedVariant = 'seller';
    } else if (['both', 'buyer+seller', 'buyer + seller'].includes(lower)) {
      determinedVariant = 'both';
    }
  }

  const getStyles = () => {
    switch (determinedVariant) {
      case 'active':
      case 'live':
        return {
          bg: '#ECFDF5',
          text: '#065F46',
          dot: '#10B981',
        };
      case 'suspended':
        return {
          bg: '#FEF2F2',
          text: '#991B1B',
          dot: '#EF4444',
        };
      case 'ending-soon':
        return {
          bg: '#FEF2F2',
          text: '#DC2626',
          dot: '#EF4444',
        };
      case 'verified':
        return {
          bg: '#CCFBF1',
          text: '#0F766E',
          dot: '#0D9488',
        };
      case 'upcoming':
        return {
          bg: '#FFFBEB',
          text: '#B45309',
          dot: '#F59E0B',
        };
      case 'warning':
        return {
          bg: '#FFFBEB',
          text: '#92400E',
          dot: '#F59E0B',
        };
      case 'buyer':
        return {
          bg: '#EFF6FF',
          text: '#1E40AF',
          dot: '#3B82F6',
        };
      case 'seller':
        return {
          bg: '#F5F3FF',
          text: '#5B21B6',
          dot: '#8B5CF6',
        };
      case 'both':
        return {
          bg: '#FDF4FF',
          text: '#86198F',
          dot: '#D946EF',
        };
      case 'inactive':
      default:
        return {
          bg: '#F1F5F9',
          text: '#475569',
          dot: '#94A3B8',
        };
    }
  };

  const style = getStyles();

  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '6px',
        padding: '3px 10px',
        borderRadius: '9999px',
        fontSize: '12px',
        fontWeight: 500,
        backgroundColor: style.bg,
        color: style.text,
        whiteSpace: 'nowrap',
      }}
    >
      {showDot && (
        <span
          style={{
            width: '6px',
            height: '6px',
            borderRadius: '50%',
            backgroundColor: style.dot,
            flexShrink: 0,
          }}
        />
      )}
      {status}
    </span>
  );
};
