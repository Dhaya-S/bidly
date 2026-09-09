import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8081/api';
export const R2_PUBLIC_URL = import.meta.env.VITE_R2_PUBLIC_URL || 'https://pub-52fd31cc3989491200f4bc5b53f9e17b.r2.dev';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 45000,
});

// Request interceptor to attach JWT token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('bidly_admin_token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor to handle 401 Unauthorized
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      localStorage.removeItem('bidly_admin_token');
      localStorage.removeItem('bidly_admin_user');
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// Media URL generator
export const getMediaUrl = (objectKey?: string | null): string => {
  if (!objectKey) return '';
  if (objectKey.startsWith('http://') || objectKey.startsWith('https://')) {
    return objectKey;
  }
  return `${API_BASE_URL}/media/file/${objectKey}`;
};
