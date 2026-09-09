import React, { useEffect, useState } from 'react';
import { Table, Button, Rate, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { reviewsApi } from '../../api/reviews.api';
import type { Review } from '../../types';
import { formatDate } from '../../utils/format';

export const ReviewsPage: React.FC = () => {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    reviewsApi.getReviews().then((res) => {
      setReviews(res.content);
      setLoading(false);
    });
  }, []);

  const columns: ColumnsType<Review> = [
    {
      title: 'Reviewer',
      dataIndex: 'reviewerName',
      key: 'reviewerName',
      render: (val) => <span style={{ fontWeight: 600, color: '#0F172A' }}>{val}</span>,
    },
    {
      title: 'Store / Target User',
      dataIndex: 'targetUserName',
      key: 'targetUserName',
      render: (val) => <span style={{ color: '#0D9488', fontWeight: 500 }}>{val}</span>,
    },
    {
      title: 'Rating',
      dataIndex: 'rating',
      key: 'rating',
      render: (val) => <Rate disabled defaultValue={val} style={{ fontSize: '14px' }} />,
    },
    {
      title: 'Comment',
      dataIndex: 'comment',
      key: 'comment',
      render: (val) => <span style={{ fontSize: '13px', color: '#334155' }}>"{val}"</span>,
    },
    {
      title: 'Date',
      dataIndex: 'createdAt',
      key: 'createdAt',
      render: (val) => <span style={{ fontSize: '12px', color: '#64748B' }}>{formatDate(val)}</span>,
    },
    {
      title: 'Action',
      key: 'action',
      align: 'right',
      render: () => (
        <Button
          danger
          size="small"
          onClick={() => message.success('Review hidden from store profile')}
          style={{ borderRadius: '6px' }}
        >
          Moderate
        </Button>
      ),
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
          Reviews & Feedback Moderation
        </h1>
        <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
          Seller ratings, feedback comments, and inappropriate language moderation
        </p>
      </div>

      <div
        style={{
          backgroundColor: '#FFFFFF',
          borderRadius: '12px',
          border: '1px solid #E2E8F0',
          overflow: 'hidden',
        }}
      >
        <Table
          columns={columns}
          dataSource={reviews}
          rowKey="id"
          loading={loading}
          pagination={false}
        />
      </div>
    </div>
  );
};
