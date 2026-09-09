import React, { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import {
  LayoutGrid,
  Users,
  ShoppingBag,
  FileText,
  CreditCard,
  Wallet,
  Star,
  MessageSquare,
  Shield,
  Activity,
  BarChart2,
  Settings,
  ChevronUp,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Layers,
} from 'lucide-react';
import { useThemeStore } from '../../store/theme.store';
import { Tooltip } from 'antd';

interface SubItem {
  key: string;
  label: string;
  path: string;
}

interface NavItem {
  key: string;
  label: string;
  path?: string;
  icon: React.ReactNode;
  children?: SubItem[];
}

export const Sidebar: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { sidebarCollapsed, toggleSidebar } = useThemeStore();

  // Accordion state for expandable sections
  const [openSections, setOpenSections] = useState<Record<string, boolean>>({
    marketplace: true,
    'trust-safety': true,
  });

  const toggleSection = (key: string) => {
    setOpenSections((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const navItems: NavItem[] = [
    {
      key: 'dashboard',
      label: 'Dashboard',
      path: '/dashboard',
      icon: <LayoutGrid size={18} />,
    },
    {
      key: 'users',
      label: 'Users',
      path: '/users',
      icon: <Users size={18} />,
    },
    {
      key: 'marketplace',
      label: 'Marketplace',
      icon: <ShoppingBag size={18} />,
      children: [
        { key: 'auctions', label: 'Auctions', path: '/marketplace/auctions' },
        { key: 'direct-buy', label: 'Direct Buy', path: '/marketplace/direct-buy' },
      ],
    },
    {
      key: 'orders',
      label: 'Orders',
      path: '/orders',
      icon: <FileText size={18} />,
    },
    {
      key: 'payments',
      label: 'Payments',
      path: '/payments',
      icon: <CreditCard size={18} />,
    },
    {
      key: 'wallets',
      label: 'Wallet',
      path: '/wallets',
      icon: <Wallet size={18} />,
    },
    {
      key: 'subscriptions',
      label: 'Subscriptions',
      path: '/subscriptions',
      icon: <Star size={18} />,
    },
    {
      key: 'communities',
      label: 'Communities',
      path: '/communities',
      icon: <MessageSquare size={18} />,
    },
    {
      key: 'trust-safety',
      label: 'Trust & Safety',
      icon: <Shield size={18} />,
      children: [
        { key: 'reports', label: 'Reports & Disputes', path: '/reports' },
        { key: 'reviews', label: 'Reviews', path: '/reviews' },
      ],
    },
    {
      key: 'engagement',
      label: 'Engagement',
      path: '/engagement',
      icon: <Activity size={18} />,
    },
    {
      key: 'analytics',
      label: 'Analytics',
      path: '/analytics',
      icon: <BarChart2 size={18} />,
    },
    {
      key: 'settings',
      label: 'Settings',
      path: '/settings',
      icon: <Settings size={18} />,
    },
  ];

  const isCurrentActive = (itemPath?: string) => {
    if (!itemPath) return false;
    if (itemPath === '/dashboard') {
      return location.pathname === '/' || location.pathname === '/dashboard';
    }
    return location.pathname.startsWith(itemPath);
  };

  return (
    <aside
      style={{
        width: sidebarCollapsed ? '68px' : '230px',
        backgroundColor: '#FFFFFF',
        height: '100vh',
        position: 'sticky',
        top: 0,
        display: 'flex',
        flexDirection: 'column',
        transition: 'width 0.2s cubic-bezier(0.4, 0, 0.2, 1)',
        overflowX: 'hidden',
        zIndex: 200,
        userSelect: 'none',
        borderRight: '1px solid #EAECF0',
        boxSizing: 'border-box',
      }}
    >
      {/* Brand Header */}
      <div
        style={{
          height: '64px',
          display: 'flex',
          alignItems: 'center',
          padding: sidebarCollapsed ? '0 16px' : '0 18px',
          borderBottom: '1px solid #F2F4F7',
          gap: '10px',
        }}
      >
        <div
          style={{
            width: '32px',
            height: '32px',
            borderRadius: '8px',
            backgroundColor: '#004E54',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#FFFFFF',
            flexShrink: 0,
          }}
        >
          <Layers size={18} color="#FFFFFF" strokeWidth={2.2} />
        </div>
        {!sidebarCollapsed && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span
              style={{
                color: '#0F172A',
                fontWeight: 700,
                fontSize: '17px',
                letterSpacing: '-0.2px',
              }}
            >
              Bidly
            </span>
            <span
              style={{
                backgroundColor: '#E6F4F1',
                color: '#0F766E',
                fontSize: '11px',
                fontWeight: 600,
                padding: '2px 8px',
                borderRadius: '9999px',
                lineHeight: 1.3,
              }}
            >
              Admin
            </span>
          </div>
        )}
      </div>

      {/* Navigation List */}
      <div
        style={{
          flex: 1,
          overflowY: 'auto',
          overflowX: 'hidden',
          padding: '12px 10px',
          display: 'flex',
          flexDirection: 'column',
          gap: '2px',
        }}
      >
        {navItems.map((item) => {
          // If item has subitems (like Marketplace, Trust & Safety)
          if (item.children) {
            const hasActiveChild = item.children.some((c) => location.pathname.startsWith(c.path));
            const isOpen = openSections[item.key] ?? true;

            if (sidebarCollapsed) {
              return (
                <Tooltip key={item.key} placement="right" title={item.label}>
                  <div
                    onClick={() => navigate(item.children![0].path)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      padding: '9px 0',
                      borderRadius: '8px',
                      cursor: 'pointer',
                      color: hasActiveChild ? '#0F766E' : '#475569',
                      backgroundColor: hasActiveChild ? '#E6F4F1' : 'transparent',
                    }}
                  >
                    {item.icon}
                  </div>
                </Tooltip>
              );
            }

            return (
              <div key={item.key} style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
                {/* Parent Row */}
                <div
                  onClick={() => toggleSection(item.key)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '8px 12px',
                    borderRadius: '8px',
                    cursor: 'pointer',
                    color: hasActiveChild ? '#0F766E' : '#344054',
                    backgroundColor: 'transparent',
                    fontWeight: 500,
                    fontSize: '13.5px',
                    transition: 'all 0.15s ease',
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.backgroundColor = '#F8FAFC';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.backgroundColor = 'transparent';
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <span style={{ color: hasActiveChild ? '#0F766E' : '#64748B', display: 'flex' }}>
                      {item.icon}
                    </span>
                    <span>{item.label}</span>
                  </div>
                  <span style={{ color: '#94A3B8' }}>
                    {isOpen ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                  </span>
                </div>

                {/* Sub-items list */}
                {isOpen && (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '2px', paddingLeft: '8px' }}>
                    {item.children.map((sub) => {
                      const subActive = location.pathname.startsWith(sub.path);
                      return (
                        <div
                          key={sub.key}
                          onClick={() => navigate(sub.path)}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '8px',
                            padding: '7px 12px',
                            borderRadius: '8px',
                            cursor: 'pointer',
                            color: subActive ? '#0F766E' : '#475569',
                            backgroundColor: subActive ? '#E6F4F1' : 'transparent',
                            fontWeight: subActive ? 600 : 400,
                            fontSize: '13px',
                            transition: 'all 0.15s ease',
                          }}
                          onMouseEnter={(e) => {
                            if (!subActive) {
                              e.currentTarget.style.backgroundColor = '#F8FAFC';
                              e.currentTarget.style.color = '#0F172A';
                            }
                          }}
                          onMouseLeave={(e) => {
                            if (!subActive) {
                              e.currentTarget.style.backgroundColor = 'transparent';
                              e.currentTarget.style.color = '#475569';
                            }
                          }}
                        >
                          <span
                            style={{
                              width: '5px',
                              height: '5px',
                              borderRadius: '50%',
                              backgroundColor: subActive ? '#0F766E' : '#CBD5E1',
                              flexShrink: 0,
                            }}
                          />
                          <span>{sub.label}</span>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          }

          // Single item
          const active = isCurrentActive(item.path);

          const rowContent = (
            <div
              onClick={() => item.path && navigate(item.path)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                padding: sidebarCollapsed ? '9px 0' : '8px 12px',
                justifyContent: sidebarCollapsed ? 'center' : 'flex-start',
                borderRadius: '8px',
                cursor: 'pointer',
                color: active ? '#0F766E' : '#344054',
                backgroundColor: active ? '#E6F4F1' : 'transparent',
                fontWeight: active ? 600 : 500,
                fontSize: '13.5px',
                transition: 'all 0.15s ease',
              }}
              onMouseEnter={(e) => {
                if (!active) {
                  e.currentTarget.style.backgroundColor = '#F8FAFC';
                  e.currentTarget.style.color = '#0F172A';
                }
              }}
              onMouseLeave={(e) => {
                if (!active) {
                  e.currentTarget.style.backgroundColor = 'transparent';
                  e.currentTarget.style.color = '#344054';
                }
              }}
            >
              <span
                style={{
                  color: active ? '#0F766E' : '#64748B',
                  display: 'flex',
                }}
              >
                {item.icon}
              </span>
              {!sidebarCollapsed && <span>{item.label}</span>}
            </div>
          );

          if (sidebarCollapsed) {
            return (
              <Tooltip key={item.key} placement="right" title={item.label}>
                {rowContent}
              </Tooltip>
            );
          }

          return <React.Fragment key={item.key}>{rowContent}</React.Fragment>;
        })}
      </div>

      {/* Collapse Toggle Footer */}
      <div
        onClick={toggleSidebar}
        style={{
          padding: '12px 16px',
          borderTop: '1px solid #F2F4F7',
          display: 'flex',
          alignItems: 'center',
          justifyContent: sidebarCollapsed ? 'center' : 'flex-start',
          gap: '8px',
          color: '#64748B',
          cursor: 'pointer',
          fontSize: '13px',
          fontWeight: 500,
          transition: 'all 0.15s ease',
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.backgroundColor = '#F8FAFC';
          e.currentTarget.style.color = '#0F172A';
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.backgroundColor = 'transparent';
          e.currentTarget.style.color = '#64748B';
        }}
      >
        {sidebarCollapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
        {!sidebarCollapsed && <span>Collapse</span>}
      </div>
    </aside>
  );
};
