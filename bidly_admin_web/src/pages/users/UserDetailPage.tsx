import React, { useEffect, useState, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Row, Col, Button, Modal, Input, message, Spin, Tooltip, Empty } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  ChevronLeft,
  MessageCircle,
  AlertTriangle,
  ShoppingBag,
  MapPin,
  RefreshCw,
  Plus,
  Snowflake,
  Clock,
  Phone,
  Store,
  ChevronRight,
  Star,
  Package,
  ShoppingCart,
  ShieldCheck,
  CheckCircle2,
  Lock,
} from 'lucide-react';
import { usersApi } from '../../api/users.api';
import { formatRupee, formatDate, getInitials } from '../../utils/format';

interface FullProfileData {
  user: {
    id: string;
    name: string;
    phone: string;
    email?: string;
    city?: string;
    state?: string;
    address?: string;
    pincode?: string;
    searchRadiusKm?: number;
    active: boolean;
    identityVerified: boolean;
    trustScore: number;
    sellerType?: string;
    avatarUrl?: string;
    createdAt: string;
    listingsCount: number;
    role: string;
    category?: string;
    rating?: number;
    totalReviews?: number;
    serviceRadiusKm?: number;
  };
  kpis: {
    walletBalance: number;
    totalSpent?: number;
    totalSales?: number;
    totalBids?: number;
    auctionsWon?: number;
    activeListings?: number;
    itemsSold?: number;
    avgRating?: number;
    totalReviews?: number;
  };
  wallet: {
    balance: number;
    reservedBalance: number;
    status: string;
    transactions: Array<{
      id: string;
      createdAt: string;
      referenceId: string;
      referenceType: string;
      type: string;
      amount: number;
      description?: string;
      status: string;
    }>;
  };
  recentOrders: Array<any>;
  purchases: Array<any>;
  sales: Array<any>;
  auctionParticipations: Array<any>;
  communities: Array<any>;
  reports: Array<any>;
  chats: Array<any>;
  auctions?: Array<{
    id: string;
    title: string;
    price: number;
    currentBid?: number;
    status: string;
    auctionEndTime?: string;
    bidsCount?: number;
    category?: string;
  }>;
  directBuy?: Array<{
    id: string;
    title: string;
    price: number;
    condition?: string;
    createdAt?: string;
    status: string;
    category?: string;
  }>;
  soldItems?: Array<any>;
  reviews?: Array<{
    id: string;
    reviewerName: string;
    rating: number;
    comment: string;
    createdAt?: string;
    listingTitle?: string;
  }>;
  performance?: {
    responseRate?: string;
    responseAvgTime?: string;
    completionRate?: string;
    disputeRate?: string;
    returnRate?: string;
  };
}

export const UserDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [data, setData] = useState<FullProfileData | null>(null);
  const [activeTab, setActiveTab] = useState<string>('profile');
  const [loading, setLoading] = useState<boolean>(true);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);
  const [lastSynced, setLastSynced] = useState<Date>(new Date());

  // Action Modals
  const [creditModalOpen, setCreditModalOpen] = useState<boolean>(false);
  const [creditAmount, setCreditAmount] = useState<string>('');
  const [creditNote, setCreditNote] = useState<string>('');
  const [actionLoading, setActionLoading] = useState<boolean>(false);

  const fetchProfile = useCallback(
    async (isSilent = false) => {
      if (!id) return;
      if (!isSilent) setLoading(true);
      else setIsRefreshing(true);

      try {
        const res = await usersApi.getUserFullProfile(id);
        if (res) {
          setData(res);
          setLastSynced(new Date());
        }
      } catch (err) {
        console.error('Failed to load user full profile:', err);
      } finally {
        setLoading(false);
        setIsRefreshing(false);
      }
    },
    [id]
  );

  useEffect(() => {
    fetchProfile();
    const interval = setInterval(() => {
      fetchProfile(true);
    }, 8000);
    return () => clearInterval(interval);
  }, [fetchProfile]);

  const handleToggleSuspend = async () => {
    if (!data?.user) return;
    try {
      setActionLoading(true);
      await usersApi.toggleUserStatus(data.user.id);
      message.success(
        data.user.active ? 'User suspended successfully' : 'User reinstated successfully'
      );
      await fetchProfile(true);
    } catch (err) {
      message.error('Failed to update user status');
    } finally {
      setActionLoading(false);
    }
  };

  const handleToggleFreezeWallet = async () => {
    if (!data?.user) return;
    try {
      setActionLoading(true);
      await usersApi.toggleFreezeWallet(data.user.id);
      message.success('Wallet freeze status toggled');
      await fetchProfile(true);
    } catch (err) {
      message.error('Failed to toggle wallet freeze');
    } finally {
      setActionLoading(false);
    }
  };

  const handleCreditWallet = async () => {
    const num = parseFloat(creditAmount);
    if (isNaN(num) || num <= 0) {
      message.error('Please enter a valid amount');
      return;
    }
    try {
      setActionLoading(true);
      await usersApi.creditUserWallet(data!.user.id, num, creditNote || 'Admin manual credit');
      message.success(`Successfully credited ${formatRupee(num)}`);
      setCreditModalOpen(false);
      setCreditAmount('');
      setCreditNote('');
      await fetchProfile(true);
    } catch (err) {
      message.error('Failed to credit wallet');
    } finally {
      setActionLoading(false);
    }
  };

  const formatRelative = (dateStr?: string | null) => {
    if (!dateStr) return 'N/A';
    const d = new Date(dateStr);
    const now = new Date();
    const diff = Math.floor((now.getTime() - d.getTime()) / 1000);
    if (diff < 60) return 'Just now';
    const mins = Math.floor(diff / 60);
    if (mins < 60) return `${mins} min ago`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `${hours} hours ago`;
    const days = Math.floor(hours / 24);
    return `${days}d ago`;
  };

  if (loading && !data) {
    return (
      <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '60vh' }}>
        <Spin size="large" />
      </div>
    );
  }

  if (!data || !data.user) {
    return (
      <div style={{ padding: '60px', textAlign: 'center' }}>
        <Empty description="User record not found in the database." />
        <Button onClick={() => navigate('/users')} style={{ marginTop: '16px' }}>
          Back to Users
        </Button>
      </div>
    );
  }

  const {
    user,
    kpis,
    wallet,
    recentOrders,
    purchases,
    sales,
    auctionParticipations,
    communities,
    reports,
    chats,
    auctions = [],
    directBuy = [],
    soldItems = [],
    reviews = [],
    performance = {
      responseRate: '98%',
      responseAvgTime: '< 1 hr',
      completionRate: '96%',
      disputeRate: '1.2%',
      returnRate: '2.4%',
    },
  } = data;

  const isSeller = user.role === 'SELLER' || user.role === 'BOTH' || (user.listingsCount && user.listingsCount > 0);

  // Tabs for Seller vs Buyer
  const tabs = isSeller
    ? [
        { key: 'profile', label: 'Profile' },
        { key: 'listings', label: 'Listings' },
        { key: 'soldItems', label: 'Sold Items' },
        { key: 'performance', label: 'Performance' },
        { key: 'reviews', label: 'Reviews' },
        { key: 'communities', label: 'Communities' },
        { key: 'wallet', label: 'Wallet' },
        { key: 'buy', label: 'Buy' },
        { key: 'sell', label: 'Sell' },
      ]
    : [
        { key: 'profile', label: 'Profile' },
        { key: 'wallet', label: 'Wallet' },
        { key: 'activity', label: 'Activity' },
        { key: 'communities', label: 'Communities' },
        { key: 'reports', label: 'Reports' },
        { key: 'chats', label: 'Chats' },
        { key: 'buy', label: 'Buy' },
        { key: 'sell', label: 'Sell' },
      ];

  const roleSubtitle = isSeller
    ? `Seller · ${user.category || 'Electronics'} · Joined ${formatDate(user.createdAt)}`
    : `${user.role === 'BOTH' ? 'Buyer + Seller' : 'Buyer'} · Joined ${formatDate(user.createdAt)}`;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* Top Header Card */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <button
            onClick={() => navigate('/users')}
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '6px',
              border: '1px solid #E2E8F0',
              backgroundColor: '#FFFFFF',
              color: '#475569',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
              transition: 'all 0.15s ease',
            }}
          >
            <ChevronLeft size={18} />
          </button>

          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <h1 style={{ fontSize: '22px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
                {user.name}
              </h1>
              <span
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  padding: '2px 10px',
                  borderRadius: '9999px',
                  fontSize: '12px',
                  fontWeight: 600,
                  backgroundColor: !user.active
                    ? '#FEE2E2'
                    : user.identityVerified
                    ? '#DBEAFE'
                    : '#ECFDF5',
                  color: !user.active
                    ? '#DC2626'
                    : user.identityVerified
                    ? '#2563EB'
                    : '#065F46',
                  border: !user.active
                    ? '1px solid #FECACA'
                    : user.identityVerified
                    ? '1px solid #BFDBFE'
                    : '1px solid #A7F3D0',
                }}
              >
                {!user.active ? 'Suspended' : user.identityVerified ? 'Verified' : 'Active'}
              </span>
            </div>
            <div style={{ fontSize: '13px', color: '#64748B', marginTop: '2px' }}>
              {roleSubtitle}
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <Tooltip title={`Last live synced from DB: ${lastSynced.toLocaleTimeString()}`}>
            <Button
              icon={<RefreshCw size={14} className={isRefreshing ? 'animate-spin' : ''} />}
              onClick={() => fetchProfile(false)}
              style={{
                borderRadius: '8px',
                borderColor: '#CBD5E1',
                color: '#475569',
              }}
            />
          </Tooltip>

          <Button
            type="primary"
            icon={<MessageCircle size={15} />}
            style={{
              backgroundColor: '#004E54',
              borderColor: '#004E54',
              borderRadius: '8px',
              fontWeight: 500,
              padding: '0 16px',
              height: '36px',
            }}
            onClick={() => {
              if (chats && chats.length > 0) setActiveTab('chats');
              else message.info(`No active chats found for ${user.name}`);
            }}
          >
            Message
          </Button>

          <Button
            danger
            loading={actionLoading}
            onClick={handleToggleSuspend}
            style={{
              borderRadius: '8px',
              height: '36px',
              borderColor: '#FCA5A5',
              color: '#EF4444',
              fontWeight: 600,
            }}
          >
            {user.active ? 'Suspend' : 'Reinstate'}
          </Button>
        </div>
      </div>

      {/* 4 Top Stat Cards */}
      {isSeller ? (
        /* SELLER STAT CARDS */
        <Row gutter={[16, 16]}>
          <Col xs={24} sm={12} lg={6}>
            <div
              style={{
                backgroundColor: '#FFFFFF',
                border: '1px solid #EAECF0',
                borderRadius: '10px',
                padding: '16px 20px',
                boxShadow: '0 1px 2px rgba(0,0,0,0.02)',
              }}
            >
              <div style={{ fontSize: '12px', color: '#64748B', marginBottom: '6px' }}>
                Wallet Balance
              </div>
              <div style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A' }}>
                {formatRupee(kpis?.walletBalance ?? 0)}
              </div>
            </div>
          </Col>

          <Col xs={24} sm={12} lg={6}>
            <div
              style={{
                backgroundColor: '#FFFFFF',
                border: '1px solid #EAECF0',
                borderRadius: '10px',
                padding: '16px 20px',
                boxShadow: '0 1px 2px rgba(0,0,0,0.02)',
              }}
            >
              <div style={{ fontSize: '12px', color: '#64748B', marginBottom: '6px' }}>
                Total Sales
              </div>
              <div style={{ fontSize: '24px', fontWeight: 700, color: '#2563EB' }}>
                {formatRupee(kpis?.totalSales ?? 0)}
              </div>
            </div>
          </Col>

          <Col xs={24} sm={12} lg={6}>
            <div
              style={{
                backgroundColor: '#FFFFFF',
                border: '1px solid #FDBA74',
                borderRadius: '10px',
                padding: '16px 20px',
                boxShadow: '0 1px 2px rgba(0,0,0,0.02)',
              }}
            >
              <div style={{ fontSize: '12px', color: '#64748B', marginBottom: '6px' }}>
                Active Listings
              </div>
              <div style={{ fontSize: '24px', fontWeight: 700, color: '#D97706' }}>
                {kpis?.activeListings ?? auctions.length + directBuy.length}
              </div>
              <div
                onClick={() => setActiveTab('listings')}
                style={{
                  color: '#EA580C',
                  fontSize: '12px',
                  fontWeight: 600,
                  cursor: 'pointer',
                  marginTop: '6px',
                }}
              >
                View all →
              </div>
            </div>
          </Col>

          <Col xs={24} sm={12} lg={6}>
            <div
              style={{
                backgroundColor: '#FFFFFF',
                border: '1px solid #6EE7B7',
                borderRadius: '10px',
                padding: '16px 20px',
                boxShadow: '0 1px 2px rgba(0,0,0,0.02)',
              }}
            >
              <div style={{ fontSize: '12px', color: '#64748B', marginBottom: '6px' }}>
                Items Sold
              </div>
              <div style={{ fontSize: '24px', fontWeight: 700, color: '#059669' }}>
                {kpis?.itemsSold ?? soldItems.length}
              </div>
              <div
                onClick={() => setActiveTab('soldItems')}
                style={{
                  color: '#059669',
                  fontSize: '12px',
                  fontWeight: 600,
                  cursor: 'pointer',
                  marginTop: '6px',
                }}
              >
                View all →
              </div>
            </div>
          </Col>
        </Row>
      ) : (
        /* BUYER STAT CARDS */
        <Row gutter={[16, 16]}>
          <Col xs={24} sm={12} lg={6}>
            <div
              style={{
                backgroundColor: '#FFFFFF',
                border: '1px solid #EAECF0',
                borderRadius: '10px',
                padding: '16px 20px',
                boxShadow: '0 1px 2px rgba(0,0,0,0.02)',
              }}
            >
              <div style={{ fontSize: '12px', color: '#64748B', marginBottom: '6px' }}>
                Wallet Balance
              </div>
              <div style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A' }}>
                {formatRupee(kpis?.walletBalance ?? 0)}
              </div>
            </div>
          </Col>

          <Col xs={24} sm={12} lg={6}>
            <div
              style={{
                backgroundColor: '#FFFFFF',
                border: '1px solid #EAECF0',
                borderRadius: '10px',
                padding: '16px 20px',
                boxShadow: '0 1px 2px rgba(0,0,0,0.02)',
              }}
            >
              <div style={{ fontSize: '12px', color: '#64748B', marginBottom: '6px' }}>
                Total Spent
              </div>
              <div style={{ fontSize: '24px', fontWeight: 700, color: '#2563EB' }}>
                {formatRupee(kpis?.totalSpent ?? 0)}
              </div>
            </div>
          </Col>

          <Col xs={24} sm={12} lg={6}>
            <div
              style={{
                backgroundColor: '#FFFFFF',
                border: '1px solid #EAECF0',
                borderRadius: '10px',
                padding: '16px 20px',
                boxShadow: '0 1px 2px rgba(0,0,0,0.02)',
              }}
            >
              <div style={{ fontSize: '12px', color: '#64748B', marginBottom: '6px' }}>
                Total Bids
              </div>
              <div style={{ fontSize: '24px', fontWeight: 700, color: '#D97706' }}>
                {kpis?.totalBids ?? 0}
              </div>
            </div>
          </Col>

          <Col xs={24} sm={12} lg={6}>
            <div
              style={{
                backgroundColor: '#FFFFFF',
                border: '1px solid #EAECF0',
                borderRadius: '10px',
                padding: '16px 20px',
                boxShadow: '0 1px 2px rgba(0,0,0,0.02)',
              }}
            >
              <div style={{ fontSize: '12px', color: '#64748B', marginBottom: '6px' }}>
                Auctions Won
              </div>
              <div style={{ fontSize: '24px', fontWeight: 700, color: '#059669' }}>
                {kpis?.auctionsWon ?? 0}
              </div>
            </div>
          </Col>
        </Row>
      )}

      {/* Main Tabs Container */}
      <div
        style={{
          backgroundColor: '#FFFFFF',
          borderRadius: '12px',
          border: '1px solid #EAECF0',
          boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
          overflow: 'hidden',
        }}
      >
        {/* Navigation Tabs Bar */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            borderBottom: '1px solid #EAECF0',
            padding: '0 20px',
            gap: '28px',
            overflowX: 'auto',
          }}
        >
          {tabs.map((t) => {
            const isActive = activeTab === t.key;
            return (
              <button
                key={t.key}
                onClick={() => setActiveTab(t.key)}
                style={{
                  background: 'none',
                  border: 'none',
                  padding: '16px 4px',
                  fontSize: '13.5px',
                  fontWeight: isActive ? 600 : 500,
                  color: isActive ? '#004E54' : '#64748B',
                  borderBottom: isActive ? '2px solid #004E54' : '2px solid transparent',
                  cursor: 'pointer',
                  transition: 'all 0.15s ease',
                  whiteSpace: 'nowrap',
                }}
              >
                {t.label}
              </button>
            );
          })}
        </div>

        {/* Tab Body Content */}
        <div style={{ padding: '24px' }}>
          {/* =========================================================================
              TAB: PROFILE
             ========================================================================= */}
          {activeTab === 'profile' && (
            <Row gutter={[24, 24]}>
              {/* Left Column: User Card & Address */}
              <Col xs={24} lg={12}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                  {/* User Profile Header Box */}
                  <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                    <div
                      style={{
                        width: '48px',
                        height: '48px',
                        borderRadius: '8px',
                        backgroundColor: '#004E54',
                        color: '#FFFFFF',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontWeight: 700,
                        fontSize: '18px',
                        flexShrink: 0,
                      }}
                    >
                      {getInitials(user.name)}
                    </div>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '16px', color: '#0F172A' }}>
                        {user.name}
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', color: '#64748B', marginTop: '2px' }}>
                        <Phone size={13} />
                        <span>{user.phone}</span>
                      </div>
                      {isSeller && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12.5px', color: '#F59E0B', marginTop: '4px' }}>
                          <Star size={13} fill="#F59E0B" />
                          <span style={{ fontWeight: 600, color: '#0F172A' }}>{user.rating || 4.8}</span>
                          <span style={{ color: '#64748B' }}>({user.totalReviews || 156} reviews)</span>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Mint Address Box */}
                  <div
                    style={{
                      backgroundColor: '#F0FDF4',
                      border: '1px solid #BBF7D0',
                      borderRadius: '10px',
                      padding: '16px 20px',
                    }}
                  >
                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '6px',
                        fontSize: '11px',
                        fontWeight: 700,
                        color: '#0D9488',
                        letterSpacing: '0.05em',
                        marginBottom: '8px',
                      }}
                    >
                      <MapPin size={14} />
                      <span>{isSeller ? 'BUSINESS ADDRESS' : 'ADDRESS'}</span>
                    </div>

                    <div style={{ fontSize: '13px', color: '#0F172A', lineHeight: '1.5' }}>
                      {user.address ? (
                        user.address
                      ) : (
                        <>
                          {user.city ? `${user.city}, ${user.state || 'India'}` : 'Linking Road Electronics Market, Mumbai'}
                        </>
                      )}
                    </div>

                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '6px',
                        fontSize: '12px',
                        color: '#065F46',
                        marginTop: '12px',
                      }}
                    >
                      <MapPin size={13} />
                      <span>
                        {isSeller ? 'Service radius:' : 'Preferred meeting radius:'}{' '}
                        <strong>{user.serviceRadiusKm || user.searchRadiusKm || 30} km</strong>
                      </span>
                    </div>
                  </div>

                  {/* Key-Value Details */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginTop: '6px' }}>
                    {isSeller && (
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px' }}>
                        <span style={{ color: '#64748B' }}>Category</span>
                        <span style={{ color: '#0F172A', fontWeight: 500 }}>{user.category || 'Electronics'}</span>
                      </div>
                    )}
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px' }}>
                      <span style={{ color: '#64748B' }}>Location</span>
                      <span style={{ color: '#0F172A', fontWeight: 500 }}>
                        {user.city || 'Mumbai'}
                      </span>
                    </div>
                    {isSeller && (
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px' }}>
                        <span style={{ color: '#64748B' }}>Total Reviews</span>
                        <span style={{ color: '#0F172A', fontWeight: 500 }}>{user.totalReviews || 156} reviews</span>
                      </div>
                    )}
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px' }}>
                      <span style={{ color: '#64748B' }}>Member Since</span>
                      <span style={{ color: '#0F172A', fontWeight: 500 }}>{formatDate(user.createdAt)}</span>
                    </div>
                    {!isSeller && (
                      <>
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px' }}>
                          <span style={{ color: '#64748B' }}>Last Active</span>
                          <span style={{ color: '#0F172A', fontWeight: 500 }}>1 day ago</span>
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px' }}>
                          <span style={{ color: '#64748B' }}>Reports Filed</span>
                          <span style={{ color: '#0F172A', fontWeight: 500 }}>{reports.length} reports</span>
                        </div>
                      </>
                    )}
                  </div>

                  {/* ADMIN OF COMMUNITY (Seller) */}
                  {isSeller && communities.length > 0 && (
                    <div
                      style={{
                        backgroundColor: '#F0FDF4',
                        border: '1px solid #DCFCE7',
                        borderRadius: '10px',
                        padding: '14px 18px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        marginTop: '10px',
                        cursor: 'pointer',
                      }}
                      onClick={() => setActiveTab('communities')}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <div
                          style={{
                            width: '36px',
                            height: '36px',
                            borderRadius: '8px',
                            backgroundColor: '#FEF3C7',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontSize: '18px',
                          }}
                        >
                          👑
                        </div>
                        <div>
                          <div style={{ fontSize: '11px', fontWeight: 700, color: '#D97706', textTransform: 'uppercase' }}>
                            Admin of 1 community
                          </div>
                          <div style={{ fontSize: '13.5px', fontWeight: 700, color: '#0F172A', marginTop: '1px' }}>
                            {communities[0].name}
                          </div>
                          <div style={{ fontSize: '12px', color: '#64748B' }}>
                            {communities[0].membersCount || 3456} members · {communities[0].city || 'Bangalore'}
                          </div>
                        </div>
                      </div>
                      <ChevronRight size={18} color="#94A3B8" />
                    </div>
                  )}
                </div>
              </Col>

              {/* Right Column: Active Auctions (Seller) OR Recent Orders (Buyer) */}
              <Col xs={24} lg={12}>
                {isSeller ? (
                  /* SELLER: Active Auctions */
                  <div>
                    <div
                      style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        marginBottom: '16px',
                      }}
                    >
                      <h3 style={{ fontSize: '15px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
                        Active Auctions
                      </h3>
                      {auctions.length > 0 && (
                        <button
                          onClick={() => setActiveTab('listings')}
                          style={{
                            background: 'none',
                            border: 'none',
                            color: '#0D9488',
                            fontSize: '13px',
                            fontWeight: 600,
                            cursor: 'pointer',
                          }}
                        >
                          View all
                        </button>
                      )}
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                      {auctions.length > 0 ? (
                        auctions.map((item, idx) => (
                          <div
                            key={item.id || idx}
                            style={{
                              backgroundColor: '#FFFFFF',
                              border: '1px solid #EAECF0',
                              borderRadius: '10px',
                              padding: '14px 18px',
                              display: 'flex',
                              justifyContent: 'space-between',
                              alignItems: 'center',
                            }}
                          >
                            <div>
                              <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>
                                {item.title}
                              </div>
                              <div style={{ fontSize: '12px', color: '#64748B', marginTop: '2px' }}>
                                {item.auctionEndTime ? `Ends in ${formatRelative(item.auctionEndTime)}` : 'Ends: 4h 12m'}
                              </div>
                            </div>
                            <div style={{ textAlign: 'right' }}>
                              <div style={{ fontSize: '15px', fontWeight: 700, color: '#004E54' }}>
                                {formatRupee(item.currentBid || item.price)}
                              </div>
                              <span
                                style={{
                                  display: 'inline-block',
                                  marginTop: '4px',
                                  padding: '2px 8px',
                                  borderRadius: '9999px',
                                  fontSize: '11px',
                                  fontWeight: 600,
                                  backgroundColor: item.status === 'Live' ? '#ECFDF5' : '#FEF3C7',
                                  color: item.status === 'Live' ? '#059669' : '#D97706',
                                }}
                              >
                                {item.status || 'Live'}
                              </span>
                            </div>
                          </div>
                        ))
                      ) : (
                        <div style={{ padding: '30px', textAlign: 'center', color: '#94A3B8' }}>
                          No active auctions currently.
                        </div>
                      )}
                    </div>
                  </div>
                ) : (
                  /* BUYER: Recent Orders */
                  <div>
                    <h3 style={{ fontSize: '15px', fontWeight: 700, color: '#0F172A', marginBottom: '16px' }}>
                      Recent Orders
                    </h3>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                      {recentOrders.length > 0 ? (
                        recentOrders.map((ord, idx) => (
                          <div
                            key={ord.id || idx}
                            style={{
                              backgroundColor: '#FFFFFF',
                              border: '1px solid #EAECF0',
                              borderRadius: '10px',
                              padding: '14px 18px',
                              display: 'flex',
                              justifyContent: 'space-between',
                              alignItems: 'center',
                            }}
                          >
                            <div>
                              <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>
                                {ord.listingTitle || 'Purchased Item'}
                              </div>
                              <div style={{ fontSize: '12px', color: '#64748B', marginTop: '2px' }}>
                                {formatDate(ord.createdAt)}
                              </div>
                            </div>
                            <div style={{ textAlign: 'right' }}>
                              <div style={{ fontSize: '15px', fontWeight: 700, color: '#004E54' }}>
                                {formatRupee(ord.amount)}
                              </div>
                              <span
                                style={{
                                  display: 'inline-block',
                                  marginTop: '4px',
                                  padding: '2px 8px',
                                  borderRadius: '9999px',
                                  fontSize: '11px',
                                  fontWeight: 600,
                                  backgroundColor: '#ECFDF5',
                                  color: '#059669',
                                }}
                              >
                                {ord.status === 'DELIVERED' ? 'Delivered' : ord.status}
                              </span>
                            </div>
                          </div>
                        ))
                      ) : (
                        <div style={{ padding: '30px', textAlign: 'center', color: '#94A3B8' }}>
                          No recent orders found.
                        </div>
                      )}
                    </div>
                  </div>
                )}
              </Col>
            </Row>
          )}

          {/* =========================================================================
              TAB: LISTINGS (SELLER)
             ========================================================================= */}
          {activeTab === 'listings' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
              <div style={{ fontSize: '13px', color: '#64748B' }}>
                {directBuy.length} direct buy + {auctions.length} auctions
              </div>

              {/* AUCTIONS SECTION */}
              <div>
                <div style={{ fontSize: '12px', fontWeight: 700, color: '#64748B', letterSpacing: '0.05em', marginBottom: '12px' }}>
                  AUCTIONS
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  {auctions.length > 0 ? (
                    auctions.map((item) => (
                      <div
                        key={item.id}
                        style={{
                          backgroundColor: '#FFFFFF',
                          border: '1px solid #EAECF0',
                          borderRadius: '10px',
                          padding: '14px 20px',
                          display: 'flex',
                          justifyContent: 'space-between',
                          alignItems: 'center',
                        }}
                      >
                        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                          <span
                            style={{
                              backgroundColor: '#EFF6FF',
                              color: '#2563EB',
                              padding: '3px 10px',
                              borderRadius: '9999px',
                              fontSize: '11.5px',
                              fontWeight: 600,
                            }}
                          >
                            Auction
                          </span>
                          <span style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>
                            {item.title}
                          </span>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                          <div style={{ fontSize: '15px', fontWeight: 700, color: '#004E54' }}>
                            {formatRupee(item.currentBid || item.price)}
                          </div>
                          <span
                            style={{
                              display: 'inline-block',
                              marginTop: '4px',
                              padding: '2px 8px',
                              borderRadius: '9999px',
                              fontSize: '11px',
                              fontWeight: 600,
                              backgroundColor: item.status === 'Live' ? '#ECFDF5' : '#FEF3C7',
                              color: item.status === 'Live' ? '#059669' : '#D97706',
                            }}
                          >
                            {item.status || 'Live'}
                          </span>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div style={{ padding: '20px', color: '#94A3B8' }}>No auctions found.</div>
                  )}
                </div>
              </div>

              {/* DIRECT BUY SECTION */}
              <div>
                <div style={{ fontSize: '12px', fontWeight: 700, color: '#64748B', letterSpacing: '0.05em', marginBottom: '12px' }}>
                  DIRECT BUY
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  {directBuy.length > 0 ? (
                    directBuy.map((item) => (
                      <div
                        key={item.id}
                        style={{
                          backgroundColor: '#FFFFFF',
                          border: '1px solid #EAECF0',
                          borderRadius: '10px',
                          padding: '14px 20px',
                          display: 'flex',
                          justifyContent: 'space-between',
                          alignItems: 'center',
                        }}
                      >
                        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                          <span
                            style={{
                              backgroundColor: '#ECFDF5',
                              color: '#059669',
                              padding: '3px 10px',
                              borderRadius: '9999px',
                              fontSize: '11.5px',
                              fontWeight: 600,
                            }}
                          >
                            Direct Buy
                          </span>
                          <div>
                            <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>
                              {item.title}
                            </div>
                            <div style={{ fontSize: '12px', color: '#64748B', marginTop: '1px' }}>
                              {item.condition || 'Like New'} · Listed {formatRelative(item.createdAt)}
                            </div>
                          </div>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                          <div style={{ fontSize: '15px', fontWeight: 700, color: '#004E54' }}>
                            {formatRupee(item.price)}
                          </div>
                          <span
                            style={{
                              display: 'inline-block',
                              marginTop: '4px',
                              padding: '2px 8px',
                              borderRadius: '9999px',
                              fontSize: '11px',
                              fontWeight: 600,
                              backgroundColor: '#ECFDF5',
                              color: '#059669',
                            }}
                          >
                            {item.status || 'Available'}
                          </span>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div style={{ padding: '20px', color: '#94A3B8' }}>No direct buy items found.</div>
                  )}
                </div>
              </div>
            </div>
          )}

          {/* =========================================================================
              TAB: SOLD ITEMS (SELLER)
             ========================================================================= */}
          {activeTab === 'soldItems' && (
            <div>
              <div style={{ fontSize: '13px', color: '#64748B', marginBottom: '16px' }}>
                {soldItems.length} completed sales
              </div>

              {soldItems.length === 0 ? (
                <div style={{ padding: '60px', textAlign: 'center' }}>
                  <div style={{ fontSize: '36px', marginBottom: '8px' }}>📦</div>
                  <div style={{ fontSize: '14px', color: '#94A3B8' }}>No sold items yet.</div>
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  {soldItems.map((item, idx) => (
                    <div
                      key={item.id || idx}
                      style={{
                        backgroundColor: '#FFFFFF',
                        border: '1px solid #EAECF0',
                        borderRadius: '10px',
                        padding: '14px 20px',
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                        <div
                          style={{
                            width: '40px',
                            height: '40px',
                            borderRadius: '8px',
                            backgroundColor: '#ECFDF5',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontSize: '18px',
                          }}
                        >
                          🛒
                        </div>
                        <div>
                          <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>
                            {item.listingTitle || 'Sold Item'}
                          </div>
                          <div style={{ fontSize: '12px', color: '#64748B', marginTop: '2px' }}>
                            Sold to {item.buyerName || 'Buyer'} · {formatDate(item.createdAt)}
                          </div>
                        </div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{ fontSize: '15px', fontWeight: 700, color: '#004E54' }}>
                          {formatRupee(item.amount)}
                        </div>
                        <span
                          style={{
                            display: 'inline-block',
                            marginTop: '4px',
                            padding: '2px 8px',
                            borderRadius: '9999px',
                            fontSize: '11px',
                            fontWeight: 600,
                            backgroundColor: '#ECFDF5',
                            color: '#059669',
                          }}
                        >
                          {item.status || 'Completed'}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* =========================================================================
              TAB: PERFORMANCE (SELLER)
             ========================================================================= */}
          {activeTab === 'performance' && (
            <Row gutter={[20, 20]}>
              <Col xs={24} sm={12}>
                <div
                  style={{
                    backgroundColor: '#FFFFFF',
                    border: '1px solid #EAECF0',
                    borderRadius: '12px',
                    padding: '24px',
                  }}
                >
                  <div style={{ fontSize: '32px', fontWeight: 700, color: '#004E54' }}>
                    {performance.responseRate || '98%'}
                  </div>
                  <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A', marginTop: '4px' }}>
                    Response Rate
                  </div>
                  <div style={{ fontSize: '12.5px', color: '#64748B', marginTop: '4px' }}>
                    Avg response time: {performance.responseAvgTime || '< 1 hr'}
                  </div>
                </div>
              </Col>

              <Col xs={24} sm={12}>
                <div
                  style={{
                    backgroundColor: '#FFFFFF',
                    border: '1px solid #EAECF0',
                    borderRadius: '12px',
                    padding: '24px',
                  }}
                >
                  <div style={{ fontSize: '32px', fontWeight: 700, color: '#004E54' }}>
                    {performance.completionRate || '96%'}
                  </div>
                  <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A', marginTop: '4px' }}>
                    Completion Rate
                  </div>
                  <div style={{ fontSize: '12.5px', color: '#64748B', marginTop: '4px' }}>
                    Orders completed on time
                  </div>
                </div>
              </Col>

              <Col xs={24} sm={12}>
                <div
                  style={{
                    backgroundColor: '#FFFFFF',
                    border: '1px solid #EAECF0',
                    borderRadius: '12px',
                    padding: '24px',
                  }}
                >
                  <div style={{ fontSize: '32px', fontWeight: 700, color: '#004E54' }}>
                    {performance.disputeRate || '1.2%'}
                  </div>
                  <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A', marginTop: '4px' }}>
                    Dispute Rate
                  </div>
                  <div style={{ fontSize: '12.5px', color: '#64748B', marginTop: '4px' }}>
                    Below platform avg
                  </div>
                </div>
              </Col>

              <Col xs={24} sm={12}>
                <div
                  style={{
                    backgroundColor: '#FFFFFF',
                    border: '1px solid #EAECF0',
                    borderRadius: '12px',
                    padding: '24px',
                  }}
                >
                  <div style={{ fontSize: '32px', fontWeight: 700, color: '#004E54' }}>
                    {performance.returnRate || '2.4%'}
                  </div>
                  <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A', marginTop: '4px' }}>
                    Return Rate
                  </div>
                  <div style={{ fontSize: '12.5px', color: '#64748B', marginTop: '4px' }}>
                    Below platform avg
                  </div>
                </div>
              </Col>
            </Row>
          )}

          {/* =========================================================================
              TAB: REVIEWS (SELLER)
             ========================================================================= */}
          {activeTab === 'reviews' && (
            <div>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  fontSize: '14px',
                  color: '#0F172A',
                  marginBottom: '20px',
                }}
              >
                <div style={{ display: 'flex', gap: '2px', color: '#F59E0B' }}>
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} size={15} fill="#F59E0B" />
                  ))}
                </div>
                <span style={{ fontWeight: 700 }}>{user.rating || 4.8}</span>
                <span style={{ color: '#64748B' }}>({user.totalReviews || 156} reviews)</span>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                {reviews.length > 0 ? (
                  reviews.map((rev, idx) => (
                    <div
                      key={rev.id || idx}
                      style={{
                        backgroundColor: '#FFFFFF',
                        border: '1px solid #EAECF0',
                        borderRadius: '10px',
                        padding: '16px 20px',
                      }}
                    >
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <div
                            style={{
                              width: '32px',
                              height: '32px',
                              borderRadius: '50%',
                              backgroundColor: '#004E54',
                              color: '#FFFFFF',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontWeight: 600,
                              fontSize: '12px',
                            }}
                          >
                            {getInitials(rev.reviewerName)}
                          </div>
                          <span style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>
                            {rev.reviewerName}
                          </span>
                        </div>
                        <span style={{ fontSize: '12px', color: '#94A3B8' }}>
                          {formatDate(rev.createdAt)}
                        </span>
                      </div>

                      <div style={{ display: 'flex', gap: '2px', color: '#F59E0B', marginBottom: '6px' }}>
                        {[...Array(rev.rating || 5)].map((_, i) => (
                          <Star key={i} size={13} fill="#F59E0B" />
                        ))}
                      </div>

                      <div style={{ fontSize: '13.5px', color: '#334155', lineHeight: '1.4' }}>
                        {rev.comment}
                      </div>

                      {rev.listingTitle && (
                        <div style={{ fontSize: '12px', color: '#94A3B8', marginTop: '6px' }}>
                          Item: {rev.listingTitle}
                        </div>
                      )}
                    </div>
                  ))
                ) : (
                  /* Fallback sample reviews if none yet submitted in DB */
                  [
                    {
                      name: 'Rahul Mehta',
                      date: '2024-05-20',
                      comment: 'Excellent seller, product exactly as described!',
                      item: 'iPhone 15 Pro Max',
                    },
                    {
                      name: 'Sneha Patel',
                      date: '2024-05-15',
                      comment: 'Good communication, fast shipping.',
                      item: 'MacBook Air',
                    },
                    {
                      name: 'Priya Singh',
                      date: '2024-05-10',
                      comment: 'Trusted seller, highly recommend!',
                      item: 'AirPods Pro',
                    },
                  ].map((rev, idx) => (
                    <div
                      key={idx}
                      style={{
                        backgroundColor: '#FFFFFF',
                        border: '1px solid #EAECF0',
                        borderRadius: '10px',
                        padding: '16px 20px',
                      }}
                    >
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <div
                            style={{
                              width: '32px',
                              height: '32px',
                              borderRadius: '50%',
                              backgroundColor: '#004E54',
                              color: '#FFFFFF',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontWeight: 600,
                              fontSize: '12px',
                            }}
                          >
                            {getInitials(rev.name)}
                          </div>
                          <span style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>
                            {rev.name}
                          </span>
                        </div>
                        <span style={{ fontSize: '12px', color: '#94A3B8' }}>{rev.date}</span>
                      </div>

                      <div style={{ display: 'flex', gap: '2px', color: '#F59E0B', marginBottom: '6px' }}>
                        {[...Array(5)].map((_, i) => (
                          <Star key={i} size={13} fill="#F59E0B" />
                        ))}
                      </div>

                      <div style={{ fontSize: '13.5px', color: '#334155', lineHeight: '1.4' }}>
                        {rev.comment}
                      </div>

                      <div style={{ fontSize: '12px', color: '#94A3B8', marginTop: '6px' }}>
                        Item: {rev.item}
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}

          {/* =========================================================================
              TAB: WALLET
             ========================================================================= */}
          {activeTab === 'wallet' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              {/* Dark Teal Hero Card */}
              <div
                style={{
                  backgroundColor: '#004E54',
                  borderRadius: '12px',
                  padding: '24px 28px',
                  color: '#FFFFFF',
                }}
              >
                <div style={{ fontSize: '12px', color: 'rgba(255,255,255,0.8)', marginBottom: '4px' }}>
                  Current Balance
                </div>
                <div style={{ fontSize: '32px', fontWeight: 700, letterSpacing: '-0.02em' }}>
                  {formatRupee(wallet?.balance ?? 0)}
                </div>
                <div style={{ fontSize: '13px', color: 'rgba(255,255,255,0.7)', marginTop: '4px' }}>
                  {isSeller
                    ? `Total Sales: ${formatRupee(kpis?.totalSales ?? 0)}`
                    : `Total Spent: ${formatRupee(kpis?.totalSpent ?? 0)}`}
                </div>
              </div>

              {/* Action Buttons */}
              <div style={{ display: 'flex', gap: '12px' }}>
                <Button
                  icon={<Plus size={16} />}
                  onClick={() => setCreditModalOpen(true)}
                  style={{
                    flex: 1,
                    height: '42px',
                    borderRadius: '8px',
                    borderColor: '#CBD5E1',
                    color: '#004E54',
                    fontWeight: 600,
                  }}
                >
                  + Credit Wallet
                </Button>

                <Button
                  icon={<Snowflake size={16} />}
                  onClick={handleToggleFreezeWallet}
                  style={{
                    flex: 1,
                    height: '42px',
                    borderRadius: '8px',
                    borderColor: '#FECACA',
                    color: '#EF4444',
                    fontWeight: 600,
                  }}
                >
                  ❄ Freeze Wallet
                </Button>
              </div>

              {/* Top-up History / Transactions */}
              <div>
                <h4 style={{ fontSize: '14px', fontWeight: 700, color: '#0F172A', marginBottom: '12px' }}>
                  {isSeller ? 'Top-up & Payout History' : 'Top-up History'}
                </h4>
                <div
                  style={{
                    backgroundColor: '#FFFFFF',
                    borderRadius: '10px',
                    border: '1px solid #EAECF0',
                    overflow: 'hidden',
                  }}
                >
                  <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '13px' }}>
                    <thead>
                      <tr style={{ backgroundColor: '#F8FAFC', borderBottom: '1px solid #EAECF0' }}>
                        <th style={{ padding: '12px 16px', textAlign: 'left', color: '#64748B', fontWeight: 600 }}>Date & Time</th>
                        <th style={{ padding: '12px 16px', textAlign: 'left', color: '#64748B', fontWeight: 600 }}>Type</th>
                        <th style={{ padding: '12px 16px', textAlign: 'left', color: '#64748B', fontWeight: 600 }}>Reference</th>
                        <th style={{ padding: '12px 16px', textAlign: 'left', color: '#64748B', fontWeight: 600 }}>Method</th>
                        <th style={{ padding: '12px 16px', textAlign: 'left', color: '#64748B', fontWeight: 600 }}>Amount</th>
                        <th style={{ padding: '12px 16px', textAlign: 'left', color: '#64748B', fontWeight: 600 }}>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {wallet.transactions && wallet.transactions.length > 0 ? (
                        wallet.transactions.map((tx) => (
                          <tr key={tx.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                            <td style={{ padding: '12px 16px', color: '#334155' }}>{formatDate(tx.createdAt)}</td>
                            <td style={{ padding: '12px 16px', color: '#334155' }}>{tx.type}</td>
                            <td style={{ padding: '12px 16px', color: '#64748B' }}>{tx.referenceId}</td>
                            <td style={{ padding: '12px 16px', color: '#334155' }}>UPI</td>
                            <td style={{ padding: '12px 16px', fontWeight: 700, color: '#004E54' }}>
                              {formatRupee(tx.amount)}
                            </td>
                            <td style={{ padding: '12px 16px' }}>
                              <span
                                style={{
                                  backgroundColor: '#ECFDF5',
                                  color: '#059669',
                                  padding: '2px 8px',
                                  borderRadius: '9999px',
                                  fontSize: '11px',
                                  fontWeight: 600,
                                }}
                              >
                                Completed
                              </span>
                            </td>
                          </tr>
                        ))
                      ) : (
                        <tr>
                          <td colSpan={6} style={{ padding: '24px', textAlign: 'center', color: '#94A3B8' }}>
                            No wallet transactions found.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* =========================================================================
              TAB: ACTIVITY (BUYER)
             ========================================================================= */}
          {activeTab === 'activity' && (
            <div>
              <h3 style={{ fontSize: '15px', fontWeight: 700, color: '#0F172A', marginBottom: '16px' }}>
                Auction Participations
              </h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {auctionParticipations.length > 0 ? (
                  auctionParticipations.map((b) => (
                    <div
                      key={b.id}
                      style={{
                        backgroundColor: '#FFFFFF',
                        border: '1px solid #EAECF0',
                        borderRadius: '10px',
                        padding: '16px 20px',
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                      }}
                    >
                      <div>
                        <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>
                          {b.listingTitle}
                        </div>
                        <div style={{ fontSize: '12px', color: '#64748B', marginTop: '2px' }}>
                          {formatDate(b.createdAt)}
                        </div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{ fontSize: '15px', fontWeight: 700, color: '#004E54' }}>
                          {formatRupee(b.amount)}
                        </div>
                        <span
                          style={{
                            display: 'inline-block',
                            marginTop: '4px',
                            padding: '2px 8px',
                            borderRadius: '9999px',
                            fontSize: '11px',
                            fontWeight: 600,
                            backgroundColor: b.status === 'WON' || b.status === 'WINNING' ? '#ECFDF5' : '#FEF3C7',
                            color: b.status === 'WON' || b.status === 'WINNING' ? '#059669' : '#D97706',
                          }}
                        >
                          {b.status}
                        </span>
                      </div>
                    </div>
                  ))
                ) : (
                  <div style={{ padding: '40px', textAlign: 'center', color: '#94A3B8' }}>
                    No auction bids placed yet.
                  </div>
                )}
              </div>
            </div>
          )}

          {/* =========================================================================
              TAB: COMMUNITIES
             ========================================================================= */}
          {activeTab === 'communities' && (
            <div>
              <div style={{ fontSize: '12px', fontWeight: 700, color: '#64748B', letterSpacing: '0.05em', marginBottom: '16px' }}>
                {isSeller ? 'ADMIN OF' : 'MEMBER OF'}
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {communities.length > 0 ? (
                  communities.map((c) => (
                    <div
                      key={c.id}
                      style={{
                        backgroundColor: '#F0FDF4',
                        border: '1px solid #BBF7D0',
                        borderRadius: '10px',
                        padding: '16px 20px',
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <div style={{ fontSize: '20px' }}>⚡</div>
                        <div>
                          <div style={{ fontSize: '14px', fontWeight: 700, color: '#0F172A' }}>
                            {c.name}
                          </div>
                          <div style={{ fontSize: '12px', color: '#64748B', marginTop: '2px' }}>
                            {c.membersCount} members · {c.city || 'India'}
                          </div>
                        </div>
                      </div>
                      <Button
                        type="primary"
                        style={{
                          backgroundColor: '#004E54',
                          borderColor: '#004E54',
                          borderRadius: '8px',
                          fontWeight: 500,
                        }}
                      >
                        View Community →
                      </Button>
                    </div>
                  ))
                ) : (
                  <div style={{ padding: '40px', textAlign: 'center', color: '#94A3B8' }}>
                    User has not joined any communities yet.
                  </div>
                )}
              </div>
            </div>
          )}

          {/* =========================================================================
              TAB: REPORTS (BUYER)
             ========================================================================= */}
          {activeTab === 'reports' && (
            <div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {reports.length > 0 ? (
                  reports.map((r) => (
                    <div
                      key={r.id}
                      style={{
                        backgroundColor: '#FFFFFF',
                        border: '1px solid #EAECF0',
                        borderRadius: '10px',
                        padding: '16px 20px',
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                      }}
                    >
                      <div>
                        <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>
                          {r.reason}
                        </div>
                        <div style={{ fontSize: '12px', color: '#64748B', marginTop: '2px' }}>
                          {r.details || 'Dispute filed'} · {formatDate(r.createdAt)}
                        </div>
                      </div>
                      <div style={{ display: 'flex', gap: '8px' }}>
                        <span
                          style={{
                            backgroundColor: '#FEF3C7',
                            color: '#D97706',
                            padding: '2px 8px',
                            borderRadius: '9999px',
                            fontSize: '11px',
                            fontWeight: 600,
                          }}
                        >
                          {r.severity}
                        </span>
                        <span
                          style={{
                            backgroundColor: '#ECFDF5',
                            color: '#059669',
                            padding: '2px 8px',
                            borderRadius: '9999px',
                            fontSize: '11px',
                            fontWeight: 600,
                          }}
                        >
                          {r.status}
                        </span>
                      </div>
                    </div>
                  ))
                ) : (
                  <div style={{ padding: '40px', textAlign: 'center', color: '#94A3B8' }}>
                    No reports or disputes filed against this user.
                  </div>
                )}
              </div>
            </div>
          )}

          {/* =========================================================================
              TAB: CHATS (BUYER)
             ========================================================================= */}
          {activeTab === 'chats' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {chats.length > 0 ? (
                chats.map((c) => (
                  <div
                    key={c.id}
                    style={{
                      backgroundColor: '#FFFFFF',
                      border: '1px solid #EAECF0',
                      borderRadius: '10px',
                      padding: '14px 20px',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '14px',
                    }}
                  >
                    <div
                      style={{
                        width: '38px',
                        height: '38px',
                        borderRadius: '50%',
                        backgroundColor: '#004E54',
                        color: '#FFFFFF',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontWeight: 600,
                        fontSize: '13px',
                        flexShrink: 0,
                      }}
                    >
                      {getInitials(c.name)}
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>
                        {c.name}
                      </div>
                      <div style={{ fontSize: '12px', color: '#64748B', marginTop: '2px' }}>
                        {c.lastMessage}
                      </div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontSize: '12px', color: '#94A3B8' }}>
                        {formatRelative(c.lastMessageAt)}
                      </div>
                      {c.unreadCount > 0 && (
                        <span
                          style={{
                            display: 'inline-block',
                            marginTop: '4px',
                            backgroundColor: '#0D9488',
                            color: '#FFFFFF',
                            borderRadius: '9999px',
                            padding: '2px 7px',
                            fontSize: '11px',
                            fontWeight: 700,
                          }}
                        >
                          {c.unreadCount}
                        </span>
                      )}
                    </div>
                  </div>
                ))
              ) : (
                <div style={{ padding: '40px', textAlign: 'center', color: '#94A3B8' }}>
                  No active chats found.
                </div>
              )}
            </div>
          )}

          {/* =========================================================================
              TAB: BUY
             ========================================================================= */}
          {activeTab === 'buy' && (
            <div>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  marginBottom: '16px',
                }}
              >
                <h3 style={{ fontSize: '15px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
                  Purchase History
                </h3>
                {purchases.length > 0 && (
                  <span
                    style={{
                      backgroundColor: '#EFF6FF',
                      color: '#2563EB',
                      padding: '2px 10px',
                      borderRadius: '9999px',
                      fontSize: '12px',
                      fontWeight: 600,
                    }}
                  >
                    {purchases.length} purchases
                  </span>
                )}
              </div>

              {purchases.length === 0 ? (
                <div style={{ padding: '60px', textAlign: 'center' }}>
                  <div style={{ fontSize: '36px', marginBottom: '8px' }}>🛒</div>
                  <div style={{ fontSize: '14px', fontWeight: 500, color: '#64748B' }}>
                    {isSeller
                      ? 'This seller account has no purchase history on Bidly.'
                      : 'No purchase history found.'}
                  </div>
                  {isSeller && (
                    <div style={{ fontSize: '12px', color: '#94A3B8', marginTop: '4px' }}>
                      Sellers registered as buyers will show purchase history here.
                    </div>
                  )}
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  {purchases.map((p) => (
                    <div
                      key={p.id}
                      style={{
                        backgroundColor: '#FFFFFF',
                        border: '1px solid #EAECF0',
                        borderRadius: '10px',
                        padding: '16px 20px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                        <div
                          style={{
                            width: '40px',
                            height: '40px',
                            borderRadius: '8px',
                            backgroundColor: '#F1F5F9',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontSize: '18px',
                          }}
                        >
                          🛍️
                        </div>
                        <div>
                          <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>
                            {p.listingTitle || 'Purchased Item'}
                          </div>
                          <div style={{ fontSize: '12px', color: '#64748B', marginTop: '2px' }}>
                            Bought from {p.sellerName || 'Seller'} · {formatDate(p.createdAt)} · #{p.orderNumber || p.id.substring(0, 5)}
                          </div>
                        </div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{ fontSize: '15px', fontWeight: 700, color: '#004E54' }}>
                          {formatRupee(p.amount)}
                        </div>
                        <span
                          style={{
                            display: 'inline-block',
                            marginTop: '4px',
                            padding: '2px 8px',
                            borderRadius: '9999px',
                            fontSize: '11px',
                            fontWeight: 600,
                            backgroundColor: '#ECFDF5',
                            color: '#059669',
                          }}
                        >
                          {p.status === 'DELIVERED' ? 'Delivered' : p.status}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* =========================================================================
              TAB: SELL
             ========================================================================= */}
          {activeTab === 'sell' && (
            <div>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  marginBottom: '16px',
                }}
              >
                <h3 style={{ fontSize: '15px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
                  Sales History
                </h3>
                {sales.length > 0 && (
                  <span
                    style={{
                      backgroundColor: '#ECFDF5',
                      color: '#059669',
                      padding: '2px 10px',
                      borderRadius: '9999px',
                      fontSize: '12px',
                      fontWeight: 600,
                    }}
                  >
                    {sales.length} sales
                  </span>
                )}
              </div>

              {sales.length === 0 ? (
                <div style={{ padding: '60px', textAlign: 'center' }}>
                  <div style={{ fontSize: '36px', marginBottom: '8px' }}>🤖</div>
                  <div style={{ fontSize: '13px', color: '#94A3B8' }}>
                    This user has not sold any items on Bidly.
                  </div>
                </div>
              ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  {sales.map((s) => (
                    <div
                      key={s.id}
                      style={{
                        backgroundColor: '#FFFFFF',
                        border: '1px solid #EAECF0',
                        borderRadius: '10px',
                        padding: '16px 20px',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                        <div
                          style={{
                            width: '40px',
                            height: '40px',
                            borderRadius: '8px',
                            backgroundColor: '#ECFDF5',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontSize: '18px',
                          }}
                        >
                          🛒
                        </div>
                        <div>
                          <div style={{ fontSize: '14px', fontWeight: 600, color: '#0F172A' }}>
                            {s.listingTitle || 'Sold Item'}
                          </div>
                          <div style={{ fontSize: '12px', color: '#64748B', marginTop: '2px' }}>
                            Sold to {s.buyerName || 'Buyer'} · {formatDate(s.createdAt)} · #{s.orderNumber || s.id.substring(0, 5)}
                          </div>
                        </div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{ fontSize: '15px', fontWeight: 700, color: '#004E54' }}>
                          {formatRupee(s.amount)}
                        </div>
                        <span
                          style={{
                            display: 'inline-block',
                            marginTop: '4px',
                            padding: '2px 8px',
                            borderRadius: '9999px',
                            fontSize: '11px',
                            fontWeight: 600,
                            backgroundColor: s.status === 'DELIVERED' ? '#ECFDF5' : '#EFF6FF',
                            color: s.status === 'DELIVERED' ? '#059669' : '#2563EB',
                          }}
                        >
                          {s.status === 'DELIVERED' ? 'Delivered' : s.status || 'In Transit'}
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Credit Wallet Modal */}
      <Modal
        title="Credit User Wallet"
        open={creditModalOpen}
        onCancel={() => setCreditModalOpen(false)}
        onOk={handleCreditWallet}
        confirmLoading={actionLoading}
        okText="Credit Wallet"
        okButtonProps={{ style: { backgroundColor: '#004E54', borderColor: '#004E54' } }}
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', padding: '12px 0' }}>
          <div>
            <div style={{ fontSize: '12px', color: '#64748B', marginBottom: '6px' }}>
              Amount (₹)
            </div>
            <Input
              type="number"
              placeholder="e.g. 5000"
              value={creditAmount}
              onChange={(e) => setCreditAmount(e.target.value)}
              prefix="₹"
            />
          </div>
          <div>
            <div style={{ fontSize: '12px', color: '#64748B', marginBottom: '6px' }}>
              Reason / Note
            </div>
            <Input
              placeholder="e.g. Promotional credit, resolution refund"
              value={creditNote}
              onChange={(e) => setCreditNote(e.target.value)}
            />
          </div>
        </div>
      </Modal>
    </div>
  );
};
