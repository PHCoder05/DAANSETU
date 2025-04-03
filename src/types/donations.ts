// Donation categories
export type DonationCategory = 
  | 'food' 
  | 'clothes' 
  | 'medicines' 
  | 'books' 
  | 'furniture'
  | 'electronics'
  | 'toys'
  | 'money'
  | 'other';

// Donation status
export type DonationStatus = 
  | 'available' 
  | 'claimed' 
  | 'in_transit' 
  | 'delivered' 
  | 'cancelled';

// Location interface
export interface Location {
  address: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
  coordinates?: {
    latitude: number;
    longitude: number;
  };
}

// Donation interface
export interface Donation {
  id: string;
  title: string;
  description: string;
  category: DonationCategory;
  quantity: number;
  unit?: string;
  images?: string[];
  status: DonationStatus;
  expiryDate?: number; // Timestamp for food/medicine expiry
  condition?: string; // For non-perishable items
  donorId: string;
  donorName: string;
  donorPhone?: string;
  pickupLocation: Location;
  claimedBy?: string; // NGO ID
  claimedAt?: number;
  deliveredAt?: number;
  createdAt: number;
  updatedAt: number;
  tags?: string[];
  isPriority?: boolean;
  notes?: string;
}

// Donation request interface (for NGOs requesting specific donations)
export interface DonationRequest {
  id: string;
  title: string;
  description: string;
  category: DonationCategory;
  quantity: number;
  unit?: string;
  urgency: 'low' | 'medium' | 'high';
  ngoId: string;
  ngoName: string;
  status: 'open' | 'fulfilled' | 'partially_fulfilled' | 'closed';
  location: Location;
  createdAt: number;
  updatedAt: number;
  fulfillments?: {
    donationId: string;
    donorId: string;
    quantity: number;
    fulfilledAt: number;
  }[];
}

// Distribution record (for NGOs to track how they distribute donations)
export interface Distribution {
  id: string;
  donationId: string;
  ngoId: string;
  beneficiaries: number;
  location: Location;
  distributedAt: number;
  images?: string[];
  notes?: string;
  impact?: string;
}

// Impact data for analytics
export interface ImpactMetrics {
  totalDonations: number;
  totalClaimed: number;
  totalDelivered: number;
  donationsByCategory: Record<DonationCategory, number>;
  beneficiariesReached: number;
  activeNgos: number;
  activeDonors: number;
  topDonors: {
    id: string;
    name: string;
    count: number;
  }[];
  topNgos: {
    id: string;
    name: string;
    count: number;
  }[];
  timeSeriesData: {
    date: string;
    donations: number;
    claims: number;
    deliveries: number;
  }[];
} 