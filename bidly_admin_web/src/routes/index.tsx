import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { PrivateRoute } from './PrivateRoute';
import { AppLayout } from '../components/layout/AppLayout';

import { LoginPage } from '../pages/auth/LoginPage';
import { DashboardPage } from '../pages/dashboard/DashboardPage';
import { UserListPage } from '../pages/users/UserListPage';
import { UserDetailPage } from '../pages/users/UserDetailPage';
import { AuctionListPage } from '../pages/marketplace/AuctionListPage';
import { AuctionDetailPage } from '../pages/marketplace/AuctionDetailPage';
import { DirectBuyListPage } from '../pages/marketplace/DirectBuyListPage';
import { OrderListPage } from '../pages/orders/OrderListPage';
import { OrderDetailPage } from '../pages/orders/OrderDetailPage';
import { PaymentsPage } from '../pages/payments/PaymentsPage';
import { WalletListPage } from '../pages/wallets/WalletListPage';
import { SubscriptionsPage } from '../pages/subscriptions/SubscriptionsPage';
import { CommunityListPage } from '../pages/communities/CommunityListPage';
import { TrustSafetyPage } from '../pages/trust-safety/TrustSafetyPage';
import { ReportListPage } from '../pages/reports/ReportListPage';
import { ReviewsPage } from '../pages/reviews/ReviewsPage';
import { EngagementPage } from '../pages/engagement/EngagementPage';
import { AnalyticsPage } from '../pages/analytics/AnalyticsPage';
import { SettingsPage } from '../pages/settings/SettingsPage';

export const AppRoutes: React.FC = () => {
  return (
    <Routes>
      {/* Public Login Route */}
      <Route path="/login" element={<LoginPage />} />

      {/* Protected Admin Routes */}
      <Route element={<PrivateRoute />}>
        <Route element={<AppLayout />}>
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          <Route path="/dashboard" element={<DashboardPage />} />
          
          {/* Users */}
          <Route path="/users" element={<UserListPage />} />
          <Route path="/users/:id" element={<UserDetailPage />} />

          {/* Marketplace */}
          <Route path="/marketplace/auctions" element={<AuctionListPage />} />
          <Route path="/marketplace/auctions/:id" element={<AuctionDetailPage />} />
          <Route path="/marketplace/direct-buy" element={<DirectBuyListPage />} />

          {/* Orders */}
          <Route path="/orders" element={<OrderListPage />} />
          <Route path="/orders/:id" element={<OrderDetailPage />} />

          {/* Payments & Wallets */}
          <Route path="/payments" element={<PaymentsPage />} />
          <Route path="/wallets" element={<WalletListPage />} />

          {/* Subscriptions */}
          <Route path="/subscriptions" element={<SubscriptionsPage />} />

          {/* Communities */}
          <Route path="/communities" element={<CommunityListPage />} />

          {/* Trust & Safety */}
          <Route path="/trust-safety" element={<TrustSafetyPage />} />

          {/* Reports & Disputes */}
          <Route path="/reports" element={<ReportListPage />} />

          {/* Reviews */}
          <Route path="/reviews" element={<ReviewsPage />} />

          {/* Engagement */}
          <Route path="/engagement" element={<EngagementPage />} />

          {/* Analytics */}
          <Route path="/analytics" element={<AnalyticsPage />} />

          {/* Settings */}
          <Route path="/settings" element={<SettingsPage />} />
        </Route>
      </Route>

      {/* Fallback */}
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
};
