import React from 'react';
import {
  ResponsiveContainer,
  BarChart as RechartsBarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from 'recharts';

interface BarSeries {
  dataKey: string;
  color: string;
  name: string;
}

interface BarChartProps {
  data: any[];
  dataKey?: string;
  xKey: string;
  height?: number;
  barColor?: string;
  barName?: string;
  series?: BarSeries[];
  ticks?: number[];
}

export const BarChart: React.FC<BarChartProps> = ({
  data,
  dataKey = 'count',
  xKey,
  height = 280,
  barColor = '#004E54',
  barName = 'Auctions',
  series,
  ticks,
}) => {
  return (
    <div style={{ width: '100%', height }}>
      <ResponsiveContainer width="100%" height="100%">
        <RechartsBarChart data={data} margin={{ top: 10, right: 10, left: -10, bottom: 0 }} barGap={4}>
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
          {series && series.length > 0 ? (
            series.map((s) => (
              <Bar
                key={s.dataKey}
                dataKey={s.dataKey}
                name={s.name}
                fill={s.color}
                radius={[4, 4, 0, 0]}
                maxBarSize={14}
              />
            ))
          ) : (
            <Bar
              dataKey={dataKey}
              name={barName}
              fill={barColor}
              radius={[4, 4, 0, 0]}
              maxBarSize={18}
            />
          )}
        </RechartsBarChart>
      </ResponsiveContainer>
    </div>
  );
};
