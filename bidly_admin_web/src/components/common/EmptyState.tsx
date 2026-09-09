import React from 'react';
import { Empty, Button } from 'antd';

interface EmptyStateProps {
  title?: string;
  description?: string;
  actionText?: string;
  onAction?: () => void;
}

export const EmptyState: React.FC<EmptyStateProps> = ({
  title = 'No Data Found',
  description = 'There are no records to display at this time.',
  actionText,
  onAction,
}) => {
  return (
    <div
      style={{
        padding: '48px 24px',
        textAlign: 'center',
        backgroundColor: '#FFFFFF',
        borderRadius: '12px',
        border: '1px solid #E2E8F0',
      }}
    >
      <Empty
        description={
          <div>
            <div style={{ fontSize: '16px', fontWeight: 600, color: '#1E293B', marginBottom: '4px' }}>
              {title}
            </div>
            <div style={{ fontSize: '13px', color: '#64748B' }}>{description}</div>
          </div>
        }
      >
        {actionText && onAction && (
          <Button type="primary" onClick={onAction} style={{ marginTop: '12px' }}>
            {actionText}
          </Button>
        )}
      </Empty>
    </div>
  );
};
