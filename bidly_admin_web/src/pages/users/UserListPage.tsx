import React, { useEffect, useState, useMemo, useCallback } from 'react';
import { Row, Col, Table, Button, Input, Tabs, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useNavigate } from 'react-router-dom';
import {
  Users,
  ShoppingBag,
  Store,
  UserCheck,
  Download,
  Search,
  ArrowRight,
} from 'lucide-react';
import { usersApi } from '../../api/users.api';
import type { User, UserFilterParams } from '../../types';
import { StatusBadge } from '../../components/common/StatusBadge';
import { formatRupee, formatDate, formatTimeAgo, getInitials, getAvatarColor } from '../../utils/format';

export const UserListPage: React.FC = () => {
  const navigate = useNavigate();

  // ── allUsers: the COMPLETE unfiltered list from the backend ──────────
  const [allUsers, setAllUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [search, setSearch] = useState<string>('');
  const [activeRole, setActiveRole] = useState<string>('ALL');
  const [activeStatus, setActiveStatus] = useState<string>('ALL');

  // ── Stat card counts – always computed from allUsers (never filtered) ─
  const totalCount = allUsers.length;
  const totalBuyers = allUsers.filter((u) => u.role === 'BUYER').length;
  const totalSellers = allUsers.filter((u) => u.role === 'SELLER').length;
  const totalBoth = allUsers.filter((u) => u.role === 'BOTH').length;

  // ── Filtered users – computed in memory, zero network calls ─────────
  const filteredUsers = useMemo(() => {
    let result = [...allUsers];

    // Role filter
    if (activeRole !== 'ALL') {
      result = result.filter((u) => u.role === activeRole);
    }

    // Status filter
    if (activeStatus !== 'ALL') {
      if (activeStatus === 'ACTIVE') result = result.filter((u) => u.active);
      else if (activeStatus === 'SUSPENDED') result = result.filter((u) => !u.active);
      else if (activeStatus === 'VERIFIED') result = result.filter((u) => u.identityVerified);
    }

    // Search filter
    if (search) {
      const q = search.toLowerCase();
      result = result.filter(
        (u) =>
          u.name.toLowerCase().includes(q) ||
          u.phone.toLowerCase().includes(q) ||
          (u.city && u.city.toLowerCase().includes(q)) ||
          (u.email && u.email.toLowerCase().includes(q))
      );
    }

    return result;
  }, [allUsers, activeRole, activeStatus, search]);

  // ── Fetch all users ONCE on mount ───────────────────────────────────
  const fetchUsers = useCallback(async (forceRefresh = false) => {
    setLoading(true);
    try {
      const users = await usersApi.getAllUsers(forceRefresh);
      setAllUsers(users);
    } catch (err) {
      console.error(err);
      message.error('Failed to load users list');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchUsers();
  }, []); // Only on mount – NO activeRole, activeStatus, search dependencies

  const handleExportCsv = () => {
    const headers = 'ID,Name,Phone,Role,City,State,WalletBalance,Status,Joined\n';
    const rows = filteredUsers
      .map(
        (u) =>
          `"${u.id}","${u.name}","${u.phone}","${u.role}","${u.city || ''}","${u.state || ''}",${u.walletBalance || 0},"${u.active ? 'Active' : 'Suspended'}","${u.createdAt}"`
      )
      .join('\n');
    const blob = new Blob([headers + rows], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `bidly-users-${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    message.success('Users exported successfully to CSV');
  };

  const columns: ColumnsType<User> = [
    {
      title: 'User',
      key: 'user',
      render: (_, record) => {
        const initials = getInitials(record.name);
        const isBoth = record.role === 'BOTH';
        const isSeller = record.role === 'SELLER';
        const avatarBg = isBoth ? '#7C3AED' : isSeller ? '#059669' : '#004E54';
        return (
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div
              style={{
                width: '38px',
                height: '38px',
                borderRadius: '50%',
                backgroundColor: avatarBg,
                color: '#FFFFFF',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontWeight: 700,
                fontSize: '13px',
                flexShrink: 0,
              }}
            >
              {initials}
            </div>
            <div>
              <div style={{ fontWeight: 600, color: '#0F172A', fontSize: '13.5px' }}>
                {record.name}
              </div>
              <div style={{ fontSize: '12px', color: '#64748B', marginTop: '1px' }}>{record.phone}</div>
            </div>
          </div>
        );
      },
    },
    {
      title: 'Role',
      key: 'role',
      render: (_, record) => {
        const isBoth = record.role === 'BOTH';
        const isSeller = record.role === 'SELLER';
        if (isBoth) {
          return (
            <span
              style={{
                backgroundColor: '#EDE9FE',
                color: '#7C3AED',
                padding: '4px 12px',
                borderRadius: '9999px',
                fontWeight: 600,
                fontSize: '12px',
                display: 'inline-block',
                whiteSpace: 'nowrap',
              }}
            >
              Buyer + Seller
            </span>
          );
        }
        if (isSeller) {
          return (
            <span
              style={{
                backgroundColor: '#D1FAE5',
                color: '#065F46',
                padding: '4px 12px',
                borderRadius: '9999px',
                fontWeight: 600,
                fontSize: '12px',
                display: 'inline-block',
                whiteSpace: 'nowrap',
              }}
            >
              Seller
            </span>
          );
        }
        return (
          <span
            style={{
              backgroundColor: '#ECFDF5',
              color: '#047857',
              padding: '4px 12px',
              borderRadius: '9999px',
              fontWeight: 600,
              fontSize: '12px',
              display: 'inline-block',
              whiteSpace: 'nowrap',
            }}
          >
            Buyer
          </span>
        );
      },
    },
    {
      title: 'Location',
      key: 'location',
      render: (_, record) => (
        <span style={{ fontSize: '13px', color: '#475569' }}>
          {record.city || 'India'}
        </span>
      ),
    },
    {
      title: 'Status',
      key: 'status',
      render: (_, record) => {
        if (!record.active) {
          return (
            <span
              style={{
                backgroundColor: '#FEE2E2',
                color: '#DC2626',
                padding: '4px 12px',
                borderRadius: '9999px',
                fontWeight: 600,
                fontSize: '12px',
                display: 'inline-block',
              }}
            >
              Suspended
            </span>
          );
        }
        if (record.identityVerified) {
          return (
            <span
              style={{
                backgroundColor: '#DBEAFE',
                color: '#2563EB',
                padding: '4px 12px',
                borderRadius: '9999px',
                fontWeight: 600,
                fontSize: '12px',
                display: 'inline-block',
              }}
            >
              Verified
            </span>
          );
        }
        return (
          <span
            style={{
              backgroundColor: '#D1FAE5',
              color: '#059669',
              padding: '4px 12px',
              borderRadius: '9999px',
              fontWeight: 600,
              fontSize: '12px',
              display: 'inline-block',
            }}
          >
            Active
          </span>
        );
      },
    },
    {
      title: 'Wallet',
      key: 'walletBalance',
      render: (_, record) => (
        <span style={{ fontWeight: 700, color: '#004E54', fontSize: '14px' }}>
          {formatRupee(record.walletBalance || 0)}
        </span>
      ),
    },
    {
      title: 'Joined',
      key: 'createdAt',
      render: (_, record) => (
        <span style={{ fontSize: '13px', color: '#94A3B8' }}>{formatDate(record.createdAt)}</span>
      ),
    },
    {
      title: 'Last Active',
      key: 'lastActiveAt',
      render: (_, record) => {
        if (!record.lastActiveAt) {
          return <span style={{ fontSize: '13px', color: '#94A3B8' }}>N/A</span>;
        }
        return (
          <span style={{ fontSize: '13px', color: '#94A3B8' }}>
            {formatTimeAgo(record.lastActiveAt)}
          </span>
        );
      },
    },
    {
      title: 'Action',
      key: 'action',
      align: 'right',
      render: (_, record) => (
        <button
          type="button"
          onClick={() => navigate(`/users/${record.id}`)}
          style={{
            border: '1px solid #147A73',
            color: '#147A73',
            backgroundColor: '#FFFFFF',
            borderRadius: '8px',
            padding: '6px 16px',
            fontWeight: 500,
            fontSize: '13px',
            cursor: 'pointer',
            transition: 'all 0.15s ease',
            whiteSpace: 'nowrap',
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.backgroundColor = '#F0FDFA';
            e.currentTarget.style.borderColor = '#004E54';
            e.currentTarget.style.color = '#004E54';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.backgroundColor = '#FFFFFF';
            e.currentTarget.style.borderColor = '#147A73';
            e.currentTarget.style.color = '#147A73';
          }}
        >
          View Profile
        </button>
      ),
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
          marginBottom: '24px',
          flexWrap: 'wrap',
          gap: '12px',
        }}
      >
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
            Users
          </h1>
          <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
            {totalCount} total registered users
          </p>
        </div>

        <Button
          icon={<Download size={15} />}
          onClick={handleExportCsv}
          style={{
            borderRadius: '8px',
            borderColor: '#CBD5E1',
            color: '#334155',
            fontWeight: 500,
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
          }}
        >
          Export CSV
        </Button>
      </div>

      {/* 4 Stat Filter Cards */}
      <Row gutter={[16, 16]} style={{ marginBottom: '24px' }}>
        <Col xs={12} sm={6}>
          <div
            onClick={() => setActiveRole('ALL')}
            style={{
              backgroundColor: '#FFFFFF',
              border: `1.5px solid ${activeRole === 'ALL' ? '#0D9488' : '#E2E8F0'}`,
              borderRadius: '12px',
              padding: '16px 20px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '16px',
            }}
          >
            <div
              style={{
                width: '42px',
                height: '42px',
                borderRadius: '10px',
                backgroundColor: '#EFF6FF',
                color: '#3B82F6',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Users size={20} />
            </div>
            <div>
              <div style={{ fontSize: '22px', fontWeight: 700, color: '#0F172A' }}>{totalCount}</div>
              <div style={{ fontSize: '12px', color: '#64748B', fontWeight: 500 }}>Total Users</div>
            </div>
          </div>
        </Col>

        <Col xs={12} sm={6}>
          <div
            onClick={() => setActiveRole('BUYER')}
            style={{
              backgroundColor: '#FFFFFF',
              border: `1.5px solid ${activeRole === 'BUYER' ? '#0D9488' : '#E2E8F0'}`,
              borderRadius: '12px',
              padding: '16px 20px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '16px',
            }}
          >
            <div
              style={{
                width: '42px',
                height: '42px',
                borderRadius: '10px',
                backgroundColor: '#ECFDF5',
                color: '#10B981',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <ShoppingBag size={20} />
            </div>
            <div>
              <div style={{ fontSize: '22px', fontWeight: 700, color: '#0F172A' }}>{totalBuyers}</div>
              <div style={{ fontSize: '12px', color: '#64748B', fontWeight: 500 }}>Buyers</div>
            </div>
          </div>
        </Col>

        <Col xs={12} sm={6}>
          <div
            onClick={() => setActiveRole('SELLER')}
            style={{
              backgroundColor: '#FFFFFF',
              border: `1.5px solid ${activeRole === 'SELLER' ? '#0D9488' : '#E2E8F0'}`,
              borderRadius: '12px',
              padding: '16px 20px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '16px',
            }}
          >
            <div
              style={{
                width: '42px',
                height: '42px',
                borderRadius: '10px',
                backgroundColor: '#FEF3C7',
                color: '#D97706',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Store size={20} />
            </div>
            <div>
              <div style={{ fontSize: '22px', fontWeight: 700, color: '#0F172A' }}>{totalSellers}</div>
              <div style={{ fontSize: '12px', color: '#64748B', fontWeight: 500 }}>Sellers</div>
            </div>
          </div>
        </Col>

        <Col xs={12} sm={6}>
          <div
            onClick={() => setActiveRole('BOTH')}
            style={{
              backgroundColor: '#FFFFFF',
              border: `1.5px solid ${activeRole === 'BOTH' ? '#0D9488' : '#E2E8F0'}`,
              borderRadius: '12px',
              padding: '16px 20px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '16px',
            }}
          >
            <div
              style={{
                width: '42px',
                height: '42px',
                borderRadius: '10px',
                backgroundColor: '#F3E8FF',
                color: '#9333EA',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <UserCheck size={20} />
            </div>
            <div>
              <div style={{ fontSize: '22px', fontWeight: 700, color: '#0F172A' }}>{totalBoth}</div>
              <div style={{ fontSize: '12px', color: '#64748B', fontWeight: 500 }}>Both Roles</div>
            </div>
          </div>
        </Col>
      </Row>

      {/* Filter & Search Bar */}
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
            placeholder="Search by name, location, phone..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            allowClear
            style={{ maxWidth: '340px', borderRadius: '8px', height: '38px' }}
          />

          {/* Status Tabs */}
          <Tabs
            activeKey={activeStatus}
            onChange={setActiveStatus}
            style={{ marginBottom: '-8px' }}
            items={[
              { key: 'ALL', label: 'All Status' },
              { key: 'ACTIVE', label: 'Active' },
              { key: 'SUSPENDED', label: 'Suspended' },
              { key: 'VERIFIED', label: 'Verified' },
            ]}
          />
        </div>
      </div>

      {/* Main Table */}
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
          dataSource={filteredUsers}
          rowKey="id"
          loading={loading}
          pagination={false}
          style={{ width: '100%' }}
        />
        <div
          style={{
            padding: '20px',
            fontSize: '13px',
            color: '#94A3B8',
            textAlign: 'center',
          }}
        >
          Showing {filteredUsers.length} of {totalCount} users
        </div>
      </div>
    </div>
  );
};
