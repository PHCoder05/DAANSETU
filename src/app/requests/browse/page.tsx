'use client';

import React, { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/Button';
import Navbar from '@/components/ui/Navbar';
import { 
  Request,
  getAllRequests,
  fulfillRequest,
  DonationType
} from '@/lib/firestore';
import { toast } from 'react-hot-toast';
import Link from 'next/link';
import { motion } from 'framer-motion';

export default function BrowseRequestsPage() {
  const { userProfile } = useAuth();
  const [requests, setRequests] = useState<Request[]>([]);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<DonationType | 'all'>('all');
  const [urgencyFilter, setUrgencyFilter] = useState<'all' | 'low' | 'medium' | 'high'>('all');
  const [sortBy, setSortBy] = useState<'newest' | 'oldest' | 'urgency'>('newest');

  useEffect(() => {
    async function fetchRequests() {
      try {
        const allRequests = await getAllRequests();
        setRequests(allRequests);
      } catch (error) {
        console.error('Error fetching requests:', error);
        toast.error('Failed to load requests');
      } finally {
        setLoading(false);
      }
    }

    fetchRequests();
  }, []);

  const handleFulfillRequest = async (requestId: string) => {
    if (!userProfile) {
      toast.error('You must be logged in to fulfill requests');
      return;
    }

    if (userProfile.role !== 'donor') {
      toast.error('Only donors can fulfill requests');
      return;
    }

    setProcessing(requestId);
    
    try {
      await fulfillRequest(requestId, userProfile.uid, userProfile.displayName || 'Donor');
      toast.success('Request fulfilled successfully');
      
      // Update the request status in the list
      setRequests(prev => prev.map(request => 
        request.id === requestId 
          ? { ...request, status: 'fulfilled' as 'open' | 'fulfilled' | 'closed' } 
          : request
      ));
    } catch (error) {
      console.error('Error fulfilling request:', error);
      toast.error('Failed to fulfill request');
    } finally {
      setProcessing(null);
    }
  };

  // Filter and sort requests
  const filteredRequests = requests
    .filter(request => request.status === 'open')
    .filter(request => {
      if (searchTerm) {
        const searchLower = searchTerm.toLowerCase();
        return (
          request.title.toLowerCase().includes(searchLower) ||
          request.description.toLowerCase().includes(searchLower) ||
          request.category.toLowerCase().includes(searchLower) ||
          (request.ngoName && request.ngoName.toLowerCase().includes(searchLower))
        );
      }
      return true;
    })
    .filter(request => {
      if (categoryFilter === 'all') return true;
      return request.category === categoryFilter;
    })
    .filter(request => {
      if (urgencyFilter === 'all') return true;
      return request.urgencyLevel === urgencyFilter;
    })
    .sort((a, b) => {
      if (sortBy === 'newest') {
        return (b.createdAt?.toMillis?.() || 0) - (a.createdAt?.toMillis?.() || 0);
      } else if (sortBy === 'oldest') {
        return (a.createdAt?.toMillis?.() || 0) - (b.createdAt?.toMillis?.() || 0);
      } else if (sortBy === 'urgency') {
        // Sort by urgency (high > medium > low)
        const urgencyValue = {
          high: 3,
          medium: 2,
          low: 1
        };
        
        return (urgencyValue[b.urgencyLevel || 'medium'] || 0) - (urgencyValue[a.urgencyLevel || 'medium'] || 0);
      }
      return 0;
    });

  const requestCategories = [
    { value: 'all', label: 'All Categories' },
    { value: 'food', label: 'Food' },
    { value: 'clothes', label: 'Clothes & Apparel' },
    { value: 'books', label: 'Books & Education' },
    { value: 'toys', label: 'Toys & Games' },
    { value: 'medicine', label: 'Medicines & Health' },
    { value: 'furniture', label: 'Furniture' },
    { value: 'electronics', label: 'Electronics' },
    { value: 'other', label: 'Other' },
  ];

  const urgencyLevels = [
    { value: 'all', label: 'All Levels' },
    { value: 'low', label: 'Low' },
    { value: 'medium', label: 'Medium' },
    { value: 'high', label: 'High' },
  ];

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
    hidden: { y: 20, opacity: 0 },
    visible: {
      y: 0,
      opacity: 1,
      transition: {
        duration: 0.3
      }
    }
  };

  // Helper function for urgency badge color
  const getUrgencyColor = (level: string) => {
    switch (level) {
      case 'high':
        return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400';
      case 'low':
        return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400';
    }
  };

  // Format date helper
  const formatDate = (date: any) => {
    if (!date) return 'No deadline';
    const d = date.toDate ? date.toDate() : new Date(date);
    return d.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  return (
    <>
      <Navbar />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">NGO Requests</h1>
            <p className="mt-2 text-gray-600 dark:text-gray-300">
              Browse open requests from NGOs and help fulfill their needs
            </p>
          </div>
          <Link href="/dashboard">
            <Button variant="outline">Back to Dashboard</Button>
          </Link>
        </div>
        
        {/* Filters */}
        <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 mb-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div>
              <label htmlFor="search" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Search
              </label>
              <input
                type="text"
                id="search"
                placeholder="Search by title, description..."
                className="w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            
            <div>
              <label htmlFor="category" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Category
              </label>
              <select
                id="category"
                className="w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700"
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value as DonationType | 'all')}
              >
                {requestCategories.map((category) => (
                  <option key={category.value} value={category.value}>
                    {category.label}
                  </option>
                ))}
              </select>
            </div>
            
            <div>
              <label htmlFor="urgency" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Urgency Level
              </label>
              <select
                id="urgency"
                className="w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700"
                value={urgencyFilter}
                onChange={(e) => setUrgencyFilter(e.target.value as 'all' | 'low' | 'medium' | 'high')}
              >
                {urgencyLevels.map((level) => (
                  <option key={level.value} value={level.value}>
                    {level.label}
                  </option>
                ))}
              </select>
            </div>
            
            <div>
              <label htmlFor="sortBy" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Sort By
              </label>
              <select
                id="sortBy"
                className="w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700"
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as 'newest' | 'oldest' | 'urgency')}
              >
                <option value="newest">Newest First</option>
                <option value="oldest">Oldest First</option>
                <option value="urgency">Urgency (High to Low)</option>
              </select>
            </div>
          </div>
        </div>
        
        {/* Results */}
        {loading ? (
          <div className="flex justify-center items-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
          </div>
        ) : filteredRequests.length === 0 ? (
          <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-12 text-center">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-16 h-16 mx-auto text-gray-400 mb-4">
              <path strokeLinecap="round" strokeLinejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
            </svg>
            <h3 className="text-xl font-medium text-gray-900 dark:text-white mb-2">No Requests Found</h3>
            <p className="text-gray-600 dark:text-gray-300 mb-6">
              {searchTerm || categoryFilter !== 'all' || urgencyFilter !== 'all'
                ? 'Try adjusting your filters to see more results' 
                : 'There are no open requests at this time. Please check back later.'}
            </p>
            {(searchTerm || categoryFilter !== 'all' || urgencyFilter !== 'all') && (
              <Button 
                variant="outline" 
                onClick={() => {
                  setSearchTerm('');
                  setCategoryFilter('all');
                  setUrgencyFilter('all');
                }}
              >
                Reset Filters
              </Button>
            )}
          </div>
        ) : (
          <motion.div 
            className="grid grid-cols-1 md:grid-cols-2 gap-6"
            variants={containerVariants}
            initial="hidden"
            animate="visible"
          >
            {filteredRequests.map((request) => (
              <motion.div 
                key={request.id}
                variants={itemVariants} 
                className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm overflow-hidden border border-gray-100 dark:border-gray-700"
              >
                <div className="p-6">
                  <div className="flex flex-wrap items-center gap-2 mb-3">
                    <span className="px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-primary/10 text-primary capitalize">
                      {request.category}
                    </span>
                    <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getUrgencyColor(request.urgencyLevel || 'medium')}`}>
                      {request.urgencyLevel?.toUpperCase() || 'MEDIUM'} URGENCY
                    </span>
                    {request.deadline && (
                      <span className="px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200">
                        Deadline: {formatDate(request.deadline)}
                      </span>
                    )}
                  </div>
                  
                  <Link href={`/requests/${request.id}`}>
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2 hover:text-primary dark:hover:text-primary transition-colors">
                      {request.title}
                    </h3>
                  </Link>
                  
                  <p className="text-gray-600 dark:text-gray-300 text-sm mb-4 line-clamp-3">
                    {request.description}
                  </p>
                  
                  <div className="flex items-start mb-4">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-4 h-4 text-gray-400 mt-0.5 mr-2 flex-shrink-0">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
                    </svg>
                    <p className="text-gray-600 dark:text-gray-300 text-sm">
                      Requested by <span className="font-semibold">{request.ngoName || 'Anonymous NGO'}</span>
                    </p>
                  </div>
                  
                  <div className="flex flex-wrap items-center justify-between gap-4">
                    <div className="flex flex-col space-y-1">
                      <div className="text-sm">
                        <span className="text-gray-500 dark:text-gray-400">Quantity Needed: </span>
                        <span className="font-medium text-gray-900 dark:text-white">{request.quantity}</span>
                      </div>
                      
                      {request.beneficiaryCount && (
                        <div className="text-sm">
                          <span className="text-gray-500 dark:text-gray-400">Beneficiaries: </span>
                          <span className="font-medium text-gray-900 dark:text-white">{request.beneficiaryCount}</span>
                        </div>
                      )}
                      
                      <div className="text-xs text-gray-500 dark:text-gray-400">
                        Posted {request.createdAt ? new Date(request.createdAt.toDate()).toLocaleDateString() : 'recently'}
                      </div>
                    </div>
                    
                    <div className="flex space-x-2">
                      <Link href={`/requests/${request.id}`}>
                        <Button variant="outline" size="sm">
                          View Details
                        </Button>
                      </Link>
                      
                      {userProfile?.role === 'donor' && (
                        <Button 
                          size="sm"
                          disabled={processing === request.id}
                          onClick={() => handleFulfillRequest(request.id)}
                        >
                          {processing === request.id ? 'Processing...' : 'Fulfill Request'}
                        </Button>
                      )}
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}
          </motion.div>
        )}
      </div>
    </>
  );
} 