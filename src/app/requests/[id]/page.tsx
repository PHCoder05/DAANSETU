'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import Navbar from '@/components/ui/Navbar';
import { Button } from '@/components/ui/Button';
import { getRequestById, fulfillRequest, Request } from '@/lib/firestore';
import Link from 'next/link';
import { toast } from 'react-hot-toast';

export default function RequestDetail() {
  const { id } = useParams();
  const router = useRouter();
  const { userProfile } = useAuth();
  const [request, setRequest] = useState<Request | null>(null);
  const [loading, setLoading] = useState(true);
  const [fulfilling, setFulfilling] = useState(false);

  useEffect(() => {
    async function loadRequest() {
      try {
        setLoading(true);
        const requestId = Array.isArray(id) ? id[0] : id;
        const requestData = await getRequestById(requestId);
        setRequest(requestData);
      } catch (error) {
        console.error('Error loading request:', error);
        toast.error('Failed to load request details');
      } finally {
        setLoading(false);
      }
    }

    loadRequest();
  }, [id]);

  const handleFulfillRequest = async () => {
    if (!request || !userProfile) return;

    try {
      setFulfilling(true);
      await fulfillRequest(
        request.id,
        userProfile.uid,
        userProfile.displayName || 'Anonymous donor'
      );
      toast.success('Request fulfilled successfully');
      // Refresh the request data
      const updatedRequest = await getRequestById(request.id);
      setRequest(updatedRequest);
    } catch (error) {
      console.error('Error fulfilling request:', error);
      toast.error('Failed to fulfill request');
    } finally {
      setFulfilling(false);
    }
  };

  function formatDate(timestamp: any) {
    if (!timestamp) return 'No deadline';
    
    try {
      const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
      return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
      });
    } catch (error) {
      return 'Invalid date';
    }
  }

  function getUrgencyColor(urgency: string) {
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

  function getStatusBadge(status: string) {
    switch (status) {
      case 'open':
        return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300';
      case 'fulfilled':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300';
      case 'closed':
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-300';
    }
  }

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

  if (!request) {
    return (
      <>
        <Navbar />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="text-center">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Request Not Found</h1>
            <p className="mt-2 text-gray-600 dark:text-gray-300">
              The request you're looking for doesn't exist or has been removed.
            </p>
            <Link href="/requests">
              <Button className="mt-4">Back to Requests</Button>
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
        <div className="flex justify-between items-center mb-6">
          <div>
            <Link href="/requests" className="text-primary inline-flex items-center mb-2">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-1">
                <path fillRule="evenodd" d="M17 10a.75.75 0 01-.75.75H5.612l4.158 3.96a.75.75 0 11-1.04 1.08l-5.5-5.25a.75.75 0 010-1.08l5.5-5.25a.75.75 0 111.04 1.08L5.612 9.25H16.25A.75.75 0 0117 10z" clipRule="evenodd" />
              </svg>
              Back to Requests
            </Link>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">{request.title}</h1>
            <div className="mt-2 flex items-center flex-wrap gap-2">
              <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getUrgencyColor(request.urgencyLevel)}`}>
                {request.urgencyLevel.toUpperCase()} Urgency
              </span>
              <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusBadge(request.status)}`}>
                {request.status.toUpperCase()}
              </span>
              <span className="text-sm text-gray-500 dark:text-gray-400 ml-2">
                Created on {formatDate(request.createdAt)}
              </span>
            </div>
          </div>
          
          {userProfile?.role === 'donor' && request.status === 'open' && (
            <Button
              onClick={handleFulfillRequest}
              disabled={fulfilling}
            >
              {fulfilling ? 'Processing...' : 'Fulfill Request'}
            </Button>
          )}
        </div>
        
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2">
            <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 mb-6">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Request Details</h2>
              <div className="prose dark:prose-invert max-w-none">
                <p>{request.description}</p>
              </div>
              
              <div className="mt-6 grid grid-cols-2 gap-4">
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Category</h3>
                  <p className="mt-1 text-sm text-gray-900 dark:text-white capitalize">{request.category}</p>
                </div>
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Quantity</h3>
                  <p className="mt-1 text-sm text-gray-900 dark:text-white">{request.quantity} items</p>
                </div>
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Deadline</h3>
                  <p className="mt-1 text-sm text-gray-900 dark:text-white">{formatDate(request.deadline)}</p>
                </div>
                <div>
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Beneficiary Count</h3>
                  <p className="mt-1 text-sm text-gray-900 dark:text-white">{request.beneficiaryCount || 'Not specified'}</p>
                </div>
              </div>
            </div>
            
            {request.status === 'fulfilled' && (
              <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6">
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Fulfillment Details</h2>
                <div className="mt-2">
                  <div>
                    <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Fulfilled By</h3>
                    <p className="mt-1 text-sm text-gray-900 dark:text-white">{request.fulfilledByName || 'Anonymous'}</p>
                  </div>
                  {request.fulfilledAt && (
                    <div className="mt-4">
                      <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Fulfilled On</h3>
                      <p className="mt-1 text-sm text-gray-900 dark:text-white">{formatDate(request.fulfilledAt)}</p>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
          
          <div>
            <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Requested By</h2>
              <div className="flex items-center">
                <div className="h-12 w-12 rounded-full bg-gray-200 dark:bg-gray-700 flex items-center justify-center text-lg font-semibold text-gray-600 dark:text-gray-300">
                  {request.ngoName.charAt(0)}
                </div>
                <div className="ml-4">
                  <h3 className="text-lg font-medium text-gray-900 dark:text-white">{request.ngoName}</h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">Verified NGO</p>
                </div>
              </div>
              
              <div className="mt-6">
                <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Contact</h3>
                <Button variant="outline" className="w-full mt-2">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-2">
                    <path d="M3 4a2 2 0 00-2 2v1.161l8.441 4.221a1.25 1.25 0 001.118 0L19 7.162V6a2 2 0 00-2-2H3z" />
                    <path d="M19 8.839l-7.77 3.885a2.75 2.75 0 01-2.46 0L1 8.839V14a2 2 0 002 2h14a2 2 0 002-2V8.839z" />
                  </svg>
                  Contact NGO
                </Button>
              </div>
              
              {userProfile?.role === 'ngo' && userProfile.uid === request.ngoId && request.status === 'open' && (
                <div className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
                  <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-3">Request Management</h3>
                  <div className="flex flex-col space-y-2">
                    <Button variant="outline" className="w-full">
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-2">
                        <path d="M5.433 13.917l1.262-3.155A4 4 0 017.58 9.42l6.92-6.918a2.121 2.121 0 013 3l-6.92 6.918c-.383.383-.84.685-1.343.886l-3.154 1.262a.5.5 0 01-.65-.65z" />
                        <path d="M3.5 5.75c0-.69.56-1.25 1.25-1.25H10A.75.75 0 0010 3H4.75A2.75 2.75 0 002 5.75v9.5A2.75 2.75 0 004.75 18h9.5A2.75 2.75 0 0017 15.25V10a.75.75 0 00-1.5 0v5.25c0 .69-.56 1.25-1.25 1.25h-9.5c-.69 0-1.25-.56-1.25-1.25v-9.5z" />
                      </svg>
                      Edit Request
                    </Button>
                    <Button variant="outline" className="w-full text-red-600 border-red-600 hover:bg-red-50 dark:hover:bg-red-900/20">
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-2">
                        <path fillRule="evenodd" d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l-.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z" clipRule="evenodd" />
                      </svg>
                      Close Request
                    </Button>
                  </div>
                </div>
              )}
            </div>
            
            <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 mt-6">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Similar Requests</h2>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Looking for more ways to help? Check out similar requests from NGOs.
              </p>
              <Link href={`/requests?filter=${request.category}`}>
                <Button variant="outline" className="w-full mt-4">
                  View Similar Requests
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </>
  );
} 