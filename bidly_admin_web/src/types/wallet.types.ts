import type { User } from './user.types';

export type WalletTransactionType =
  | 'CREDIT'
  | 'DEBIT'
  | 'RESERVE'
  | 'RELEASE'
  | 'ESCROW_HOLD'
  | 'ESCROW_RELEASE';

export interface Wallet {
  id: string;
  userId: string;
  user?: User;
  balance: number;
  reservedBalance: number;
  availableBalance: number;
  status?: 'ACTIVE' | 'FROZEN';
  createdAt?: string;
  updatedAt?: string;
}

export interface WalletTransaction {
  id: string;
  walletId: string;
  amount: number;
  type: WalletTransactionType;
  referenceId?: string;
  referenceType?: string;
  description: string;
  status: 'COMPLETED' | 'PENDING' | 'FAILED';
  createdAt: string;
}
