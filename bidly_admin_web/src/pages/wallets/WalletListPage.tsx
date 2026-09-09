import React, { useEffect, useState, useMemo, useCallback } from 'react';
import { Table, Button, Input, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useNavigate } from 'react-router-dom';
import { Search, Wallet, Lock, Plus } from 'lucide-react';
import { walletsApi } from '../../api/wallets.api';
import type { Wallet as WalletType } from '../../types';
import { StatusBadge } from '../../components/common/StatusBadge';
import { formatRupee, formatDate } from '../../utils/format';

export const WalletListPage: React.FC = () => {
  const navigate = useNavigate();
  const [allWallets, setAllWallets] = useState<WalletType[]>([]);
  const [search, setSearch] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);

  const fetchWallets = useCallback(async () => {
    setLoading(true);
    try {
      const res = await walletsApi.getWallets({});
      setAllWallets(res.content);
    } catch {
      message.error('Failed to load wallets');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchWallets();
  }, []); // Only on mount

  // In-memory search filtering
  const filteredWallets = useMemo(() => {
    if (!search) return allWallets;
    const q = search.toLowerCase();
    return allWallets.filter(
      (w) =>
        w.user?.name.toLowerCase().includes(q) ||
        w.user?.phone.includes(q)
    );
  }, [allWallets, search]);

  const columns: ColumnsType<WalletType> = [
    {
      title: 'User',
      key: 'user',
      render: (_, record) => (
        <span
          onClick={() => navigate(`/users/${record.userId}`)}
          style={{ fontWeight: 600, color: '#0D9488', cursor: 'pointer' }}
        >
          {record.user?.name}
        </span>
      ),
    },
    {
      title: 'Role',
      key: 'role',
      render: (_, record) => <StatusBadge status={record.user?.role || 'User'} showDot={false} />,
    },
    {
      title: 'Total Balance',
      dataIndex: 'balance',
      key: 'balance',
      render: (val) => (
        <span style={{ fontWeight: 700, color: '#0F172A', fontSize: '14px' }}>
          {formatRupee(val)}
        </span>
      ),
    },
    {
      title: 'Reserved',
      dataIndex: 'reservedBalance',
      key: 'reservedBalance',
      render: (val) => (
        <span style={{ color: '#64748B', fontSize: '13px' }}>{formatRupee(val)}</span>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (val) => (
        <StatusBadge
          status={val === 'ACTIVE' ? 'Active' : 'Frozen'}
          variant={val === 'ACTIVE' ? 'active' : 'suspended'}
        />
      ),
    },
    {
      title: 'Action',
      key: 'action',
      align: 'right',
      render: (_, record) => (
        <Button
          type="link"
          onClick={() => navigate(`/users/${record.userId}`)}
          style={{ color: '#0D9488', fontWeight: 600, padding: 0 }}
        >
          Manage Wallet →
        </Button>
      ),
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
          Wallet Management
        </h1>
        <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
          Platform user wallet balances, credits, freezes, and top-up ledgers
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
        <div style={{ padding: '16px 20px', borderBottom: '1px solid #E2E8F0' }}>
          <Input
            prefix={<Search size={16} color="#94A3B8" />}
            placeholder="Search wallet by user name or phone..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            allowClear
            style={{ maxWidth: '340px', borderRadius: '8px', height: '38px' }}
          />
        </div>

        <Table
          columns={columns}
          dataSource={filteredWallets}
          rowKey="id"
          loading={loading}
          pagination={false}
        />
      </div>
    </div>
  );
};
