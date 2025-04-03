'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import Navbar from '@/components/ui/Navbar';
import { Button } from '@/components/ui/Button';
import { createRequest } from '@/lib/firestore';
import Link from 'next/link';
import { toast } from 'react-hot-toast';

// Define request categories
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

export default function CreateRequest() {
  const router = useRouter();
  const { userProfile } = useAuth();
  
  // Initialize form state
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: '',
    quantity: '',
    beneficiaryCount: '',
    urgencyLevel: 'medium',
    deadline: '',
  });
  
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);

  // Handle input changes
  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    
    // Clear error for this field when user types
    if (errors[name]) {
      setErrors(prev => {
        const newErrors = { ...prev };
        delete newErrors[name];
        return newErrors;
      });
    }
  };

  // Validate form data
  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.title.trim()) newErrors.title = 'Title is required';
    if (!formData.description.trim()) newErrors.description = 'Description is required';
    if (!formData.category) newErrors.category = 'Please select a category';
    
    const quantity = parseInt(formData.quantity);
    if (isNaN(quantity) || quantity <= 0) {
      newErrors.quantity = 'Please enter a valid quantity';
    }
    
    if (formData.beneficiaryCount) {
      const beneficiaryCount = parseInt(formData.beneficiaryCount);
      if (isNaN(beneficiaryCount) || beneficiaryCount <= 0) {
        newErrors.beneficiaryCount = 'Please enter a valid number';
      }
    }
    
    if (!formData.urgencyLevel) newErrors.urgencyLevel = 'Urgency level is required';
    
    if (!formData.deadline) {
      newErrors.deadline = 'Deadline is required';
    } else {
      const deadlineDate = new Date(formData.deadline);
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      if (deadlineDate < today) {
        newErrors.deadline = 'Deadline cannot be in the past';
      }
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!userProfile) {
      toast.error('You must be logged in as an NGO to create requests');
      return;
    }
    
    if (userProfile.role !== 'ngo') {
      toast.error('Only NGOs can create donation requests');
      return;
    }
    
    if (!validateForm()) return;
    
    try {
      setLoading(true);
      
      await createRequest({
        title: formData.title,
        description: formData.description,
        category: formData.category,
        quantity: parseInt(formData.quantity),
        beneficiaryCount: formData.beneficiaryCount ? parseInt(formData.beneficiaryCount) : undefined,
        urgencyLevel: formData.urgencyLevel as 'high' | 'medium' | 'low',
        deadline: new Date(formData.deadline),
        ngoId: userProfile.uid,
        ngoName: userProfile.displayName || 'Anonymous NGO',
      });
      
      toast.success('Request created successfully');
      router.push('/requests');
    } catch (error) {
      console.error('Error creating request:', error);
      toast.error('Failed to create request. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  // Redirect if not logged in or not an NGO
  if (!userProfile) {
    return (
      <>
        <Navbar />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="text-center">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Authentication Required</h2>
            <p className="mt-2 text-gray-600 dark:text-gray-300">
              You need to be logged in to create a donation request
            </p>
            <Link href="/auth/login">
              <Button className="mt-4">Log In</Button>
            </Link>
          </div>
        </div>
      </>
    );
  }

  if (userProfile.role !== 'ngo') {
    return (
      <>
        <Navbar />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="text-center">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Access Denied</h2>
            <p className="mt-2 text-gray-600 dark:text-gray-300">
              Only NGOs can create donation requests
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
      <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="flex justify-between items-center mb-8">
          <div>
            <Link href="/requests" className="text-primary inline-flex items-center mb-2">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 mr-1">
                <path fillRule="evenodd" d="M17 10a.75.75 0 01-.75.75H5.612l4.158 3.96a.75.75 0 11-1.04 1.08l-5.5-5.25a.75.75 0 010-1.08l5.5-5.25a.75.75 0 111.04 1.08L5.612 9.25H16.25A.75.75 0 0117 10z" clipRule="evenodd" />
              </svg>
              Back to Requests
            </Link>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Create Donation Request</h1>
            <p className="mt-1 text-gray-500 dark:text-gray-400">
              Request donations for your organization's needs
            </p>
          </div>
        </div>
        
        <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 mb-6">
          <form onSubmit={handleSubmit}>
            <div className="space-y-6">
              <div>
                <label htmlFor="title" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Request Title*
                </label>
                <input
                  type="text"
                  id="title"
                  name="title"
                  value={formData.title}
                  onChange={handleChange}
                  className={`block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900 ${errors.title ? 'border-red-500' : ''}`}
                  placeholder="E.g., Winter Clothing for 50 Children"
                />
                {errors.title && (
                  <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.title}</p>
                )}
              </div>
              
              <div>
                <label htmlFor="description" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Description*
                </label>
                <textarea
                  id="description"
                  name="description"
                  rows={4}
                  value={formData.description}
                  onChange={handleChange}
                  className={`block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900 ${errors.description ? 'border-red-500' : ''}`}
                  placeholder="Provide details about why you need these items, who they will benefit, and any specific requirements"
                ></textarea>
                {errors.description && (
                  <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.description}</p>
                )}
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label htmlFor="category" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Category*
                  </label>
                  <select
                    id="category"
                    name="category"
                    value={formData.category}
                    onChange={handleChange}
                    className={`block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900 ${errors.category ? 'border-red-500' : ''}`}
                  >
                    <option value="">Select a category</option>
                    {CATEGORIES.map((category) => (
                      <option key={category} value={category}>
                        {category.charAt(0).toUpperCase() + category.slice(1)}
                      </option>
                    ))}
                  </select>
                  {errors.category && (
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.category}</p>
                  )}
                </div>
                
                <div>
                  <label htmlFor="quantity" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Quantity Needed*
                  </label>
                  <input
                    type="number"
                    id="quantity"
                    name="quantity"
                    min="1"
                    value={formData.quantity}
                    onChange={handleChange}
                    className={`block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900 ${errors.quantity ? 'border-red-500' : ''}`}
                    placeholder="How many items do you need?"
                  />
                  {errors.quantity && (
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.quantity}</p>
                  )}
                </div>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label htmlFor="beneficiaryCount" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Number of Beneficiaries (Optional)
                  </label>
                  <input
                    type="number"
                    id="beneficiaryCount"
                    name="beneficiaryCount"
                    min="1"
                    value={formData.beneficiaryCount}
                    onChange={handleChange}
                    className={`block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900 ${errors.beneficiaryCount ? 'border-red-500' : ''}`}
                    placeholder="How many people will benefit?"
                  />
                  {errors.beneficiaryCount && (
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.beneficiaryCount}</p>
                  )}
                </div>
                
                <div>
                  <label htmlFor="urgencyLevel" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Urgency Level*
                  </label>
                  <select
                    id="urgencyLevel"
                    name="urgencyLevel"
                    value={formData.urgencyLevel}
                    onChange={handleChange}
                    className={`block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900 ${errors.urgencyLevel ? 'border-red-500' : ''}`}
                  >
                    <option value="low">Low - Within a few months</option>
                    <option value="medium">Medium - Within a few weeks</option>
                    <option value="high">High - Urgent need</option>
                  </select>
                  {errors.urgencyLevel && (
                    <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.urgencyLevel}</p>
                  )}
                </div>
              </div>
              
              <div>
                <label htmlFor="deadline" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Deadline*
                </label>
                <input
                  type="date"
                  id="deadline"
                  name="deadline"
                  value={formData.deadline}
                  onChange={handleChange}
                  className={`block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900 ${errors.deadline ? 'border-red-500' : ''}`}
                />
                {errors.deadline && (
                  <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.deadline}</p>
                )}
                <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                  When do you need these items by?
                </p>
              </div>
              
              <div>
                <div className="border-t border-gray-200 dark:border-gray-700 pt-6 mt-6">
                  <div className="flex justify-end">
                    <Link href="/requests">
                      <Button type="button" variant="outline" className="mr-3">
                        Cancel
                      </Button>
                    </Link>
                    <Button type="submit" disabled={loading}>
                      {loading ? 'Creating...' : 'Create Request'}
                    </Button>
                  </div>
                </div>
              </div>
            </div>
          </form>
        </div>
      </div>
    </>
  );
} 