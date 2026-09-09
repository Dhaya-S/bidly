import React from 'react';
import {
  ResponsiveContainer,
  AreaChart as RechartsAreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ReferenceLine,
} from 'recharts';
import { formatRupee } from '../../utils/format';

interface AreaChartProps {
  data: any[];
  dataKey: string;
  xKey: string;
  height?: number;
  color?: string;
  gradientId?: string;
  yAxisFormatter?: (val: any) => string;
  ticks?: number[];
  showGreenZeroLine?: boolean;
}

export const AreaChart: React.FC<AreaChartProps> = ({
  data,
  dataKey,
  xKey,
  height = 280,
  color = '#004E54',
  gradientId = 'areaColor',
  yAxisFormatter = (val) => {
    if (val === 0) return '₹0';
    if (val >= 100000) return `₹${(val / 1000).toFixed(0)}K`;
    if (val >= 1000) return `₹${(val / 1000).toFixed(0)}K`;
    return formatRupee(val, true);
  },
  ticks,
  showGreenZeroLine = true,
}) => {
  return (
    <div style={{ width: '100%', height }}>
      <ResponsiveContainer width="100%" height="100%">
        <RechartsAreaChart data={data} margin={{ top: 10, right: 10, left: 5, bottom: 0 }}>
          <defs>
            <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor={color} stopOpacity={0.25} />
              <stop offset="95%" stopColor={color} stopOpacity={0.01} />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="#F1F5F9" vertical={false} />
          <XAxis
            dataKey={xKey}
            stroke="#94A3B8"
            fontSize={12}
            tickLine={false}
            axisLine={{ stroke: '#E2E8F0' }}
          />
          <YAxis
            stroke="#94A3B8"
            fontSize={12}
            tickLine={false}
            axisLine={false}
            tickFormatter={yAxisFormatter}
            ticks={ticks}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: '#1E293B',
              borderRadius: '8px',
              border: 'none',
              color: '#FFFFFF',
              fontSize: '13px',
            }}
            formatter={(value: any) => [formatRupee(Number(value)), 'Revenue']}
          />
          {showGreenZeroLine && (
            <ReferenceLine y={0} stroke="#10B981" strokeDasharray="3 3" strokeWidth={1.5} />
          )}
          <Area
            type="monotone"
            dataKey={dataKey}
            stroke={color}
            strokeWidth={2.5}
            fillOpacity={1}
            fill={`url(#${gradientId})`}
          />
        </RechartsAreaChart>
      </ResponsiveContainer>
    </div>
  );
};
