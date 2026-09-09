import React, { useEffect, useState } from 'react';
import { Row, Col, Card, Select, Button, message } from 'antd';
import { Download, TrendingUp, BarChart3, Users, DollarSign } from 'lucide-react';
import { AreaChart } from '../../components/charts/AreaChart';
import { BarChart } from '../../components/charts/BarChart';
import { LineChart } from '../../components/charts/LineChart';
import { analyticsApi } from '../../api/analytics.api';
import type { RevenueDataPoint, AuctionActivityDataPoint, UserGrowthStats } from '../../types';

export const AnalyticsPage: React.FC = () => {
  const [range, setRange] = useState('30d');
  const [revenue, setRevenue] = useState<RevenueDataPoint[]>([]);
  const [auctions, setAuctions] = useState<AuctionActivityDataPoint[]>([]);
  const [growth, setGrowth] = useState<UserGrowthStats | null>(null);

  useEffect(() => {
    Promise.all([
      analyticsApi.getRevenueOverview(),
      analyticsApi.getAuctionActivity(),
      analyticsApi.getUserGrowthStats(),
    ]).then(([r, a, g]) => {
      setRevenue(r);
      setAuctions(a);
      setGrowth(g);
    });
  }, [range]);

  return (
    <div>
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
            Marketplace Analytics
          </h1>
          <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
            Historical transaction metrics, liquidity indices, and user conversion funnels
          </p>
        </div>

        <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
          <Select
            value={range}
            onChange={setRange}
            style={{ width: 140 }}
            options={[
              { value: '7d', label: 'Last 7 Days' },
              { value: '30d', label: 'Last 30 Days' },
              { value: '90d', label: 'Last 90 Days' },
              { value: '1y', label: 'Last 1 Year' },
            ]}
          />
          <Button
            icon={<Download size={15} />}
            onClick={() => message.success('Analytics report exported as CSV')}
            style={{ borderRadius: '8px' }}
          >
            Export Report
          </Button>
        </div>
      </div>

      <Row gutter={[20, 20]} style={{ marginBottom: '24px' }}>
        <Col xs={24} lg={12}>
          <Card
            title={<span style={{ fontSize: '15px', fontWeight: 600 }}>Platform GMV Trend</span>}
            bodyStyle={{ padding: '20px 16px 12px' }}
            style={{ borderRadius: '12px', border: '1px solid #E2E8F0' }}
          >
            <AreaChart data={revenue} dataKey="revenue" xKey="month" height={260} />
          </Card>
        </Col>

        <Col xs={24} lg={12}>
          <Card
            title={<span style={{ fontSize: '15px', fontWeight: 600 }}>Completed Auction Volume</span>}
            bodyStyle={{ padding: '20px 16px 12px' }}
            style={{ borderRadius: '12px', border: '1px solid #E2E8F0' }}
          >
            <BarChart data={auctions} dataKey="count" xKey="month" height={260} />
          </Card>
        </Col>
      </Row>

      <Card
        title={<span style={{ fontSize: '15px', fontWeight: 600 }}>Cohort User Acquisition Funnel</span>}
        bodyStyle={{ padding: '24px' }}
        style={{ borderRadius: '12px', border: '1px solid #E2E8F0' }}
      >
        <LineChart
          data={growth?.monthlyData || []}
          xKey="month"
          height={260}
          series={[
            { key: 'buyers', name: 'New Buyers', color: '#0D9488' },
            { key: 'sellers', name: 'New Sellers', color: '#10B981' },
          ]}
        />
      </Card>
    </div>
  );
};
