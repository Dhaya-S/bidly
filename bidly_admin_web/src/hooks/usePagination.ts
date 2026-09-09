import { useState } from 'react';

export const usePagination = (initialSize: number = 10) => {
  const [page, setPage] = useState<number>(0);
  const [size, setSize] = useState<number>(initialSize);

  const onPageChange = (newPage: number, newSize?: number) => {
    // Ant Design pagination is 1-indexed, spring boot is 0-indexed
    setPage(newPage - 1);
    if (newSize && newSize !== size) {
      setSize(newSize);
      setPage(0);
    }
  };

  return {
    page,
    size,
    antdCurrent: page + 1,
    setPage,
    setSize,
    onPageChange,
  };
};
