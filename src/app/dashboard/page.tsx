'use client';

import React, { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import Navbar from '@/components/ui/Navbar';
import DonorDashboard from '@/components/dashboard/DonorDashboard';
import NGODashboard from '@/components/dashboard/NGODashboard';
import AdminDashboard from '@/components/dashboard/AdminDashboard';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import RouteGuard from '@/components/auth/RouteGuard';
import { toast } from '@/components/ui/Toast';

export default function DashboardPage() {
  const { userProfile } = useAuth();
  const [dashboardType, setDashboardType] = useState<'donor' | 'ngo' | 'admin' | null>(null);

  useEffect(() => {
    if (userProfile) {
      setDashboardType(userProfile.role);
    }
  }, [userProfile]);

  const renderDashboard = () => {
    switch (dashboardType) {
      case 'donor':
        return <DonorDashboard />;
      case 'ngo':
        return <NGODashboard />;
      case 'admin':
        return <AdminDashboard />;
      default:
        // This should never happen because of RouteGuard, but just in case
        return (
          <Card>
            <CardHeader>
              <CardTitle>Dashboard Error</CardTitle>
            </CardHeader>
            <CardContent>
              <p>There was an error loading your dashboard. Please try refreshing the page.</p>
            </CardContent>
          </Card>
        );
    }
  };

  return (
    <RouteGuard requiredAuth={true}>
      <Navbar />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">
          {dashboardType === 'donor' && 'Donor Dashboard'}
          {dashboardType === 'ngo' && 'NGO Dashboard'}
          {dashboardType === 'admin' && 'Admin Dashboard'}
        </h1>
        {renderDashboard()}
      </div>
    </RouteGuard>
  );
} 