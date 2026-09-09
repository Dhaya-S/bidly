import React, { useEffect } from 'react';
import { BrowserRouter } from 'react-router-dom';
import { ConfigProvider } from 'antd';
import { bidlyTheme } from './styles/theme';
import { AppRoutes } from './routes';
import { useAuthStore } from './store/auth.store';
import './styles/global.css';

export const App: React.FC = () => {
  const { initialize } = useAuthStore();

  useEffect(() => {
    initialize();
  }, [initialize]);

  return (
    <ConfigProvider theme={bidlyTheme}>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </ConfigProvider>
  );
};

export default App;
