import React from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Header } from './Header';

export const AppLayout: React.FC = () => {
  return (
    <div style={{ display: 'flex', minHeight: '100vh', width: '100%', backgroundColor: '#F8FAFC' }}>
      <Sidebar />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0, overflowX: 'hidden' }}>
        <Header />
        <main
          style={{
            flex: 1,
            padding: '24px 32px',
            maxWidth: '1600px',
            width: '100%',
            margin: '0 auto',
            boxSizing: 'border-box',
          }}
        >
          <Outlet />
        </main>
      </div>
    </div>
  );
};
