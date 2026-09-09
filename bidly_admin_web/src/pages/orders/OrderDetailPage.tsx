import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Row, Col, Card, Button, Steps, message, Modal } from 'antd';
import { ArrowLeft, CheckCircle, Truck, MapPin, ShieldCheck, DollarSign } from 'lucide-react';
import { ordersApi } from '../../api/orders.api';
import type { Order } from '../../types';
import { StatusBadge } from '../../components/common/StatusBadge';
import { formatRupee, formatDate } from '../../utils/format';

export const OrderDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [order, setOrder] = useState<Order | null>(null);

  useEffect(() => {
    if (!id) return;
    ordersApi.getOrderById(id).then(setOrder);
  }, [id]);

  if (!order) {
    return <div style={{ padding: '40px', textAlign: 'center' }}>Loading order...</div>;
  }

  const handleReleaseEscrow = () => {
    Modal.confirm({
      title: 'Release Escrow to Seller?',
      content: `This will instantly transfer ${formatRupee(order.amount)} to seller ${order.seller.name}'s wallet.`,
      okText: 'Yes, Release Payment',
      okButtonProps: { style: { backgroundColor: '#0D9488' } },
      onOk: () => {
        message.success('Escrow released successfully to seller');
        setOrder({ ...order, paymentStatus: 'RELEASED' });
      },
    });
  };

  return (
    <div>
      <div style={{ marginBottom: '16px' }}>
        <Button
          type="text"
          icon={<ArrowLeft size={16} />}
          onClick={() => navigate('/orders')}
          style={{ padding: '0 8px', color: '#64748B', fontWeight: 500 }}
        >
          Back to Orders
        </Button>
      </div>

      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          backgroundColor: '#FFFFFF',
          padding: '24px 28px',
          borderRadius: '12px',
          border: '1px solid #E2E8F0',
          marginBottom: '24px',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <h1 style={{ fontSize: '22px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
              Order {order.orderNumber}
            </h1>
            <StatusBadge status={order.status} />
            <StatusBadge status={order.paymentStatus} />
          </div>
          <div style={{ fontSize: '13px', color: '#64748B', marginTop: '4px' }}>
            Placed on {formatDate(order.createdAt)} · Type: {order.deliveryType}
          </div>
        </div>

        <div style={{ display: 'flex', gap: '12px' }}>
          {order.paymentStatus === 'IN_ESCROW' && (
            <Button
              type="primary"
              onClick={handleReleaseEscrow}
              style={{ backgroundColor: '#0D9488', borderRadius: '8px', fontWeight: 600 }}
            >
              Release Escrow Payout
            </Button>
          )}
        </div>
      </div>

      {/* Steps */}
      <Card style={{ borderRadius: '12px', border: '1px solid #E2E8F0', marginBottom: '24px' }}>
        <Steps
          current={order.status === 'DELIVERED' ? 4 : order.status === 'SHIPPED' ? 2 : 1}
          items={[
            { title: 'Order Placed', description: formatDate(order.createdAt) },
            { title: 'Payment In Escrow', description: 'Secured' },
            { title: 'Fulfillment', description: order.deliveryType },
            { title: 'Delivered / Completed' },
          ]}
        />
      </Card>

      <Row gutter={[24, 24]}>
        <Col xs={24} md={12}>
          <Card
            title={<span style={{ fontSize: '15px', fontWeight: 600 }}>Buyer Information</span>}
            style={{ borderRadius: '12px', border: '1px solid #E2E8F0', marginBottom: '20px' }}
          >
            <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>{order.buyer?.name}</div>
            <div style={{ fontSize: '13px', color: '#64748B', marginTop: '4px' }}>{order.buyer?.phone}</div>
            <div style={{ fontSize: '13px', color: '#64748B' }}>{order.buyer?.email}</div>
            <Button
              type="link"
              onClick={() => navigate(`/users/${order.buyer.id}`)}
              style={{ padding: 0, marginTop: '8px', color: '#0D9488', fontWeight: 600 }}
            >
              View Buyer Profile →
            </Button>
          </Card>

          <Card
            title={<span style={{ fontSize: '15px', fontWeight: 600 }}>Seller Information</span>}
            style={{ borderRadius: '12px', border: '1px solid #E2E8F0' }}
          >
            <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>{order.seller?.name}</div>
            <div style={{ fontSize: '13px', color: '#64748B', marginTop: '4px' }}>{order.seller?.phone}</div>
            <Button
              type="link"
              onClick={() => navigate(`/users/${order.seller.id}`)}
              style={{ padding: 0, marginTop: '8px', color: '#0D9488', fontWeight: 600 }}
            >
              View Seller Profile →
            </Button>
          </Card>
        </Col>

        <Col xs={24} md={12}>
          <Card
            title={<span style={{ fontSize: '15px', fontWeight: 600 }}>Order Financials</span>}
            style={{ borderRadius: '12px', border: '1px solid #E2E8F0' }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', fontSize: '14px' }}>
              <span style={{ color: '#64748B' }}>Item Subtotal:</span>
              <span style={{ fontWeight: 600, color: '#0F172A' }}>{formatRupee(order.amount)}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', fontSize: '14px' }}>
              <span style={{ color: '#64748B' }}>Bidly Platform Fee:</span>
              <span style={{ fontWeight: 600, color: '#0D9488' }}>{formatRupee(order.platformFee)}</span>
            </div>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                padding: '12px 0 0',
                borderTop: '1px solid #E2E8F0',
                fontSize: '16px',
              }}
            >
              <span style={{ fontWeight: 700, color: '#0F172A' }}>Total Amount:</span>
              <span style={{ fontWeight: 700, color: '#0F172A' }}>{formatRupee(order.totalAmount)}</span>
            </div>
          </Card>
        </Col>
      </Row>
    </div>
  );
};
