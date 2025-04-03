'use client';

import { db } from './firebase';
import { 
  collection, 
  doc, 
  setDoc, 
  getDocs, 
  query, 
  where, 
  serverTimestamp,
  writeBatch,
  deleteDoc
} from 'firebase/firestore';
import { toast } from 'react-hot-toast';
import { UserRole, Donation, Request, DonationStatus, DonationType, UrgencyLevel } from './firestore';

// Function to clear existing data from collections
export async function clearCollection(collectionName: string) {
  try {
    const collectionRef = collection(db, collectionName);
    const snapshot = await getDocs(query(collectionRef));
    
    const batch = writeBatch(db);
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    console.log(`Cleared ${snapshot.size} documents from ${collectionName}`);
  } catch (error) {
    console.error(`Error clearing ${collectionName}:`, error);
  }
}

// Function to seed test users
export async function seedUsers() {
  try {
    // Clear existing users first
    await clearCollection('users');
    
    const users = [
      {
        uid: 'donor1',
        email: 'donor1@example.com',
        displayName: 'Test Donor',
        photoURL: null,
        role: 'donor' as UserRole,
        createdAt: Date.now(),
        address: '123 Main St, City, Country',
        phone: '1234567890',
        verified: true
      },
      {
        uid: 'ngo1',
        email: 'ngo1@example.com',
        displayName: 'Test NGO',
        photoURL: null,
        role: 'ngo' as UserRole,
        createdAt: Date.now(),
        address: '456 NGO Avenue, City, Country',
        phone: '9876543210',
        verified: true
      },
      {
        uid: 'admin1',
        email: 'admin@example.com',
        displayName: 'Admin User',
        photoURL: null,
        role: 'admin' as UserRole,
        createdAt: Date.now(),
        verified: true
      }
    ];
    
    const batch = writeBatch(db);
    
    users.forEach(user => {
      const userRef = doc(db, 'users', user.uid);
      batch.set(userRef, user);
    });
    
    await batch.commit();
    console.log('Seeded users successfully');
    return true;
  } catch (error) {
    console.error('Error seeding users:', error);
    return false;
  }
}

// Function to seed test donations
export async function seedDonations() {
  try {
    // Clear existing donations first
    await clearCollection('donations');
    
    const donations: Omit<Donation, 'createdAt'>[] = [
      {
        id: 'donation1',
        title: 'Winter Clothes',
        description: 'A box of gently used winter clothes including jackets, sweaters, and gloves',
        category: 'clothes' as DonationType,
        quantity: 15,
        address: '123 Main St, City, Country',
        location: { lat: 18.5204, lng: 73.8567 },
        pickupInstructions: 'Available after 5 PM on weekdays',
        requiresPickup: true,
        donorId: 'donor1',
        donorName: 'Test Donor',
        status: 'available' as DonationStatus,
        images: []
      },
      {
        id: 'donation2',
        title: 'Children\'s Books',
        description: 'A collection of 30 children\'s books in good condition',
        category: 'books' as DonationType,
        quantity: 30,
        address: '123 Main St, City, Country',
        location: { lat: 18.5204, lng: 73.8567 },
        pickupInstructions: 'Ring the doorbell upon arrival',
        requiresPickup: true,
        donorId: 'donor1',
        donorName: 'Test Donor',
        status: 'available' as DonationStatus,
        images: []
      },
      {
        id: 'donation3',
        title: 'Non-perishable Food Items',
        description: 'Canned foods, rice, pasta, and other non-perishables',
        category: 'food' as DonationType,
        quantity: 25,
        address: '123 Main St, City, Country',
        location: { lat: 18.5204, lng: 73.8567 },
        pickupInstructions: 'Please call before coming',
        requiresPickup: true,
        donorId: 'donor1',
        donorName: 'Test Donor',
        status: 'claimed' as DonationStatus,
        claimedBy: 'ngo1',
        claimedByName: 'Test NGO',
        claimedAt: { seconds: Math.floor(Date.now() / 1000), nanoseconds: 0 },
        images: []
      }
    ];
    
    const batch = writeBatch(db);
    
    donations.forEach(donation => {
      const donationRef = doc(db, 'donations', donation.id);
      batch.set(donationRef, {
        ...donation,
        createdAt: serverTimestamp()
      });
    });
    
    await batch.commit();
    console.log('Seeded donations successfully');
    return true;
  } catch (error) {
    console.error('Error seeding donations:', error);
    return false;
  }
}

// Function to seed test requests
export async function seedRequests() {
  try {
    // Clear existing requests first
    await clearCollection('requests');
    
    const requests: Omit<Request, 'createdAt'>[] = [
      {
        id: 'request1',
        title: 'Need Winter Clothes for Shelter',
        description: 'We need winter clothes for our homeless shelter serving about 50 people',
        category: 'clothes' as DonationType,
        quantity: 50,
        urgencyLevel: 'high' as UrgencyLevel,
        beneficiaryCount: 50,
        deadline: { seconds: Math.floor((Date.now() + 7 * 24 * 60 * 60 * 1000) / 1000), nanoseconds: 0 },
        ngoId: 'ngo1',
        ngoName: 'Test NGO',
        status: 'open' as 'open' | 'fulfilled' | 'closed'
      },
      {
        id: 'request2',
        title: 'Books for Community Library',
        description: 'We are setting up a library for underprivileged children',
        category: 'books' as DonationType,
        quantity: 100,
        urgencyLevel: 'medium' as UrgencyLevel,
        beneficiaryCount: 200,
        deadline: { seconds: Math.floor((Date.now() + 14 * 24 * 60 * 60 * 1000) / 1000), nanoseconds: 0 },
        ngoId: 'ngo1',
        ngoName: 'Test NGO',
        status: 'open' as 'open' | 'fulfilled' | 'closed'
      }
    ];
    
    const batch = writeBatch(db);
    
    requests.forEach(request => {
      const requestRef = doc(db, 'requests', request.id);
      batch.set(requestRef, {
        ...request,
        createdAt: serverTimestamp()
      });
    });
    
    await batch.commit();
    console.log('Seeded requests successfully');
    return true;
  } catch (error) {
    console.error('Error seeding requests:', error);
    return false;
  }
}

// Main function to seed all test data
export async function seedTestData() {
  try {
    await seedUsers();
    await seedDonations();
    await seedRequests();
    return true;
  } catch (error) {
    console.error('Error seeding test data:', error);
    return false;
  }
}

// Function to seed the database with test data
export async function seedDatabase() {
  try {
    // Use our new seedTestData function instead
    const success = await seedTestData();
    
    if (success) {
      toast.success('Database seeded successfully');
    } else {
      toast.error('Failed to seed database');
    }
    
    return success;
  } catch (error) {
    console.error('Error seeding database:', error);
    toast.error('Failed to seed database');
    return false;
  }
} 