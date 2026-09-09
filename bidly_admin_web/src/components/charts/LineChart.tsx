import React from 'react';
import {
  ResponsiveContainer,
  LineChart as RechartsLineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from 'recharts';

export interface LineSeries {
  key: string;
  name: string;
  color: string;
}

interface LineChartProps {
  data: any[];
  xKey: string;
  series: LineSeries[];
  height?: number;
  ticks?: number[];
  yAxisFormatter?: (val: any) => string;
}

export const LineChart: React.FC<LineChartProps> = ({
  data,
  xKey,
  series,
  height = 260,
  ticks,
  yAxisFormatter = (val) => {
    if (val === 0) return '0';
    if (val >= 1000) return `${(val / 1000).toFixed(1)}K`;
    return `${val}`;
  },
}) => {
  return (
    <div style={{ width: '100%', height }}>
      <ResponsiveContainer width="100%" height="100%">
        <RechartsLineChart data={data} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
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
            ticks={ticks}
            tickFormatter={yAxisFormatter}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: '#1E293B',
              borderRadius: '8px',
              border: 'none',
              color: '#FFFFFF',
              fontSize: '13px',
            }}
          />
          {series.map((s) => (
            <Line
              key={s.key}
              type="monotone"
              dataKey={s.key}
              name={s.name}
              stroke={s.color}
              strokeWidth={2.5}
              dot={{ r: 4, fill: s.color, stroke: s.color, strokeWidth: 1 }}
              activeDot={{ r: 6, fill: s.color }}
            />
          ))}
        </RechartsLineChart>
      </ResponsiveContainer>
    </div>
  );
};
