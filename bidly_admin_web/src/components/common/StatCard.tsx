import React from 'react';
import { Card } from 'antd';
import { ChevronRight } from 'lucide-react';

export interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: React.ReactNode;
  icon: React.ReactNode;
  iconBgColor?: string;
  iconColor?: string;
  trendText?: string;
  trendType?: 'positive' | 'negative' | 'neutral' | 'warning' | 'danger' | 'info';
  onClick?: () => void;
  showChevron?: boolean;
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  subtitle,
  icon,
  iconBgColor = '#E0F2FE',
  iconColor = '#0284C7',
  trendText,
  trendType = 'positive',
  onClick,
  showChevron = true,
}) => {
  const getTrendColor = () => {
    switch (trendType) {
      case 'positive':
        return '#0D9488'; // Teal / Green
      case 'danger':
      case 'negative':
        return '#EF4444'; // Red
      case 'warning':
        return '#D97706'; // Amber
      case 'info':
        return '#0284C7'; // Sky / Blue
      default:
        return '#0D9488';
    }
  };

  return (
    <Card
      hoverable={!!onClick}
      onClick={onClick}
      bodyStyle={{ padding: '20px 24px' }}
      style={{
        borderRadius: '12px',
        border: '1px solid #EAECF0',
        backgroundColor: '#FFFFFF',
        boxShadow: '0 1px 2px rgba(16, 24, 40, 0.04)',
        cursor: onClick ? 'pointer' : 'default',
        height: '100%',
        transition: 'all 0.2s ease',
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '16px',
        }}
      >
        <div
          style={{
            width: '40px',
            height: '40px',
            borderRadius: '50%',
            backgroundColor: iconBgColor,
            color: iconColor,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: '18px',
          }}
        >
          {icon}
        </div>
        {showChevron && (
          <ChevronRight size={16} color="#94A3B8" />
        )}
      </div>

      <div
        style={{
          fontSize: '30px',
          fontWeight: 700,
          color: '#0F172A',
          lineHeight: 1.15,
          marginBottom: '4px',
          letterSpacing: '-0.5px',
        }}
      >
        {value}
      </div>

      <div style={{ fontSize: '14px', fontWeight: 500, color: '#64748B', marginBottom: '8px' }}>
        {title}
      </div>

      {trendText && (
        <div
          style={{
            fontSize: '13px',
            fontWeight: 600,
            color: getTrendColor(),
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
          }}
        >
          {trendText}
        </div>
      )}

      {subtitle && !trendText && (
        <div style={{ marginTop: '2px', fontSize: '13px', color: '#94A3B8' }}>
          {subtitle}
        </div>
      )}
    </Card>
  );
};
