'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import Navbar from '@/components/ui/Navbar';
import { Button } from '@/components/ui/Button';
import { getPendingNgoVerifications, approveNgoVerification, rejectNgoVerification } from '@/lib/firestore';
import { toast } from 'react-hot-toast';
import Link from 'next/link';
import { formatDistance } from 'date-fns';

interface VerificationRequest {
  id: string;
  uid: string;
  status: 'pending' | 'approved' | 'rejected';
  submittedAt: any;
  registrationNumber: string;
  registrationDocument: string;
  taxExemptionDocument?: string;
  website?: string;
  focusAreas?: string[];
  socialLinks?: {
    facebook?: string;
    twitter?: string;
    instagram?: string;
    linkedin?: string;
  };
  ngoName?: string;
  ngoEmail?: string;
}

export default function AdminVerificationsPage() {
  const { userProfile } = useAuth();
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [verificationRequests, setVerificationRequests] = useState<VerificationRequest[]>([]);
  const [selectedRequest, setSelectedRequest] = useState<VerificationRequest | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [showRejectDialog, setShowRejectDialog] = useState(false);
  const [processing, setProcessing] = useState(false);

  useEffect(() => {
    async function loadVerificationRequests() {
      if (!userProfile) {
        return;
      }
      
      if (userProfile.role !== 'admin') {
        return;
      }
      
      try {
        setLoading(true);
        const requests = await getPendingNgoVerifications(20);
        setVerificationRequests(requests);
      } catch (error) {
        console.error('Error loading verification requests:', error);
        toast.error('Failed to load verification requests');
      } finally {
        setLoading(false);
      }
    }
    
    loadVerificationRequests();
  }, [userProfile]);

  const handleApprove = async (request: VerificationRequest) => {
    if (!confirm('Are you sure you want to approve this NGO verification?')) {
      return;
    }
    
    try {
      setProcessing(true);
      await approveNgoVerification(request.uid, request.id);
      
      // Update local state
      setVerificationRequests(prev => prev.filter(req => req.id !== request.id));
      
      toast.success('NGO verification approved successfully');
      
      if (selectedRequest?.id === request.id) {
        setSelectedRequest(null);
      }
    } catch (error) {
      console.error('Error approving verification:', error);
      toast.error('Failed to approve verification');
    } finally {
      setProcessing(false);
    }
  };

  const handleReject = async () => {
    if (!selectedRequest) return;
    
    if (!rejectReason.trim()) {
      toast.error('Please provide a reason for rejection');
      return;
    }
    
    try {
      setProcessing(true);
      await rejectNgoVerification(selectedRequest.uid, selectedRequest.id, rejectReason);
      
      // Update local state
      setVerificationRequests(prev => 
        prev.filter(req => req.id !== selectedRequest.id)
      );
      
      toast.success('NGO verification rejected');
      setShowRejectDialog(false);
      setSelectedRequest(null);
      setRejectReason('');
    } catch (error) {
      console.error('Error rejecting verification:', error);
      toast.error('Failed to reject verification');
    } finally {
      setProcessing(false);
    }
  };

  const openRejectDialog = (request: VerificationRequest) => {
    setSelectedRequest(request);
    setShowRejectDialog(true);
  };

  const viewRequestDetails = (request: VerificationRequest) => {
    setSelectedRequest(request);
    setShowRejectDialog(false);
  };

  if (!userProfile) {
    return (
      <>
        <Navbar />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="text-center">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Authentication Required</h2>
            <p className="mt-2 text-gray-600 dark:text-gray-300">
              You need to be logged in to access this page
            </p>
            <Link href="/auth/login">
              <Button className="mt-4">Log In</Button>
            </Link>
          </div>
        </div>
      </>
    );
  }

  if (userProfile.role !== 'admin') {
    return (
      <>
        <Navbar />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="text-center">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Access Denied</h2>
            <p className="mt-2 text-gray-600 dark:text-gray-300">
              Only administrators can access this page
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
        <div className="flex flex-col md:flex-row gap-8">
          {/* Left side: Verification requests list */}
          <div className="w-full md:w-1/3 bg-white dark:bg-zinc-800 rounded-lg shadow-sm overflow-hidden">
            <div className="p-4 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                Pending NGO Verifications
              </h2>
            </div>
            
            {loading ? (
              <div className="flex flex-col items-center justify-center p-6">
                <div className="w-8 h-8 rounded-full border-2 border-primary border-t-transparent animate-spin"></div>
                <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">Loading requests...</p>
              </div>
            ) : verificationRequests.length === 0 ? (
              <div className="p-6 text-center">
                <p className="text-gray-500 dark:text-gray-400">No pending verification requests</p>
              </div>
            ) : (
              <ul className="divide-y divide-gray-200 dark:divide-gray-700 max-h-[600px] overflow-y-auto">
                {verificationRequests.map(request => (
                  <li 
                    key={request.id}
                    className={`p-4 cursor-pointer hover:bg-gray-50 dark:hover:bg-zinc-700/50 transition-colors ${
                      selectedRequest?.id === request.id ? 'bg-gray-100 dark:bg-zinc-700/80' : ''
                    }`}
                    onClick={() => viewRequestDetails(request)}
                  >
                    <div className="flex justify-between">
                      <div>
                        <h3 className="font-medium text-gray-900 dark:text-white">
                          {request.ngoName || 'NGO Organization'}
                        </h3>
                        <p className="text-sm text-gray-500 dark:text-gray-400">
                          {request.registrationNumber}
                        </p>
                      </div>
                      <div className="text-right">
                        <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400">
                          Pending
                        </span>
                        <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                          {request.submittedAt?.toDate ? 
                            formatDistance(request.submittedAt.toDate(), new Date(), { addSuffix: true }) : 
                            'Recently'}
                        </p>
                      </div>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </div>
          
          {/* Right side: Selected verification details */}
          <div className="w-full md:w-2/3 bg-white dark:bg-zinc-800 rounded-lg shadow-sm overflow-hidden">
            {!selectedRequest ? (
              <div className="flex flex-col items-center justify-center p-12">
                <div className="text-center">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" strokeWidth={1.5} stroke="currentColor" className="w-12 h-12 mx-auto text-gray-400 dark:text-gray-500 mb-4">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z" />
                  </svg>
                  <h3 className="text-lg font-medium text-gray-900 dark:text-white">No Verification Selected</h3>
                  <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                    Select a verification request from the list to view details
                  </p>
                </div>
              </div>
            ) : (
              <div className="p-6">
                <div className="flex justify-between items-start mb-6">
                  <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
                    Verification Details
                  </h2>
                  <div className="flex space-x-2">
                    <Button
                      onClick={() => openRejectDialog(selectedRequest)}
                      variant="outline"
                      disabled={processing}
                      className="border-red-300 text-red-600 hover:bg-red-50 dark:border-red-700 dark:text-red-400 dark:hover:bg-red-950/30"
                    >
                      Reject
                    </Button>
                    <Button
                      onClick={() => handleApprove(selectedRequest)}
                      disabled={processing}
                    >
                      Approve
                    </Button>
                  </div>
                </div>
                
                <div className="space-y-6">
                  <div>
                    <h3 className="text-lg font-medium text-gray-900 dark:text-white">
                      Organization Information
                    </h3>
                    <div className="mt-3 bg-gray-50 dark:bg-zinc-700/30 rounded-lg p-4">
                      <dl className="grid grid-cols-1 md:grid-cols-2 gap-x-4 gap-y-3">
                        <div>
                          <dt className="text-sm font-medium text-gray-500 dark:text-gray-400">Organization Name</dt>
                          <dd className="mt-1 text-sm text-gray-900 dark:text-white">{selectedRequest.ngoName || 'Not specified'}</dd>
                        </div>
                        <div>
                          <dt className="text-sm font-medium text-gray-500 dark:text-gray-400">Email</dt>
                          <dd className="mt-1 text-sm text-gray-900 dark:text-white">{selectedRequest.ngoEmail || 'Not specified'}</dd>
                        </div>
                        <div>
                          <dt className="text-sm font-medium text-gray-500 dark:text-gray-400">Registration Number</dt>
                          <dd className="mt-1 text-sm text-gray-900 dark:text-white">{selectedRequest.registrationNumber}</dd>
                        </div>
                        <div>
                          <dt className="text-sm font-medium text-gray-500 dark:text-gray-400">Website</dt>
                          <dd className="mt-1 text-sm text-gray-900 dark:text-white">
                            {selectedRequest.website ? (
                              <a 
                                href={selectedRequest.website} 
                                target="_blank"
                                rel="noopener noreferrer"
                                className="text-primary hover:underline"
                              >
                                {selectedRequest.website}
                              </a>
                            ) : (
                              'Not provided'
                            )}
                          </dd>
                        </div>
                        <div className="col-span-2">
                          <dt className="text-sm font-medium text-gray-500 dark:text-gray-400">Focus Areas</dt>
                          <dd className="mt-1 text-sm text-gray-900 dark:text-white">
                            {selectedRequest.focusAreas && selectedRequest.focusAreas.length > 0 ? (
                              <div className="flex flex-wrap gap-2">
                                {selectedRequest.focusAreas.map((area, index) => (
                                  <span 
                                    key={index}
                                    className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200"
                                  >
                                    {area}
                                  </span>
                                ))}
                              </div>
                            ) : (
                              'Not specified'
                            )}
                          </dd>
                        </div>
                      </dl>
                    </div>
                  </div>
                  
                  <div>
                    <h3 className="text-lg font-medium text-gray-900 dark:text-white">
                      Document Verification
                    </h3>
                    <div className="mt-3 space-y-4">
                      <div className="bg-gray-50 dark:bg-zinc-700/30 rounded-lg p-4">
                        <div className="flex justify-between items-center mb-2">
                          <div className="text-sm font-medium text-gray-900 dark:text-white">Registration Certificate</div>
                          <a 
                            href={selectedRequest.registrationDocument}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-xs font-medium text-primary hover:underline"
                          >
                            View Document
                          </a>
                        </div>
                        <p className="text-xs text-gray-500 dark:text-gray-400">
                          {selectedRequest.registrationDocument}
                        </p>
                      </div>
                      
                      {selectedRequest.taxExemptionDocument && (
                        <div className="bg-gray-50 dark:bg-zinc-700/30 rounded-lg p-4">
                          <div className="flex justify-between items-center mb-2">
                            <div className="text-sm font-medium text-gray-900 dark:text-white">Tax Exemption Certificate</div>
                            <a 
                              href={selectedRequest.taxExemptionDocument}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="text-xs font-medium text-primary hover:underline"
                            >
                              View Document
                            </a>
                          </div>
                          <p className="text-xs text-gray-500 dark:text-gray-400">
                            {selectedRequest.taxExemptionDocument}
                          </p>
                        </div>
                      )}
                    </div>
                  </div>
                  
                  {selectedRequest.socialLinks && Object.values(selectedRequest.socialLinks).some(link => link) && (
                    <div>
                      <h3 className="text-lg font-medium text-gray-900 dark:text-white">
                        Social Media Presence
                      </h3>
                      <div className="mt-3 bg-gray-50 dark:bg-zinc-700/30 rounded-lg p-4">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                          {selectedRequest.socialLinks.facebook && (
                            <div>
                              <dt className="text-sm font-medium text-gray-500 dark:text-gray-400">Facebook</dt>
                              <dd className="mt-1 text-sm text-gray-900 dark:text-white">
                                <a 
                                  href={selectedRequest.socialLinks.facebook} 
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="text-primary hover:underline"
                                >
                                  View Profile
                                </a>
                              </dd>
                            </div>
                          )}
                          
                          {selectedRequest.socialLinks.twitter && (
                            <div>
                              <dt className="text-sm font-medium text-gray-500 dark:text-gray-400">Twitter</dt>
                              <dd className="mt-1 text-sm text-gray-900 dark:text-white">
                                <a 
                                  href={selectedRequest.socialLinks.twitter} 
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="text-primary hover:underline"
                                >
                                  View Profile
                                </a>
                              </dd>
                            </div>
                          )}
                          
                          {selectedRequest.socialLinks.instagram && (
                            <div>
                              <dt className="text-sm font-medium text-gray-500 dark:text-gray-400">Instagram</dt>
                              <dd className="mt-1 text-sm text-gray-900 dark:text-white">
                                <a 
                                  href={selectedRequest.socialLinks.instagram} 
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="text-primary hover:underline"
                                >
                                  View Profile
                                </a>
                              </dd>
                            </div>
                          )}
                          
                          {selectedRequest.socialLinks.linkedin && (
                            <div>
                              <dt className="text-sm font-medium text-gray-500 dark:text-gray-400">LinkedIn</dt>
                              <dd className="mt-1 text-sm text-gray-900 dark:text-white">
                                <a 
                                  href={selectedRequest.socialLinks.linkedin} 
                                  target="_blank"
                                  rel="noopener noreferrer"
                                  className="text-primary hover:underline"
                                >
                                  View Profile
                                </a>
                              </dd>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
      
      {/* Reject Dialog */}
      {showRejectDialog && selectedRequest && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-lg max-w-md w-full p-6">
            <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-4">
              Reject Verification Request
            </h3>
            <p className="text-sm text-gray-500 dark:text-gray-400 mb-4">
              Please provide a reason for rejecting this verification request. This will be shared with the NGO.
            </p>
            <textarea
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900 h-32"
              placeholder="Enter rejection reason..."
            ></textarea>
            <div className="mt-4 flex justify-end space-x-3">
              <Button
                onClick={() => {
                  setShowRejectDialog(false);
                  setRejectReason('');
                }}
                variant="outline"
                disabled={processing}
              >
                Cancel
              </Button>
              <Button
                onClick={handleReject}
                disabled={processing || !rejectReason.trim()}
                className="bg-red-600 hover:bg-red-700 focus:ring-red-500"
              >
                Reject
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  );
} 