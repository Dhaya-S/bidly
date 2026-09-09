import React, { useState } from 'react';
import { Row, Col, Card, Input, Button, Select, message } from 'antd';
import { Megaphone, Send, Bell } from 'lucide-react';

export const EngagementPage: React.FC = () => {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [audience, setAudience] = useState('ALL');

  const handleSend = () => {
    if (!title || !body) {
      message.error('Please enter notification title and message');
      return;
    }
    message.success(`Broadcast successfully sent to ${audience} users!`);
    setTitle('');
    setBody('');
  };

  return (
    <div>
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#0F172A', margin: 0 }}>
          User Engagement & Campaigns
        </h1>
        <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
          Broadcast push notifications, announcements, and promotional updates
        </p>
      </div>

      <Row gutter={[24, 24]}>
        <Col xs={24} md={14}>
          <Card
            title={
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Megaphone size={18} color="#0D9488" />
                <span style={{ fontSize: '15px', fontWeight: 600 }}>Create New Push Broadcast</span>
              </div>
            }
            style={{ borderRadius: '12px', border: '1px solid #E2E8F0' }}
          >
            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '6px' }}>
                Target Audience
              </label>
              <Select
                value={audience}
                onChange={setAudience}
                style={{ width: '100%' }}
                options={[
                  { value: 'ALL', label: 'All Registered Users' },
                  { value: 'BUYERS', label: 'Buyers Segment' },
                  { value: 'SELLERS', label: 'Sellers & Creators' },
                  { value: 'COMMUNITIES', label: 'All Community Members' },
                ]}
              />
            </div>

            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '6px' }}>
                Notification Title
              </label>
              <Input
                placeholder="e.g. Flash Auction Ending Tonight!"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
              />
            </div>

            <div style={{ marginBottom: '24px' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, marginBottom: '6px' }}>
                Message Body
              </label>
              <Input.TextArea
                rows={4}
                placeholder="Type push message text..."
                value={body}
                onChange={(e) => setBody(e.target.value)}
              />
            </div>

            <Button
              type="primary"
              icon={<Send size={15} />}
              onClick={handleSend}
              style={{ backgroundColor: '#0D9488', borderRadius: '8px', fontWeight: 600 }}
            >
              Dispatch Broadcast
            </Button>
          </Card>
        </Col>

        <Col xs={24} md={10}>
          <Card
            title={<span style={{ fontSize: '15px', fontWeight: 600 }}>Recent Dispatches</span>}
            style={{ borderRadius: '12px', border: '1px solid #E2E8F0' }}
          >
            <div style={{ padding: '12px 0', borderBottom: '1px solid #F1F5F9' }}>
              <div style={{ fontWeight: 600, fontSize: '13px', color: '#0F172A' }}>
                Weekend Tech Bazaar is Live!
              </div>
              <div style={{ fontSize: '12px', color: '#64748B' }}>Sent to All Users · 2 days ago</div>
            </div>
            <div style={{ padding: '12px 0' }}>
              <div style={{ fontWeight: 600, fontSize: '13px', color: '#0F172A' }}>
                Escrow Guarantee Notice
              </div>
              <div style={{ fontSize: '12px', color: '#64748B' }}>Sent to Buyers · 5 days ago</div>
            </div>
          </Card>
        </Col>
      </Row>
    </div>
  );
};
