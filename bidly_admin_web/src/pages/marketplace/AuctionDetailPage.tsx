import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Row, Col, Card, Button, Table, message, Modal } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { ArrowLeft, Gavel, Clock, Eye, AlertCircle, CheckCircle } from 'lucide-react';
import { listingsApi } from '../../api/listings.api';
import { auctionsApi } from '../../api/auctions.api';
import type { Listing, Bid } from '../../types';
import { StatusBadge } from '../../components/common/StatusBadge';
import { formatRupee, formatDate, formatTimeAgo } from '../../utils/format';

export const AuctionDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [listing, setListing] = useState<Listing | null>(null);
  const [bids, setBids] = useState<Bid[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    const load = async () => {
      if (!id) return;
      try {
        const [l, b] = await Promise.all([
          listingsApi.getListingById(id),
          auctionsApi.getBidsForListing(id),
        ]);
        setListing(l);
        setBids(b);
      } catch {
        message.error('Failed to load auction detail');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [id]);

  if (!listing) {
    return <div style={{ padding: '40px', textAlign: 'center' }}>Loading auction...</div>;
  }

  const bidColumns: ColumnsType<Bid> = [
    {
      title: 'Bidder',
      key: 'bidder',
      render: (_, record) => (
        <span
          onClick={() => navigate(`/users/${record.bidder.id}`)}
          style={{ color: '#0D9488', fontWeight: 600, cursor: 'pointer' }}
        >
          {record.bidder.name}
        </span>
      ),
    },
    {
      title: 'Bid Amount',
      dataIndex: 'amount',
      key: 'amount',
      render: (val, record) => (
        <span style={{ fontWeight: 700, color: record.status === 'ACTIVE' ? '#10B981' : '#0F172A' }}>
          {formatRupee(val)}
        </span>
      ),
    },
    {
      title: 'Placed At',
      dataIndex: 'createdAt',
      key: 'createdAt',
      render: (val) => formatTimeAgo(val),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (val) => <StatusBadge status={val} />,
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: '16px' }}>
        <Button
          type="text"
          icon={<ArrowLeft size={16} />}
          onClick={() => navigate('/marketplace/auctions')}
          style={{ padding: '0 8px', color: '#64748B', fontWeight: 500 }}
        >
          Back to Auctions
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
              {listing.title}
            </h1>
            <StatusBadge status="Live" variant="live" />
          </div>
          <div style={{ fontSize: '13px', color: '#64748B', marginTop: '4px' }}>
            Category: {listing.category?.name} · Condition: {listing.condition} · Listed on{' '}
            {formatDate(listing.createdAt)}
          </div>
        </div>

        <div style={{ display: 'flex', gap: '12px' }}>
          <Button
            danger
            onClick={() =>
              Modal.confirm({
                title: 'Cancel this Auction?',
                content: 'This will refund/cancel all placed bids and remove the listing from public feed.',
                okText: 'Yes, Cancel',
                okType: 'danger',
                onOk: () => message.success('Auction cancelled by administrator'),
              })
            }
            style={{ borderRadius: '8px', fontWeight: 600 }}
          >
            Cancel Auction
          </Button>
        </div>
      </div>

      <Row gutter={[24, 24]}>
        <Col xs={24} lg={16}>
          <Card
            title={<span style={{ fontSize: '15px', fontWeight: 600 }}>Live Bidding Log</span>}
            bodyStyle={{ padding: 0 }}
            style={{ borderRadius: '12px', border: '1px solid #E2E8F0', overflow: 'hidden' }}
          >
            <Table
              columns={bidColumns}
              dataSource={bids}
              rowKey="id"
              pagination={false}
              locale={{ emptyText: 'No bids placed yet' }}
            />
          </Card>

          <Card
            title={<span style={{ fontSize: '15px', fontWeight: 600 }}>Item Description</span>}
            style={{ marginTop: '20px', borderRadius: '12px', border: '1px solid #E2E8F0' }}
          >
            <p style={{ color: '#334155', lineHeight: 1.6, fontSize: '14px' }}>
              {listing.description || 'No description provided.'}
            </p>
          </Card>
        </Col>

        <Col xs={24} lg={8}>
          <Card
            style={{
              borderRadius: '12px',
              border: '1px solid #E2E8F0',
              backgroundColor: '#0F4C4C',
              color: '#FFFFFF',
              marginBottom: '20px',
            }}
          >
            <div style={{ fontSize: '12px', color: '#99F6E4', textTransform: 'uppercase' }}>
              Current Highest Bid
            </div>
            <div style={{ fontSize: '32px', fontWeight: 800, marginTop: '4px' }}>
              {formatRupee(listing.currentBid || listing.price)}
            </div>
            <div style={{ fontSize: '12px', color: '#CCFBF1', marginTop: '6px' }}>
              Starting Price: {formatRupee(listing.startingBid || listing.price)} · Minimum Increment:{' '}
              {formatRupee(listing.bidIncrement || 1000)}
            </div>
          </Card>

          <Card
            title={<span style={{ fontSize: '15px', fontWeight: 600 }}>Seller Information</span>}
            style={{ borderRadius: '12px', border: '1px solid #E2E8F0' }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '12px' }}>
              <div
                style={{
                  width: '40px',
                  height: '40px',
                  borderRadius: '50%',
                  backgroundColor: '#0D9488',
                  color: '#FFFFFF',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontWeight: 700,
                }}
              >
                {listing.seller.name.slice(0, 2).toUpperCase()}
              </div>
              <div>
                <div
                  onClick={() => navigate(`/users/${listing.seller.id}`)}
                  style={{ fontWeight: 600, color: '#0D9488', cursor: 'pointer' }}
                >
                  {listing.seller.name}
                </div>
                <div style={{ fontSize: '12px', color: '#64748B' }}>{listing.seller.phone}</div>
              </div>
            </div>
            <Button
              block
              onClick={() => navigate(`/users/${listing.seller.id}`)}
              style={{ borderRadius: '8px', marginTop: '8px' }}
            >
              View Full Seller Profile
            </Button>
          </Card>
        </Col>
      </Row>
    </div>
  );
};
