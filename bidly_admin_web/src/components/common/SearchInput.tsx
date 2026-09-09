import React from 'react';
import { Input } from 'antd';
import { Search } from 'lucide-react';

interface SearchInputProps {
  placeholder?: string;
  value?: string;
  onChange?: (e: React.ChangeEvent<HTMLInputElement>) => void;
  onSearch?: (val: string) => void;
  style?: React.CSSProperties;
  allowClear?: boolean;
}

export const SearchInput: React.FC<SearchInputProps> = ({
  placeholder = 'Search...',
  value,
  onChange,
  onSearch,
  style,
  allowClear = true,
}) => {
  return (
    <Input
      prefix={<Search size={16} color="#94A3B8" style={{ marginRight: 6 }} />}
      placeholder={placeholder}
      value={value}
      onChange={onChange}
      onPressEnter={(e) => onSearch && onSearch((e.target as HTMLInputElement).value)}
      allowClear={allowClear}
      style={{
        borderRadius: 8,
        borderColor: '#E2E8F0',
        backgroundColor: '#FFFFFF',
        height: 38,
        ...style,
      }}
    />
  );
};
