'use client';

import React, { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/Button';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { seedDatabase, seedTestData } from '@/lib/seedDatabase';
import { toast } from 'react-hot-toast';

export default function AdminDashboard() {
  const { userProfile } = useAuth();
  const [isSeeding, setIsSeeding] = useState(false);

  // Mock data for pending NGO verifications
  const pendingNgos = [
    {
      id: '1',
      name: 'Children First Foundation',
      email: 'info@childrenfirst.org',
      phone: '+91 9876543210',
      appliedAt: Date.now() - 3 * 24 * 60 * 60 * 1000, // 3 days ago
      documents: ['registration.pdf', 'tax_exempt.pdf'],
    },
    {
      id: '2',
      name: 'Green Earth Initiative',
      email: 'contact@greenearthinitiative.org',
      phone: '+91 9876543211',
      appliedAt: Date.now() - 1 * 24 * 60 * 60 * 1000, // 1 day ago
      documents: ['registration.pdf', 'annual_report.pdf', 'certificate.pdf'],
    },
  ];

  // Mock data for recent users
  const recentUsers = [
    {
      id: '101',
      name: 'Rahul Sharma',
      email: 'rahul.sharma@example.com',
      role: 'donor',
      joinedAt: Date.now() - 2 * 24 * 60 * 60 * 1000, // 2 days ago
    },
    {
      id: '102',
      name: 'Hope NGO',
      email: 'contact@hopengoindia.org',
      role: 'ngo',
      joinedAt: Date.now() - 3 * 24 * 60 * 60 * 1000, // 3 days ago
      isVerified: true,
    },
    {
      id: '103',
      name: 'Priya Desai',
      email: 'priya.desai@example.com',
      role: 'donor',
      joinedAt: Date.now() - 4 * 24 * 60 * 60 * 1000, // 4 days ago
    },
  ];

  // Mock data for reported issues
  const reportedIssues = [
    {
      id: '201',
      title: 'Donation not received as described',
      reportedBy: 'Hope NGO',
      donationId: 'D-10045',
      reportedAt: Date.now() - 12 * 60 * 60 * 1000, // 12 hours ago
      status: 'pending',
      priority: 'high',
    },
    {
      id: '202',
      title: 'Inaccurate location data',
      reportedBy: 'Rahul Sharma',
      donationId: 'D-10032',
      reportedAt: Date.now() - 2 * 24 * 60 * 60 * 1000, // 2 days ago
      status: 'investigating',
      priority: 'medium',
    },
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
        duration: 0.4
      }
    }
  };

  const handleSeedDatabase = async () => {
    if (!userProfile || userProfile.role !== 'admin') {
      toast.error('You must be an admin to seed the database');
      return;
    }

    setIsSeeding(true);
    try {
      const success = await seedDatabase();
      if (success) {
        // Toast is already shown in seedDatabase function
      }
    } catch (error) {
      console.error('Error seeding database:', error);
      toast.error('Failed to seed database');
    } finally {
      setIsSeeding(false);
    }
  };

  const handleSeedTestData = async () => {
    try {
      setIsSeeding(true);
      const success = await seedTestData();
      if (success) {
        toast.success('Test data seeded successfully!');
      } else {
        toast.error('Failed to seed test data');
      }
    } catch (error) {
      console.error('Error seeding test data:', error);
      toast.error('An error occurred while seeding test data');
    } finally {
      setIsSeeding(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Admin Dashboard</h2>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Database Management</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-gray-600 dark:text-gray-300 mb-4">
              Seed the database with sample data for testing. This will create sample donations, requests, and users if they don't exist.
            </p>
            <Button
              onClick={handleSeedDatabase}
              disabled={isSeeding}
              className="w-full"
            >
              {isSeeding ? 'Seeding Database...' : 'Seed Database with Sample Data'}
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>User Management</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-gray-600 dark:text-gray-300 mb-4">
              View and manage users in the system. You can edit roles, delete users, or create new admin accounts.
            </p>
            <Button variant="outline" className="w-full">
              Manage Users
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Analytics</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-gray-600 dark:text-gray-300 mb-4">
              View platform analytics including donations, requests, user growth, and distribution metrics.
            </p>
            <Button variant="outline" className="w-full">
              View Analytics
            </Button>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>System Settings</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-gray-600 dark:text-gray-300 mb-4">
              Configure application settings, notification preferences, and security rules.
            </p>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Button variant="outline">
                Configure Notifications
              </Button>
              <Button variant="outline">
                Security Settings
              </Button>
              <Button variant="outline">
                API Configuration
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Stats Section */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-4">
        <div className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6">
          <div className="text-sm text-gray-500 dark:text-gray-400">Total Users</div>
          <div className="mt-2 text-3xl font-bold text-gray-900 dark:text-white">5,842</div>
        </div>
        <div className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6">
          <div className="text-sm text-gray-500 dark:text-gray-400">Verified NGOs</div>
          <div className="mt-2 text-3xl font-bold text-gray-900 dark:text-white">156</div>
        </div>
        <div className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6">
          <div className="text-sm text-gray-500 dark:text-gray-400">Active Donations</div>
          <div className="mt-2 text-3xl font-bold text-gray-900 dark:text-white">2,304</div>
        </div>
        <div className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6">
          <div className="text-sm text-gray-500 dark:text-gray-400">Pending Issues</div>
          <div className="mt-2 text-3xl font-bold text-gray-900 dark:text-white">8</div>
        </div>
      </div>
      
      {/* Quick Actions */}
      <div className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6">
        <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-4">Admin Actions</h3>
        <div className="flex flex-wrap gap-4">
          <Button>
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-2">
              <path fillRule="evenodd" d="M3 4.25A2.25 2.25 0 015.25 2h5.5A2.25 2.25 0 0113 4.25v2a.75.75 0 01-1.5 0v-2a.75.75 0 00-.75-.75h-5.5a.75.75 0 00-.75.75v11.5c0 .414.336.75.75.75h5.5a.75.75 0 00.75-.75v-2a.75.75 0 011.5 0v2A2.25 2.25 0 0110.75 18h-5.5A2.25 2.25 0 013 15.75V4.25z" clipRule="evenodd" />
              <path fillRule="evenodd" d="M6 10a.75.75 0 01.75-.75h9.546l-1.048-.943a.75.75 0 111.004-1.114l2.5 2.25a.75.75 0 010 1.114l-2.5 2.25a.75.75 0 11-1.004-1.114l1.048-.943H6.75A.75.75 0 016 10z" clipRule="evenodd" />
            </svg>
            Export Data
          </Button>
          <Button variant="outline">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-2">
              <path d="M10 3.75a2 2 0 10-4 0 2 2 0 004 0zM17.25 4.5a.75.75 0 000-1.5h-5.5a.75.75 0 000 1.5h5.5zM5 3.75a.75.75 0 01-.75.75h-1.5a.75.75 0 010-1.5h1.5a.75.75 0 01.75.75zM4.25 17a.75.75 0 000-1.5h-1.5a.75.75 0 000 1.5h1.5zM17.25 17a.75.75 0 000-1.5h-5.5a.75.75 0 000 1.5h5.5zM9 10a.75.75 0 01-.75.75h-5.5a.75.75 0 010-1.5h5.5A.75.75 0 019 10zM17.25 10.75a.75.75 0 000-1.5h-1.5a.75.75 0 000 1.5h1.5zM14 10a2 2 0 10-4 0 2 2 0 004 0zM10 16.25a2 2 0 10-4 0 2 2 0 004 0z" />
            </svg>
            System Settings
          </Button>
          <Button variant="outline">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-2">
              <path d="M4.214 3.227a.75.75 0 00-1.156-.956 8.97 8.97 0 00-1.856 3.826.75.75 0 001.466.316 7.47 7.47 0 011.546-3.186zM16.942 2.271a.75.75 0 00-1.157.956 7.47 7.47 0 011.547 3.186.75.75 0 001.466-.316 8.971 8.971 0 00-1.856-3.826z" />
              <path fillRule="evenodd" d="M10 2a6 6 0 00-6 6c0 1.887-.454 3.665-1.257 5.234a.75.75 0 00.515 1.076 32.94 32.94 0 003.256.508 3.5 3.5 0 006.972 0 32.933 32.933 0 003.256-.508.75.75 0 00.515-1.076A11.448 11.448 0 0116 8a6 6 0 00-6-6zm0 14.5a2 2 0 01-1.95-1.557 33.54 33.54 0 003.9 0A2 2 0 0110 16.5z" clipRule="evenodd" />
            </svg>
            Send Notifications
          </Button>
        </div>
      </div>
      
      {/* Pending NGO Verifications */}
      <div className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-medium text-gray-900 dark:text-white">Pending NGO Verifications</h3>
          <Link href="/admin/ngos" className="text-primary text-sm hover:underline">
            View All
          </Link>
        </div>
        
        <motion.div 
          className="space-y-4"
          variants={containerVariants}
          initial="hidden"
          animate="visible"
        >
          {pendingNgos.map((ngo) => (
            <motion.div 
              key={ngo.id}
              className="border border-gray-200 dark:border-gray-700 rounded-lg p-4"
              variants={itemVariants}
            >
              <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center">
                <div>
                  <h4 className="font-medium text-gray-900 dark:text-white">{ngo.name}</h4>
                  <div className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                    <div className="flex items-center">
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4 mr-1">
                        <path d="M3 4a2 2 0 00-2 2v1.161l8.441 4.221a1.25 1.25 0 001.118 0L19 7.162V6a2 2 0 00-2-2H3z" />
                        <path d="M19 8.839l-7.77 3.885a2.75 2.75 0 01-2.46 0L1 8.839V14a2 2 0 002 2h14a2 2 0 002-2V8.839z" />
                      </svg>
                      {ngo.email}
                    </div>
                    <div className="flex items-center mt-1">
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4 mr-1">
                        <path fillRule="evenodd" d="M2 3.5A1.5 1.5 0 013.5 2h1.148a1.5 1.5 0 011.465 1.175l.716 3.223a1.5 1.5 0 01-1.052 1.767l-.933.267c-.41.117-.643.555-.48.95a11.542 11.542 0 006.254 6.254c.395.163.833-.07.95-.48l.267-.933a1.5 1.5 0 011.767-1.052l3.223.716A1.5 1.5 0 0118 15.352V16.5a1.5 1.5 0 01-1.5 1.5H15c-1.149 0-2.263-.15-3.326-.43A13.022 13.022 0 012.43 8.326 13.019 13.019 0 012 5V3.5z" clipRule="evenodd" />
                      </svg>
                      {ngo.phone}
                    </div>
                  </div>
                  <div className="mt-2 text-sm">
                    <div className="flex items-center">
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4 mr-1 text-blue-500">
                        <path fillRule="evenodd" d="M15.621 4.379a3 3 0 00-4.242 0l-7 7a3 3 0 004.241 4.243h.001l.497-.5a.75.75 0 011.064 1.057l-.498.501-.002.002a4.5 4.5 0 01-6.364-6.364l7-7a4.5 4.5 0 016.368 6.36l-3.455 3.553A2.625 2.625 0 119.52 9.52l3.45-3.451a.75.75 0 111.061 1.06l-3.45 3.451a1.125 1.125 0 001.587 1.595l3.454-3.553a3 3 0 000-4.242z" clipRule="evenodd" />
                      </svg>
                      {ngo.documents.map((doc, index) => (
                        <span key={index} className="mr-2 text-blue-500 hover:underline cursor-pointer">
                          {doc}
                          {index < ngo.documents.length - 1 && ","}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>
                <div className="flex space-x-2 mt-3 sm:mt-0">
                  <Button size="sm" variant="outline" className="text-green-600 border-green-600 hover:bg-green-50 dark:hover:bg-green-900/20">
                    Approve
                  </Button>
                  <Button size="sm" variant="outline" className="text-red-600 border-red-600 hover:bg-red-50 dark:hover:bg-red-900/20">
                    Reject
                  </Button>
                  <Button size="sm" variant="outline">
                    View Details
                  </Button>
                </div>
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>
      
      {/* Recent Users */}
      <div className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-medium text-gray-900 dark:text-white">Recent Users</h3>
          <Link href="/admin/users" className="text-primary text-sm hover:underline">
            Manage Users
          </Link>
        </div>
        
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead className="bg-gray-50 dark:bg-zinc-700">
              <tr>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Name
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Email
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Role
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Joined
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white dark:bg-zinc-800 divide-y divide-gray-200 dark:divide-gray-700">
              {recentUsers.map((user) => (
                <motion.tr key={user.id} variants={itemVariants}>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">
                    {user.name}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">
                    {user.email}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                      user.role === 'admin' ? 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-300' : 
                      user.role === 'ngo' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300' : 
                      'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                    }`}>
                      {user.role}
                      {user.role === 'ngo' && user.isVerified && (
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4 ml-1 inline">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clipRule="evenodd" />
                        </svg>
                      )}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">
                    {new Date(user.joinedAt).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <button className="text-primary hover:text-primary-dark mr-3">
                      View
                    </button>
                    <button className="text-red-600 hover:text-red-900 dark:hover:text-red-400">
                      Suspend
                    </button>
                  </td>
                </motion.tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
      
      {/* Reported Issues */}
      <div className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-medium text-gray-900 dark:text-white">Reported Issues</h3>
          <Link href="/admin/issues" className="text-primary text-sm hover:underline">
            View All Issues
          </Link>
        </div>
        
        <motion.div 
          className="space-y-4"
          variants={containerVariants}
          initial="hidden"
          animate="visible"
        >
          {reportedIssues.map((issue) => (
            <motion.div 
              key={issue.id}
              className="border border-gray-200 dark:border-gray-700 rounded-lg p-4"
              variants={itemVariants}
            >
              <div className="flex justify-between items-start">
                <div>
                  <div className="flex items-center">
                    <h4 className="font-medium text-gray-900 dark:text-white">{issue.title}</h4>
                    <span className={`ml-2 px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                      issue.priority === 'high' ? 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300' : 
                      issue.priority === 'medium' ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300' : 
                      'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300'
                    }`}>
                      {issue.priority}
                    </span>
                  </div>
                  <div className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                    <span>Reported by: {issue.reportedBy}</span>
                    <span className="mx-2">•</span>
                    <span>Donation: <Link href={`/admin/donations/${issue.donationId}`} className="text-primary hover:underline">{issue.donationId}</Link></span>
                    <span className="mx-2">•</span>
                    <span>{new Date(issue.reportedAt).toLocaleString()}</span>
                  </div>
                </div>
                <div>
                  <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                    issue.status === 'pending' ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300' : 
                    issue.status === 'investigating' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300' : 
                    'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                  }`}>
                    {issue.status}
                  </span>
                </div>
              </div>
              <div className="mt-4 flex justify-end space-x-2">
                <Button size="sm" variant="outline">
                  View Details
                </Button>
                <Button size="sm">
                  Resolve
                </Button>
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>

      {/* System Health */}
      <div className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6">
        <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-4">System Health</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <h4 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Server Status</h4>
            <div className="flex items-center">
              <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
              <span className="text-gray-900 dark:text-white font-medium">All Systems Operational</span>
            </div>
            <div className="mt-2 space-y-2">
              <div className="flex justify-between text-sm">
                <span>API Response Time</span>
                <span className="font-medium">120ms</span>
              </div>
              <div className="flex justify-between text-sm">
                <span>Database Queries</span>
                <span className="font-medium">45.2k/day</span>
              </div>
              <div className="flex justify-between text-sm">
                <span>Storage Usage</span>
                <span className="font-medium">42% (4.2/10GB)</span>
              </div>
            </div>
          </div>
          
          <div>
            <h4 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Recent Activity</h4>
            <div className="space-y-2">
              <div className="text-sm">
                <div className="flex justify-between">
                  <span>New Users (24h)</span>
                  <span className="font-medium">+48</span>
                </div>
                <div className="mt-1 h-1.5 w-full bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div className="h-full bg-primary rounded-full" style={{ width: '38%' }}></div>
                </div>
              </div>
              <div className="text-sm">
                <div className="flex justify-between">
                  <span>New Donations (24h)</span>
                  <span className="font-medium">+126</span>
                </div>
                <div className="mt-1 h-1.5 w-full bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div className="h-full bg-blue-500 rounded-full" style={{ width: '65%' }}></div>
                </div>
              </div>
              <div className="text-sm">
                <div className="flex justify-between">
                  <span>Completed Transfers (24h)</span>
                  <span className="font-medium">+72</span>
                </div>
                <div className="mt-1 h-1.5 w-full bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div className="h-full bg-green-500 rounded-full" style={{ width: '45%' }}></div>
                </div>
              </div>
            </div>
          </div>
          
          <div>
            <h4 className="text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Security Overview</h4>
            <div className="space-y-2">
              <div className="flex items-center text-sm">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-2 text-green-500">
                  <path fillRule="evenodd" d="M16.403 12.652a3 3 0 000-5.304 3 3 0 00-3.75-3.751 3 3 0 00-5.305 0 3 3 0 00-3.751 3.75 3 3 0 000 5.305 3 3 0 003.75 3.751 3 3 0 005.305 0 3 3 0 003.751-3.75zm-2.546-4.46a.75.75 0 00-1.214-.883l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clipRule="evenodd" />
                </svg>
                <span>SSL Certificate Valid</span>
              </div>
              <div className="flex items-center text-sm">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-2 text-green-500">
                  <path fillRule="evenodd" d="M16.403 12.652a3 3 0 000-5.304 3 3 0 00-3.75-3.751 3 3 0 00-5.305 0 3 3 0 00-3.751 3.75 3 3 0 000 5.305 3 3 0 003.75 3.751 3 3 0 005.305 0 3 3 0 003.751-3.75zm-2.546-4.46a.75.75 0 00-1.214-.883l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clipRule="evenodd" />
                </svg>
                <span>Firebase Security Rules Updated</span>
              </div>
              <div className="flex items-center text-sm">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-2 text-yellow-500">
                  <path fillRule="evenodd" d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z" clipRule="evenodd" />
                </svg>
                <span>1 Security Alert (Low Severity)</span>
              </div>
              <div className="mt-3">
                <Button size="sm" variant="outline" className="w-full">
                  View Security Report
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg p-6">
        <h2 className="text-xl font-medium text-gray-900 dark:text-white mb-4">Admin Dashboard</h2>
        <p className="text-gray-600 dark:text-gray-300 mb-4">
          Welcome to the admin dashboard. Here you can manage the platform.
        </p>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-6">
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-lg">Development Tools</CardTitle>
            </CardHeader>
            <CardContent>
              <Button 
                onClick={handleSeedTestData}
                disabled={isSeeding}
                className="w-full"
              >
                {isSeeding ? 'Seeding...' : 'Seed Test Data'}
              </Button>
              <p className="text-xs text-gray-500 mt-2">
                This will create test users, donations, and requests for development purposes.
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
} 