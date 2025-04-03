'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import { Button } from '@/components/ui/Button';
import { createDonation, DonationType } from '@/lib/firestore';
import { GeoPoint } from 'firebase/firestore';
import { toast } from 'react-hot-toast';

interface CreateDonationFormProps {
  onSuccess?: () => void;
  onCancel?: () => void;
}

export default function CreateDonationForm({ onSuccess, onCancel }: CreateDonationFormProps) {
  const { userProfile } = useAuth();
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: 'food' as DonationType,
    quantity: 1,
    address: '',
    pickupInstructions: '',
    isPickupRequired: true,
    latitude: 0,
    longitude: 0,
  });

  const [errors, setErrors] = useState<Record<string, string>>({});

  const donationCategories: { value: DonationType; label: string }[] = [
    { value: 'food', label: 'Food' },
    { value: 'clothes', label: 'Clothes & Apparel' },
    { value: 'books', label: 'Books & Education' },
    { value: 'toys', label: 'Toys & Games' },
    { value: 'medicine', label: 'Medicines & Health' },
    { value: 'furniture', label: 'Furniture' },
    { value: 'electronics', label: 'Electronics' },
    { value: 'other', label: 'Other' },
  ];

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target;
    
    setFormData(prev => ({
      ...prev,
      [name]: type === 'number' ? Number(value) : value,
    }));
    
    // Clear error when user types
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const handleCheckboxChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, checked } = e.target;
    
    setFormData(prev => ({
      ...prev,
      [name]: checked,
    }));
  };

  // In a real app, this would use the Geolocation API and/or a map picker
  const handleGetLocation = () => {
    if (navigator.geolocation) {
      setLoading(true);
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setFormData(prev => ({
            ...prev,
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
          }));
          setLoading(false);
          toast.success('Location detected successfully');
        },
        (error) => {
          console.error('Error getting location:', error);
          toast.error('Failed to get location. Please enter address manually.');
          setLoading(false);
        }
      );
    } else {
      toast.error('Geolocation is not supported by this browser');
    }
  };

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.title.trim()) {
      newErrors.title = 'Title is required';
    }
    
    if (!formData.description.trim()) {
      newErrors.description = 'Description is required';
    }
    
    if (formData.quantity <= 0) {
      newErrors.quantity = 'Quantity must be greater than 0';
    }
    
    if (!formData.address.trim()) {
      newErrors.address = 'Address is required';
    }
    
    if (formData.latitude === 0 && formData.longitude === 0) {
      newErrors.location = 'Please use the detect location button or enter a valid address';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!userProfile) {
      toast.error('You must be logged in to create a donation');
      return;
    }
    
    if (!validate()) {
      return;
    }
    
    setLoading(true);
    
    try {
      const donationData = {
        title: formData.title,
        description: formData.description,
        category: formData.category,
        quantity: formData.quantity,
        donorId: userProfile.uid,
        donorName: userProfile.displayName || 'Anonymous',
        location: { lat: formData.latitude, lng: formData.longitude },
        address: formData.address,
        pickupInstructions: formData.pickupInstructions,
        requiresPickup: formData.isPickupRequired,
        images: [],
      };
      
      await createDonation(donationData);
      
      toast.success('Donation created successfully!');
      
      if (onSuccess) {
        onSuccess();
      } else {
        router.push('/dashboard');
      }
    } catch (error) {
      console.error('Error creating donation:', error);
      toast.error('Failed to create donation. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="space-y-4">
        <div>
          <label htmlFor="title" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
            Title *
          </label>
          <input
            type="text"
            id="title"
            name="title"
            value={formData.title}
            onChange={handleChange}
            className={`mt-1 block w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700 ${
              errors.title ? 'border-red-500' : ''
            }`}
            placeholder="E.g., Winter Clothes, Children's Books"
          />
          {errors.title && (
            <p className="mt-1 text-sm text-red-600">{errors.title}</p>
          )}
        </div>
        
        <div>
          <label htmlFor="description" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
            Description *
          </label>
          <textarea
            id="description"
            name="description"
            rows={3}
            value={formData.description}
            onChange={handleChange}
            className={`mt-1 block w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700 ${
              errors.description ? 'border-red-500' : ''
            }`}
            placeholder="Describe your donation, including condition, age, etc."
          />
          {errors.description && (
            <p className="mt-1 text-sm text-red-600">{errors.description}</p>
          )}
        </div>
        
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <label htmlFor="category" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
              Category *
            </label>
            <select
              id="category"
              name="category"
              value={formData.category}
              onChange={handleChange}
              className="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700"
            >
              {donationCategories.map((category) => (
                <option key={category.value} value={category.value}>
                  {category.label}
                </option>
              ))}
            </select>
          </div>
          
          <div>
            <label htmlFor="quantity" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
              Quantity *
            </label>
            <input
              type="number"
              id="quantity"
              name="quantity"
              min="1"
              value={formData.quantity}
              onChange={handleChange}
              className={`mt-1 block w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700 ${
                errors.quantity ? 'border-red-500' : ''
              }`}
            />
            {errors.quantity && (
              <p className="mt-1 text-sm text-red-600">{errors.quantity}</p>
            )}
          </div>
        </div>
        
        <div>
          <label htmlFor="address" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
            Address *
          </label>
          <div className="mt-1 flex rounded-md shadow-sm">
            <input
              type="text"
              id="address"
              name="address"
              value={formData.address}
              onChange={handleChange}
              className={`block w-full flex-1 rounded-none rounded-l-md border-gray-300 dark:border-gray-700 focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700 ${
                errors.address ? 'border-red-500' : ''
              }`}
              placeholder="Enter your full address"
            />
            <button
              type="button"
              onClick={handleGetLocation}
              className="inline-flex items-center px-3 py-2 border border-l-0 border-gray-300 dark:border-gray-700 rounded-r-md bg-gray-50 dark:bg-zinc-800 text-gray-500 dark:text-gray-400 text-sm"
              disabled={loading}
            >
              {loading ? 'Detecting...' : 'Detect Location'}
            </button>
          </div>
          {errors.address && (
            <p className="mt-1 text-sm text-red-600">{errors.address}</p>
          )}
          {errors.location && (
            <p className="mt-1 text-sm text-red-600">{errors.location}</p>
          )}
          {formData.latitude !== 0 && formData.longitude !== 0 && (
            <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
              Location detected: {formData.latitude.toFixed(6)}, {formData.longitude.toFixed(6)}
            </p>
          )}
        </div>
        
        <div>
          <label htmlFor="pickupInstructions" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
            Pickup Instructions
          </label>
          <textarea
            id="pickupInstructions"
            name="pickupInstructions"
            rows={2}
            value={formData.pickupInstructions}
            onChange={handleChange}
            className="mt-1 block w-full rounded-md border-gray-300 dark:border-gray-700 shadow-sm focus:border-primary focus:ring-primary sm:text-sm bg-white dark:bg-zinc-700"
            placeholder="E.g., Available after 5 PM, Contact before pickup, etc."
          />
        </div>
        
        <div className="flex items-start">
          <div className="flex items-center h-5">
            <input
              id="isPickupRequired"
              name="isPickupRequired"
              type="checkbox"
              checked={formData.isPickupRequired}
              onChange={handleCheckboxChange}
              className="focus:ring-primary h-4 w-4 text-primary border-gray-300 dark:border-gray-700 rounded"
            />
          </div>
          <div className="ml-3 text-sm">
            <label htmlFor="isPickupRequired" className="font-medium text-gray-700 dark:text-gray-300">
              Pickup Required
            </label>
            <p className="text-gray-500 dark:text-gray-400">Check if the NGO needs to arrange pickup</p>
          </div>
        </div>
      </div>
      
      <div className="flex justify-end space-x-2">
        {onCancel && (
          <Button type="button" onClick={onCancel} variant="outline">
            Cancel
          </Button>
        )}
        <Button type="submit" disabled={loading}>
          {loading ? 'Creating...' : 'Create Donation'}
        </Button>
      </div>
    </form>
  );
} 