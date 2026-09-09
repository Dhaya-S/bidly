import React, { useEffect, useState } from 'react';
import { Row, Col, Table, Button, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { IndianRupee, ShieldCheck, ArrowUpRight, CheckCircle2 } from 'lucide-react';
import { paymentsApi } from '../../api/payments.api';
import type { Payment } from '../../types';
import { StatCard } from '../../components/common/StatCard';
import { StatusBadge } from '../../components/common/StatusBadge';
import { formatRupee, formatDate } from '../../utils/format';

export const PaymentsPage: React.FC = () => {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    paymentsApi.getPayments().then((res) => {
      setPayments(res.content);
      setLoading(false);
    });
  }, []);

  const columns: ColumnsType<Payment> = [
    {
      title: 'Payment ID',
      dataIndex: 'id',
      key: 'id',
      render: (val) => <span style={{ fontWeight: 600, color: '#0F172A' }}>{val}</span>,
    },
    {
      title: 'Order',
      dataIndex: 'orderNumber',
      key: 'orderNumber',
      render: (val) => <span style={{ color: '#0D9488', fontWeight: 500 }}>{val}</span>,
    },
    {
      title: 'User',
      dataIndex: 'userName',
      key: 'userName',
      render: (val) => <span style={{ color: '#334155', fontWeight: 500 }}>{val}</span>,
    },
    {
      title: 'Gross Amount',
      dataIndex: 'amount',
      key: 'amount',
      render: (val) => (
        <span style={{ fontWeight: 700, color: '#0F172A' }}>{formatRupee(val)}</span>
      ),
    },
    {
      title: 'Platform Fee',
      dataIndex: 'feeAmount',
      key: 'feeAmount',
      render: (val) => (
        <span style={{ color: '#0D9488', fontWeight: 600 }}>{formatRupee(val)}</span>
      ),
    },
    {
      title: 'Gateway / Mode',
      dataIndex: 'gateway',
      key: 'gateway',
      render: (val, record) => (
        <span style={{ fontSize: '13px', color: '#64748B' }}>
          {val} {record.paymentMethod ? `(${record.paymentMethod})` : ''}
        </span>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (val) => <StatusBadge status={val} variant="active" />,
    },
    {
      title: 'Date',
      dataIndex: 'createdAt',
      key: 'createdAt',
      render: (val) => <span style={{ fontSize: '12px', color: '#64748B' }}>{formatDate(val)}</span>,
    },
  ];

  const totalVolume = payments.reduce((acc, p) => acc + (Number(p.amount) || 0), 0);
  const escrowInHolding = payments.filter((p) => p.status === 'PENDING').reduce((acc, p) => acc + (Number(p.amount) || 0), 0);
  const totalFees = payments.reduce((acc, p) => acc + (Number(p.feeAmount) || 0), 0);

  return (
    <div>
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
          Payments & Settlement
        </h1>
        <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
          Escrow settlement, payment gateway logs, and platform revenue collection
        </p>
      </div>

      <Row gutter={[20, 20]} style={{ marginBottom: '24px' }}>
        <Col xs={24} sm={8}>
          <StatCard
            title="Total Revenue Volume"
            value={formatRupee(totalVolume, true)}
            trendText="Realtime from orders"
            trendType="positive"
            icon={<IndianRupee size={22} />}
            iconBgColor="#ECFDF5"
            iconColor="#10B981"
          />
        </Col>
        <Col xs={24} sm={8}>
          <StatCard
            title="Escrow In Holding"
            value={formatRupee(escrowInHolding, true)}
            subtitle={`${payments.filter((p) => p.status === 'PENDING').length} orders in escrow`}
            icon={<ShieldCheck size={22} />}
            iconBgColor="#EFF6FF"
            iconColor="#3B82F6"
          />
        </Col>
        <Col xs={24} sm={8}>
          <StatCard
            title="Platform Fees Earned"
            value={formatRupee(totalFees)}
            trendText="Calculated from real fee deductions"
            icon={<CheckCircle2 size={22} />}
            iconBgColor="#F0FDFA"
            iconColor="#0D9488"
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
            Recent Payment Transactions
          </h2>
        </div>
        <Table
          columns={columns}
          dataSource={payments}
          rowKey="id"
          loading={loading}
          pagination={false}
        />
      </div>
    </div>
  );
};
