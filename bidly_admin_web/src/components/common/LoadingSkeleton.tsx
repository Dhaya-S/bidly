import React from 'react';
import { Skeleton, Card } from 'antd';

export const LoadingSkeleton: React.FC<{ rows?: number }> = ({ rows = 5 }) => {
  return (
    <Card style={{ borderRadius: 12, border: '1px solid #E2E8F0', padding: 16 }}>
      <Skeleton active paragraph={{ rows }} />
    </Card>
  );
};
