import React, { useEffect, useState, useMemo, useCallback } from 'react';
import { Table, Button, Input, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useNavigate } from 'react-router-dom';
import { MessageSquare, Users, Plus, Search } from 'lucide-react';
import { communitiesApi } from '../../api/communities.api';
import type { Community } from '../../types';
import { StatusBadge } from '../../components/common/StatusBadge';
import { formatDate } from '../../utils/format';

export const CommunityListPage: React.FC = () => {
  const navigate = useNavigate();
  const [allCommunities, setAllCommunities] = useState<Community[]>([]);
  const [search, setSearch] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);

  const fetchCommunities = useCallback(async () => {
    setLoading(true);
    try {
      const res = await communitiesApi.getCommunities({});
      setAllCommunities(res.content);
    } catch {
      message.error('Failed to load communities');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchCommunities();
  }, []); // Only on mount

  // In-memory search filtering
  const filteredCommunities = useMemo(() => {
    if (!search) return allCommunities;
    const q = search.toLowerCase();
    return allCommunities.filter(
      (c) => c.name?.toLowerCase().includes(q) || c.city?.toLowerCase().includes(q)
    );
  }, [allCommunities, search]);

  const columns: ColumnsType<Community> = [
    {
      title: 'Community',
      key: 'name',
      render: (_, record) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div
            style={{
              width: '38px',
              height: '38px',
              borderRadius: '8px',
              backgroundColor: '#0D9488',
              color: '#FFFFFF',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 700,
            }}
          >
            {record.name.slice(0, 2).toUpperCase()}
          </div>
          <div>
            <div style={{ fontWeight: 600, color: '#0F172A', fontSize: '14px' }}>
              {record.name}
            </div>
            <div style={{ fontSize: '12px', color: '#64748B' }}>
              {record.type} · {record.city || 'Pan-India'}
            </div>
          </div>
        </div>
      ),
    },
    {
      title: 'Category',
      dataIndex: 'category',
      key: 'category',
      render: (val) => <span style={{ fontSize: '13px', color: '#334155' }}>{val || 'General'}</span>,
    },
    {
      title: 'Members',
      dataIndex: 'membersCount',
      key: 'membersCount',
      render: (val) => (
        <span style={{ fontWeight: 600, color: '#0F172A', display: 'flex', alignItems: 'center', gap: '4px' }}>
          <Users size={14} color="#64748B" /> {val.toLocaleString()}
        </span>
      ),
    },
    {
      title: 'Recent Activity',
      key: 'activity',
      render: (_, record) => (
        <div>
          <div style={{ fontSize: '12px', color: '#0F172A' }}>{record.recentActivityText}</div>
          <div style={{ fontSize: '11px', color: '#94A3B8' }}>{record.recentActivityTime}</div>
        </div>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'active',
      key: 'active',
      render: (val) => (
        <StatusBadge status={val ? 'Active' : 'Inactive'} variant={val ? 'active' : 'inactive'} />
      ),
    },
    {
      title: 'Action',
      key: 'action',
      align: 'right',
      render: (_, record) => (
        <Button
          type="link"
          style={{ color: '#0D9488', fontWeight: 600, padding: 0 }}
        >
          Manage →
        </Button>
      ),
    },
  ];

  return (
    <div>
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
            Communities
          </h1>
          <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
            Hyperlocal neighborhoods, college campuses, and special interest groups
          </p>
        </div>

        <Button
          type="primary"
          icon={<Plus size={15} />}
          style={{ backgroundColor: '#0D9488', borderRadius: '8px', fontWeight: 600 }}
          onClick={() => message.info('Community creation modal')}
        >
          Create Community
        </Button>
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
            placeholder="Search communities by name or city..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            allowClear
            style={{ maxWidth: '340px', borderRadius: '8px', height: '38px' }}
          />
        </div>

        <Table
          columns={columns}
          dataSource={filteredCommunities}
          rowKey="id"
          loading={loading}
          pagination={false}
        />
      </div>
    </div>
  );
};
