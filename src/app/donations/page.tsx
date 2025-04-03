'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import { Donation, subscribeToUserDonations, updateDonation } from '@/lib/firestore';
import { Button } from '@/components/ui/Button';
import Navbar from '@/components/ui/Navbar';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { toast } from 'react-hot-toast';
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';
import CreateDonationForm from '@/components/donations/CreateDonationForm';
import { Tab } from '@headlessui/react';
import { 
  Gift, 
  PlusCircle, 
  Clock, 
  CheckCircle, 
  XCircle,
  Filter,
  Search,
  ExternalLink
} from 'lucide-react';

export default function DonationsPage() {
  const { userProfile } = useAuth();
  const router = useRouter();
  const [donations, setDonations] = useState<Donation[]>([]);
  const [filteredDonations, setFilteredDonations] = useState<Donation[]>([]);
  const [loading, setLoading] = useState(true);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [selectedTab, setSelectedTab] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');

  // Fetch user's donations if they are a donor
  useEffect(() => {
    if (!userProfile) return;

    let unsubscribe = () => {};

    if (userProfile.role === 'donor') {
      unsubscribe = subscribeToUserDonations(userProfile.uid, (donationData) => {
        setDonations(donationData);
        setFilteredDonations(donationData);
        setLoading(false);
      });
    } else {
      setLoading(false);
    }

    return () => unsubscribe();
  }, [userProfile]);

  // Filter donations when tab or search term changes
  useEffect(() => {
    if (donations.length === 0) return;

    let filtered = [...donations];

    // Apply tab filter
    if (selectedTab === 1) { // Available
      filtered = filtered.filter(d => d.status === 'available');
    } else if (selectedTab === 2) { // In Progress
      filtered = filtered.filter(d => d.status === 'claimed');
    } else if (selectedTab === 3) { // Completed
      filtered = filtered.filter(d => d.status === 'delivered');
    } else if (selectedTab === 4) { // Cancelled
      filtered = filtered.filter(d => d.status === 'cancelled');
    }

    // Apply search filter
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(d => 
        d.title.toLowerCase().includes(term) || 
        d.description.toLowerCase().includes(term) ||
        d.category.toLowerCase().includes(term)
      );
    }

    // Sort by newest first
    filtered.sort((a, b) => {
      const dateA = a.createdAt?.toDate?.() || new Date(a.createdAt || 0);
      const dateB = b.createdAt?.toDate?.() || new Date(b.createdAt || 0);
      return dateB.getTime() - dateA.getTime();
    });

    setFilteredDonations(filtered);
  }, [donations, selectedTab, searchTerm]);

  const handleCancelDonation = async (donationId: string) => {
    try {
      await updateDonation(donationId, { status: 'cancelled' });
      toast.success('Donation cancelled successfully');
    } catch (error) {
      console.error('Error canceling donation:', error);
      toast.error('Failed to cancel donation');
    }
  };

  const formatDate = (timestamp: any) => {
    if (!timestamp) return 'N/A';
    
    try {
      const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
      return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      });
    } catch (error) {
      console.error('Error formatting date:', error);
      return 'Invalid date';
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'available':
        return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300';
      case 'claimed':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300';
      case 'delivered':
        return 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300';
      case 'cancelled':
        return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'available':
        return <Gift className="h-4 w-4 mr-1 text-green-600 dark:text-green-400" />;
      case 'claimed':
        return <Clock className="h-4 w-4 mr-1 text-blue-600 dark:text-blue-400" />;
      case 'delivered':
        return <CheckCircle className="h-4 w-4 mr-1 text-purple-600 dark:text-purple-400" />;
      case 'cancelled':
        return <XCircle className="h-4 w-4 mr-1 text-red-600 dark:text-red-400" />;
      default:
        return null;
    }
  };

  // Animation variants
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: { staggerChildren: 0.05 }
    }
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { opacity: 1, y: 0 }
  };

  if (loading) {
    return (
      <>
        <Navbar />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="flex justify-center items-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <Navbar />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">My Donations</h1>
            <p className="mt-1 text-gray-600 dark:text-gray-400">
              {userProfile?.role === 'donor' 
                ? 'Manage your donations and track their status' 
                : 'Browse available donations from generous donors'}
            </p>
          </div>
          
          <div className="mt-4 md:mt-0 flex space-x-2">
            {userProfile?.role === 'donor' && (
              <Button 
                onClick={() => setIsCreateModalOpen(true)}
                className="flex items-center"
              >
                <PlusCircle className="h-5 w-5 mr-1" />
                Create Donation
              </Button>
            )}
            
            <Link href="/donations/browse">
              <Button variant="outline" className="flex items-center">
                <Search className="h-5 w-5 mr-1" />
                Browse All
              </Button>
            </Link>
          </div>
        </div>
        
        {userProfile?.role === 'donor' ? (
          <>
            {donations.length === 0 ? (
              <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-12 text-center">
                <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 mb-4">
                  <Gift className="h-8 w-8" />
                </div>
                <h2 className="text-2xl font-semibold text-gray-900 dark:text-white mb-2">No Donations Yet</h2>
                <p className="text-gray-600 dark:text-gray-400 max-w-md mx-auto mb-8">
                  You haven't created any donations yet. Start making a difference by sharing items you no longer need with those who could benefit from them.
                </p>
                <Button onClick={() => setIsCreateModalOpen(true)}>Create Your First Donation</Button>
              </div>
            ) : (
              <>
                {/* Filtering and search */}
                <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-4 mb-6">
                  <div className="flex flex-col md:flex-row items-center gap-4">
                    <div className="w-full md:w-64">
                      <div className="relative">
                        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                          <Search className="h-5 w-5 text-gray-400" />
                        </div>
                        <input
                          type="text"
                          placeholder="Search donations..."
                          value={searchTerm}
                          onChange={(e) => setSearchTerm(e.target.value)}
                          className="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-700 bg-white dark:bg-zinc-900 rounded-md shadow-sm focus:outline-none focus:ring-primary focus:border-primary text-sm"
                        />
                      </div>
                    </div>
                    
                    <div className="w-full md:w-auto flex-1">
                      <Tab.Group selectedIndex={selectedTab} onChange={setSelectedTab}>
                        <Tab.List className="flex space-x-1 rounded-lg bg-gray-100 dark:bg-zinc-700 p-1 overflow-x-auto">
                          <Tab
                            className={({ selected }) =>
                              `px-3 py-2 text-sm font-medium leading-5 rounded-md whitespace-nowrap
                              ${selected 
                                ? 'bg-white dark:bg-zinc-800 text-primary shadow'
                                : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white hover:bg-gray-50 dark:hover:bg-zinc-700/70'}`
                            }
                          >
                            All
                          </Tab>
                          <Tab
                            className={({ selected }) =>
                              `px-3 py-2 text-sm font-medium leading-5 rounded-md whitespace-nowrap flex items-center
                              ${selected 
                                ? 'bg-white dark:bg-zinc-800 text-primary shadow'
                                : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white hover:bg-gray-50 dark:hover:bg-zinc-700/70'}`
                            }
                          >
                            <Gift className="h-4 w-4 mr-1" />
                            Available
                          </Tab>
                          <Tab
                            className={({ selected }) =>
                              `px-3 py-2 text-sm font-medium leading-5 rounded-md whitespace-nowrap flex items-center
                              ${selected 
                                ? 'bg-white dark:bg-zinc-800 text-primary shadow'
                                : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white hover:bg-gray-50 dark:hover:bg-zinc-700/70'}`
                            }
                          >
                            <Clock className="h-4 w-4 mr-1" />
                            In Progress
                          </Tab>
                          <Tab
                            className={({ selected }) =>
                              `px-3 py-2 text-sm font-medium leading-5 rounded-md whitespace-nowrap flex items-center
                              ${selected 
                                ? 'bg-white dark:bg-zinc-800 text-primary shadow'
                                : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white hover:bg-gray-50 dark:hover:bg-zinc-700/70'}`
                            }
                          >
                            <CheckCircle className="h-4 w-4 mr-1" />
                            Completed
                          </Tab>
                          <Tab
                            className={({ selected }) =>
                              `px-3 py-2 text-sm font-medium leading-5 rounded-md whitespace-nowrap flex items-center
                              ${selected 
                                ? 'bg-white dark:bg-zinc-800 text-primary shadow'
                                : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white hover:bg-gray-50 dark:hover:bg-zinc-700/70'}`
                            }
                          >
                            <XCircle className="h-4 w-4 mr-1" />
                            Cancelled
                          </Tab>
                        </Tab.List>
                      </Tab.Group>
                    </div>
                  </div>
                </div>
                
                {/* Donations List */}
                {filteredDonations.length === 0 ? (
                  <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-8 text-center">
                    <Filter className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">No matching donations</h3>
                    <p className="text-gray-500 dark:text-gray-400 mb-4">Try adjusting your filters or create a new donation.</p>
                    <Button variant="outline" onClick={() => {setSelectedTab(0); setSearchTerm('');}}>
                      Reset Filters
                    </Button>
                  </div>
                ) : (
                  <motion.div 
                    className="space-y-4"
                    variants={containerVariants}
                    initial="hidden"
                    animate="visible"
                  >
                    {filteredDonations.map((donation) => (
                      <motion.div 
                        key={donation.id}
                        className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm overflow-hidden transition-all hover:shadow"
                        variants={itemVariants}
                      >
                        <div className="p-6">
                          <div className="flex flex-col sm:flex-row justify-between">
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center gap-2 mb-2">
                                <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full flex items-center ${getStatusBadge(donation.status)}`}>
                                  {getStatusIcon(donation.status)}
                                  {donation.status.charAt(0).toUpperCase() + donation.status.slice(1)}
                                </span>
                                <span className="text-xs text-gray-500 dark:text-gray-400">
                                  Created on {formatDate(donation.createdAt)}
                                </span>
                              </div>
                              <h3 className="text-lg font-medium text-gray-900 dark:text-white truncate">
                                {donation.title}
                              </h3>
                              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400 line-clamp-2">
                                {donation.description}
                              </p>
                              <div className="mt-3 flex flex-wrap gap-2">
                                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300">
                                  {donation.category}
                                </span>
                                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300">
                                  {donation.quantity} items
                                </span>
                                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300">
                                  {donation.requiresPickup ? 'Pickup Required' : 'No Pickup Required'}
                                </span>
                              </div>
                            </div>
                            <div className="mt-4 sm:mt-0 sm:ml-4 flex flex-col justify-between min-w-[140px]">
                              {donation.claimedBy && (
                                <div className="text-sm mb-4">
                                  <span className="block text-gray-500 dark:text-gray-400">Claimed by:</span>
                                  <span className="font-medium text-gray-900 dark:text-white">
                                    {donation.claimedByName || 'NGO'}
                                  </span>
                                </div>
                              )}
                              <div className="flex flex-col gap-2">
                                <Link href={`/donations/${donation.id}`}>
                                  <Button size="sm" variant="outline" className="w-full justify-center">
                                    <ExternalLink className="h-4 w-4 mr-1" />
                                    View Details
                                  </Button>
                                </Link>
                                {donation.status === 'available' && (
                                  <Button 
                                    size="sm" 
                                    variant="outline" 
                                    className="w-full justify-center text-red-600 border-red-300 hover:bg-red-50 dark:border-red-800 dark:hover:bg-red-900/20 dark:text-red-400"
                                    onClick={() => handleCancelDonation(donation.id)}
                                  >
                                    <XCircle className="h-4 w-4 mr-1" />
                                    Cancel
                                  </Button>
                                )}
                              </div>
                            </div>
                          </div>
                        </div>
                      </motion.div>
                    ))}
                  </motion.div>
                )}
              </>
            )}
          </>
        ) : (
          <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-8 text-center">
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 mb-4">
              <Gift className="h-8 w-8" />
            </div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">Browse Available Donations</h2>
            <p className="text-gray-600 dark:text-gray-400 max-w-md mx-auto mb-8">
              {userProfile?.role === 'ngo' 
                ? 'As an NGO, you can browse and claim available donations that match your needs.' 
                : 'Explore donations from generous donors in your community.'}
            </p>
            <Link href="/donations/browse">
              <Button>Browse All Donations</Button>
            </Link>
          </div>
        )}
        
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
              
              <CreateDonationForm onSuccess={() => setIsCreateModalOpen(false)} onCancel={() => setIsCreateModalOpen(false)} />
            </DialogPanel>
          </div>
        </Dialog>
      </div>
    </>
  );
} 