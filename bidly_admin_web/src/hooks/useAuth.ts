import { useAuthStore } from '../store/auth.store';

export const useAuth = () => {
  const { user, token, isAuthenticated, isLoading, login, logout, initialize } = useAuthStore();
  return {
    user,
    token,
    isAuthenticated,
    isLoading,
    login,
    logout,
    initialize,
  };
};
