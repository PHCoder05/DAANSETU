'use client';

import React, { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/Button';
import Navbar from '@/components/ui/Navbar';
import { 
  Donation, 
  getDonationById,
  claimDonation,
  updateDonation,
  DonationStatus
} from '@/lib/firestore';
import { toast } from 'react-hot-toast';
import Link from 'next/link';
import { motion } from 'framer-motion';

export default function DonationDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { currentUser, userProfile } = useAuth();
  const [donation, setDonation] = useState<Donation | null>(null);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(false);

  const donationId = params.id as string;

  useEffect(() => {
    async function fetchDonation() {
      if (!donationId) return;

      try {
        const donationData = await getDonationById(donationId);
        if (!donationData) {
          toast.error('Donation not found');
          router.push('/dashboard');
          return;
        }
        
        setDonation(donationData);
      } catch (error) {
        console.error('Error fetching donation:', error);
        toast.error('Failed to load donation details');
      } finally {
        setLoading(false);
      }
    }

    fetchDonation();
  }, [donationId, router]);

  const handleClaimDonation = async () => {
    if (!currentUser || !userProfile || !donation) return;
    
    if (userProfile.role !== 'ngo') {
      toast.error('Only NGOs can claim donations');
      return;
    }
    
    setProcessing(true);
    
    try {
      await claimDonation(donationId, userProfile.uid, userProfile.displayName || 'NGO');
      toast.success('Donation claimed successfully');
      
      // Update local state
      setDonation(prev => prev ? { ...prev, status: 'claimed', claimedBy: userProfile.uid } : null);
    } catch (error) {
      console.error('Error claiming donation:', error);
      toast.error('Failed to claim donation');
    } finally {
      setProcessing(false);
    }
  };

  const handleUpdateStatus = async (newStatus: DonationStatus) => {
    if (!donation) return;
    
    setProcessing(true);
    
    try {
      await updateDonation(donationId, { status: newStatus });
      toast.success(`Donation status updated to ${newStatus.replace('_', ' ')}`);
      
      // Update local state
      setDonation(prev => prev ? { ...prev, status: newStatus } : null);
    } catch (error) {
      console.error('Error updating donation status:', error);
      toast.error('Failed to update donation status');
    } finally {
      setProcessing(false);
    }
  };

  const handleCancelDonation = async () => {
    if (!donation) return;
    
    setProcessing(true);
    
    try {
      await updateDonation(donationId, { status: 'cancelled' });
      toast.success('Donation cancelled successfully');
      router.push('/dashboard');
    } catch (error) {
      console.error('Error canceling donation:', error);
      toast.error('Failed to cancel donation');
    } finally {
      setProcessing(false);
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

  const renderStatusBadge = (status: DonationStatus) => {
    const statusStyles = {
      available: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
      claimed: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300',
      delivered: 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300',
      cancelled: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300',
    };
    
    return (
      <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${statusStyles[status]}`}>
        {status.replace('_', ' ')}
      </span>
    );
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

  if (!donation) {
    return (
      <>
        <Navbar />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="text-center">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Donation Not Found</h1>
            <p className="mt-2 text-gray-600 dark:text-gray-300">
              The donation you're looking for doesn't exist or has been removed.
            </p>
            <Link href="/dashboard">
              <Button className="mt-4">Back to Dashboard</Button>
            </Link>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <Navbar />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <div className="flex justify-between items-center mb-6">
            <div>
              <Link href="/dashboard" className="text-primary inline-flex items-center mb-2">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-1">
                  <path fillRule="evenodd" d="M17 10a.75.75 0 01-.75.75H5.612l4.158 3.96a.75.75 0 11-1.04 1.08l-5.5-5.25a.75.75 0 010-1.08l5.5-5.25a.75.75 0 111.04 1.08L5.612 9.25H16.25A.75.75 0 0117 10z" clipRule="evenodd" />
                </svg>
                Back to Dashboard
              </Link>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">{donation.title}</h1>
              <div className="mt-2 flex items-center">
                {renderStatusBadge(donation.status)}
                <span className="ml-2 text-sm text-gray-500 dark:text-gray-400">
                  Created on {formatDate(donation.createdAt)}
                </span>
              </div>
            </div>
            
            <div className="flex space-x-2">
              {/* Dynamic action buttons based on user role and donation status */}
              {userProfile?.role === 'donor' && donation.donorId === userProfile.uid && donation.status === 'available' && (
                <Button
                  variant="outline"
                  className="text-red-600 border-red-600 hover:bg-red-50 dark:hover:bg-red-900/20"
                  onClick={handleCancelDonation}
                  disabled={processing}
                >
                  Cancel Donation
                </Button>
              )}
              
              {userProfile?.role === 'ngo' && donation.status === 'available' && (
                <Button
                  onClick={handleClaimDonation}
                  disabled={processing}
                >
                  {processing ? 'Processing...' : 'Claim Donation'}
                </Button>
              )}
              
              {userProfile?.role === 'ngo' && donation.claimedBy === userProfile.uid && donation.status === 'claimed' && (
                <Button
                  onClick={() => handleUpdateStatus('delivered')}
                  disabled={processing}
                >
                  {processing ? 'Processing...' : 'Mark as Delivered'}
                </Button>
              )}
            </div>
          </div>
          
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2">
              <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 mb-6">
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Donation Details</h2>
                <div className="prose dark:prose-invert max-w-none">
                  <p>{donation.description}</p>
                </div>
                
                <div className="mt-6 grid grid-cols-2 gap-4">
                  <div>
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Category</h3>
                    <p className="mt-1 text-sm text-gray-900 dark:text-white capitalize">{donation.category}</p>
                  </div>
                  <div>
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Quantity</h3>
                    <p className="mt-1 text-sm text-gray-900 dark:text-white">{donation.quantity} items</p>
                  </div>
                  <div>
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Pickup Required</h3>
                    <p className="mt-1 text-sm text-gray-900 dark:text-white">{donation.requiresPickup ? 'Yes' : 'No'}</p>
                  </div>
                </div>
                
                {donation.pickupInstructions && (
                  <div className="mt-6">
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Pickup Instructions</h3>
                    <p className="mt-1 text-sm text-gray-900 dark:text-white">{donation.pickupInstructions}</p>
                  </div>
                )}
              </div>
              
              {donation.status !== 'available' && donation.status !== 'cancelled' && (
                <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6">
                  <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Tracking Information</h2>
                  
                  <div className="relative">
                    <div className="absolute left-4 top-0 bottom-0 w-0.5 bg-gray-200 dark:bg-gray-700"></div>
                    
                    <div className="relative flex items-start mb-6">
                      <div className="flex items-center h-6">
                        <div className="flex items-center h-6">
                          <div className="relative z-10 w-6 h-6 flex items-center justify-center bg-primary rounded-full">
                            <svg className="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                              <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd"></path>
                            </svg>
                          </div>
                        </div>
                      </div>
                      <div className="ml-4">
                        <h3 className="text-sm font-medium text-gray-900 dark:text-white">Claimed</h3>
                        <p className="text-sm text-gray-500 dark:text-gray-400">{formatDate(donation.claimedAt)}</p>
                      </div>
                    </div>
                    
                    <div className="relative flex items-start">
                      <div className="flex items-center h-6">
                        <div className={`relative z-10 w-6 h-6 flex items-center justify-center rounded-full ${donation.status === 'delivered' ? 'bg-primary' : 'bg-gray-300 dark:bg-gray-600'}`}>
                          {donation.status === 'delivered' ? (
                            <svg className="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                              <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd"></path>
                            </svg>
                          ) : (
                            <span className="w-3 h-3"></span>
                          )}
                        </div>
                      </div>
                      <div className="ml-4">
                        <h3 className="text-sm font-medium text-gray-900 dark:text-white">Delivered</h3>
                        <p className="text-sm text-gray-500 dark:text-gray-400">
                          {donation.status === 'delivered' ? 'Delivered to destination' : 'Waiting for pickup'}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
            
            <div>
              <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 mb-6">
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Donor Information</h2>
                <div className="flex items-center mb-4">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center text-primary mr-3">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-6 h-6">
                      <path d="M10 8a3 3 0 100-6 3 3 0 000 6zM3.465 14.493a1.23 1.23 0 00.41 1.412A9.957 9.957 0 0010 18c2.31 0 4.438-.784 6.131-2.1.43-.333.604-.903.408-1.41a7.002 7.002 0 00-13.074.003z" />
                    </svg>
                  </div>
                  <div>
                    <div className="font-medium text-gray-900 dark:text-white">{donation.donorName}</div>
                    <div className="text-sm text-gray-500 dark:text-gray-400">Donor</div>
                  </div>
                </div>
              </div>
              
              <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 mb-6">
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Location</h2>
                
                <div className="mb-4">
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Address</h3>
                  <p className="mt-1 text-gray-900 dark:text-white">{donation.address}</p>
                </div>
                
                <div className="w-full h-48 bg-gray-200 dark:bg-gray-700 rounded-lg overflow-hidden">
                  <div className="w-full h-full flex items-center justify-center text-gray-500 dark:text-gray-400">
                    <p className="text-sm">Map view will be available in the complete implementation</p>
                  </div>
                </div>
              </div>
              
              {donation.claimedBy && donation.status !== 'available' && donation.status !== 'cancelled' && (
                <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6">
                  <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Claimed By</h2>
                  <div className="flex items-center">
                    <div className="w-10 h-10 bg-blue-500/10 rounded-full flex items-center justify-center text-blue-500 mr-3">
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-6 h-6">
                        <path fillRule="evenodd" d="M4 16.5v-13h-.25a.75.75 0 010-1.5h12.5a.75.75 0 010 1.5H16v13h.25a.75.75 0 010 1.5h-3.5a.75.75 0 01-.75-.75v-2.5a.75.75 0 00-.75-.75h-2.5a.75.75 0 00-.75.75v2.5a.75.75 0 01-.75.75h-3.5a.75.75 0 010-1.5H4zm3-11a.5.5 0 01.5-.5h1a.5.5 0 01.5.5v1a.5.5 0 01-.5.5h-1a.5.5 0 01-.5-.5v-1zm0 3a.5.5 0 01.5-.5h1a.5.5 0 01.5.5v1a.5.5 0 01-.5.5h-1a.5.5 0 01-.5-.5v-1zm3.5-.5a.5.5 0 00-.5.5v1a.5.5 0 00.5.5h1a.5.5 0 00.5-.5v-1a.5.5 0 00-.5-.5h-1zM7 11.5a.5.5 0 01.5-.5h1a.5.5 0 01.5.5v1a.5.5 0 01-.5.5h-1a.5.5 0 01-.5-.5v-1zm3.5-.5a.5.5 0 00-.5.5v1a.5.5 0 00.5.5h1a.5.5 0 00.5-.5v-1a.5.5 0 00-.5-.5h-1z" clipRule="evenodd" />
                      </svg>
                    </div>
                    <div>
                      <div className="font-medium text-gray-900 dark:text-white">
                        {userProfile?.role === 'ngo' && donation.claimedBy === userProfile.uid 
                          ? 'Your Organization' 
                          : 'NGO Partner'}
                      </div>
                      <div className="text-sm text-gray-500 dark:text-gray-400">
                        Claimed on {formatDate(donation.claimedAt)}
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </motion.div>
      </div>
    </>
  );
} 