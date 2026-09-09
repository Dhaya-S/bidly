import React, { useEffect, useState } from 'react';
import { Table, Button, Input, Tabs, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useNavigate } from 'react-router-dom';
import { Search, Eye, ArrowRight } from 'lucide-react';
import { listingsApi } from '../../api/listings.api';
import { categoriesApi } from '../../api/categories.api';
import type { Listing, Category } from '../../types';
import { StatusBadge } from '../../components/common/StatusBadge';
import { formatRupee, formatDate } from '../../utils/format';

export const DirectBuyListPage: React.FC = () => {
  const navigate = useNavigate();
  const [listings, setListings] = useState<Listing[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [search, setSearch] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    const load = async () => {
      try {
        const [cats, lists] = await Promise.all([
          categoriesApi.getCategories(),
          listingsApi.getListings({ sellingMethod: 'DIRECT_BUY' }),
        ]);
        setCategories(cats);
        setListings(lists.content);
      } catch {
        message.error('Failed to load listings');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const filtered = listings.filter((l) => {
    if (selectedCategory !== 'All' && l.category?.name.toLowerCase() !== selectedCategory.toLowerCase()) {
      return false;
    }
    if (search) {
      const q = search.toLowerCase();
      if (!l.title.toLowerCase().includes(q) && !l.seller.name.toLowerCase().includes(q)) {
        return false;
      }
    }
    return true;
  });

  const columns: ColumnsType<Listing> = [
    {
      title: 'Listing',
      key: 'title',
      render: (_, record) => (
        <div>
          <div style={{ fontWeight: 600, color: '#0F172A', fontSize: '14px' }}>
            {record.title}
          </div>
          <div style={{ fontSize: '12px', color: '#64748B' }}>
            {record.category?.name} · {record.subcategory || 'General'}
          </div>
        </div>
      ),
    },
    {
      title: 'Seller',
      key: 'seller',
      render: (_, record) => (
        <span
          onClick={(e) => {
            e.stopPropagation();
            navigate(`/users/${record.seller.id}`);
          }}
          style={{ color: '#0D9488', fontWeight: 600, cursor: 'pointer', fontSize: '13px' }}
        >
          {record.seller.name}
        </span>
      ),
    },
    {
      title: 'Price',
      dataIndex: 'price',
      key: 'price',
      render: (val) => (
        <span style={{ fontSize: '14px', fontWeight: 700, color: '#0F172A' }}>
          {formatRupee(val)}
        </span>
      ),
    },
    {
      title: 'Condition',
      dataIndex: 'condition',
      key: 'condition',
      render: (val) => (
        <span
          style={{
            padding: '2px 8px',
            borderRadius: '4px',
            backgroundColor: '#F1F5F9',
            fontSize: '11px',
            fontWeight: 600,
            color: '#475569',
          }}
        >
          {val}
        </span>
      ),
    },
    {
      title: 'Views',
      dataIndex: 'viewsCount',
      key: 'viewsCount',
      render: (val) => (
        <span style={{ fontSize: '13px', color: '#64748B', display: 'flex', alignItems: 'center', gap: '4px' }}>
          <Eye size={14} /> {val || 0}
        </span>
      ),
    },
    {
      title: 'Status',
      key: 'status',
      render: (_, record) => (
        <StatusBadge
          status={record.status === 'ACTIVE' ? 'Available' : record.status}
          variant={record.status === 'ACTIVE' ? 'active' : 'inactive'}
        />
      ),
    },
    {
      title: 'Listed Date',
      dataIndex: 'createdAt',
      key: 'createdAt',
      render: (val) => <span style={{ fontSize: '12px', color: '#64748B' }}>{formatDate(val)}</span>,
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
          Direct Buy Marketplace
        </h1>
        <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
          Fixed-price second-hand inventory across communities
        </p>
      </div>

      {/* Category Pills Bar */}
      <div
        style={{
          display: 'flex',
          gap: '8px',
          overflowX: 'auto',
          paddingBottom: '12px',
          marginBottom: '16px',
        }}
      >
        {categories.map((c) => {
          const isSelected = selectedCategory === c.name;
          return (
            <button
              key={c.id}
              onClick={() => setSelectedCategory(c.name)}
              style={{
                padding: '6px 14px',
                borderRadius: '9999px',
                fontSize: '13px',
                fontWeight: isSelected ? 600 : 500,
                backgroundColor: isSelected ? '#0D9488' : '#FFFFFF',
                color: isSelected ? '#FFFFFF' : '#475569',
                border: `1px solid ${isSelected ? '#0D9488' : '#E2E8F0'}`,
                cursor: 'pointer',
                whiteSpace: 'nowrap',
                transition: 'all 0.15s ease',
              }}
            >
              {c.name}
            </button>
          );
        })}
      </div>

      <div
        style={{
          backgroundColor: '#FFFFFF',
          borderRadius: '12px',
          border: '1px solid #E2E8F0',
          overflow: 'hidden',
        }}
      >
        <div style={{ padding: '16px 20px', borderBottom: '1px solid #E2E8F0' }}>
          <Input
            prefix={<Search size={16} color="#94A3B8" />}
            placeholder="Search direct buy listings..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            allowClear
            style={{ maxWidth: '340px', borderRadius: '8px', height: '38px' }}
          />
        </div>

        <Table
          columns={columns}
          dataSource={filtered}
          rowKey="id"
          loading={loading}
          pagination={false}
        />
      </div>
    </div>
  );
};
