'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import Navbar from '@/components/ui/Navbar';
import { Button } from '@/components/ui/Button';
import { submitNgoVerification } from '@/lib/firestore';
import { toast } from 'react-hot-toast';
import Link from 'next/link';

export default function NgoVerificationPage() {
  const { userProfile, refreshUserProfile } = useAuth();
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  
  const [formData, setFormData] = useState({
    registrationNumber: '',
    registrationDocument: '',
    taxExemptionDocument: '',
    website: '',
    focusAreas: '',
    facebook: '',
    twitter: '',
    instagram: '',
    linkedin: '',
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!userProfile) {
      toast.error('You must be logged in to submit verification');
      return;
    }
    
    if (userProfile.role !== 'ngo') {
      toast.error('Only NGO accounts can submit verification');
      return;
    }
    
    if (!formData.registrationNumber || !formData.registrationDocument) {
      toast.error('Registration number and document are required');
      return;
    }
    
    try {
      setLoading(true);
      
      const focusAreasArray = formData.focusAreas
        .split(',')
        .map(area => area.trim())
        .filter(area => area.length > 0);
      
      const socialLinks = {
        facebook: formData.facebook || undefined,
        twitter: formData.twitter || undefined,
        instagram: formData.instagram || undefined,
        linkedin: formData.linkedin || undefined,
      };
      
      await submitNgoVerification(userProfile.uid, {
        registrationNumber: formData.registrationNumber,
        registrationDocument: formData.registrationDocument,
        taxExemptionDocument: formData.taxExemptionDocument || undefined,
        website: formData.website || undefined,
        focusAreas: focusAreasArray.length > 0 ? focusAreasArray : undefined,
        socialLinks: Object.values(socialLinks).some(v => v) ? socialLinks : undefined,
      });
      
      await refreshUserProfile();
      toast.success('Verification submitted successfully');
      router.push('/dashboard');
    } catch (error) {
      console.error('Error submitting verification:', error);
      toast.error('Failed to submit verification. Please try again.');
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
              You need to be logged in to submit verification
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
              Only NGO accounts can submit verification
            </p>
            <Link href="/dashboard">
              <Button className="mt-4">Back to Dashboard</Button>
            </Link>
          </div>
        </div>
      </>
    );
  }

  if (userProfile.verificationStatus === 'verified') {
    return (
      <>
        <Navbar />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="text-center">
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-green-100 dark:bg-green-900/30 mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-8 h-8 text-green-600 dark:text-green-400">
                <path fillRule="evenodd" d="M8.603 3.799A4.49 4.49 0 0112 2.25c1.357 0 2.573.6 3.397 1.549a4.49 4.49 0 013.498 1.307 4.491 4.491 0 011.307 3.497A4.49 4.49 0 0121.75 12a4.49 4.49 0 01-1.549 3.397 4.491 4.491 0 01-1.307 3.497 4.491 4.491 0 01-3.497 1.307A4.49 4.49 0 0112 21.75a4.49 4.49 0 01-3.397-1.549 4.49 4.49 0 01-3.498-1.306 4.491 4.491 0 01-1.307-3.498A4.49 4.49 0 012.25 12c0-1.357.6-2.573 1.549-3.397a4.49 4.49 0 011.307-3.497 4.49 4.49 0 013.497-1.307zm7.007 6.387a.75.75 0 10-1.22-.872l-3.236 4.53L9.53 12.22a.75.75 0 00-1.06 1.06l2.25 2.25a.75.75 0 001.14-.094l3.75-5.25z" clipRule="evenodd" />
              </svg>
            </div>
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Already Verified</h2>
            <p className="mt-2 text-gray-600 dark:text-gray-300">
              Your NGO account is already verified. You can access all features.
            </p>
            <Link href="/dashboard">
              <Button className="mt-4">Go to Dashboard</Button>
            </Link>
          </div>
        </div>
      </>
    );
  }

  if (userProfile.verificationStatus === 'pending') {
    return (
      <>
        <Navbar />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="text-center">
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-yellow-100 dark:bg-yellow-900/30 mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-8 h-8 text-yellow-600 dark:text-yellow-400">
                <path fillRule="evenodd" d="M12 2.25c-5.385 0-9.75 4.365-9.75 9.75s4.365 9.75 9.75 9.75 9.75-4.365 9.75-9.75S17.385 2.25 12 2.25zM12.75 6a.75.75 0 00-1.5 0v6c0 .414.336.75.75.75h4.5a.75.75 0 000-1.5h-3.75V6z" clipRule="evenodd" />
              </svg>
            </div>
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Verification Pending</h2>
            <p className="mt-2 text-gray-600 dark:text-gray-300">
              Your verification request is being reviewed. This usually takes 1-3 business days.
            </p>
            <Link href="/dashboard">
              <Button className="mt-4">Back to Dashboard</Button>
            </Link>
          </div>
        </div>
      </>
    );
  }

  if (userProfile.verificationStatus === 'rejected') {
    return (
      <>
        <Navbar />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm overflow-hidden">
            <div className="px-6 py-8">
              <div className="flex items-center justify-center mb-6">
                <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-red-100 dark:bg-red-900/30">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-8 h-8 text-red-600 dark:text-red-400">
                    <path fillRule="evenodd" d="M12 2.25c-5.385 0-9.75 4.365-9.75 9.75s4.365 9.75 9.75 9.75 9.75-4.365 9.75-9.75S17.385 2.25 12 2.25zm-1.72 6.97a.75.75 0 10-1.06 1.06L10.94 12l-1.72 1.72a.75.75 0 101.06 1.06L12 13.06l1.72 1.72a.75.75 0 101.06-1.06L13.06 12l1.72-1.72a.75.75 0 10-1.06-1.06L12 10.94l-1.72-1.72z" clipRule="evenodd" />
                  </svg>
                </div>
              </div>
              <h2 className="text-2xl font-bold text-gray-900 dark:text-white text-center mb-2">Verification Rejected</h2>
              <p className="text-gray-600 dark:text-gray-300 text-center mb-6">
                Your previous verification request was rejected. Please submit again with accurate information.
              </p>
              
              <div className="p-4 bg-red-50 dark:bg-red-900/10 border border-red-100 dark:border-red-800 rounded-md mb-8">
                <h3 className="text-sm font-semibold text-red-800 dark:text-red-400 mb-1">Reason for rejection:</h3>
                <p className="text-sm text-red-700 dark:text-red-300">
                  The provided registration document could not be verified or was invalid. Please provide a clearer copy of your official registration certificate.
                </p>
              </div>
              
              <form onSubmit={handleSubmit} className="space-y-6">
                {/* Form content identical to the regular form below */}
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                  Submit Verification Documents
                </h3>
                
                <div className="space-y-6">
                  <div>
                    <label htmlFor="registrationNumber" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      NGO Registration Number*
                    </label>
                    <input
                      type="text"
                      id="registrationNumber"
                      name="registrationNumber"
                      value={formData.registrationNumber}
                      onChange={handleChange}
                      className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                      required
                    />
                  </div>
                  
                  <div>
                    <label htmlFor="registrationDocument" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Registration Certificate URL*
                    </label>
                    <input
                      type="url"
                      id="registrationDocument"
                      name="registrationDocument"
                      value={formData.registrationDocument}
                      onChange={handleChange}
                      className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                      placeholder="https://drive.google.com/file/..."
                      required
                    />
                    <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                      Provide a Google Drive or another cloud storage link to your registration certificate
                    </p>
                  </div>
                  
                  <div>
                    <label htmlFor="taxExemptionDocument" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Tax Exemption Certificate URL (Optional)
                    </label>
                    <input
                      type="url"
                      id="taxExemptionDocument"
                      name="taxExemptionDocument"
                      value={formData.taxExemptionDocument}
                      onChange={handleChange}
                      className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                      placeholder="https://drive.google.com/file/..."
                    />
                  </div>
                  
                  <div className="border-t border-gray-200 dark:border-gray-700 pt-6">
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                      Additional Information
                    </h3>
                    
                    <div className="space-y-6">
                      <div>
                        <label htmlFor="website" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                          Website (Optional)
                        </label>
                        <input
                          type="url"
                          id="website"
                          name="website"
                          value={formData.website}
                          onChange={handleChange}
                          className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                          placeholder="https://yourorganization.org"
                        />
                      </div>
                      
                      <div>
                        <label htmlFor="focusAreas" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                          Focus Areas (Optional)
                        </label>
                        <input
                          type="text"
                          id="focusAreas"
                          name="focusAreas"
                          value={formData.focusAreas}
                          onChange={handleChange}
                          className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                          placeholder="Education, Healthcare, Poverty Alleviation"
                        />
                        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                          Comma-separated list of your organization's focus areas
                        </p>
                      </div>
                      
                      <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                          Social Media Links (Optional)
                        </label>
                        
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                          <div>
                            <label htmlFor="facebook" className="block text-xs text-gray-500 dark:text-gray-400 mb-1">
                              Facebook
                            </label>
                            <input
                              type="url"
                              id="facebook"
                              name="facebook"
                              value={formData.facebook}
                              onChange={handleChange}
                              className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                              placeholder="https://facebook.com/yourorg"
                            />
                          </div>
                          
                          <div>
                            <label htmlFor="twitter" className="block text-xs text-gray-500 dark:text-gray-400 mb-1">
                              Twitter
                            </label>
                            <input
                              type="url"
                              id="twitter"
                              name="twitter"
                              value={formData.twitter}
                              onChange={handleChange}
                              className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                              placeholder="https://twitter.com/yourorg"
                            />
                          </div>
                          
                          <div>
                            <label htmlFor="instagram" className="block text-xs text-gray-500 dark:text-gray-400 mb-1">
                              Instagram
                            </label>
                            <input
                              type="url"
                              id="instagram"
                              name="instagram"
                              value={formData.instagram}
                              onChange={handleChange}
                              className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                              placeholder="https://instagram.com/yourorg"
                            />
                          </div>
                          
                          <div>
                            <label htmlFor="linkedin" className="block text-xs text-gray-500 dark:text-gray-400 mb-1">
                              LinkedIn
                            </label>
                            <input
                              type="url"
                              id="linkedin"
                              name="linkedin"
                              value={formData.linkedin}
                              onChange={handleChange}
                              className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                              placeholder="https://linkedin.com/company/yourorg"
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <div className="flex justify-end space-x-3">
                    <Link href="/dashboard">
                      <Button type="button" variant="outline">
                        Cancel
                      </Button>
                    </Link>
                    <Button
                      type="submit"
                      disabled={loading}
                    >
                      {loading ? 'Submitting...' : 'Submit Verification'}
                    </Button>
                  </div>
                </div>
              </form>
            </div>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <Navbar />
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm overflow-hidden">
          <div className="px-6 py-8">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
              NGO Verification
            </h1>
            <p className="text-gray-600 dark:text-gray-300 mb-8">
              To access all features and claim donations, please submit your verification documents. This helps us ensure that donations go to legitimate organizations.
            </p>
            
            <form onSubmit={handleSubmit} className="space-y-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                Submit Verification Documents
              </h3>
              
              <div className="space-y-6">
                <div>
                  <label htmlFor="registrationNumber" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    NGO Registration Number*
                  </label>
                  <input
                    type="text"
                    id="registrationNumber"
                    name="registrationNumber"
                    value={formData.registrationNumber}
                    onChange={handleChange}
                    className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                    required
                  />
                </div>
                
                <div>
                  <label htmlFor="registrationDocument" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Registration Certificate URL*
                  </label>
                  <input
                    type="url"
                    id="registrationDocument"
                    name="registrationDocument"
                    value={formData.registrationDocument}
                    onChange={handleChange}
                    className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                    placeholder="https://drive.google.com/file/..."
                    required
                  />
                  <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                    Provide a Google Drive or another cloud storage link to your registration certificate
                  </p>
                </div>
                
                <div>
                  <label htmlFor="taxExemptionDocument" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Tax Exemption Certificate URL (Optional)
                  </label>
                  <input
                    type="url"
                    id="taxExemptionDocument"
                    name="taxExemptionDocument"
                    value={formData.taxExemptionDocument}
                    onChange={handleChange}
                    className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                    placeholder="https://drive.google.com/file/..."
                  />
                </div>
                
                <div className="border-t border-gray-200 dark:border-gray-700 pt-6">
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                    Additional Information
                  </h3>
                  
                  <div className="space-y-6">
                    <div>
                      <label htmlFor="website" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Website (Optional)
                      </label>
                      <input
                        type="url"
                        id="website"
                        name="website"
                        value={formData.website}
                        onChange={handleChange}
                        className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                        placeholder="https://yourorganization.org"
                      />
                    </div>
                    
                    <div>
                      <label htmlFor="focusAreas" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Focus Areas (Optional)
                      </label>
                      <input
                        type="text"
                        id="focusAreas"
                        name="focusAreas"
                        value={formData.focusAreas}
                        onChange={handleChange}
                        className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                        placeholder="Education, Healthcare, Poverty Alleviation"
                      />
                      <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                        Comma-separated list of your organization's focus areas
                      </p>
                    </div>
                    
                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                        Social Media Links (Optional)
                      </label>
                      
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                          <label htmlFor="facebook" className="block text-xs text-gray-500 dark:text-gray-400 mb-1">
                            Facebook
                          </label>
                          <input
                            type="url"
                            id="facebook"
                            name="facebook"
                            value={formData.facebook}
                            onChange={handleChange}
                            className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                            placeholder="https://facebook.com/yourorg"
                          />
                        </div>
                        
                        <div>
                          <label htmlFor="twitter" className="block text-xs text-gray-500 dark:text-gray-400 mb-1">
                            Twitter
                          </label>
                          <input
                            type="url"
                            id="twitter"
                            name="twitter"
                            value={formData.twitter}
                            onChange={handleChange}
                            className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                            placeholder="https://twitter.com/yourorg"
                          />
                        </div>
                        
                        <div>
                          <label htmlFor="instagram" className="block text-xs text-gray-500 dark:text-gray-400 mb-1">
                            Instagram
                          </label>
                          <input
                            type="url"
                            id="instagram"
                            name="instagram"
                            value={formData.instagram}
                            onChange={handleChange}
                            className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                            placeholder="https://instagram.com/yourorg"
                          />
                        </div>
                        
                        <div>
                          <label htmlFor="linkedin" className="block text-xs text-gray-500 dark:text-gray-400 mb-1">
                            LinkedIn
                          </label>
                          <input
                            type="url"
                            id="linkedin"
                            name="linkedin"
                            value={formData.linkedin}
                            onChange={handleChange}
                            className="block w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-md shadow-sm focus:ring-primary focus:border-primary bg-white dark:bg-zinc-900"
                            placeholder="https://linkedin.com/company/yourorg"
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                
                <div className="flex justify-end space-x-3">
                  <Link href="/dashboard">
                    <Button type="button" variant="outline">
                      Cancel
                    </Button>
                  </Link>
                  <Button
                    type="submit"
                    disabled={loading}
                  >
                    {loading ? 'Submitting...' : 'Submit Verification'}
                  </Button>
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>
    </>
  );
} 