import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/context/AuthContext';
import { UserRole } from '@/context/AuthContext';
import { Button } from '@/components/ui/Button';
import { motion } from 'framer-motion';
import toast from 'react-hot-toast';

export default function SignupForm() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [name, setName] = useState('');
  const [role, setRole] = useState<UserRole>('donor');
  const [isLoading, setIsLoading] = useState(false);
  
  const { signup, googleSignIn } = useAuth();
  const router = useRouter();
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    // Validate form
    if (password !== confirmPassword) {
      toast.error('Passwords do not match');
      setIsLoading(false);
      return;
    }
    
    try {
      await signup(email, password, role, name);
      toast.success('Account created successfully!');
      router.push('/dashboard');
    } catch (error: any) {
      toast.error(error.message || 'Failed to create account');
    } finally {
      setIsLoading(false);
    }
  };
  
  const handleGoogleSignIn = async () => {
    try {
      setIsLoading(true);
      await googleSignIn();
      router.push('/dashboard');
    } catch (error: any) {
      toast.error(error.message || 'Failed to sign in with Google');
    } finally {
      setIsLoading(false);
    }
  };
  
  return (
    <motion.div 
      className="max-w-md w-full mx-auto p-6 bg-white dark:bg-zinc-800 rounded-xl shadow-md"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
    >
      <h2 className="text-2xl font-bold text-center mb-6">Create Your Account</h2>
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="name" className="block text-sm font-medium mb-1">
            Full Name
          </label>
          <input
            id="name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
            required
          />
        </div>
        
        <div>
          <label htmlFor="email" className="block text-sm font-medium mb-1">
            Email Address
          </label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
            required
          />
        </div>
        
        <div>
          <label htmlFor="password" className="block text-sm font-medium mb-1">
            Password
          </label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
            required
            minLength={6}
          />
        </div>
        
        <div>
          <label htmlFor="confirmPassword" className="block text-sm font-medium mb-1">
            Confirm Password
          </label>
          <input
            id="confirmPassword"
            type="password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
            required
            minLength={6}
          />
        </div>
        
        <div>
          <label htmlFor="role" className="block text-sm font-medium mb-1">
            I am a
          </label>
          <select
            id="role"
            value={role}
            onChange={(e) => setRole(e.target.value as UserRole)}
            className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-primary"
            required
          >
            <option value="donor">Donor</option>
            <option value="ngo">NGO Representative</option>
          </select>
        </div>
        
        <Button type="submit" className="w-full" isLoading={isLoading}>
          Create Account
        </Button>
      </form>
      
      <div className="mt-4 text-center">
        <p className="text-sm">or</p>
      </div>
      
      <Button
        type="button"
        variant="outline"
        className="w-full mt-4"
        onClick={handleGoogleSignIn}
        isLoading={isLoading}
      >
        <svg className="w-5 h-5 mr-2" viewBox="0 0 24 24">
          <path
            fill="currentColor"
            d="M12.545,12.151L12.545,12.151c0,1.054-0.699,2.002-1.753,2.002H7.871c-1.054,0-1.909-0.948-1.909-2.002v-4.185   c0-1.054,0.855-1.911,1.909-1.911h2.921c1.054,0,1.753,0.856,1.753,1.911V12.151z M14.027,8.195v3.856   c0,1.876-1.511,3.399-3.375,3.399H7.871c-1.863,0-3.375-1.523-3.375-3.399V8.195c0-1.876,1.512-3.399,3.375-3.399h2.781   C12.516,4.796,14.027,6.319,14.027,8.195z"
          />
          <path
            fill="currentColor"
            d="M21.347,8.195v3.856c0,1.876-1.512,3.399-3.375,3.399h-2.781c-1.864,0-3.375-1.523-3.375-3.399V8.195   c0-1.876,1.511-3.399,3.375-3.399h2.781C19.835,4.796,21.347,6.319,21.347,8.195z M19.882,12.151L19.882,12.151   c0,1.054-0.855,2.002-1.909,2.002h-2.781c-1.054,0-1.91-0.948-1.91-2.002v-4.185c0-1.054,0.855-1.911,1.91-1.911h2.781   c1.054,0,1.909,0.856,1.909,1.911V12.151z"
          />
          <path
            fill="currentColor"
            d="M14.027,19.811L14.027,19.811c0,1.054-0.855,1.909-1.909,1.909H7.871c-1.054,0-1.91-0.855-1.91-1.909v-2.781   c0-1.054,0.855-1.909,1.91-1.909h4.247c1.054,0,1.909,0.855,1.909,1.909V19.811z M19.882,19.811L19.882,19.811   c0,1.054-0.855,1.909-1.909,1.909h-2.781c-1.054,0-1.91-0.855-1.91-1.909v-2.781c0-1.054,0.855-1.909,1.91-1.909h2.781   c1.054,0,1.909,0.855,1.909,1.909V19.811z"
          />
        </svg>
        Continue with Google
      </Button>
      
      <p className="mt-6 text-center text-sm">
        Already have an account?{' '}
        <Link href="/auth/login" className="text-primary font-medium hover:underline">
          Sign in
        </Link>
      </p>
    </motion.div>
  );
} 