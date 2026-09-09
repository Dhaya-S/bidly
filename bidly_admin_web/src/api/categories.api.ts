import { apiClient } from './client';
import type { Category } from '../types';

export const categoriesApi = {
  getCategories: async (): Promise<Category[]> => {
    try {
      const res = await apiClient.get('/categories');
      const list = res.data?.data || res.data || [];
      return [{ id: 'all', name: 'All', active: true }, ...list];
    } catch (err) {
      console.error('Failed to fetch categories from database:', err);
      return [{ id: 'all', name: 'All', active: true }];
    }
  },
};
