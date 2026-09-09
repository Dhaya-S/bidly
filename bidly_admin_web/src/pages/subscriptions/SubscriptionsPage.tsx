import React, { useEffect, useState } from 'react';
import { Row, Col, Card, Button } from 'antd';
import { Sparkles, Check, Crown } from 'lucide-react';
import { StatCard } from '../../components/common/StatCard';
import { usersApi } from '../../api/users.api';

export const SubscriptionsPage: React.FC = () => {
  const [totalSellers, setTotalSellers] = useState<number>(0);

  useEffect(() => {
    usersApi.getUsers().then((res) => {
      const sellers = res.content.filter((u) => u.role === 'SELLER' || (u.activeListingsCount && u.activeListingsCount > 0));
      setTotalSellers(sellers.length);
    });
  }, []);

  const plans = [
    {
      name: 'Free Seller',
      price: 0,
      period: '/ month',
      features: ['Up to 5 active listings', 'Standard 3% platform fee', 'Standard search visibility'],
      activeSubscribers: totalSellers,
    },
    {
      name: 'Pro Merchant',
      price: 999,
      period: '/ month',
      popular: true,
      features: [
        'Unlimited active listings',
        'Reduced 1.5% platform fee',
        'Featured badges on auctions',
        'Storefront customization',
        'Priority live support',
      ],
      activeSubscribers: 0,
    },
    {
      name: 'Enterprise / Auctioneer',
      price: 2999,
      period: '/ month',
      features: [
        'Unlimited listings & auctions',
        '0.9% platform fee',
        'Verified Gold badge',
        'Featured carousel on homepage',
        'Dedicated account manager',
      ],
      activeSubscribers: 0,
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
          Subscription Plans
        </h1>
        <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
          Seller tier subscriptions, recurring revenues, and membership perks
        </p>
      </div>

      <Row gutter={[20, 20]} style={{ marginBottom: '28px' }}>
        <Col xs={24} sm={8}>
          <StatCard
            title="Total Active Sellers"
            value={totalSellers}
            trendText="Live from Neon DB"
            trendType="positive"
            icon={<Crown size={22} />}
            iconBgColor="#FEF3C7"
            iconColor="#D97706"
          />
        </Col>
        <Col xs={24} sm={8}>
          <StatCard
            title="Monthly Recurring Revenue (MRR)"
            value="₹0"
            trendText="Free tier active"
            trendType="positive"
            icon={<Sparkles size={22} />}
            iconBgColor="#EFF6FF"
            iconColor="#3B82F6"
          />
        </Col>
        <Col xs={24} sm={8}>
          <StatCard
            title="Paid Pro Conversion Rate"
            value="0.0%"
            trendText="Organic growth"
            trendType="positive"
            icon={<Sparkles size={22} />}
            iconBgColor="#F0FDFA"
            iconColor="#0D9488"
          />
        </Col>
      </Row>

      <Row gutter={[24, 24]}>
        {plans.map((plan, i) => (
          <Col xs={24} md={8} key={i}>
            <Card
              style={{
                borderRadius: '12px',
                border: plan.popular ? '2px solid #0D9488' : '1px solid #E2E8F0',
                position: 'relative',
                height: '100%',
              }}
            >
              {plan.popular && (
                <div
                  style={{
                    position: 'absolute',
                    top: '-12px',
                    right: '24px',
                    backgroundColor: '#0D9488',
                    color: '#FFFFFF',
                    fontSize: '11px',
                    fontWeight: 700,
                    padding: '2px 10px',
                    borderRadius: '9999px',
                    letterSpacing: '0.5px',
                  }}
                >
                  MOST POPULAR
                </div>
              )}

              <div style={{ fontSize: '18px', fontWeight: 700, color: '#0F172A', marginBottom: '8px' }}>
                {plan.name}
              </div>

              <div style={{ display: 'flex', alignItems: 'baseline', gap: '4px', marginBottom: '16px' }}>
                <span style={{ fontSize: '32px', fontWeight: 800, color: '#0F172A' }}>
                  ₹{plan.price}
                </span>
                <span style={{ fontSize: '13px', color: '#64748B' }}>{plan.period}</span>
              </div>

              <div
                style={{
                  padding: '8px 12px',
                  borderRadius: '6px',
                  backgroundColor: '#F8FAFC',
                  fontSize: '12px',
                  color: '#475569',
                  marginBottom: '20px',
                  fontWeight: 500,
                }}
              >
                {plan.activeSubscribers} active sellers on this tier
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', marginBottom: '24px' }}>
                {plan.features.map((feat, idx) => (
                  <div key={idx} style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#334155' }}>
                    <Check size={16} color="#0D9488" />
                    <span>{feat}</span>
                  </div>
                ))}
              </div>

              <Button
                type={plan.popular ? 'primary' : 'default'}
                block
                style={{
                  borderRadius: '8px',
                  height: '40px',
                  fontWeight: 600,
                  backgroundColor: plan.popular ? '#0D9488' : undefined,
                  borderColor: plan.popular ? '#0D9488' : '#CBD5E1',
                }}
              >
                Manage Tier
              </Button>
            </Card>
          </Col>
        ))}
      </Row>
    </div>
  );
};
