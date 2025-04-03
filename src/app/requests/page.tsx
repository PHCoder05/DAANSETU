'use client';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import Navbar from '@/components/ui/Navbar';
import { Button } from '@/components/ui/Button';
import { getAllRequests, Request } from '@/lib/firestore';
import Link from 'next/link';
import { useAuth } from '@/context/AuthContext';
import { toast } from 'react-hot-toast';

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

const URGENCY_LEVELS = [
  { value: 'high', label: 'High Urgency' },
  { value: 'medium', label: 'Medium Urgency' },
  { value: 'low', label: 'Low Urgency' },
];

export default function Requests() {
  const { userProfile } = useAuth();
  const router = useRouter();
  const searchParams = useSearchParams();
  
  const [requests, setRequests] = useState<Request[]>([]);
  const [filteredRequests, setFilteredRequests] = useState<Request[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filters, setFilters] = useState({
    category: searchParams.get('filter') || '',
    urgency: '',
    status: 'open',
  });

  useEffect(() => {
    async function loadRequests() {
      try {
        setLoading(true);
        const allRequests = await getAllRequests();
        setRequests(allRequests);
        applyFilters(allRequests, filters, search);
      } catch (error) {
        console.error('Error loading requests:', error);
        toast.error('Failed to load requests');
      } finally {
        setLoading(false);
      }
    }

    loadRequests();
  }, []);

  useEffect(() => {
    applyFilters(requests, filters, search);
  }, [filters, search]);

  function applyFilters(reqs: Request[], currentFilters: any, searchQuery: string) {
    let result = [...reqs];

    // Apply status filter
    if (currentFilters.status) {
      result = result.filter(r => r.status === currentFilters.status);
    }

    // Apply category filter
    if (currentFilters.category) {
      result = result.filter(r => r.category === currentFilters.category);
    }

    // Apply urgency filter
    if (currentFilters.urgency) {
      result = result.filter(r => r.urgencyLevel === currentFilters.urgency);
    }

    // Apply search
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      result = result.filter(r => 
        r.title.toLowerCase().includes(query) || 
        r.description.toLowerCase().includes(query) ||
        r.ngoName.toLowerCase().includes(query)
      );
    }

    // Sort by urgency level and date
    result.sort((a, b) => {
      const urgencyOrder = { high: 0, medium: 1, low: 2 };
      const aOrder = urgencyOrder[a.urgencyLevel as keyof typeof urgencyOrder] || 3;
      const bOrder = urgencyOrder[b.urgencyLevel as keyof typeof urgencyOrder] || 3;
      
      if (aOrder !== bOrder) {
        return aOrder - bOrder;
      }
      
      // If same urgency, sort by newest first
      const aDate = a.createdAt?.toDate?.() || new Date(a.createdAt || 0);
      const bDate = b.createdAt?.toDate?.() || new Date(b.createdAt || 0);
      return bDate.getTime() - aDate.getTime();
    });

    setFilteredRequests(result);
  }

  function handleFilterChange(name: string, value: string) {
    setFilters(prev => ({ ...prev, [name]: value }));
  }

  function resetFilters() {
    setFilters({
      category: '',
      urgency: '',
      status: 'open',
    });
    setSearch('');
  }

  function getUrgencyBadge(urgency: string) {
    switch (urgency) {
      case 'high':
        return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300';
      case 'medium':
        return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300';
      case 'low':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300';
    }
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

  return (
    <>
      <Navbar />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">NGO Requests</h1>
            <p className="mt-1 text-gray-500 dark:text-gray-400">
              Browse requests from verified NGOs and help make a difference
            </p>
          </div>
          
          {userProfile?.role === 'ngo' && (
            <Link href="/requests/create">
              <Button className="mt-4 md:mt-0">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-2">
                  <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
                </svg>
                Create New Request
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
                  placeholder="Search requests..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-700 bg-white dark:bg-zinc-900 rounded-md shadow-sm focus:outline-none focus:ring-primary focus:border-primary text-sm"
                />
              </div>
            </div>
            
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 md:w-2/3">
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
                <label htmlFor="urgency-filter" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Urgency
                </label>
                <select
                  id="urgency-filter"
                  value={filters.urgency}
                  onChange={(e) => handleFilterChange('urgency', e.target.value)}
                  className="block w-full pl-3 pr-10 py-2 text-base border border-gray-300 dark:border-gray-700 bg-white dark:bg-zinc-900 focus:outline-none focus:ring-primary focus:border-primary rounded-md shadow-sm text-sm"
                >
                  <option value="">All Urgency Levels</option>
                  {URGENCY_LEVELS.map((level) => (
                    <option key={level.value} value={level.value}>
                      {level.label}
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
                  <option value="open">Open Requests</option>
                  <option value="fulfilled">Fulfilled Requests</option>
                  <option value="closed">Closed Requests</option>
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
        ) : filteredRequests.length === 0 ? (
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
                d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
              />
            </svg>
            <h3 className="mt-2 text-sm font-medium text-gray-900 dark:text-white">No requests found</h3>
            <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
              {search ? 'Try adjusting your search or filter criteria.' : 'Check back later or adjust your filters.'}
            </p>
            
            {userProfile?.role === 'ngo' && (
              <div className="mt-6">
                <Link href="/requests/create">
                  <Button>
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-2">
                      <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
                    </svg>
                    Create New Request
                  </Button>
                </Link>
              </div>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredRequests.map((request) => (
              <div key={request.id} className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm overflow-hidden hover:shadow-md transition-shadow duration-200">
                <div className="p-6">
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center mb-2">
                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getUrgencyBadge(request.urgencyLevel)}`}>
                          {request.urgencyLevel.toUpperCase()}
                        </span>
                        <span className="text-xs text-gray-500 dark:text-gray-400 ml-2">
                          {formatDate(request.createdAt)}
                        </span>
                      </div>
                      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1 line-clamp-1">
                        {request.title}
                      </h3>
                      <p className="text-sm text-gray-500 dark:text-gray-400 mb-3">
                        By {request.ngoName}
                      </p>
                      <p className="text-sm text-gray-600 dark:text-gray-300 mb-4 line-clamp-2">
                        {request.description}
                      </p>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-2 gap-2 mb-4">
                    <div>
                      <span className="block text-xs text-gray-500 dark:text-gray-400">Category</span>
                      <span className="text-sm font-medium text-gray-900 dark:text-white capitalize">{request.category}</span>
                    </div>
                    <div>
                      <span className="block text-xs text-gray-500 dark:text-gray-400">Quantity</span>
                      <span className="text-sm font-medium text-gray-900 dark:text-white">{request.quantity} items</span>
                    </div>
                  </div>
                  
                  <Link href={`/requests/${request.id}`}>
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