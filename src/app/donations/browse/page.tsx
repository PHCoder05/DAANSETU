'use client';

import React, { useState, useEffect } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/Button';
import Navbar from '@/components/ui/Navbar';
import { 
  Donation, 
  getNearbyDonations,
  claimDonation,
  DonationType,
  getAllDonations
} from '@/lib/firestore';
import { toast } from 'react-hot-toast';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { useRouter, useSearchParams } from 'next/navigation';

const CATEGORIES = [
  'food',
  'clothing',
  'education',
  'healthcare',
  'shelter',
  'hygiene',
  'electronics',
  'furniture',
  'toys',
  'other',
];

export default function BrowseDonations() {
  const { userProfile } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  
  const [donations, setDonations] = useState<Donation[]>([]);
  const [filteredDonations, setFilteredDonations] = useState<Donation[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filters, setFilters] = useState({
    category: searchParams.get('filter') || '',
    status: 'available',
  });

  // Mock coordinates (would be user's actual location in production)
  const defaultLat = 28.6139; // Delhi coordinates for example
  const defaultLng = 77.2090;

  useEffect(() => {
    async function loadDonations() {
      try {
        setLoading(true);
        const allDonations = await getAllDonations();
        setDonations(allDonations);
        applyFilters(allDonations, filters, search);
      } catch (error) {
        console.error('Error loading donations:', error);
        toast.error('Failed to load donations');
      } finally {
        setLoading(false);
      }
    }

    loadDonations();
  }, []);

  useEffect(() => {
    applyFilters(donations, filters, search);
  }, [filters, search]);

  function applyFilters(items: Donation[], currentFilters: any, searchQuery: string) {
    let result = [...items];

    // Apply status filter
    if (currentFilters.status) {
      result = result.filter(d => d.status === currentFilters.status);
    }

    // Apply category filter
    if (currentFilters.category) {
      result = result.filter(d => d.category === currentFilters.category);
    }

    // Apply search
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      result = result.filter(d => 
        d.title.toLowerCase().includes(query) || 
        d.description.toLowerCase().includes(query) ||
        (d.donorName && d.donorName.toLowerCase().includes(query))
      );
    }

    // Sort by newest first
    result.sort((a, b) => {
      const aDate = a.createdAt?.toDate?.() || new Date(a.createdAt || 0);
      const bDate = b.createdAt?.toDate?.() || new Date(b.createdAt || 0);
      return bDate.getTime() - aDate.getTime();
    });

    setFilteredDonations(result);
  }

  function handleFilterChange(name: string, value: string) {
    setFilters(prev => ({ ...prev, [name]: value }));
  }

  function resetFilters() {
    setFilters({
      category: '',
      status: 'available',
    });
    setSearch('');
  }

  function formatDate(timestamp: any) {
    if (!timestamp) return '';
    
    try {
      const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
      return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
      });
    } catch (error) {
      return '';
    }
  }

  function getStatusBadge(status: string) {
    switch (status) {
      case 'available':
        return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300';
      case 'claimed':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300';
      case 'completed':
        return 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300';
      case 'cancelled':
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300';
    }
  }

  const handleClaimDonation = async (donationId: string) => {
    if (!userProfile) {
      toast.error('You must be logged in to claim donations');
      return;
    }

    if (userProfile.role !== 'ngo') {
      toast.error('Only NGOs can claim donations');
      return;
    }

    setProcessing(donationId);
    
    try {
      await claimDonation(donationId, userProfile.uid, userProfile.displayName || 'NGO');
      toast.success('Donation claimed successfully');
      
      // Remove the claimed donation from the list
      setDonations(prev => prev.filter(donation => donation.id !== donationId));
    } catch (error) {
      console.error('Error claiming donation:', error);
      toast.error('Failed to claim donation');
    } finally {
      setProcessing(null);
    }
  };

  const [processing, setProcessing] = useState<string | null>(null);

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

  return (
    <>
      <Navbar />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Browse Donations</h1>
            <p className="mt-1 text-gray-500 dark:text-gray-400">
              Explore available donations from generous donors
            </p>
          </div>
          
          {userProfile?.role === 'donor' && (
            <Link href="/dashboard">
              <Button className="mt-4 md:mt-0">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-2">
                  <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
                </svg>
                Create New Donation
              </Button>
            </Link>
          )}
        </div>
        
        <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-4 mb-8">
          <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1">
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 text-gray-400">
                    <path fillRule="evenodd" d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z" clipRule="evenodd" />
                  </svg>
                </div>
                <input
                  type="text"
                  placeholder="Search donations..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-700 bg-white dark:bg-zinc-900 rounded-md shadow-sm focus:outline-none focus:ring-primary focus:border-primary text-sm"
                />
              </div>
            </div>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 md:w-1/2">
              <div>
                <label htmlFor="category-filter" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Category
                </label>
                <select
                  id="category-filter"
                  value={filters.category}
                  onChange={(e) => handleFilterChange('category', e.target.value)}
                  className="block w-full pl-3 pr-10 py-2 text-base border border-gray-300 dark:border-gray-700 bg-white dark:bg-zinc-900 focus:outline-none focus:ring-primary focus:border-primary rounded-md shadow-sm text-sm"
                >
                  <option value="">All Categories</option>
                  {CATEGORIES.map((category) => (
                    <option key={category} value={category}>
                      {category.charAt(0).toUpperCase() + category.slice(1)}
                    </option>
                  ))}
                </select>
              </div>
              
              <div>
                <label htmlFor="status-filter" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Status
                </label>
                <select
                  id="status-filter"
                  value={filters.status}
                  onChange={(e) => handleFilterChange('status', e.target.value)}
                  className="block w-full pl-3 pr-10 py-2 text-base border border-gray-300 dark:border-gray-700 bg-white dark:bg-zinc-900 focus:outline-none focus:ring-primary focus:border-primary rounded-md shadow-sm text-sm"
                >
                  <option value="available">Available</option>
                  <option value="claimed">Claimed</option>
                  <option value="completed">Completed</option>
                  <option value="">All Statuses</option>
                </select>
              </div>
            </div>
          </div>
          
          <div className="flex justify-end mt-4">
            <Button
              variant="outline"
              onClick={resetFilters}
              className="text-sm"
            >
              Reset Filters
            </Button>
          </div>
        </div>
        
        {loading ? (
          <div className="flex justify-center items-center py-20">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
          </div>
        ) : filteredDonations.length === 0 ? (
          <div className="text-center py-16 bg-white dark:bg-zinc-800 rounded-lg shadow-sm">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={1}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
              />
            </svg>
            <h3 className="mt-2 text-sm font-medium text-gray-900 dark:text-white">No donations found</h3>
            <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
              {search ? 'Try adjusting your search or filter criteria.' : 'Check back later or adjust your filters.'}
            </p>
            
            {userProfile?.role === 'donor' && (
              <div className="mt-6">
                <Link href="/dashboard">
                  <Button>
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-2">
                      <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
                    </svg>
                    Create New Donation
                  </Button>
                </Link>
              </div>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredDonations.map((donation) => (
              <div key={donation.id} className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm overflow-hidden hover:shadow-md transition-shadow duration-200">
                <div className="p-6">
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center mb-2">
                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusBadge(donation.status)}`}>
                          {donation.status.toUpperCase()}
                        </span>
                        <span className="text-xs text-gray-500 dark:text-gray-400 ml-2">
                          {formatDate(donation.createdAt)}
                        </span>
                      </div>
                      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1 line-clamp-1">
                        {donation.title}
                      </h3>
                      <p className="text-sm text-gray-500 dark:text-gray-400 mb-3">
                        By {donation.donorName || 'Anonymous Donor'}
                      </p>
                      <p className="text-sm text-gray-600 dark:text-gray-300 mb-4 line-clamp-2">
                        {donation.description}
                      </p>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-2 mb-4">
                    <div>
                      <span className="block text-xs text-gray-500 dark:text-gray-400">Category</span>
                      <span className="text-sm font-medium text-gray-900 dark:text-white capitalize">{donation.category}</span>
                    </div>
                    <div>
                      <span className="block text-xs text-gray-500 dark:text-gray-400">Quantity</span>
                      <span className="text-sm font-medium text-gray-900 dark:text-white">{donation.quantity} items</span>
                    </div>
                  </div>
                  
                  <Link href={`/donations/${donation.id}`}>
                    <Button variant="outline" className="w-full">
                      View Details
                    </Button>
                  </Link>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </>
  );
} 