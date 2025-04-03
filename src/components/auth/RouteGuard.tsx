'use client';

import React, { ReactNode, useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import { UserRole } from '@/lib/firestore';
import { toast } from '@/components/ui/Toast';
import Link from 'next/link';

interface RouteGuardProps {
  children: ReactNode;
  requiredAuth?: boolean;
  allowedRoles?: UserRole[];
  redirectTo?: string;
}

/**
 * Route Guard component to protect routes based on authentication and user roles
 * 
 * @param children - The content to render if access is allowed
 * @param requiredAuth - Whether authentication is required for this route
 * @param allowedRoles - Array of roles allowed to access this route
 * @param redirectTo - Where to redirect if access is denied
 */
export default function RouteGuard({
  children,
  requiredAuth = true,
  allowedRoles = [],
  redirectTo = '/auth/login'
}: RouteGuardProps) {
  const { user, userProfile, loading: authLoading } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [authorized, setAuthorized] = useState(false);
  const [checking, setChecking] = useState(true);
  const [accessDenied, setAccessDenied] = useState(false);

  useEffect(() => {
    // Authentication check function
    const checkAuth = () => {
      // Still loading auth state, wait
      if (authLoading) return;

      // Auth required but no user
      if (requiredAuth && !user) {
        toast.error('Please log in to access this page');
        router.push(redirectTo);
        return;
      }

      // Check role if specified and user exists
      if (user && userProfile && allowedRoles.length > 0) {
        if (!allowedRoles.includes(userProfile.role)) {
          setAccessDenied(true);
          toast.error('You do not have permission to access this page');
          return;
        }
      }

      // If we get here, access is allowed
      setAuthorized(true);
    };

    // Check auth status when component mounts or route changes
    checkAuth();
    
    // Set checking to false after a short delay
    const timer = setTimeout(() => setChecking(false), 500);
    
    return () => clearTimeout(timer);
  }, [user, userProfile, authLoading, requiredAuth, allowedRoles, redirectTo, router, pathname]);

  // Display a loading state
  if (checking || authLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen p-4">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
        <p className="mt-4 text-center text-gray-600 dark:text-gray-300">
          Loading, please wait...
        </p>
      </div>
    );
  }

  // Display an access denied message
  if (accessDenied) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen p-4 text-center">
        <div className="rounded-full bg-red-100 dark:bg-red-900/20 p-4 mb-4">
          <svg 
            xmlns="http://www.w3.org/2000/svg" 
            className="h-12 w-12 text-red-500 dark:text-red-400" 
            fill="none" 
            viewBox="0 0 24 24" 
            stroke="currentColor"
          >
            <path 
              strokeLinecap="round" 
              strokeLinejoin="round" 
              strokeWidth={2} 
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" 
            />
          </svg>
        </div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Access Denied</h1>
        <p className="text-gray-600 dark:text-gray-300 mb-6 max-w-md">
          {userProfile 
            ? `You don't have permission to access this page. This area is restricted to ${allowedRoles.join(' or ')} users.`
            : 'You need to be logged in to access this page.'}
        </p>
        <div className="space-x-4">
          <Link 
            href={userProfile ? '/' : '/auth/login'} 
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
          >
            {userProfile ? 'Go to Homepage' : 'Log In'}
          </Link>
          {userProfile && (
            <button 
              onClick={() => router.back()}
              className="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-200 bg-white dark:bg-zinc-800 hover:bg-gray-50 dark:hover:bg-zinc-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
            >
              Go Back
            </button>
          )}
        </div>
      </div>
    );
  }

  // If authorized, render children
  return authorized ? <>{children}</> : null;
} 