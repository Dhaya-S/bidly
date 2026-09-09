import React, { useEffect, useState } from 'react';
import { Row, Col, Button, Table, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { ShieldCheck, AlertTriangle, FileText } from 'lucide-react';
import { StatCard } from '../../components/common/StatCard';
import { usersApi } from '../../api/users.api';
import type { User } from '../../types';
import { StatusBadge } from '../../components/common/StatusBadge';

export const TrustSafetyPage: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    usersApi.getUsers().then((res) => {
      setUsers(res.content);
      setLoading(false);
    });
  }, []);

  const verifiedUsers = users.filter((u: User) => u.identityVerified);
  const suspendedUsers = users.filter((u: User) => !u.active);
  const pendingKyc = users.filter((u: User) => !u.identityVerified && u.active);

  const columns: ColumnsType<User> = [
    {
      title: 'User',
      dataIndex: 'name',
      key: 'name',
      render: (val, record) => (
        <div>
          <div style={{ fontWeight: 600, color: '#0F172A' }}>{val}</div>
          <div style={{ fontSize: '12px', color: '#64748B' }}>{record.phone}</div>
        </div>
      ),
    },
    {
      title: 'Identity Provider',
      key: 'provider',
      render: (_, record) => (
        <span style={{ fontSize: '13px' }}>
          {record.identityProvider || 'Aadhaar e-KYC (DigiLocker)'}
        </span>
      ),
    },
    {
      title: 'Trust Score',
      key: 'trustScore',
      render: (_, record) => (
        <span style={{ fontWeight: 700, color: '#10B981' }}>
          {record.trustScore || 0} / 100
        </span>
      ),
    },
    {
      title: 'Status',
      key: 'status',
      render: (_, record) => (
        <StatusBadge
          status={record.identityVerified ? 'Verified' : 'Unverified'}
          variant={record.identityVerified ? 'verified' : 'inactive'}
        />
      ),
    },
    {
      title: 'Action',
      key: 'action',
      align: 'right',
      render: () => (
        <Button
          type="link"
          style={{ color: '#0D9488', fontWeight: 600, padding: 0 }}
          onClick={() => message.info('Viewing KYC documentation')}
        >
          View Audit Log →
        </Button>
      ),
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
          Trust & Safety
        </h1>
        <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
          User identity verification (KYC), fraud detection, and safety score management
        </p>
      </div>

      <Row gutter={[20, 20]} style={{ marginBottom: '24px' }}>
        <Col xs={24} sm={8}>
          <StatCard
            title="Verified Identities"
            value={verifiedUsers.length}
            trendText="Realtime from Neon DB"
            trendType="positive"
            icon={<ShieldCheck size={22} />}
            iconBgColor="#CCFBF1"
            iconColor="#0D9488"
          />
        </Col>
        <Col xs={24} sm={8}>
          <StatCard
            title="Pending Verification"
            value={pendingKyc.length}
            trendText="Unverified accounts"
            trendType="warning"
            icon={<FileText size={22} />}
            iconBgColor="#FEF3C7"
            iconColor="#D97706"
          />
        </Col>
        <Col xs={24} sm={8}>
          <StatCard
            title="Suspended Accounts"
            value={suspendedUsers.length}
            trendText="Restricted access"
            trendType="danger"
            icon={<AlertTriangle size={22} />}
            iconBgColor="#FEF2F2"
            iconColor="#EF4444"
          />
        </Col>
      </Row>

      <div
        style={{
          backgroundColor: '#FFFFFF',
          borderRadius: '12px',
          border: '1px solid #E2E8F0',
          overflow: 'hidden',
        }}
      >
        <div style={{ padding: '16px 20px', borderBottom: '1px solid #E2E8F0' }}>
          <h2 style={{ fontSize: '15px', fontWeight: 600, color: '#0F172A', margin: 0 }}>
            Identity & Safety Registry
          </h2>
        </div>
        <Table
          columns={columns}
          dataSource={users}
          rowKey="id"
          loading={loading}
          pagination={false}
        />
      </div>
    </div>
  );
};
