import React from 'react';
import { Badge, Dropdown, Avatar } from 'antd';
import type { MenuProps } from 'antd';
import { Bell, Search, LogOut, User as UserIcon, Shield } from 'lucide-react';
import { useAuthStore } from '../../store/auth.store';
import { useNavigate } from 'react-router-dom';

export const Header: React.FC = () => {
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const userMenuItems: MenuProps['items'] = [
    {
      key: 'user-info',
      label: (
        <div style={{ padding: '4px 0' }}>
          <div style={{ fontWeight: 600, color: '#0F172A' }}>{user?.name || 'Aryan Sharma'}</div>
          <div style={{ fontSize: '12px', color: '#64748B' }}>{user?.email || 'admin@bidly.com'}</div>
        </div>
      ),
      disabled: true,
    },
    { type: 'divider' },
    {
      key: 'settings',
      icon: <Shield size={16} />,
      label: 'Admin Settings',
      onClick: () => navigate('/settings'),
    },
    {
      key: 'logout',
      icon: <LogOut size={16} color="#EF4444" />,
      danger: true,
      label: 'Sign Out',
      onClick: handleLogout,
    },
  ];

  const notificationMenuItems: MenuProps['items'] = [
    {
      key: 'header',
      label: <span style={{ fontWeight: 600 }}>Notifications (3 New)</span>,
      disabled: true,
    },
    { type: 'divider' },
    {
      key: 'notif-1',
      label: (
        <div style={{ maxWidth: 280, padding: '4px 0' }} onClick={() => navigate('/reports')}>
          <div style={{ fontWeight: 600, color: '#EF4444', fontSize: '13px' }}>Critical Dispute Filed</div>
          <div style={{ fontSize: '12px', color: '#64748B' }}>Buyer Priya Singh filed an urgent dispute on Order ORD-2024-9841</div>
          <div style={{ fontSize: '10px', color: '#94A3B8', marginTop: '2px' }}>15 mins ago</div>
        </div>
      ),
    },
    {
      key: 'notif-2',
      label: (
        <div style={{ maxWidth: 280, padding: '4px 0' }} onClick={() => navigate('/marketplace/auctions')}>
          <div style={{ fontWeight: 600, color: '#F59E0B', fontSize: '13px' }}>Auction Ending Soon</div>
          <div style={{ fontSize: '12px', color: '#64748B' }}>Vintage Gibson Les Paul 1959 is ending in 18 minutes</div>
          <div style={{ fontSize: '10px', color: '#94A3B8', marginTop: '2px' }}>25 mins ago</div>
        </div>
      ),
    },
    {
      key: 'notif-3',
      label: (
        <div style={{ maxWidth: 280, padding: '4px 0' }} onClick={() => navigate('/orders')}>
          <div style={{ fontWeight: 600, color: '#0D9488', fontSize: '13px' }}>Order Confirmed</div>
          <div style={{ fontSize: '12px', color: '#64748B' }}>Order ORD-2024-9843 for ₹1,60,000 in escrow</div>
          <div style={{ fontSize: '10px', color: '#94A3B8', marginTop: '2px' }}>2 hours ago</div>
        </div>
      ),
    },
  ];

  return (
    <header
      style={{
        height: '64px',
        backgroundColor: '#FFFFFF',
        borderBottom: '1px solid #E2E8F0',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '0 24px',
        position: 'sticky',
        top: 0,
        zIndex: 100,
      }}
    >
      {/* Search bar */}
      <div style={{ display: 'flex', alignItems: 'center', flex: '0 1 420px' }}>
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            backgroundColor: '#F8FAFC',
            border: '1px solid #E2E8F0',
            borderRadius: '8px',
            padding: '7px 14px',
            width: '100%',
          }}
        >
          <Search size={16} color="#94A3B8" style={{ marginRight: 10, flexShrink: 0 }} />
          <input
            type="text"
            placeholder="Search users, auctions, orders..."
            style={{
              border: 'none',
              outline: 'none',
              backgroundColor: 'transparent',
              fontSize: '13px',
              color: '#0F172A',
              width: '100%',
            }}
          />
        </div>
      </div>

      {/* Right section: Notifications & User profile */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
        <Dropdown menu={{ items: notificationMenuItems }} trigger={['click']} placement="bottomRight">
          <div
            style={{
              width: 38,
              height: 38,
              borderRadius: '8px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
              border: '1px solid #E2E8F0',
              backgroundColor: '#FFFFFF',
              transition: 'background-color 0.2s',
            }}
          >
            <Badge count={3} size="small" offset={[2, -2]}>
              <Bell size={18} color="#475569" />
            </Badge>
          </div>
        </Dropdown>

        <Dropdown menu={{ items: userMenuItems }} trigger={['click']} placement="bottomRight">
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              cursor: 'pointer',
              padding: '4px 8px',
              borderRadius: '8px',
            }}
          >
            <Avatar
              style={{
                backgroundColor: '#0D9488',
                color: '#FFFFFF',
                fontWeight: 600,
                fontSize: '14px',
              }}
              size={36}
            >
              {user?.name ? user.name.slice(0, 2).toUpperCase() : 'AS'}
            </Avatar>
            <div style={{ display: 'flex', flexDirection: 'column', textAlign: 'left' }}>
              <span style={{ fontSize: '13px', fontWeight: 600, color: '#0F172A', lineHeight: 1.2 }}>
                {user?.name || 'Aryan Sharma'}
              </span>
              <span style={{ fontSize: '11px', color: '#0D9488', fontWeight: 500 }}>
                Super Admin
              </span>
            </div>
          </div>
        </Dropdown>
      </div>
    </header>
  );
};
