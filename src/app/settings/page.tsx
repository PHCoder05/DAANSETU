'use client';

import { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import Navbar from '@/components/ui/Navbar';
import { Button } from '@/components/ui/Button';
import { toast } from 'react-hot-toast';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

export default function SettingsPage() {
  const { userProfile, logout, refreshUserProfile } = useAuth();
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState('');
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  // Handle changing password
  const handleChangePassword = async () => {
    router.push('/auth/reset-password');
  };

  // Handle logout from all devices
  const handleLogoutAllDevices = async () => {
    try {
      setLoading(true);
      await logout();
      toast.success('Logged out from all devices');
      router.push('/auth/login');
    } catch (error) {
      console.error('Error logging out:', error);
      toast.error('Failed to log out from all devices');
    } finally {
      setLoading(false);
    }
  };

  // Handle account deletion
  const handleDeleteAccount = async () => {
    if (deleteConfirm !== 'DELETE') {
      toast.error('Please type DELETE to confirm account deletion');
      return;
    }

    try {
      setLoading(true);
      // Account deletion would go here
      toast.success('Account deletion request submitted');
      setDeleteConfirm('');
      setShowDeleteConfirm(false);
      await logout();
      router.push('/');
    } catch (error) {
      console.error('Error deleting account:', error);
      toast.error('Failed to delete account');
    } finally {
      setLoading(false);
    }
  };

  if (!userProfile) {
    return (
      <>
        <Navbar />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="text-center">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Authentication Required</h2>
            <p className="mt-2 text-gray-600 dark:text-gray-300">
              You need to be logged in to view your settings
            </p>
            <Link href="/auth/login">
              <Button className="mt-4">Log In</Button>
            </Link>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <Navbar />
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-1">Settings</h1>
          <p className="text-gray-600 dark:text-gray-300">
            Manage your account settings and preferences
          </p>
        </div>
        
        <div className="space-y-8">
          {/* Account Settings */}
          <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm overflow-hidden">
            <div className="px-6 py-5 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-lg font-medium text-gray-900 dark:text-white">Account Settings</h2>
            </div>
            
            <div className="px-6 py-5">
              <div className="space-y-6">
                <div>
                  <div className="flex justify-between items-center">
                    <div>
                      <h3 className="text-sm font-medium text-gray-900 dark:text-white">Profile Information</h3>
                      <p className="text-sm text-gray-500 dark:text-gray-400">
                        Update your profile information
                      </p>
                    </div>
                    <Link href="/profile">
                      <Button variant="outline">
                        Edit Profile
                      </Button>
                    </Link>
                  </div>
                </div>
                
                <div className="border-t border-gray-200 dark:border-gray-700 pt-6">
                  <div className="flex justify-between items-center">
                    <div>
                      <h3 className="text-sm font-medium text-gray-900 dark:text-white">Password</h3>
                      <p className="text-sm text-gray-500 dark:text-gray-400">
                        Change your password
                      </p>
                    </div>
                    <Button 
                      variant="outline"
                      onClick={handleChangePassword}
                    >
                      Change Password
                    </Button>
                  </div>
                </div>
                
                <div className="border-t border-gray-200 dark:border-gray-700 pt-6">
                  <div className="flex justify-between items-center">
                    <div>
                      <h3 className="text-sm font-medium text-gray-900 dark:text-white">Sessions</h3>
                      <p className="text-sm text-gray-500 dark:text-gray-400">
                        Log out from all devices
                      </p>
                    </div>
                    <Button 
                      variant="outline"
                      onClick={handleLogoutAllDevices}
                      disabled={loading}
                    >
                      {loading ? 'Processing...' : 'Logout from all devices'}
                    </Button>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          {/* Notification Settings */}
          <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm overflow-hidden">
            <div className="px-6 py-5 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-lg font-medium text-gray-900 dark:text-white">Notification Settings</h2>
            </div>
            
            <div className="px-6 py-5">
              <div className="space-y-6">
                <div>
                  <h3 className="text-sm font-medium text-gray-900 dark:text-white mb-4">Email Notifications</h3>
                  
                  <div className="space-y-4">
                    <div className="flex items-start">
                      <div className="flex items-center h-5">
                        <input
                          id="donations"
                          name="donations"
                          type="checkbox"
                          defaultChecked={true}
                          className="focus:ring-primary h-4 w-4 text-primary border-gray-300 rounded"
                        />
                      </div>
                      <div className="ml-3 text-sm">
                        <label htmlFor="donations" className="font-medium text-gray-700 dark:text-gray-300">Donation Updates</label>
                        <p className="text-gray-500 dark:text-gray-400">Get notified when your donations are claimed or delivered.</p>
                      </div>
                    </div>
                    
                    <div className="flex items-start">
                      <div className="flex items-center h-5">
                        <input
                          id="requests"
                          name="requests"
                          type="checkbox"
                          defaultChecked={true}
                          className="focus:ring-primary h-4 w-4 text-primary border-gray-300 rounded"
                        />
                      </div>
                      <div className="ml-3 text-sm">
                        <label htmlFor="requests" className="font-medium text-gray-700 dark:text-gray-300">Request Updates</label>
                        <p className="text-gray-500 dark:text-gray-400">Get notified when your requests are fulfilled.</p>
                      </div>
                    </div>
                    
                    <div className="flex items-start">
                      <div className="flex items-center h-5">
                        <input
                          id="system"
                          name="system"
                          type="checkbox"
                          defaultChecked={true}
                          className="focus:ring-primary h-4 w-4 text-primary border-gray-300 rounded"
                        />
                      </div>
                      <div className="ml-3 text-sm">
                        <label htmlFor="system" className="font-medium text-gray-700 dark:text-gray-300">System Updates</label>
                        <p className="text-gray-500 dark:text-gray-400">Get notified about important system updates and announcements.</p>
                      </div>
                    </div>
                  </div>
                </div>
                
                <div className="flex justify-end">
                  <Button>
                    Save Preferences
                  </Button>
                </div>
              </div>
            </div>
          </div>
          
          {/* Danger Zone */}
          <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm overflow-hidden">
            <div className="px-6 py-5 border-b border-gray-200 dark:border-gray-700 bg-red-50 dark:bg-red-900/10">
              <h2 className="text-lg font-medium text-red-700 dark:text-red-400">Danger Zone</h2>
            </div>
            
            <div className="px-6 py-5">
              <div className="space-y-6">
                <div>
                  <div className="flex justify-between items-center">
                    <div>
                      <h3 className="text-sm font-medium text-gray-900 dark:text-white">Delete Account</h3>
                      <p className="text-sm text-gray-500 dark:text-gray-400">
                        Permanently delete your account and all your data
                      </p>
                    </div>
                    <Button 
                      variant="outline"
                      className="text-red-600 border-red-300 hover:bg-red-50 dark:hover:bg-red-900/20"
                      onClick={() => setShowDeleteConfirm(!showDeleteConfirm)}
                    >
                      Delete Account
                    </Button>
                  </div>
                  
                  {showDeleteConfirm && (
                    <div className="mt-4 p-4 bg-red-50 dark:bg-red-900/20 rounded-md">
                      <p className="text-sm text-red-600 dark:text-red-400 mb-3">
                        This action cannot be undone. Please type <strong>DELETE</strong> to confirm.
                      </p>
                      <div className="flex space-x-3">
                        <input
                          type="text"
                          value={deleteConfirm}
                          onChange={(e) => setDeleteConfirm(e.target.value)}
                          className="block px-4 py-2 border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-red-500 focus:border-red-500 bg-white dark:bg-zinc-900 text-sm"
                          placeholder="Type DELETE to confirm"
                        />
                        <Button 
                          onClick={handleDeleteAccount}
                          disabled={loading || deleteConfirm !== 'DELETE'}
                          className="bg-red-600 hover:bg-red-700 text-white"
                        >
                          Confirm
                        </Button>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
} 