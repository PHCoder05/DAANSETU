'use client';

import React, { useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/Button';
import { toast } from 'react-hot-toast';
import { createRequest, DonationType } from '@/lib/firestore';

type CreateRequestFormProps = {
  onSuccess?: () => void;
  onCancel?: () => void;
};

export default function CreateRequestForm({ onSuccess, onCancel }: CreateRequestFormProps) {
  const { userProfile } = useAuth();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: 'food' as DonationType,
    quantity: '',
    urgencyLevel: 'medium' as 'low' | 'medium' | 'high',
    beneficiaryCount: '',
    deadline: ''
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!userProfile) {
      toast.error('You must be logged in to create requests');
      return;
    }
    
    if (userProfile.role !== 'ngo') {
      toast.error('Only NGOs can create requests');
      return;
    }
    
    // Validate form
    if (!formData.title || !formData.description || !formData.category || !formData.quantity) {
      toast.error('Please fill in all required fields');
      return;
    }
    
    setLoading(true);
    
    try {
      const requestData = {
        ...formData,
        quantity: parseInt(formData.quantity, 10) || 0,
        beneficiaryCount: parseInt(formData.beneficiaryCount, 10) || 0,
        deadline: formData.deadline ? new Date(formData.deadline) : null,
        ngoId: userProfile.uid,
        ngoName: userProfile.displayName || 'NGO',
        createdAt: new Date(),
        status: 'open' as 'open' | 'fulfilled' | 'closed',
      };
      
      await createRequest(requestData);
      toast.success('Request created successfully');
      
      // Reset form
      setFormData({
        title: '',
        description: '',
        category: 'food',
        quantity: '',
        urgencyLevel: 'medium',
        beneficiaryCount: '',
        deadline: ''
      });
      
      if (onSuccess) {
        onSuccess();
      }
    } catch (error) {
      console.error('Error creating request:', error);
      toast.error('Failed to create request');
    } finally {
      setLoading(false);
    }
  };

  const categories = [
    { value: 'food', label: 'Food & Groceries' },
    { value: 'clothes', label: 'Clothes & Apparel' },
    { value: 'books', label: 'Books & Education' },
    { value: 'toys', label: 'Toys & Games' },
    { value: 'medicine', label: 'Medicines & Healthcare' },
    { value: 'furniture', label: 'Furniture' },
    { value: 'electronics', label: 'Electronics' },
    { value: 'other', label: 'Other' },
  ];

  const urgencyLevels = [
    { value: 'low', label: 'Low - Needed within weeks' },
    { value: 'medium', label: 'Medium - Needed within days' },
    { value: 'high', label: 'High - Needed immediately' },
  ];

  return (
    <div className="bg-white dark:bg-zinc-800 shadow-sm rounded-lg">
      <div className="p-6">
        <h2 className="text-lg font-medium text-gray-900 dark:text-white mb-4">Create Request</h2>
        
        <form onSubmit={handleSubmit}>
          <div className="space-y-6">
            <div>
              <label htmlFor="title" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Request Title <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                id="title"
                name="title"
                value={formData.title}
                onChange={handleChange}
                placeholder="E.g., Need 50 Blankets for Winter Shelter"
                className="w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700"
                required
              />
            </div>
            
            <div>
              <label htmlFor="description" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Description <span className="text-red-500">*</span>
              </label>
              <textarea
                id="description"
                name="description"
                rows={4}
                value={formData.description}
                onChange={handleChange}
                placeholder="Describe in detail what you need, why you need it, and how it will be used to help beneficiaries..."
                className="w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700"
                required
              />
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label htmlFor="category" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Category <span className="text-red-500">*</span>
                </label>
                <select
                  id="category"
                  name="category"
                  value={formData.category}
                  onChange={handleChange}
                  className="w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700"
                  required
                >
                  {categories.map((category) => (
                    <option key={category.value} value={category.value}>
                      {category.label}
                    </option>
                  ))}
                </select>
              </div>
              
              <div>
                <label htmlFor="quantity" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Quantity Needed <span className="text-red-500">*</span>
                </label>
                <input
                  type="number"
                  id="quantity"
                  name="quantity"
                  value={formData.quantity}
                  onChange={handleChange}
                  min="1"
                  placeholder="E.g., 50"
                  className="w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700"
                  required
                />
              </div>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label htmlFor="urgencyLevel" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Urgency Level
                </label>
                <select
                  id="urgencyLevel"
                  name="urgencyLevel"
                  value={formData.urgencyLevel}
                  onChange={handleChange}
                  className="w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700"
                >
                  {urgencyLevels.map((level) => (
                    <option key={level.value} value={level.value}>
                      {level.label}
                    </option>
                  ))}
                </select>
              </div>
              
              <div>
                <label htmlFor="beneficiaryCount" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Number of Beneficiaries
                </label>
                <input
                  type="number"
                  id="beneficiaryCount"
                  name="beneficiaryCount"
                  value={formData.beneficiaryCount}
                  onChange={handleChange}
                  min="1"
                  placeholder="E.g., 100"
                  className="w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700"
                />
              </div>
            </div>
            
            <div>
              <label htmlFor="deadline" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Request Deadline
              </label>
              <input
                type="date"
                id="deadline"
                name="deadline"
                value={formData.deadline}
                onChange={handleChange}
                className="w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700"
              />
              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                After this date, the request will be automatically closed
              </p>
            </div>
            
            <div className="flex justify-end space-x-3 pt-2">
              {onCancel && (
                <Button 
                  type="button"
                  variant="outline"
                  onClick={onCancel}
                >
                  Cancel
                </Button>
              )}
              <Button 
                type="submit"
                disabled={loading}
              >
                {loading ? 'Creating...' : 'Create Request'}
              </Button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
} 