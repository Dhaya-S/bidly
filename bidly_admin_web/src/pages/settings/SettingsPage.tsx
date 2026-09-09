import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Form, InputNumber, Switch, Button, message, Tabs } from 'antd';
import { settingsApi } from '../../api/settings.api';
import type { PlatformSettings } from '../../types';

export const SettingsPage: React.FC = () => {
  const [settings, setSettings] = useState<PlatformSettings | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    settingsApi.getSettings().then((s) => {
      setSettings(s);
      setLoading(false);
    });
  }, []);

  const handleSave = (values: any) => {
    settingsApi.updateSettings(values);
    message.success('Platform settings successfully saved and applied live');
  };

  if (!settings) return null;

  return (
    <div>
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
          System Settings & Control
        </h1>
        <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
          Platform take-rate, feature flags, media upload thresholds, and governance
        </p>
      </div>

      <Row gutter={[24, 24]}>
        <Col xs={24} md={14}>
          <Card
            title={<span style={{ fontSize: '15px', fontWeight: 600 }}>Marketplace & Financial Parameters</span>}
            style={{ borderRadius: '12px', border: '1px solid #E2E8F0' }}
          >
            <Form
              layout="vertical"
              initialValues={{
                platformFeePercentage: settings.platformFeePercentage,
                defaultRadiusKm: settings.defaultRadiusKm,
                minAuctionDurationHours: settings.minAuctionDurationHours,
                maxVideoDurationSeconds: settings.maxVideoDurationSeconds,
              }}
              onFinish={handleSave}
            >
              <Form.Item
                label="Standard Platform Fee (%)"
                name="platformFeePercentage"
                tooltip="Charged on completed auctions and direct sales at escrow settlement"
              >
                <InputNumber min={0} max={25} step={0.5} style={{ width: '100%' }} />
              </Form.Item>

              <Form.Item
                label="Default Hyperlocal Search Radius (KM)"
                name="defaultRadiusKm"
              >
                <InputNumber min={1} max={100} style={{ width: '100%' }} />
              </Form.Item>

              <Form.Item
                label="Minimum Auction Duration (Hours)"
                name="minAuctionDurationHours"
              >
                <InputNumber min={1} max={72} style={{ width: '100%' }} />
              </Form.Item>

              <Form.Item
                label="Maximum Video Reel Duration (Seconds)"
                name="maxVideoDurationSeconds"
              >
                <InputNumber min={10} max={180} style={{ width: '100%' }} />
              </Form.Item>

              <Button
                type="primary"
                htmlType="submit"
                style={{ backgroundColor: '#0D9488', borderRadius: '8px', fontWeight: 600 }}
              >
                Save Changes
              </Button>
            </Form>
          </Card>
        </Col>

        <Col xs={24} md={10}>
          <Card
            title={<span style={{ fontSize: '15px', fontWeight: 600 }}>Feature Flags & Toggles</span>}
            style={{ borderRadius: '12px', border: '1px solid #E2E8F0' }}
          >
            <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ fontWeight: 600, fontSize: '14px', color: '#0F172A' }}>
                    Live Auctions
                  </div>
                  <div style={{ fontSize: '12px', color: '#64748B' }}>
                    Allow users to start real-time bidding rooms
                  </div>
                </div>
                <Switch defaultChecked={settings.featureFlags.auctionsLive} />
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ fontWeight: 600, fontSize: '14px', color: '#0F172A' }}>
                    Hyperlocal Community Posts
                  </div>
                  <div style={{ fontSize: '12px', color: '#64748B' }}>
                    Allow member discussions in neighborhoods
                  </div>
                </div>
                <Switch defaultChecked={settings.featureFlags.communityPosts} />
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ fontWeight: 600, fontSize: '14px', color: '#0F172A' }}>
                    Buyer-Seller Direct Chat
                  </div>
                  <div style={{ fontSize: '12px', color: '#64748B' }}>
                    In-app messaging and offer negotiation
                  </div>
                </div>
                <Switch defaultChecked={settings.featureFlags.directChat} />
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ fontWeight: 600, fontSize: '14px', color: '#0F172A' }}>
                    Development Mock Wallet
                  </div>
                  <div style={{ fontSize: '12px', color: '#64748B' }}>
                    Bypass real payment gateway in test environment
                  </div>
                </div>
                <Switch defaultChecked={settings.devWalletEnabled} />
              </div>
            </div>
          </Card>
        </Col>
      </Row>
    </div>
  );
};
