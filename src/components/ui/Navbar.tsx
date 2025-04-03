"use client"
import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/context/AuthContext';
import { useTheme } from '@/context/ThemeContext';
import { motion, AnimatePresence } from 'framer-motion';
import { Button } from './Button';

export default function Navbar() {
  const { currentUser, userProfile, logout } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [mounted, setMounted] = useState(false);
  
  // Use useEffect to safely check theme after mount
  useEffect(() => {
    setMounted(true);
  }, []);
  
  const handleLogout = async () => {
    try {
      await logout();
    } catch (error) {
      console.error('Failed to log out', error);
    }
  };

  const handleThemeToggle = () => {
    console.log('Theme toggle clicked');
    console.log('Current theme before toggle:', theme);
    toggleTheme();
  };
  
  // Don't render theme icons until mounted to prevent hydration mismatch
  const ThemeIcon = () => {
    if (!mounted) return null;
    
    return theme === 'dark' ? (
      // Sun icon - shown when in dark mode (clicking will switch to light)
      <svg 
        xmlns="http://www.w3.org/2000/svg" 
        fill="none" 
        viewBox="0 0 24 24" 
        strokeWidth={1.5} 
        stroke="currentColor" 
        className="w-6 h-6"
      >
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-4.773-4.227-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z" />
      </svg>
    ) : (
      // Moon icon - shown when in light mode (clicking will switch to dark)
      <svg 
        xmlns="http://www.w3.org/2000/svg" 
        fill="none" 
        viewBox="0 0 24 24" 
        strokeWidth={1.5} 
        stroke="currentColor" 
        className="w-6 h-6"
      >
        <path strokeLinecap="round" strokeLinejoin="round" d="M21.752 15.002A9.72 9.72 0 0 1 18 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 0 0 3 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 0 0 9.002-5.998Z" />
      </svg>
    );
  };
  
  // Mobile theme icon with smaller size
  const MobileThemeIcon = () => {
    if (!mounted) return null;
    
    return theme === 'dark' ? (
      // Sun icon - shown when in dark mode
      <svg 
        xmlns="http://www.w3.org/2000/svg" 
        fill="none" 
        viewBox="0 0 24 24" 
        strokeWidth={1.5} 
        stroke="currentColor" 
        className="w-5 h-5"
      >
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-4.773-4.227-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z" />
      </svg>
    ) : (
      // Moon icon - shown when in light mode
      <svg 
        xmlns="http://www.w3.org/2000/svg" 
        fill="none" 
        viewBox="0 0 24 24" 
        strokeWidth={1.5} 
        stroke="currentColor" 
        className="w-5 h-5"
      >
        <path strokeLinecap="round" strokeLinejoin="round" d="M21.752 15.002A9.72 9.72 0 0 1 18 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 0 0 3 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 0 0 9.002-5.998Z" />
      </svg>
    );
  };
  
  return (
    <nav className="bg-white dark:bg-zinc-800 shadow-sm sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex">
            <Link href="/" className="flex-shrink-0 flex items-center">
              <h1 className="text-2xl font-bold text-primary">DAANSETU</h1>
            </Link>
            <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
              <Link 
                href="/" 
                className="border-transparent text-gray-500 dark:text-gray-300 hover:border-primary hover:text-primary dark:hover:text-primary inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                Home
              </Link>
              <Link 
                href="/donations" 
                className="border-transparent text-gray-500 dark:text-gray-300 hover:border-primary hover:text-primary dark:hover:text-primary inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                Donations
              </Link>
              <Link 
                href="/about" 
                className="border-transparent text-gray-500 dark:text-gray-300 hover:border-primary hover:text-primary dark:hover:text-primary inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                About
              </Link>
              <Link 
                href="/contact" 
                className="border-transparent text-gray-500 dark:text-gray-300 hover:border-primary hover:text-primary dark:hover:text-primary inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium"
              >
                Contact
              </Link>
            </div>
          </div>
          <div className="hidden sm:ml-6 sm:flex sm:items-center sm:space-x-4">
            <button
              type="button"
              className="p-1 rounded-full text-gray-500 dark:text-gray-300 hover:text-primary dark:hover:text-primary focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
              onClick={handleThemeToggle}
              aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
            >
              <ThemeIcon />
            </button>
            
            {currentUser ? (
              <div className="relative">
                <button
                  className="flex text-sm bg-gray-100 dark:bg-gray-700 rounded-full focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
                  onClick={() => setIsProfileOpen(!isProfileOpen)}
                >
                  <img
                    className="h-8 w-8 rounded-full object-cover"
                    src={currentUser.photoURL || `https://ui-avatars.com/api/?name=${userProfile?.displayName || 'User'}&background=random`}
                    alt={userProfile?.displayName || 'User profile'}
                  />
                </button>
                
                <AnimatePresence>
                  {isProfileOpen && (
                    <motion.div
                      className="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg py-1 bg-white dark:bg-zinc-700 ring-1 ring-black ring-opacity-5 focus:outline-none"
                      initial={{ opacity: 0, scale: 0.95 }}
                      animate={{ opacity: 1, scale: 1 }}
                      exit={{ opacity: 0, scale: 0.95 }}
                      transition={{ duration: 0.1 }}
                    >
                      <div className="px-4 py-2 border-b border-gray-200 dark:border-gray-600">
                        <p className="text-sm font-medium">{userProfile?.displayName || 'User'}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400 truncate">{currentUser.email}</p>
                      </div>
                      <Link
                        href="/dashboard"
                        className="block px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-zinc-600"
                        onClick={() => setIsProfileOpen(false)}
                      >
                        Dashboard
                      </Link>
                      <Link
                        href="/profile"
                        className="block px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-zinc-600"
                        onClick={() => setIsProfileOpen(false)}
                      >
                        Your Profile
                      </Link>
                      <button
                        className="block w-full text-left px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-zinc-600"
                        onClick={() => {
                          handleLogout();
                          setIsProfileOpen(false);
                        }}
                      >
                        Sign out
                      </button>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            ) : (
              <>
                <Link href="/auth/login">
                  <Button variant="ghost">Log in</Button>
                </Link>
                <Link href="/auth/signup">
                  <Button>Sign up</Button>
                </Link>
              </>
            )}
          </div>
          
          <div className="flex items-center sm:hidden">
            <button
              type="button"
              className="p-1 mr-2 rounded-full text-gray-500 dark:text-gray-300 hover:text-primary dark:hover:text-primary focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
              onClick={handleThemeToggle}
              aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
            >
              <MobileThemeIcon />
            </button>
            
            <button
              className="inline-flex items-center justify-center p-2 rounded-md text-gray-500 dark:text-gray-300 hover:text-primary dark:hover:text-primary hover:bg-gray-100 dark:hover:bg-zinc-700 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-primary"
              onClick={() => setIsMenuOpen(!isMenuOpen)}
            >
              <span className="sr-only">Open main menu</span>
              {isMenuOpen ? (
                <svg
                  className="block h-6 w-6"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              ) : (
                <svg
                  className="block h-6 w-6"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth="2"
                    d="M4 6h16M4 12h16M4 18h16"
                  />
                </svg>
              )}
            </button>
          </div>
        </div>
      </div>
      
      <AnimatePresence>
        {isMenuOpen && (
          <motion.div
            className="sm:hidden"
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.2 }}
          >
            <div className="pt-2 pb-3 space-y-1">
              <Link 
                href="/"
                className="block pl-3 pr-4 py-2 border-l-4 border-transparent text-base font-medium text-gray-600 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-zinc-700 hover:border-primary hover:text-primary dark:hover:text-primary"
              >
                Home
              </Link>
              <Link 
                href="/donations"
                className="block pl-3 pr-4 py-2 border-l-4 border-transparent text-base font-medium text-gray-600 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-zinc-700 hover:border-primary hover:text-primary dark:hover:text-primary"
              >
                Donations
              </Link>
              <Link 
                href="/about"
                className="block pl-3 pr-4 py-2 border-l-4 border-transparent text-base font-medium text-gray-600 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-zinc-700 hover:border-primary hover:text-primary dark:hover:text-primary"
              >
                About
              </Link>
              <Link 
                href="/contact"
                className="block pl-3 pr-4 py-2 border-l-4 border-transparent text-base font-medium text-gray-600 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-zinc-700 hover:border-primary hover:text-primary dark:hover:text-primary"
              >
                Contact
              </Link>
            </div>
            
            <div className="pt-4 pb-3 border-t border-gray-200 dark:border-gray-600">
              {currentUser ? (
                <>
                  <div className="flex items-center px-4">
                    <div className="flex-shrink-0">
                      <img
                        className="h-10 w-10 rounded-full object-cover"
                        src={currentUser.photoURL || `https://ui-avatars.com/api/?name=${userProfile?.displayName || 'User'}&background=random`}
                        alt={userProfile?.displayName || 'User profile'}
                      />
                    </div>
                    <div className="ml-3">
                      <div className="text-base font-medium text-gray-800 dark:text-gray-200">{userProfile?.displayName || 'User'}</div>
                      <div className="text-sm font-medium text-gray-500 dark:text-gray-400 truncate">{currentUser.email}</div>
                    </div>
                  </div>
                  <div className="mt-3 space-y-1">
                    <Link 
                      href="/dashboard"
                      className="block px-4 py-2 text-base font-medium text-gray-600 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-zinc-700 hover:text-primary dark:hover:text-primary"
                      onClick={() => setIsMenuOpen(false)}
                    >
                      Dashboard
                    </Link>
                    <Link 
                      href="/profile"
                      className="block px-4 py-2 text-base font-medium text-gray-600 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-zinc-700 hover:text-primary dark:hover:text-primary"
                      onClick={() => setIsMenuOpen(false)}
                    >
                      Your Profile
                    </Link>
                    <button
                      className="block w-full text-left px-4 py-2 text-base font-medium text-gray-600 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-zinc-700 hover:text-primary dark:hover:text-primary"
                      onClick={() => {
                        handleLogout();
                        setIsMenuOpen(false);
                      }}
                    >
                      Sign out
                    </button>
                  </div>
                </>
              ) : (
                <div className="mt-3 space-y-1 px-2">
                  <Link 
                    href="/auth/login"
                    className="block px-4 py-2 text-base font-medium text-gray-600 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-zinc-700 hover:text-primary dark:hover:text-primary"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Log in
                  </Link>
                  <Link 
                    href="/auth/signup"
                    className="block px-4 py-2 text-base font-medium text-gray-600 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-zinc-700 hover:text-primary dark:hover:text-primary"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    Sign up
                  </Link>
                </div>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </nav>
  );
} 