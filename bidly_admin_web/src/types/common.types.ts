export interface ApiResponse<T = any> {
  success?: boolean;
  message?: string;
  data?: T;
  error?: string;
}

export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
  first: boolean;
  last: boolean;
}

export interface PaginationParams {
  page?: number;
  size?: number;
  sort?: string;
  search?: string;
}
