import React, { useEffect, useState } from 'react';
import { Table, Button, Input, Tabs, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useNavigate } from 'react-router-dom';
import { Search, LayoutGrid, List, ArrowRight, Eye, Users } from 'lucide-react';
import { auctionsApi } from '../../api/auctions.api';
import { categoriesApi } from '../../api/categories.api';
import type { AuctionSummary, Category } from '../../types';
import { StatusBadge } from '../../components/common/StatusBadge';
import { formatRupee } from '../../utils/format';

export const AuctionListPage: React.FC = () => {
  const navigate = useNavigate();
  const [auctions, setAuctions] = useState<AuctionSummary[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [activeStatus, setActiveStatus] = useState<string>('ALL');
  const [search, setSearch] = useState<string>('');
  const [viewMode, setViewMode] = useState<'list' | 'grid'>('list');
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    const load = async () => {
      try {
        const [cats, aucs] = await Promise.all([
          categoriesApi.getCategories(),
          auctionsApi.getActiveAuctions(),
        ]);
        setCategories(cats);
        setAuctions(aucs);
      } catch {
        message.error('Failed to load auctions');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  const filteredAuctions = auctions.filter((auc) => {
    if (selectedCategory !== 'All' && auc.category.toLowerCase() !== selectedCategory.toLowerCase()) {
      return false;
    }
    if (activeStatus === 'LIVE' && auc.status !== 'LIVE') return false;
    if (activeStatus === 'ENDING_SOON' && auc.status !== 'ENDING_SOON') return false;
    if (activeStatus === 'UPCOMING' && auc.status !== 'UPCOMING') return false;
    if (search) {
      const q = search.toLowerCase();
      if (!auc.title.toLowerCase().includes(q) && !auc.sellerName.toLowerCase().includes(q)) {
        return false;
      }
    }
    return true;
  });

  const columns: ColumnsType<AuctionSummary> = [
    {
      title: 'Auction',
      key: 'auction',
      render: (_, record) => (
        <div>
          <div style={{ fontWeight: 600, color: '#0F172A', fontSize: '14px' }}>
            {record.title}
          </div>
          <div style={{ fontSize: '12px', color: '#64748B' }}>{record.category}</div>
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
            navigate(`/users/${record.sellerId}`);
          }}
          style={{ color: '#0D9488', fontWeight: 600, cursor: 'pointer', fontSize: '13px' }}
        >
          {record.sellerStoreName || record.sellerName}
        </span>
      ),
    },
    {
      title: 'Start Price',
      dataIndex: 'startPrice',
      key: 'startPrice',
      render: (val) => (
        <span style={{ fontSize: '13px', color: '#64748B' }}>{formatRupee(val)}</span>
      ),
    },
    {
      title: 'Current Bid',
      dataIndex: 'currentBid',
      key: 'currentBid',
      render: (val) => (
        <span style={{ fontSize: '14px', fontWeight: 700, color: '#10B981' }}>
          {formatRupee(val)}
        </span>
      ),
    },
    {
      title: 'Bids',
      dataIndex: 'bidsCount',
      key: 'bidsCount',
      render: (val) => (
        <span style={{ fontSize: '13px', fontWeight: 500, color: '#0F172A' }}>
          {val} bids
        </span>
      ),
    },
    {
      title: 'Ends In',
      key: 'endsIn',
      render: (_, record) => {
        let text = '4h 12m';
        if (record.status === 'ENDING_SOON') text = '18m 40s';
        if (record.status === 'UPCOMING') text = 'Upcoming';
        return (
          <span
            style={{
              fontSize: '13px',
              fontWeight: 600,
              color: record.status === 'ENDING_SOON' ? '#DC2626' : '#334155',
            }}
          >
            {text}
          </span>
        );
      },
    },
    {
      title: 'Watchers',
      dataIndex: 'watchersCount',
      key: 'watchersCount',
      render: (val) => (
        <span style={{ fontSize: '13px', color: '#64748B', display: 'flex', alignItems: 'center', gap: '4px' }}>
          <Eye size={14} /> {val}
        </span>
      ),
    },
    {
      title: 'Status',
      key: 'status',
      render: (_, record) => {
        if (record.status === 'ENDING_SOON') {
          return <StatusBadge status="Ending Soon" variant="ending-soon" />;
        }
        if (record.status === 'UPCOMING') {
          return <StatusBadge status="Upcoming" variant="upcoming" />;
        }
        return <StatusBadge status="Live" variant="live" />;
      },
    },
  ];

  return (
    <div>
      {/* Top Header */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '20px',
          flexWrap: 'wrap',
          gap: '12px',
        }}
      >
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
            Auctions
          </h1>
          <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
            8 live · 1 ending soon
          </p>
        </div>

        {/* View Mode Toggle */}
        <div style={{ display: 'flex', gap: '4px', backgroundColor: '#F1F5F9', padding: '3px', borderRadius: '8px' }}>
          <Button
            type={viewMode === 'list' ? 'primary' : 'text'}
            size="small"
            icon={<List size={16} />}
            onClick={() => setViewMode('list')}
            style={{
              backgroundColor: viewMode === 'list' ? '#0D9488' : 'transparent',
              borderRadius: '6px',
            }}
          />
          <Button
            type={viewMode === 'grid' ? 'primary' : 'text'}
            size="small"
            icon={<LayoutGrid size={16} />}
            onClick={() => setViewMode('grid')}
            style={{
              backgroundColor: viewMode === 'grid' ? '#0D9488' : 'transparent',
              borderRadius: '6px',
            }}
          />
        </div>
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

      {/* Filter and Search Bar */}
      <div
        style={{
          backgroundColor: '#FFFFFF',
          borderRadius: '12px 12px 0 0',
          border: '1px solid #E2E8F0',
          borderBottom: 'none',
          padding: '16px 20px 0 20px',
        }}
      >
        <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap', alignItems: 'center' }}>
          <Input
            prefix={<Search size={16} color="#94A3B8" />}
            placeholder="Search auctions..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            allowClear
            style={{ maxWidth: '340px', borderRadius: '8px', height: '38px' }}
          />

          <Tabs
            activeKey={activeStatus}
            onChange={setActiveStatus}
            style={{ marginBottom: '-8px' }}
            items={[
              { key: 'ALL', label: 'All Status' },
              { key: 'LIVE', label: 'Live' },
              { key: 'ENDING_SOON', label: 'Ending Soon' },
              { key: 'UPCOMING', label: 'Upcoming' },
            ]}
          />
        </div>
      </div>

      {/* Table Container */}
      <div
        style={{
          backgroundColor: '#FFFFFF',
          borderRadius: '0 0 12px 12px',
          border: '1px solid #E2E8F0',
          overflow: 'hidden',
        }}
      >
        <Table
          columns={columns}
          dataSource={filteredAuctions}
          rowKey="id"
          loading={loading}
          pagination={false}
          onRow={(record) => ({
            onClick: () => navigate(`/marketplace/auctions/${record.id}`),
            style: { cursor: 'pointer' },
          })}
        />
      </div>
    </div>
  );
};
