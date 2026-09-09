import React, { useEffect, useState, useMemo, useCallback } from 'react';
import { Table, Button, Input, Tabs, message } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { useNavigate } from 'react-router-dom';
import { Search, ArrowRight, Package, Truck, Handshake } from 'lucide-react';
import { ordersApi } from '../../api/orders.api';
import type { Order } from '../../types';
import { StatusBadge } from '../../components/common/StatusBadge';
import { formatRupee, formatDate } from '../../utils/format';

export const OrderListPage: React.FC = () => {
  const navigate = useNavigate();
  const [allOrders, setAllOrders] = useState<Order[]>([]);
  const [activeStatus, setActiveStatus] = useState<string>('ALL');
  const [search, setSearch] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);

  // Fetch once on mount — all filtering is in-memory
  const fetchOrders = useCallback(async () => {
    setLoading(true);
    try {
      const orders = await ordersApi.getAllOrders();
      setAllOrders(orders);
    } catch {
      message.error('Failed to load orders');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchOrders();
  }, []);

  // In-memory filtering — instant, zero network calls
  const filteredOrders = useMemo(() => {
    let result = [...allOrders];

    if (activeStatus !== 'ALL') {
      result = result.filter((o) => o.status === activeStatus);
    }
    if (search) {
      const q = search.toLowerCase();
      result = result.filter(
        (o) =>
          o.orderNumber.toLowerCase().includes(q) ||
          o.buyer?.name?.toLowerCase().includes(q) ||
          o.seller?.name?.toLowerCase().includes(q) ||
          o.listing?.title?.toLowerCase().includes(q)
      );
    }

    return result;
  }, [allOrders, activeStatus, search]);

  const columns: ColumnsType<Order> = [
    {
      title: 'Order Number',
      dataIndex: 'orderNumber',
      key: 'orderNumber',
      render: (val, record) => (
        <span
          onClick={() => navigate(`/orders/${record.id}`)}
          style={{ fontWeight: 600, color: '#0D9488', cursor: 'pointer' }}
        >
          {val}
        </span>
      ),
    },
    {
      title: 'Listing',
      key: 'listing',
      render: (_, record) => (
        <div style={{ maxWidth: 220 }}>
          <div style={{ fontWeight: 600, color: '#0F172A', fontSize: '13px' }}>
            {record.listing?.title}
          </div>
          <div style={{ fontSize: '12px', color: '#64748B' }}>
            {record.orderSource === 'AUCTION' ? 'Auction Win' : 'Direct Sale'}
          </div>
        </div>
      ),
    },
    {
      title: 'Buyer',
      key: 'buyer',
      render: (_, record) => (
        <span
          onClick={() => navigate(`/users/${record.buyer.id}`)}
          style={{ color: '#0D9488', cursor: 'pointer', fontSize: '13px', fontWeight: 500 }}
        >
          {record.buyer?.name}
        </span>
      ),
    },
    {
      title: 'Seller',
      key: 'seller',
      render: (_, record) => (
        <span
          onClick={() => navigate(`/users/${record.seller.id}`)}
          style={{ color: '#0D9488', cursor: 'pointer', fontSize: '13px', fontWeight: 500 }}
        >
          {record.seller?.name}
        </span>
      ),
    },
    {
      title: 'Amount',
      dataIndex: 'amount',
      key: 'amount',
      render: (val) => (
        <span style={{ fontWeight: 700, color: '#0F172A', fontSize: '13px' }}>
          {formatRupee(val)}
        </span>
      ),
    },
    {
      title: 'Platform Fee',
      dataIndex: 'platformFee',
      key: 'platformFee',
      render: (val) => (
        <span style={{ fontSize: '12px', color: '#0D9488', fontWeight: 600 }}>
          {formatRupee(val)}
        </span>
      ),
    },
    {
      title: 'Delivery Type',
      dataIndex: 'deliveryType',
      key: 'deliveryType',
      render: (val) => (
        <span style={{ fontSize: '12px', color: '#475569', display: 'flex', alignItems: 'center', gap: '4px' }}>
          {val === 'COURIER' ? <Truck size={14} /> : <Handshake size={14} />}
          {val === 'COURIER' ? 'Courier' : 'In-Person'}
        </span>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (val) => <StatusBadge status={val} />,
    },
    {
      title: 'Payment Status',
      dataIndex: 'paymentStatus',
      key: 'paymentStatus',
      render: (val) => <StatusBadge status={val} />,
    },
    {
      title: 'Action',
      key: 'action',
      align: 'right',
      render: (_, record) => (
        <Button
          type="link"
          onClick={() => navigate(`/orders/${record.id}`)}
          style={{ color: '#0D9488', fontWeight: 600, padding: 0 }}
        >
          Details →
        </Button>
      ),
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
          Orders
        </h1>
        <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
          Manage marketplace escrow transactions and fulfillment tracking
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
        <div style={{ padding: '16px 20px 0', borderBottom: '1px solid #E2E8F0' }}>
          <div style={{ display: 'flex', gap: '16px', flexWrap: 'wrap', alignItems: 'center' }}>
            <Input
              prefix={<Search size={16} color="#94A3B8" />}
              placeholder="Search by order number, buyer, seller..."
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
                { key: 'ALL', label: 'All Orders' },
                { key: 'DELIVERED', label: 'Delivered' },
                { key: 'SHIPPED', label: 'Shipped' },
                { key: 'SELLER_CONFIRMED', label: 'Confirmed' },
              ]}
            />
          </div>
        </div>

        <Table
          columns={columns}
          dataSource={filteredOrders}
          rowKey="id"
          loading={loading}
          pagination={false}
        />
      </div>
    </div>
  );
};
