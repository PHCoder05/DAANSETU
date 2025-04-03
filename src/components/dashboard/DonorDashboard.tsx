'use client';

import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/Button';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { useAuth } from '@/context/AuthContext';
import { 
  Donation, 
  subscribeToUserDonations, 
  deleteDonation, 
  updateDonation,
  DonationStatus,
  getNearbyRequests,
  DonationRequest,
  DonationType
} from '@/lib/firestore';
import { toast } from '@/components/ui/Toast';
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';
import CreateDonationForm from '../donations/CreateDonationForm';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { 
  PlusCircle, 
  Search, 
  LineChart, 
  FileSearch, 
  Gift, 
  Check, 
  Clock, 
  Award, 
  Calendar,
  BookOpen,
  Map,
  MessageSquare,
  AlertCircle,
  TrendingUp
} from 'lucide-react';
import { 
  DonationBarChart, 
  DonationPieChart, 
  DonationStatusChart,
  DonationCategoryData,
  DonationStatusData,
  DonationTimeData,
  generateDummyTimeData,
  generateDummyCategoryData,
  generateDummyStatusData
} from './DashboardCharts';

export default function DonorDashboard() {
  const { userProfile } = useAuth();
  const [donations, setDonations] = useState<Donation[]>([]);
  const [nearbyRequests, setNearbyRequests] = useState<DonationRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [requestsLoading, setRequestsLoading] = useState(true);
  const [donationsError, setDonationsError] = useState<string | null>(null);
  const [requestsError, setRequestsError] = useState<string | null>(null);
  const [stats, setStats] = useState({
    total: 0,
    active: 0,
    completed: 0,
    impact: 0
  });
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  
  // Chart data states
  const [timeData, setTimeData] = useState<DonationTimeData[]>([]);
  const [categoryData, setCategoryData] = useState<DonationCategoryData[]>([]);
  const [statusData, setStatusData] = useState<DonationStatusData[]>([]);

  // Subscribe to user donations with error handling
  useEffect(() => {
    if (!userProfile) return;

    // Set a timeout to prevent infinite loading
    const loadingTimeout = setTimeout(() => {
      if (loading) {
        setLoading(false);
        setDonationsError("Loading timed out. Please refresh the page to try again.");
      }
    }, 15000);

    try {
      const unsubscribe = subscribeToUserDonations(userProfile.uid, (donationData) => {
        setDonations(donationData);
        
        // Calculate statistics
        const activeCount = donationData.filter(d => ['available', 'claimed'].includes(d.status)).length;
        const completedCount = donationData.filter(d => d.status === 'delivered').length;
        
        setStats({
          total: donationData.length,
          active: activeCount,
          completed: completedCount,
          impact: completedCount * 5 // Approximate impact (each donation helps ~5 people)
        });
        
        // Prepare data for charts
        prepareChartData(donationData);
        
        setLoading(false);
        clearTimeout(loadingTimeout);
      });

      return () => {
        unsubscribe();
        clearTimeout(loadingTimeout);
      };
    } catch (error) {
      console.error('Error subscribing to donations:', error);
      setDonationsError("Failed to load donations. Please refresh the page to try again.");
      setLoading(false);
      clearTimeout(loadingTimeout);
    }
  }, [userProfile]);

  // Prepare chart data from donations
  const prepareChartData = (donationData: Donation[]) => {
    // Generate time-based data
    // In a real app, this would aggregate the actual donations by date
    setTimeData(generateDummyTimeData());
    
    // Create category data from actual donations
    const categoryMap = new Map<DonationType, number>();
    donationData.forEach(donation => {
      const current = categoryMap.get(donation.category) || 0;
      categoryMap.set(donation.category, current + 1);
    });
    
    const categoryChartData: DonationCategoryData[] = Array.from(categoryMap.entries())
      .map(([category, count]) => ({
        name: category.charAt(0).toUpperCase() + category.slice(1),
        value: count,
        category
      }));
    
    setCategoryData(categoryChartData.length > 0 ? categoryChartData : generateDummyCategoryData());
    
    // Create status data from actual donations
    const statusCounts = donationData.reduce((acc, donation) => {
      acc[donation.status] = (acc[donation.status] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);
    
    const statusChartData: DonationStatusData[] = [
      { name: 'Available', value: statusCounts['available'] || 0 },
      { name: 'Claimed', value: statusCounts['claimed'] || 0 },
      { name: 'Delivered', value: statusCounts['delivered'] || 0 },
      { name: 'Cancelled', value: statusCounts['cancelled'] || 0 }
    ];
    
    setStatusData(statusChartData.some(d => d.value > 0) ? statusChartData : generateDummyStatusData());
  };

  // Fetch nearby requests from NGOs with error handling
  useEffect(() => {
    async function fetchNearbyRequests() {
      if (!userProfile) return;

      try {
        // Default to a central location if user's location is not available
        const defaultLat = 28.6139; // Default coordinates
        const defaultLng = 77.2090;
        
        const requests = await getNearbyRequests(defaultLat, defaultLng, 50);
        setNearbyRequests(requests);
        setRequestsError(null);
      } catch (error) {
        console.error('Error fetching nearby requests:', error);
        setRequestsError("Failed to load NGO requests. Please refresh to try again.");
      } finally {
        setRequestsLoading(false);
      }
    }

    fetchNearbyRequests();
  }, [userProfile]);

  const handleCancelDonation = async (donationId: string) => {
    try {
      await updateDonation(donationId, { status: 'cancelled' });
      toast.success('Donation cancelled successfully');
    } catch (error) {
      console.error('Error canceling donation:', error);
      toast.error('Failed to cancel donation. Please try again.');
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
        <p className="ml-4 text-gray-600 dark:text-gray-300">Loading your donations...</p>
      </div>
    );
  }

  // Display error state
  if (donationsError) {
    return (
      <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-6 text-center">
        <AlertCircle className="h-12 w-12 text-red-500 dark:text-red-400 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-red-800 dark:text-red-300 mb-2">Error Loading Dashboard</h3>
        <p className="text-red-600 dark:text-red-400 mb-4">{donationsError}</p>
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
        className="grid grid-cols-1 gap-4 sm:grid-cols-4"
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
              <Gift className="h-6 w-6 text-blue-500 dark:text-blue-400" />
            </div>
            <div className="ml-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">Total Donations</div>
              <div className="mt-1 text-3xl font-bold text-gray-900 dark:text-white">{stats.total}</div>
            </div>
          </div>
        </motion.div>
        
        <motion.div 
          className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
          variants={itemVariants}
        >
          <div className="flex items-center">
            <div className="p-3 rounded-full bg-green-50 dark:bg-green-900/30">
              <Clock className="h-6 w-6 text-green-500 dark:text-green-400" />
            </div>
            <div className="ml-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">Active Donations</div>
              <div className="mt-1 text-3xl font-bold text-gray-900 dark:text-white">{stats.active}</div>
            </div>
          </div>
        </motion.div>
        
        <motion.div 
          className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
          variants={itemVariants}
        >
          <div className="flex items-center">
            <div className="p-3 rounded-full bg-purple-50 dark:bg-purple-900/30">
              <Check className="h-6 w-6 text-purple-500 dark:text-purple-400" />
            </div>
            <div className="ml-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">Completed</div>
              <div className="mt-1 text-3xl font-bold text-gray-900 dark:text-white">{stats.completed}</div>
            </div>
          </div>
        </motion.div>
        
        <motion.div 
          className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
          variants={itemVariants}
        >
          <div className="flex items-center">
            <div className="p-3 rounded-full bg-amber-50 dark:bg-amber-900/30">
              <Award className="h-6 w-6 text-amber-500 dark:text-amber-400" />
            </div>
            <div className="ml-4">
              <div className="text-sm text-gray-500 dark:text-gray-400">Lives Impacted</div>
              <div className="mt-1 text-3xl font-bold text-gray-900 dark:text-white">{stats.impact}+</div>
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
                <h4 className="font-medium text-gray-900 dark:text-white">Create Donation</h4>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Share items you no longer need</p>
              </button>
            </CardContent>
          </Card>
          
          <Card className="border border-green-100 dark:border-green-900/30 hover:shadow-md transition-shadow duration-300">
            <CardContent className="p-4">
              <Link href="/requests/browse" className="w-full flex flex-col items-center text-center py-4">
                <div className="p-3 rounded-full bg-green-50 dark:bg-green-900/30 mb-3">
                  <FileSearch className="h-6 w-6 text-green-500 dark:text-green-400" />
                </div>
                <h4 className="font-medium text-gray-900 dark:text-white">Browse Requests</h4>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">See what NGOs are looking for</p>
              </Link>
            </CardContent>
          </Card>
          
          <Card className="border border-purple-100 dark:border-purple-900/30 hover:shadow-md transition-shadow duration-300">
            <CardContent className="p-4">
              <Link href="/donations" className="w-full flex flex-col items-center text-center py-4">
                <div className="p-3 rounded-full bg-purple-50 dark:bg-purple-900/30 mb-3">
                  <BookOpen className="h-6 w-6 text-purple-500 dark:text-purple-400" />
                </div>
                <h4 className="font-medium text-gray-900 dark:text-white">My Donations</h4>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Track all your donations</p>
              </Link>
            </CardContent>
          </Card>
          
          <Card className="border border-amber-100 dark:border-amber-900/30 hover:shadow-md transition-shadow duration-300">
            <CardContent className="p-4">
              <Link href="/profile" className="w-full flex flex-col items-center text-center py-4">
                <div className="p-3 rounded-full bg-amber-50 dark:bg-amber-900/30 mb-3">
                  <Map className="h-6 w-6 text-amber-500 dark:text-amber-400" />
                </div>
                <h4 className="font-medium text-gray-900 dark:text-white">Donation Map</h4>
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">View donations on map</p>
              </Link>
            </CardContent>
          </Card>
        </div>
      </motion.div>
      
      {/* Donation Analytics */}
      {donations.length > 0 && (
        <motion.div 
          className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
          variants={cardVariants}
          initial="hidden"
          animate="visible"
        >
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-medium text-gray-900 dark:text-white">Donation Analytics</h3>
            <div className="flex items-center text-sm text-gray-500 dark:text-gray-400">
              <TrendingUp className="h-4 w-4 mr-1" />
              <span>Last 14 days</span>
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-4">
            <div>
              <DonationBarChart 
                data={timeData} 
                title="Donation Activity" 
                height={250}
              />
            </div>
            <div>
              <DonationStatusChart 
                data={statusData} 
                title="Donation Status" 
                height={250} 
              />
            </div>
          </div>
          
          <div>
            <DonationPieChart 
              data={categoryData} 
              title="Donations by Category" 
              height={250} 
            />
          </div>
        </motion.div>
      )}
      
      {/* Recent Donations */}
      <motion.div 
        className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
        variants={cardVariants}
        initial="hidden"
        animate="visible"
      >
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-medium text-gray-900 dark:text-white">Recent Donations</h3>
          <Link href="/donations" className="text-primary text-sm hover:underline">
            View All
          </Link>
        </div>
        
        {donations.length === 0 ? (
          <div className="text-center py-8 text-gray-500 dark:text-gray-400">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-12 h-12 mx-auto mb-4 text-gray-400">
              <path strokeLinecap="round" strokeLinejoin="round" d="M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5m8.25 3v6.75m0 0l-3-3m3 3l3-3M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
            </svg>
            <p>You haven't created any donations yet.</p>
            <Button onClick={() => setIsCreateModalOpen(true)} className="mt-4">
              Create Your First Donation
            </Button>
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
                      Category
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                      Quantity
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                      Status
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white dark:bg-zinc-800 divide-y divide-gray-200 dark:divide-gray-700">
                  {donations.slice(0, 5).map((donation) => (
                    <motion.tr key={donation.id} variants={itemVariants} className="hover:bg-gray-50 dark:hover:bg-zinc-700/50 transition-colors">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">
                        {donation.title}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300 capitalize">
                        {donation.category}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">
                        {donation.quantity} items
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full 
                          ${donation.status === 'available' ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300' : 
                            donation.status === 'claimed' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300' : 
                            donation.status === 'delivered' ? 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300' :
                            'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300'}`}
                        >
                          {donation.status.charAt(0).toUpperCase() + donation.status.slice(1).replace('_', ' ')}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <Link href={`/donations/${donation.id}`} className="text-primary hover:text-primary-dark mr-4">
                          View
                        </Link>
                        {donation.status === 'available' && (
                          <button 
                            onClick={() => handleCancelDonation(donation.id)}
                            className="text-red-600 hover:text-red-900 dark:hover:text-red-400"
                          >
                            Cancel
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
      
      {/* NGO Requests Near You */}
      <motion.div 
        className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6"
        variants={cardVariants}
        initial="hidden"
        animate="visible"
      >
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-medium text-gray-900 dark:text-white">NGO Requests Near You</h3>
          <Link href="/requests/browse" className="text-primary text-sm hover:underline">
            View All
          </Link>
        </div>
        
        {requestsLoading ? (
          <div className="flex justify-center items-center h-40">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
          </div>
        ) : requestsError ? (
          <div className="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-4 text-amber-800 dark:text-amber-300 text-sm mb-4">
            <div className="flex">
              <AlertCircle className="h-5 w-5 mr-2 flex-shrink-0" />
              <span>{requestsError}</span>
            </div>
          </div>
        ) : nearbyRequests.length === 0 ? (
          <div className="text-center py-8 text-gray-500 dark:text-gray-400">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-12 h-12 mx-auto mb-4 text-gray-400">
              <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 17.25v3.375c0 .621-.504 1.125-1.125 1.125h-9.75a1.125 1.125 0 01-1.125-1.125V7.875c0-.621.504-1.125 1.125-1.125H6.75a9.06 9.06 0 011.5.124m7.5 10.376h3.375c.621 0 1.125-.504 1.125-1.125V11.25c0-4.46-3.243-8.161-7.5-8.876a9.06 9.06 0 00-1.5-.124H9.375c-.621 0-1.125.504-1.125 1.125v3.5m7.5 10.375H9.375a1.125 1.125 0 01-1.125-1.125v-9.25m12 6.625v-1.875a3.375 3.375 0 00-3.375-3.375h-1.5a1.125 1.125 0 01-1.125-1.125v-1.5a3.375 3.375 0 00-3.375-3.375H9.75" />
            </svg>
            <p>No NGO requests found in your area.</p>
            <Link href="/requests/browse">
              <Button variant="outline" className="mt-4">
                Browse All Requests
              </Button>
            </Link>
          </div>
        ) : (
          <motion.div 
            className="space-y-4"
            variants={containerVariants}
            initial="hidden"
            animate="visible"
          >
            {nearbyRequests.slice(0, 3).map((request) => (
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
                          <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-5.5-2.5a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0zM10 12a5.99 5.99 0 00-4.793 2.39A6.483 6.483 0 0010 16.5a6.483 6.483 0 004.793-2.11A5.99 5.99 0 0010 12z" clipRule="evenodd" />
                        </svg>
                        {request.ngoName}
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
                    <Link href={`/requests/${request.id}`}>
                      <Button size="sm" className="mt-2 sm:mt-4">
                        <MessageSquare className="h-4 w-4 mr-1" />
                        Respond
                      </Button>
                    </Link>
                  </div>
                </div>
              </motion.div>
            ))}
            {nearbyRequests.length > 3 && (
              <div className="text-center mt-4">
                <Link href="/requests/browse">
                  <Button variant="outline">View All Requests</Button>
                </Link>
              </div>
            )}
          </motion.div>
        )}
      </motion.div>
      
      {/* Donation Creation Modal */}
      <Dialog
        open={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
        className="fixed inset-0 z-50 overflow-y-auto"
      >
        <div className="flex min-h-screen items-center justify-center p-4">
          <div className="fixed inset-0 bg-black/30" />
          
          <DialogPanel className="relative bg-white dark:bg-zinc-800 rounded-lg p-6 w-full max-w-3xl mx-auto">
            <DialogTitle className="text-lg font-medium text-gray-900 dark:text-white mb-4">
              Create New Donation
            </DialogTitle>
            
            <CreateDonationForm 
              onSuccess={() => {
                setIsCreateModalOpen(false);
                toast.success('Donation created successfully');
              }} 
              onCancel={() => setIsCreateModalOpen(false)} 
            />
          </DialogPanel>
        </div>
      </Dialog>
    </div>
  );
} 