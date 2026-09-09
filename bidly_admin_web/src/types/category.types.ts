export interface Category {
  id: string;
  name: string;
  iconUrl?: string;
  sortOrder?: number;
  parentId?: string;
  parent?: Category;
  children?: Category[];
  active: boolean;
  itemCount?: number;
  createdAt?: string;
  updatedAt?: string;
}
