'use client';

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/Button';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { useAuth } from '@/context/AuthContext';
import { 
  subscribeToNGOClaims, 
  subscribeToNGORequests, 
  DonationStatus, 
  Donation,
  DonationRequest,
  updateDonation,
  deleteDonationRequest
} from '@/lib/firestore';
import { toast } from '@/components/ui/Toast';
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';
import CreateRequestForm from '../requests/CreateRequestForm';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { 
  Calendar, 
  FileCheck, 
  FileSearch, 
  TrendingUp, 
  PlusCircle, 
  AlertCircle,
  Users, 
  Truck, 
  Package, 
  Check, 
  MessagesSquare,
  Clock,
  Loader2
} from 'lucide-react';
import { 
  DonationBarChart, 
  DonationPieChart, 
  DonationTimeData,
  DonationCategoryData,
  generateDummyTimeData,
  generateDummyCategoryData
} from './DashboardCharts';

export default function NGODashboard() {
  const { userProfile } = useAuth();
  const [claims, setClaims] = useState<Donation[]>([]);
  const [requests, setRequests] = useState<DonationRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [claimsError, setClaimsError] = useState<string | null>(null);
  const [requestsError, setRequestsError] = useState<string | null>(null);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [stats, setStats] = useState({
    totalClaims: 0,
    pendingClaims: 0,
    completedDeliveries: 0,
    activeRequests: 0,
    totalRequests: 0,
    peopleBenefited: 0
  });
  
  // Chart data states
  const [requestsTimeData, setRequestsTimeData] = useState<DonationTimeData[]>([]);
  const [claimsTimeData, setClaimsTimeData] = useState<DonationTimeData[]>([]);
  const [categoriesData, setCategoriesData] = useState<DonationCategoryData[]>([]);

  // Subscribe to NGO's claimed donations
  useEffect(() => {
    if (!userProfile) return;

    // Set a timeout to prevent infinite loading
    const loadingTimeout = setTimeout(() => {
      if (loading) {
        setLoading(false);
        setClaimsError("Loading timed out. Please refresh the page to try again.");
      }
    }, 15000);

    try {
      const unsubscribe = subscribeToNGOClaims(userProfile.uid, (donationsData) => {
        setClaims(donationsData);
        
        // Calculate statistics
        const pendingCount = donationsData.filter(d => d.status === 'claimed').length;
        const completedCount = donationsData.filter(d => d.status === 'delivered').length;
        
      setStats(prev => ({
        ...prev,
          totalClaims: donationsData.length,
          pendingClaims: pendingCount,
          completedDeliveries: completedCount,
          peopleBenefited: completedCount * 10 // Estimate: each delivery helps ~10 people
        }));
        
        // Prepare time data for claims chart
        prepareClaimsChartData(donationsData);
        
        setLoading(false);
        clearTimeout(loadingTimeout);
      });

      return () => {
        unsubscribe();
        clearTimeout(loadingTimeout);
      };
    } catch (error) {
      console.error('Error subscribing to claimed donations:', error);
      setClaimsError("Failed to load claimed donations. Please refresh to try again.");
      setLoading(false);
      clearTimeout(loadingTimeout);
    }
  }, [userProfile]);

  // Subscribe to NGO's donation requests
  useEffect(() => {
      if (!userProfile) return;

      try {
      const unsubscribe = subscribeToNGORequests(userProfile.uid, (requestsData) => {
        setRequests(requestsData);
        
        // Calculate statistics for requests
        const activeCount = requestsData.filter(r => r.status === 'active').length;
        
        setStats(prev => ({
          ...prev,
          activeRequests: activeCount,
          totalRequests: requestsData.length
        }));
        
        // Prepare request chart data
        prepareRequestsChartData(requestsData);
        
        // Prepare category data from both claims and requests
        prepareCategoryData(claims, requestsData);
      });

      return () => unsubscribe();
      } catch (error) {
      console.error('Error subscribing to requests:', error);
      setRequestsError("Failed to load donation requests. Please refresh to try again.");
    }
  }, [userProfile, claims]);
  
  // Prepare chart data from claims
  const prepareClaimsChartData = (claimsData: Donation[]) => {
    // In real app, aggregate by date from actual donation data
    setClaimsTimeData(generateDummyTimeData());
  };
  
  // Prepare chart data from requests
  const prepareRequestsChartData = (requestsData: DonationRequest[]) => {
    // In real app, aggregate by date from actual request data
    setRequestsTimeData(generateDummyTimeData());
  };
  
  // Prepare category data from claims and requests
  const prepareCategoryData = (claimsData: Donation[], requestsData: DonationRequest[]) => {
    // Get categories from both claims and requests
    const categoryMap = new Map<string, { claimed: number; requested: number }>();
    
    // Count claims by category
    claimsData.forEach(claim => {
      const current = categoryMap.get(claim.category) || { claimed: 0, requested: 0 };
      categoryMap.set(claim.category, { ...current, claimed: current.claimed + 1 });
    });
    
    // Count requests by category
    requestsData.forEach(request => {
      const current = categoryMap.get(request.category) || { claimed: 0, requested: 0 };
      categoryMap.set(request.category, { ...current, requested: current.requested + 1 });
    });
    
    const categories: DonationCategoryData[] = Array.from(categoryMap.entries())
      .map(([category, counts]) => ({
        name: category.charAt(0).toUpperCase() + category.slice(1),
        value: counts.claimed + counts.requested,
        category: category as any
      }));
    
    setCategoriesData(categories.length > 0 ? categories : generateDummyCategoryData());
  };

  const handleMarkAsDelivered = async (donationId: string) => {
    try {
      await updateDonation(donationId, { status: 'delivered' });
      toast.success('Donation marked as delivered');
    } catch (error) {
      console.error('Error updating donation status:', error);
      toast.error('Failed to update donation status');
    }
  };
  
  const handleDeleteRequest = async (requestId: string) => {
    try {
      await deleteDonationRequest(requestId);
      toast.success('Request deleted successfully');
    } catch (error) {
      console.error('Error deleting request:', error);
      toast.error('Failed to delete request');
    }
  };

  // Animation variants
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1
      }
    }
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: {
        duration: 0.4
      }
    }
  };

  const cardVariants = {
    hidden: { opacity: 0, scale: 0.95 },
    visible: {
      opacity: 1,
      scale: 1,
      transition: {
        duration: 0.5
      }
    }
  };

  // Display loading state
  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
        <p className="ml-4 text-gray-600 dark:text-gray-300">Loading your dashboard...</p>
      </div>
    );
  }

  // Display error state
  if (claimsError) {
    return (
      <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-6 text-center">
        <AlertCircle className="h-12 w-12 text-red-500 dark:text-red-400 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-red-800 dark:text-red-300 mb-2">Error Loading Dashboard</h3>
        <p className="text-red-600 dark:text-red-400 mb-4">{claimsError}</p>
        <Button onClick={() => window.location.reload()}>
          Refresh Page
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Stats Section */}
      <motion.div 
        className="grid grid-cols-1 gap-4 sm:grid-cols-3 lg:grid-cols-6"
        variants={containerVariants}
        initial="hidden"
        animate="visible"
      >
        <motion.div 
          className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
          variants={itemVariants}
        >
          <div className="flex items-center">
            <div className="p-3 rounded-full bg-blue-50 dark:bg-blue-900/30">
              <Package className="h-6 w-6 text-blue-500 dark:text-blue-400" />
            </div>
            <div className="ml-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">Total Claims</div>
              <div className="mt-1 text-3xl font-bold text-gray-900 dark:text-white">{stats.totalClaims}</div>
            </div>
          </div>
        </motion.div>
        
        <motion.div 
          className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
          variants={itemVariants}
        >
          <div className="flex items-center">
            <div className="p-3 rounded-full bg-amber-50 dark:bg-amber-900/30">
              <Clock className="h-6 w-6 text-amber-500 dark:text-amber-400" />
            </div>
            <div className="ml-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">Pending</div>
              <div className="mt-1 text-3xl font-bold text-gray-900 dark:text-white">{stats.pendingClaims}</div>
            </div>
          </div>
        </motion.div>
        
        <motion.div 
          className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
          variants={itemVariants}
        >
          <div className="flex items-center">
            <div className="p-3 rounded-full bg-green-50 dark:bg-green-900/30">
              <Truck className="h-6 w-6 text-green-500 dark:text-green-400" />
            </div>
            <div className="ml-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">Delivered</div>
              <div className="mt-1 text-3xl font-bold text-gray-900 dark:text-white">{stats.completedDeliveries}</div>
            </div>
          </div>
        </motion.div>
        
        <motion.div 
          className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
          variants={itemVariants}
        >
          <div className="flex items-center">
            <div className="p-3 rounded-full bg-purple-50 dark:bg-purple-900/30">
              <FileSearch className="h-6 w-6 text-purple-500 dark:text-purple-400" />
            </div>
            <div className="ml-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">Open Requests</div>
              <div className="mt-1 text-3xl font-bold text-gray-900 dark:text-white">{stats.activeRequests}</div>
            </div>
          </div>
        </motion.div>
        
        <motion.div 
          className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
          variants={itemVariants}
        >
          <div className="flex items-center">
            <div className="p-3 rounded-full bg-indigo-50 dark:bg-indigo-900/30">
              <FileCheck className="h-6 w-6 text-indigo-500 dark:text-indigo-400" />
            </div>
            <div className="ml-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">Total Requests</div>
              <div className="mt-1 text-3xl font-bold text-gray-900 dark:text-white">{stats.totalRequests}</div>
            </div>
        </div>
        </motion.div>
        
        <motion.div 
          className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
          variants={itemVariants}
        >
          <div className="flex items-center">
            <div className="p-3 rounded-full bg-rose-50 dark:bg-rose-900/30">
              <Users className="h-6 w-6 text-rose-500 dark:text-rose-400" />
        </div>
            <div className="ml-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">People Helped</div>
              <div className="mt-1 text-3xl font-bold text-gray-900 dark:text-white">{stats.peopleBenefited}+</div>
        </div>
      </div>
        </motion.div>
      </motion.div>
      
      {/* Quick Actions */}
      <motion.div 
        className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
        variants={cardVariants}
        initial="hidden"
        animate="visible"
      >
        <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <Card className="border border-blue-100 dark:border-blue-900/30 hover:shadow-md transition-shadow duration-300">
            <CardContent className="p-4">
              <button 
                onClick={() => setIsCreateModalOpen(true)}
                className="w-full flex flex-col items-center text-center py-4"
              >
                <div className="p-3 rounded-full bg-blue-50 dark:bg-blue-900/30 mb-3">
                  <PlusCircle className="h-6 w-6 text-blue-500 dark:text-blue-400" />
                </div>
                <h4 className="font-medium text-gray-900 dark:text-white">Create Request</h4>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Request supplies you need</p>
              </button>
            </CardContent>
          </Card>
          
          <Card className="border border-green-100 dark:border-green-900/30 hover:shadow-md transition-shadow duration-300">
            <CardContent className="p-4">
              <Link href="/donations/browse" className="w-full flex flex-col items-center text-center py-4">
                <div className="p-3 rounded-full bg-green-50 dark:bg-green-900/30 mb-3">
                  <FileSearch className="h-6 w-6 text-green-500 dark:text-green-400" />
                </div>
                <h4 className="font-medium text-gray-900 dark:text-white">Browse Donations</h4>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">View available donations</p>
          </Link>
            </CardContent>
          </Card>
          
          <Card className="border border-purple-100 dark:border-purple-900/30 hover:shadow-md transition-shadow duration-300">
            <CardContent className="p-4">
              <Link href="/requests" className="w-full flex flex-col items-center text-center py-4">
                <div className="p-3 rounded-full bg-purple-50 dark:bg-purple-900/30 mb-3">
                  <Calendar className="h-6 w-6 text-purple-500 dark:text-purple-400" />
                </div>
                <h4 className="font-medium text-gray-900 dark:text-white">My Requests</h4>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Manage your requests</p>
          </Link>
            </CardContent>
          </Card>
          
          <Card className="border border-amber-100 dark:border-amber-900/30 hover:shadow-md transition-shadow duration-300">
            <CardContent className="p-4">
              <Link href="/messages" className="w-full flex flex-col items-center text-center py-4">
                <div className="p-3 rounded-full bg-amber-50 dark:bg-amber-900/30 mb-3">
                  <MessagesSquare className="h-6 w-6 text-amber-500 dark:text-amber-400" />
                </div>
                <h4 className="font-medium text-gray-900 dark:text-white">Messages</h4>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Contact donors</p>
          </Link>
            </CardContent>
          </Card>
        </div>
      </motion.div>
      
      {/* Activity Charts */}
      <motion.div 
        className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
        variants={cardVariants}
        initial="hidden"
        animate="visible"
      >
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-medium text-gray-900 dark:text-white">Activity Overview</h3>
          <div className="flex items-center text-sm text-gray-500 dark:text-gray-400">
            <TrendingUp className="h-4 w-4 mr-1" />
            <span>Last 14 days</span>
          </div>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-4">
          <div>
            <DonationBarChart 
              data={claimsTimeData} 
              title="Claims Activity" 
              height={250}
            />
          </div>
          <div>
            <DonationBarChart 
              data={requestsTimeData} 
              title="Requests Activity" 
              height={250} 
            />
          </div>
        </div>
        
        <div>
          <DonationPieChart 
            data={categoriesData} 
            title="Categories Distribution" 
            height={250} 
          />
      </div>
      </motion.div>
      
      {/* Claimed Donations */}
      <motion.div 
        className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
        variants={cardVariants}
        initial="hidden"
        animate="visible"
      >
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-medium text-gray-900 dark:text-white">Claimed Donations</h3>
          <Link href="/claims" className="text-primary text-sm hover:underline">
            View All
          </Link>
        </div>
        
        {claims.length === 0 ? (
          <div className="text-center py-8 text-gray-500 dark:text-gray-400">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-12 h-12 mx-auto mb-4 text-gray-400">
              <path strokeLinecap="round" strokeLinejoin="round" d="M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5m8.25 3v6.75m0 0l-3-3m3 3l3-3M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
            </svg>
            <p>You haven't claimed any donations yet.</p>
            <Link href="/donations/browse">
              <Button className="mt-4">
                Browse Available Donations
              </Button>
            </Link>
          </div>
        ) : (
          <motion.div 
            className="overflow-hidden"
            variants={containerVariants}
            initial="hidden"
            animate="visible"
          >
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                <thead className="bg-gray-50 dark:bg-zinc-700">
                  <tr>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                      Item
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                      Donor
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                      Status
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                      Claimed Date
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white dark:bg-zinc-800 divide-y divide-gray-200 dark:divide-gray-700">
                  {claims.slice(0, 5).map((claim) => (
                    <motion.tr key={claim.id} variants={itemVariants} className="hover:bg-gray-50 dark:hover:bg-zinc-700/50 transition-colors">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">
                        {claim.title}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">
                        {claim.donorName || 'Anonymous Donor'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full 
                          ${claim.status === 'claimed' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300' : 
                            claim.status === 'delivered' ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300' :
                            'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300'}`}
                        >
                          {claim.status.charAt(0).toUpperCase() + claim.status.slice(1)}
                      </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">
                        {claim.claimedAt ? new Date(claim.claimedAt.seconds * 1000).toLocaleDateString() : 'N/A'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <Link href={`/donations/${claim.id}`} className="text-primary hover:text-primary-dark mr-4">
                          View
                        </Link>
                        {claim.status === 'claimed' && (
                          <button 
                            onClick={() => handleMarkAsDelivered(claim.id)}
                            className="text-green-600 hover:text-green-900 dark:hover:text-green-400"
                          >
                            Mark Delivered
                          </button>
                        )}
                      </td>
                    </motion.tr>
                  ))}
                </tbody>
              </table>
                </div>
          </motion.div>
        )}
      </motion.div>
      
      {/* My Requests */}
      <motion.div 
        className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
        variants={cardVariants}
        initial="hidden"
        animate="visible"
      >
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-medium text-gray-900 dark:text-white">My Requests</h3>
          <Link href="/requests" className="text-primary text-sm hover:underline">
            View All
          </Link>
        </div>
        
        {requestsError ? (
          <div className="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4 text-amber-800 dark:text-amber-300 text-sm mb-4">
            <div className="flex">
              <AlertCircle className="h-5 w-5 mr-2 flex-shrink-0" />
              <span>{requestsError}</span>
            </div>
          </div>
        ) : requests.length === 0 ? (
          <div className="text-center py-8 text-gray-500 dark:text-gray-400">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-12 h-12 mx-auto mb-4 text-gray-400">
              <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 17.25v3.375c0 .621-.504 1.125-1.125 1.125h-9.75a1.125 1.125 0 01-1.125-1.125V7.875c0-.621.504-1.125 1.125-1.125H6.75a9.06 9.06 0 011.5.124m7.5 10.376h3.375c.621 0 1.125-.504 1.125-1.125V11.25c0-4.46-3.243-8.161-7.5-8.876a9.06 9.06 0 00-1.5-.124H9.375c-.621 0-1.125.504-1.125 1.125v3.5m7.5 10.375H9.375a1.125 1.125 0 01-1.125-1.125v-9.25m12 6.625v-1.875a3.375 3.375 0 00-3.375-3.375h-1.5a1.125 1.125 0 01-1.125-1.125v-1.5a3.375 3.375 0 00-3.375-3.375H9.75" />
            </svg>
            <p>You haven't created any requests yet.</p>
            <Button onClick={() => setIsCreateModalOpen(true)} className="mt-4">
              Create Your First Request
              </Button>
          </div>
        ) : (
          <motion.div 
            className="space-y-4"
            variants={containerVariants}
            initial="hidden"
            animate="visible"
          >
            {requests.slice(0, 3).map((request) => (
              <motion.div 
                key={request.id}
                className="border border-gray-200 dark:border-gray-700 rounded-lg p-4 hover:shadow-md transition-shadow"
                variants={itemVariants}
              >
                <div className="flex flex-col sm:flex-row sm:justify-between">
                  <div>
                    <h4 className="font-medium text-gray-900 dark:text-white">{request.title}</h4>
                    <div className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                      <span className="inline-flex items-center">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4 mr-1">
                          <path fillRule="evenodd" d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z" clipRule="evenodd" />
                        </svg>
                        {request.category}
                      </span>
                      <span className="mx-2">•</span>
                      <span className="inline-flex items-center">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4 mr-1">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm.75-13a.75.75 0 00-1.5 0v5c0 .414.336.75.75.75h4a.75.75 0 000-1.5h-3.25V5z" clipRule="evenodd" />
                        </svg>
                        {request.createdAt ? new Date(request.createdAt.seconds * 1000).toLocaleDateString() : 'N/A'}
                      </span>
                      <span className="inline-flex items-center ml-2 bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300 text-xs px-2 py-0.5 rounded">
                        {request.urgency} priority
                      </span>
                    </div>
                    <p className="mt-2 text-sm text-gray-600 dark:text-gray-300">
                      {request.description.length > 100 
                        ? `${request.description.substring(0, 100)}...` 
                        : request.description}
                    </p>
                  </div>
                  <div className="mt-4 sm:mt-0 sm:ml-4 flex flex-col items-end justify-between">
                    <div className="text-sm font-medium text-gray-900 dark:text-white">
                      Needed: {request.quantity} items
                    </div>
                    <div className="flex space-x-2 mt-2 sm:mt-4">
                      <Link href={`/requests/${request.id}`}>
                        <Button size="sm" variant="outline">
                          View
                        </Button>
                      </Link>
                      <Button 
                        size="sm" 
                        variant="outline"
                        className="text-red-600 hover:text-red-500 border-red-200 hover:border-red-300 dark:border-red-800 dark:hover:border-red-700"
                        onClick={() => handleDeleteRequest(request.id)}
                      >
                        Delete
                      </Button>
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}
            {requests.length > 3 && (
              <div className="text-center mt-4">
                <Link href="/requests">
                  <Button variant="outline">View All Requests</Button>
                </Link>
              </div>
            )}
          </motion.div>
        )}
      </motion.div>
      
      {/* Create Request Modal */}
      <Dialog
        open={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
        className="fixed inset-0 z-50 overflow-y-auto"
      >
        <div className="flex min-h-screen items-center justify-center p-4">
          <div className="fixed inset-0 bg-black/30" />
          
          <DialogPanel className="relative bg-white dark:bg-zinc-800 rounded-lg p-6 w-full max-w-3xl mx-auto">
            <DialogTitle className="text-lg font-medium text-gray-900 dark:text-white mb-4">
              Create New Donation Request
            </DialogTitle>
              
              <CreateRequestForm 
              onSuccess={() => {
                setIsCreateModalOpen(false);
                toast.success('Request created successfully');
              }} 
              onCancel={() => setIsCreateModalOpen(false)} 
            />
          </DialogPanel>
        </div>
      </Dialog>
    </div>
  );
} 