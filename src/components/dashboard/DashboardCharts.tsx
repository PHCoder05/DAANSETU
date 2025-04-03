'use client';

import React from 'react';
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  TooltipProps
} from 'recharts';
import { DonationType } from '@/lib/firestore';

// Color palette for charts
const COLORS = {
  primary: '#3B82F6',
  secondary: '#6366F1',
  success: '#10B981',
  warning: '#F59E0B',
  danger: '#EF4444',
  info: '#06B6D4',
  categories: {
    food: '#F97316',
    clothing: '#8B5CF6',
    medicine: '#EC4899',
    books: '#14B8A6',
    furniture: '#6366F1',
    electronics: '#F43F5E',
    toys: '#84CC16',
    other: '#A1A1AA'
  },
  status: {
    available: '#10B981',
    claimed: '#3B82F6',
    delivered: '#8B5CF6',
    cancelled: '#A1A1AA'
  }
};

// Custom tooltip component
const CustomTooltip = ({ active, payload, label }: TooltipProps<any, any>) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-white dark:bg-zinc-800 p-2 border border-gray-200 dark:border-gray-700 rounded shadow-sm">
        <p className="text-xs text-gray-500 dark:text-gray-400">{label}</p>
        {payload.map((entry, index) => (
          <p key={`item-${index}`} className="text-sm font-medium" style={{ color: entry.color }}>
            {entry.name}: {entry.value}
          </p>
        ))}
      </div>
    );
  }

  return null;
};

// Data interfaces
export interface DonationTimeData {
  date: string;
  donations: number;
  value?: number;
}

export interface DonationCategoryData {
  name: string;
  value: number;
  category: DonationType;
}

export interface DonationStatusData {
  name: string;
  value: number;
}

// Donation Bar Chart Component
interface DonationBarChartProps {
  data: DonationTimeData[];
  title?: string;
  height?: number;
  showLegend?: boolean;
}

export const DonationBarChart: React.FC<DonationBarChartProps> = ({
  data,
  title = 'Donations Over Time',
  height = 300,
  showLegend = false
}) => {
  return (
    <div className="w-full">
      {title && <h4 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">{title}</h4>}
      <div style={{ width: '100%', height }}>
        <ResponsiveContainer>
          <BarChart
            data={data}
            margin={{ top: 5, right: 20, left: 5, bottom: 5 }}
          >
            <CartesianGrid strokeDasharray="3 3" strokeOpacity={0.2} />
            <XAxis 
              dataKey="date" 
              tick={{ fontSize: 12 }} 
              tickLine={false}
              axisLine={{ strokeOpacity: 0.2 }}
            />
            <YAxis 
              tick={{ fontSize: 12 }} 
              tickLine={false}
              axisLine={{ strokeOpacity: 0.2 }}
            />
            <Tooltip content={<CustomTooltip />} />
            {showLegend && <Legend />}
            <Bar 
              dataKey="donations" 
              name="Donations" 
              fill={COLORS.primary} 
              radius={[4, 4, 0, 0]}
              animationDuration={1500}
            />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

// Donation Line Chart Component
interface DonationLineChartProps {
  data: DonationTimeData[];
  title?: string;
  height?: number;
  showLegend?: boolean;
}

export const DonationLineChart: React.FC<DonationLineChartProps> = ({
  data,
  title = 'Donation Trends',
  height = 300,
  showLegend = false
}) => {
  return (
    <div className="w-full">
      {title && <h4 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">{title}</h4>}
      <div style={{ width: '100%', height }}>
        <ResponsiveContainer>
          <LineChart
            data={data}
            margin={{ top: 5, right: 20, left: 5, bottom: 5 }}
          >
            <CartesianGrid strokeDasharray="3 3" strokeOpacity={0.2} />
            <XAxis 
              dataKey="date" 
              tick={{ fontSize: 12 }} 
              tickLine={false}
              axisLine={{ strokeOpacity: 0.2 }}
            />
            <YAxis 
              tick={{ fontSize: 12 }} 
              tickLine={false}
              axisLine={{ strokeOpacity: 0.2 }}
            />
            <Tooltip content={<CustomTooltip />} />
            {showLegend && <Legend />}
            <Line 
              type="monotone" 
              dataKey="donations" 
              name="Donations" 
              stroke={COLORS.primary} 
              strokeWidth={2}
              dot={{ r: 3 }}
              activeDot={{ r: 5 }}
              animationDuration={1500}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

// Donation Pie Chart Component
interface DonationPieChartProps {
  data: DonationCategoryData[];
  title?: string;
  height?: number;
  showLegend?: boolean;
}

export const DonationPieChart: React.FC<DonationPieChartProps> = ({
  data,
  title = 'Donations by Category',
  height = 300,
  showLegend = true
}) => {
  return (
    <div className="w-full">
      {title && <h4 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">{title}</h4>}
      <div style={{ width: '100%', height }}>
        <ResponsiveContainer>
          <PieChart>
            <Pie
              data={data}
              cx="50%"
              cy="50%"
              labelLine={false}
              outerRadius={80}
              fill={COLORS.primary}
              dataKey="value"
              nameKey="name"
              label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
              animationDuration={1500}
            >
              {data.map((entry, index) => (
                <Cell 
                  key={`cell-${index}`} 
                  fill={COLORS.categories[entry.category] || COLORS.categories.other} 
                />
              ))}
            </Pie>
            <Tooltip content={<CustomTooltip />} />
            {showLegend && <Legend />}
          </PieChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

// Donation Status Chart Component
interface DonationStatusChartProps {
  data: DonationStatusData[];
  title?: string;
  height?: number;
  showLegend?: boolean;
}

export const DonationStatusChart: React.FC<DonationStatusChartProps> = ({
  data,
  title = 'Donations by Status',
  height = 300,
  showLegend = true
}) => {
  return (
    <div className="w-full">
      {title && <h4 className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">{title}</h4>}
      <div style={{ width: '100%', height }}>
        <ResponsiveContainer>
          <PieChart>
            <Pie
              data={data}
              cx="50%"
              cy="50%"
              labelLine={false}
              outerRadius={80}
              fill={COLORS.primary}
              dataKey="value"
              nameKey="name"
              label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
              animationDuration={1500}
            >
              {data.map((entry, index) => {
                const statusKey = entry.name.toLowerCase() as keyof typeof COLORS.status;
                return (
                  <Cell 
                    key={`cell-${index}`} 
                    fill={COLORS.status[statusKey] || COLORS.info} 
                  />
                );
              })}
            </Pie>
            <Tooltip content={<CustomTooltip />} />
            {showLegend && <Legend />}
          </PieChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

// Generate dummy data for testing
export function generateDummyTimeData(): DonationTimeData[] {
  const data: DonationTimeData[] = [];
  const now = new Date();
  
  for (let i = 13; i >= 0; i--) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    const formattedDate = `${date.getDate()}/${date.getMonth() + 1}`;
    
    data.push({
      date: formattedDate,
      donations: Math.floor(Math.random() * 10) + 1
    });
  }
  
  return data;
}

export function generateDummyCategoryData(): DonationCategoryData[] {
  return [
    { name: 'Food', value: 8, category: 'food' },
    { name: 'Clothing', value: 12, category: 'clothing' },
    { name: 'Medicine', value: 5, category: 'medicine' },
    { name: 'Books', value: 7, category: 'books' },
    { name: 'Furniture', value: 3, category: 'furniture' },
    { name: 'Electronics', value: 4, category: 'electronics' },
    { name: 'Toys', value: 6, category: 'toys' },
    { name: 'Other', value: 2, category: 'other' }
  ];
}

export function generateDummyStatusData(): DonationStatusData[] {
  return [
    { name: 'Available', value: 15 },
    { name: 'Claimed', value: 8 },
    { name: 'Delivered', value: 10 },
    { name: 'Cancelled', value: 3 }
  ];
} 