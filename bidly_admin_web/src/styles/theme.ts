import type { ThemeConfig } from 'antd';

export const bidlyTheme: ThemeConfig = {
  token: {
    colorPrimary: '#0D9488',
    colorPrimaryHover: '#0F766E',
    colorPrimaryActive: '#115E59',
    colorSuccess: '#10B981',
    colorWarning: '#F59E0B',
    colorError: '#EF4444',
    colorInfo: '#0EA5E9',
    colorTextBase: '#0F172A',
    colorTextSecondary: '#64748B',
    colorBgBase: '#FFFFFF',
    colorBorder: '#E2E8F0',
    borderRadius: 8,
    fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
  },
  components: {
    Button: {
      borderRadius: 8,
      controlHeight: 38,
      colorPrimary: '#0D9488',
      colorPrimaryHover: '#0F766E',
    },
    Input: {
      borderRadius: 8,
      controlHeight: 40,
    },
    Card: {
      borderRadiusLG: 12,
      headerBg: 'transparent',
    },
    Table: {
      borderRadius: 8,
      headerBg: '#F8FAFC',
      headerColor: '#64748B',
      rowHoverBg: '#F1F5F9',
    },
    Menu: {
      darkItemBg: '#1A1D21',
      darkItemSelectedBg: '#0D9488',
      darkItemColor: '#9CA3AF',
      darkItemSelectedColor: '#FFFFFF',
      darkItemHoverBg: '#262A30',
      darkItemHoverColor: '#FFFFFF',
    },
    Tabs: {
      colorPrimary: '#0D9488',
      itemActiveColor: '#0D9488',
      itemSelectedColor: '#0D9488',
      itemHoverColor: '#0F766E',
    },
    Badge: {
      colorPrimary: '#0D9488',
    },
  },
};
