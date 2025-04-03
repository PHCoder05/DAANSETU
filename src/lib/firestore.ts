import { 
  getFirestore, 
  collection, 
  getDocs, 
  getDoc, 
  setDoc, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  doc, 
  query, 
  where, 
  orderBy, 
  limit, 
  serverTimestamp, 
  onSnapshot, 
  Timestamp, 
  GeoPoint,
  DocumentData,
  FieldValue,
  writeBatch
} from 'firebase/firestore';
import { db } from './firebase';
import { auth } from './firebase';

// Types
export type DonationStatus = 'available' | 'claimed' | 'delivered' | 'cancelled';
export type DonationType = 'food' | 'clothes' | 'books' | 'toys' | 'medicine' | 'furniture' | 'electronics' | 'other';
export type UserRole = 'donor' | 'ngo' | 'admin';
export type NgoVerificationStatus = 'pending' | 'verified' | 'rejected';
export type ReportStatus = 'pending' | 'investigating' | 'resolved' | 'closed';
export type NotificationType = 
  | 'donationCreated' 
  | 'donationClaimed' 
  | 'requestCreated' 
  | 'requestFulfilled'
  | 'messageReceived'
  | 'verificationRequest'
  | 'verificationUpdated';
export type RequestStatus = 'open' | 'fulfilled' | 'closed';
export type UrgencyLevel = 'low' | 'medium' | 'high';

// Interfaces
export interface UserProfile {
  uid: string;
  displayName: string;
  email: string;
  photoURL?: string;
  phoneNumber?: string;
  role: UserRole;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  address?: string;
  location?: GeoPoint;
  bio?: string;
  isVerified?: boolean;
}

export interface NgoProfile extends UserProfile {
  registrationNumber: string;
  registrationDocument?: string;
  taxExemptionDocument?: string;
  verificationStatus: NgoVerificationStatus;
  verificationDate?: Timestamp;
  focusAreas?: string[];
  website?: string;
  socialLinks?: {
    facebook?: string;
    twitter?: string;
    instagram?: string;
    linkedin?: string;
  };
}

export interface Donation {
  id: string;
  title: string;
  description: string;
  category: DonationType;
  quantity: number;
  address: string;
  location?: { lat: number; lng: number };
  pickupInstructions?: string;
  requiresPickup: boolean;
  donorId: string;
  donorName: string;
  status: DonationStatus;
  images?: string[];
  createdAt: Timestamp | null;
  claimedBy?: string;
  claimedByName?: string;
  claimedAt?: Timestamp;
  deliveredAt?: Timestamp;
}

export interface DonationRequest {
  id: string;
  title: string;
  description: string;
  category: DonationType;
  quantity: number;
  urgency: 'low' | 'medium' | 'high';
  ngoId: string;
  ngoName: string;
  status: 'open' | 'fulfilled' | 'closed';
  createdAt: Timestamp;
  updatedAt: Timestamp;
  location: GeoPoint;
  address: string;
  fulfilledBy?: string[];
  distance?: number; // Distance in km from search location
}

export interface Notification {
  id: string;
  userId?: string;
  targetUserRole?: string;
  type: NotificationType;
  title: string;
  message: string;
  isRead: boolean;
  createdAt: Timestamp | FieldValue;
  metadata?: Record<string, any>;
}

export interface Report {
  id: string;
  title: string;
  description: string;
  reportedBy: string;
  reporterRole: UserRole;
  referenceId: string;
  referenceType: string;
  status: ReportStatus;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  priority: 'low' | 'medium' | 'high';
  assignedTo?: string;
  resolution?: string;
}

export interface Request {
  id: string;
  title: string;
  description: string;
  category: DonationType;
  quantity: number;
  beneficiaryCount?: number;
  urgencyLevel: 'high' | 'medium' | 'low';
  status: 'open' | 'fulfilled' | 'closed';
  ngoId: string;
  ngoName: string;
  deadline: Date | Timestamp;
  createdAt: Date | Timestamp;
  updatedAt: Date | Timestamp;
  fulfilledById?: string;
  fulfilledByName?: string;
  fulfilledAt?: Date | Timestamp;
}

export interface RequestInput {
  title: string;
  description: string;
  category: DonationType;
  quantity: number;
  beneficiaryCount?: number;
  urgencyLevel: 'high' | 'medium' | 'low';
  deadline: Date;
  ngoId: string;
  ngoName: string;
}

interface NgoVerificationData {
  registrationNumber: string;
  registrationDocument: string;
  taxExemptionDocument?: string;
  website?: string;
  focusAreas?: string[];
  socialLinks?: {
    facebook?: string;
    twitter?: string;
    instagram?: string;
    linkedin?: string;
  };
}

// Collection references
const usersRef = collection(db, 'users');
const donationsRef = collection(db, 'donations');
const requestsRef = collection(db, 'requests');
const notificationsRef = collection(db, 'notifications');
const reportsRef = collection(db, 'reports');

// User functions
export const createUserProfile = async (
  uid: string, 
  data: Partial<UserProfile>
) => {
  const userDocRef = doc(db, 'users', uid);
  
  await setDoc(userDocRef, {
    ...data,
    uid,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }, { merge: true });
  
  return userDocRef;
};

export const getUserProfile = async (uid: string) => {
  const userDocRef = doc(db, 'users', uid);
  const userDoc = await getDoc(userDocRef);
  
  if (userDoc.exists()) {
    return { uid: userDoc.id, ...userDoc.data() } as UserProfile;
  }
  
  return null;
};

export const updateUserProfile = async (
  uid: string, 
  data: Partial<UserProfile>
) => {
  const userDocRef = doc(db, 'users', uid);
  
  await updateDoc(userDocRef, {
    ...data,
    updatedAt: serverTimestamp(),
  });
  
  return userDocRef;
};

// NGO verification functions
export async function submitNgoVerification(uid: string, verificationData: NgoVerificationData): Promise<void> {
  try {
    const db = getFirestore();
    const userRef = doc(db, 'users', uid);
    
    // Update the user profile with verification status
    await updateDoc(userRef, {
      verificationStatus: 'pending',
      verificationSubmittedAt: serverTimestamp(),
      verificationData: verificationData
    });
    
    // Create a verification request in a separate collection for admin review
    const verificationRequestRef = doc(collection(db, 'verificationRequests'));
    await setDoc(verificationRequestRef, {
      uid,
      status: 'pending',
      submittedAt: serverTimestamp(),
      ...verificationData
    });
    
    // Send notification to admins
    await createNotification({
      type: 'verificationRequest',
      targetUserRole: 'admin',
      title: 'New NGO Verification Request',
      message: `A new NGO verification request has been submitted and needs review.`,
      isRead: false,
      metadata: {
        ngoId: uid
      }
    });
    
  } catch (error) {
    console.error('Error submitting NGO verification:', error);
    throw error;
  }
}

export const updateNgoVerificationStatus = async (
  uid: string, 
  status: NgoVerificationStatus
) => {
  const userDocRef = doc(db, 'users', uid);
  
  await updateDoc(userDocRef, {
    verificationStatus: status,
    verificationDate: serverTimestamp(),
    isVerified: status === 'verified',
    updatedAt: serverTimestamp(),
  });
  
  return userDocRef;
};

// Donation functions
export async function createDonation(donationData: Omit<Donation, 'id' | 'createdAt' | 'status'>) {
  try {
    const donationRef = doc(collection(db, 'donations'));
    const newDonation = {
      ...donationData,
      id: donationRef.id,
      status: 'available' as DonationStatus,
      createdAt: serverTimestamp()
    };
    
    await setDoc(donationRef, newDonation);
    return donationRef.id;
  } catch (error) {
    console.error('Error creating donation:', error);
    throw error;
  }
}

export async function getDonationById(id: string): Promise<Donation | null> {
  try {
    const docRef = doc(db, 'donations', id);
    const docSnap = await getDoc(docRef);
    
    if (docSnap.exists()) {
      return { id: docSnap.id, ...docSnap.data() } as Donation;
    }
    
    return null;
  } catch (error) {
    console.error('Error getting donation:', error);
    throw error;
  }
}

export async function updateDonation(donationId: string, data: Partial<Donation>): Promise<void> {
  try {
    const donationRef = doc(db, 'donations', donationId);
    await updateDoc(donationRef, data);
  } catch (error) {
    console.error('Error updating donation:', error);
    throw error;
  }
}

export async function deleteDonation(id: string): Promise<void> {
  try {
    const donationDocRef = doc(db, 'donations', id);
    await deleteDoc(donationDocRef);
  } catch (error) {
    console.error('Error deleting donation:', error);
    throw error;
  }
}

export async function getDonationsByDonorId(donorId: string): Promise<Donation[]> {
  try {
    const q = query(
      collection(db, 'donations'),
      where('donorId', '==', donorId),
      orderBy('createdAt', 'desc')
    );
    
    const querySnapshot = await getDocs(q);
    const donations: Donation[] = [];
    
    querySnapshot.forEach((doc) => {
      donations.push({ id: doc.id, ...doc.data() } as Donation);
    });
    
    return donations;
  } catch (error) {
    console.error('Error getting donations by donor:', error);
    throw error;
  }
}

export async function getAllDonations(status?: DonationStatus): Promise<Donation[]> {
  try {
    let q;
    
    if (status) {
      q = query(
        collection(db, 'donations'),
        where('status', '==', status),
        orderBy('createdAt', 'desc')
      );
    } else {
      q = query(
        collection(db, 'donations'),
        orderBy('createdAt', 'desc')
      );
    }
    
    const querySnapshot = await getDocs(q);
    const donations: Donation[] = [];
    
    querySnapshot.forEach((doc) => {
      donations.push({ id: doc.id, ...doc.data() } as Donation);
    });
    
    return donations;
  } catch (error) {
    console.error('Error getting all donations:', error);
    throw error;
  }
}

export async function updateDonationStatus(donationId: string, status: DonationStatus): Promise<void> {
  try {
    const donationRef = doc(db, 'donations', donationId);
    
    await updateDoc(donationRef, {
      status,
      ...(status === 'delivered' ? { deliveredAt: serverTimestamp() } : {})
    });
  } catch (error) {
    console.error('Error updating donation status:', error);
    throw error;
  }
}

// Helper function to calculate distance using the Haversine formula
export function calculateDistance(
  lat1: number, 
  lon1: number, 
  lat2: number, 
  lon2: number
): number {
  const R = 6371; // Radius of the earth in km
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * 
    Math.sin(dLon/2) * Math.sin(dLon/2); 
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
  const distance = R * c; // Distance in km
  return distance;
}

function deg2rad(deg: number): number {
  return deg * (Math.PI / 180);
}

export async function getNearbyDonations(lat: number, lng: number, radiusKm: number = 10): Promise<Donation[]> {
  try {
    // Firestore doesn't support geo queries directly, so we fetch all available donations
    // and filter them based on distance
    const q = query(
      collection(db, 'donations'),
      where('status', '==', 'available'),
      orderBy('createdAt', 'desc')
    );
    
    const querySnapshot = await getDocs(q);
    const donations: Donation[] = [];
    
    querySnapshot.forEach((doc) => {
      const data = doc.data() as Donation;
      
      // Check if donation has location data
      if (data.location && data.location.lat && data.location.lng) {
        const distance = calculateDistance(
          lat, lng,
          data.location.lat, data.location.lng
        );
        
        // Only include donations within the radius
        if (distance <= radiusKm) {
          const donationWithDistance = { 
            ...data, 
            id: doc.id,
            distance 
          };
          donations.push(donationWithDistance as Donation);
        }
      } else {
        // Include donations without location data (optional)
        donations.push({ ...data, id: doc.id } as Donation);
      }
    });
    
    return donations;
  } catch (error) {
    console.error('Error getting nearby donations:', error);
    throw error;
  }
}

export async function claimDonation(donationId: string, ngoId: string, ngoName: string): Promise<void> {
  try {
    const donationRef = doc(db, 'donations', donationId);
    const donationSnap = await getDoc(donationRef);
    
    if (!donationSnap.exists()) {
      throw new Error('Donation not found');
    }
    
    const donationData = donationSnap.data() as Donation;
    
    if (donationData.status !== 'available') {
      throw new Error('Donation is not available for claiming');
    }
    
    await updateDoc(donationRef, {
      status: 'claimed',
      claimedBy: ngoId,
      claimedByName: ngoName,
      claimedAt: serverTimestamp()
    });
  } catch (error) {
    console.error('Error claiming donation:', error);
    throw error;
  }
}

// Donation request functions
export const createDonationRequest = async (request: Omit<DonationRequest, 'id' | 'createdAt' | 'updatedAt'>) => {
  const newRequestRef = await addDoc(requestsRef, {
    ...request,
    status: 'open',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  
  return newRequestRef;
};

export const getDonationRequestById = async (id: string) => {
  const requestDocRef = doc(db, 'requests', id);
  const requestDoc = await getDoc(requestDocRef);
  
  if (requestDoc.exists()) {
    return { id: requestDoc.id, ...requestDoc.data() } as DonationRequest;
  }
  
  return null;
};

export const updateDonationRequest = async (
  id: string, 
  data: Partial<DonationRequest>
) => {
  const requestDocRef = doc(db, 'requests', id);
  
  await updateDoc(requestDocRef, {
    ...data,
    updatedAt: serverTimestamp(),
  });
  
  return requestDocRef;
};

export const getNgoRequests = async (ngoId: string, status?: DonationRequest['status']) => {
  let q = query(
    requestsRef,
    where('ngoId', '==', ngoId),
    orderBy('createdAt', 'desc')
  );
  
  if (status) {
    q = query(
      requestsRef,
      where('ngoId', '==', ngoId),
      where('status', '==', status),
      orderBy('createdAt', 'desc')
    );
  }
  
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }) as DonationRequest);
};

// Notification functions
export const createNotification = async (notification: Omit<Notification, 'id' | 'createdAt'>) => {
  const newNotificationRef = await addDoc(notificationsRef, {
    ...notification,
    createdAt: serverTimestamp(),
  });
  
  return newNotificationRef;
};

export const getUserNotifications = async (userId: string, limitSize = 20) => {
  const q = query(
    notificationsRef,
    where('userId', '==', userId),
    orderBy('createdAt', 'desc'),
    limit(limitSize as number)
  );
  
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }) as Notification);
};

export const markNotificationAsRead = async (id: string) => {
  const notificationDocRef = doc(db, 'notifications', id);
  
  await updateDoc(notificationDocRef, {
    read: true,
  });
  
  return notificationDocRef;
};

// Report functions
export const createReport = async (report: Omit<Report, 'id' | 'createdAt' | 'updatedAt'>) => {
  const newReportRef = await addDoc(reportsRef, {
    ...report,
    status: 'pending',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
  
  return newReportRef;
};

export const getReportById = async (id: string) => {
  const reportDocRef = doc(db, 'reports', id);
  const reportDoc = await getDoc(reportDocRef);
  
  if (reportDoc.exists()) {
    return { id: reportDoc.id, ...reportDoc.data() } as Report;
  }
  
  return null;
};

export const updateReport = async (
  id: string, 
  data: Partial<Report>
) => {
  const reportDocRef = doc(db, 'reports', id);
  
  await updateDoc(reportDocRef, {
    ...data,
    updatedAt: serverTimestamp(),
  });
  
  return reportDocRef;
};

export const getPendingReports = async (limitSize = 10) => {
  const q = query(
    reportsRef,
    where('status', 'in', ['pending', 'investigating']),
    orderBy('priority', 'desc'),
    orderBy('createdAt', 'asc'),
    limit(limitSize as number)
  );
  
  const snapshot = await getDocs(q);
  return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }) as Report);
};

// Real-time updates
export const subscribeToUserDonations = (userId: string, callback: (donations: Donation[]) => void) => {
  const q = query(
    donationsRef,
    where('donorId', '==', userId),
    orderBy('createdAt', 'desc')
  );
  
  return onSnapshot(q, (snapshot) => {
    const donations = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }) as Donation);
    callback(donations);
  });
};

export function subscribeToClaimedDonations(ngoId: string, callback: (donations: Donation[]) => void) {
  const q = query(
    donationsRef,
    where('claimedBy', '==', ngoId),
    where('status', 'in', ['claimed', 'delivered']),
    orderBy('claimedAt', 'desc')
  );
  
  return onSnapshot(q, (snapshot) => {
    const donations = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }) as Donation);
    callback(donations);
  });
}

export const subscribeToNotifications = (userId: string, callback: (notifications: Notification[]) => void) => {
  const q = query(
    notificationsRef,
    where('userId', '==', userId),
    orderBy('createdAt', 'desc'),
    limit(50 as number)
  );
  
  return onSnapshot(q, (snapshot) => {
    const notifications = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }) as Notification);
    callback(notifications);
  });
};

// Functions for Requests

// Create a new request
export async function createRequest(requestData: RequestInput): Promise<string> {
  try {
    const db = getFirestore();
    const now = new Date();
    
    const requestWithDates = {
      ...requestData,
      status: 'open',
      createdAt: now,
      updatedAt: now,
    };
    
    const docRef = await addDoc(collection(db, 'requests'), requestWithDates);
    return docRef.id;
  } catch (error) {
    console.error('Error creating request:', error);
    throw error;
  }
}

// Get a request by ID
export async function getRequestById(requestId: string): Promise<Request | null> {
  try {
    const db = getFirestore();
    const requestRef = doc(db, 'requests', requestId);
    const snapshot = await getDoc(requestRef);
    
    if (!snapshot.exists()) {
      return null;
    }
    
    return {
      id: snapshot.id,
      ...snapshot.data(),
    } as Request;
  } catch (error) {
    console.error('Error getting request by ID:', error);
    throw error;
  }
}

// Get all requests by NGO
export async function getRequestsByNgoId(ngoId: string): Promise<Request[]> {
  try {
    const db = getFirestore();
    const requestsRef = collection(db, 'requests');
    const q = query(requestsRef, where('ngoId', '==', ngoId));
    const snapshot = await getDocs(q);
    
    const requests: Request[] = [];
    snapshot.forEach((doc) => {
      const data = doc.data();
      requests.push({
        id: doc.id,
        ...data,
      } as Request);
    });
    
    return requests;
  } catch (error) {
    console.error('Error getting NGO requests:', error);
    throw error;
  }
}

// Get all open requests
export async function getAllRequests(status?: RequestStatus): Promise<Request[]> {
  try {
    let q;
    
    if (status) {
      q = query(
        collection(db, 'requests'),
        where('status', '==', status),
        orderBy('createdAt', 'desc')
      );
    } else {
      q = query(
        collection(db, 'requests'),
        orderBy('createdAt', 'desc')
      );
    }
    
    const querySnapshot = await getDocs(q);
    const requests: Request[] = [];
    
    querySnapshot.forEach((doc) => {
      requests.push({ id: doc.id, ...doc.data() } as Request);
    });
    
    return requests;
  } catch (error) {
    console.error('Error getting all requests:', error);
    throw error;
  }
}

/**
 * Get nearby NGO requests based on location
 * @param lat Latitude
 * @param lng Longitude
 * @param radiusKm Search radius in kilometers
 * @returns List of nearby requests
 */
export async function getNearbyRequests(lat: number, lng: number, radiusKm: number = 20): Promise<DonationRequest[]> {
  try {
    // Firestore doesn't support geo queries directly, so we fetch open requests
    // and filter them based on distance if location data is available
    const q = query(
      collection(db, 'requests'),
      where('status', '==', 'open'),
      orderBy('createdAt', 'desc')
    );
    
    const querySnapshot = await getDocs(q);
    const requests: DonationRequest[] = [];
    
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      const request = { id: doc.id, ...data } as DonationRequest;
      
      // If the request has location data, calculate distance
      if (request.location && request.location instanceof GeoPoint) {
        const distance = calculateDistance(
          lat, lng,
          request.location.latitude, request.location.longitude
        );
        
        // Only include requests within the radius
        if (distance <= radiusKm) {
          request.distance = distance;
          requests.push(request);
        }
      } else {
        // Include requests without location data
        requests.push(request);
      }
    });
    
    // Sort by distance if available
    return requests.sort((a, b) => {
      if (a.distance !== undefined && b.distance !== undefined) {
        return a.distance - b.distance;
      }
      return 0;
    });
  } catch (error) {
    console.error('Error getting nearby requests:', error);
    throw error;
  }
}

// Fulfill a request
export async function fulfillRequest(
  requestId: string,
  donorId: string,
  donorName: string
): Promise<void> {
  try {
    const db = getFirestore();
    const requestRef = doc(db, 'requests', requestId);
    
    // Get the request first to verify it's open
    const requestSnapshot = await getDoc(requestRef);
    if (!requestSnapshot.exists()) {
      throw new Error('Request not found');
    }
    
    const requestData = requestSnapshot.data() as Request;
    if (requestData.status !== 'open') {
      throw new Error('This request is no longer open');
    }
    
    // Update the request
    const now = new Date();
    await updateDoc(requestRef, {
      status: 'fulfilled',
      fulfilledById: donorId,
      fulfilledByName: donorName,
      fulfilledAt: now,
      updatedAt: now,
    });
  } catch (error) {
    console.error('Error fulfilling request:', error);
    throw error;
  }
}

// Get request counts by NGO
export async function getNgoRequestStats(ngoId: string) {
  try {
    const openQ = query(
      collection(db, 'requests'),
      where('ngoId', '==', ngoId),
      where('status', '==', 'open')
    );
    
    const fulfilledQ = query(
      collection(db, 'requests'),
      where('ngoId', '==', ngoId),
      where('status', '==', 'fulfilled')
    );
    
    const [openSnap, fulfilledSnap] = await Promise.all([
      getDocs(openQ),
      getDocs(fulfilledQ)
    ]);
    
    return {
      open: openSnap.size,
      fulfilled: fulfilledSnap.size
    };
  } catch (error) {
    console.error('Error getting NGO request counts:', error);
    throw error;
  }
}

/**
 * Approve NGO verification request
 * @param ngoUid User ID of the NGO
 * @param requestId The verification request ID
 */
export async function approveNgoVerification(ngoUid: string, requestId: string): Promise<void> {
  try {
    const db = getFirestore();
    const batch = writeBatch(db);
    
    // Update the verification request status
    const requestRef = doc(db, 'verificationRequests', requestId);
    batch.update(requestRef, {
      status: 'approved',
      approvedAt: serverTimestamp(),
      approvedBy: auth.currentUser?.uid || 'system'
    });
    
    // Update the user profile with verified status
    const userRef = doc(db, 'users', ngoUid);
    batch.update(userRef, {
      verificationStatus: 'verified',
      verifiedAt: serverTimestamp()
    });
    
    await batch.commit();
    
    // Send notification to the NGO
    await createNotification({
      userId: ngoUid,
      type: 'verificationUpdated',
      title: 'Verification Approved',
      message: 'Congratulations! Your NGO verification has been approved. You now have full access to all platform features.',
      isRead: false
    });
    
  } catch (error) {
    console.error('Error approving NGO verification:', error);
    throw error;
  }
}

/**
 * Reject NGO verification request
 * @param ngoUid User ID of the NGO
 * @param requestId The verification request ID
 * @param reason Reason for rejection
 */
export async function rejectNgoVerification(ngoUid: string, requestId: string, reason: string): Promise<void> {
  try {
    const db = getFirestore();
    const batch = writeBatch(db);
    
    // Update the verification request status
    const requestRef = doc(db, 'verificationRequests', requestId);
    batch.update(requestRef, {
      status: 'rejected',
      rejectedAt: serverTimestamp(),
      rejectedBy: auth.currentUser?.uid || 'system',
      rejectionReason: reason
    });
    
    // Update the user profile with rejected status
    const userRef = doc(db, 'users', ngoUid);
    batch.update(userRef, {
      verificationStatus: 'rejected',
      rejectionReason: reason
    });
    
    await batch.commit();
    
    // Send notification to the NGO
    await createNotification({
      userId: ngoUid,
      type: 'verificationUpdated',
      title: 'Verification Rejected',
      message: `Your NGO verification has been rejected. Reason: ${reason}`,
      isRead: false
    });
    
  } catch (error) {
    console.error('Error rejecting NGO verification:', error);
    throw error;
  }
}

/**
 * Get pending NGO verification requests
 * @param limitSize Number of requests to return
 */
export async function getPendingNgoVerifications(limitSize = 10): Promise<any[]> {
  try {
    const db = getFirestore();
    const q = query(
      collection(db, 'verificationRequests'),
      where('status', '==', 'pending'),
      orderBy('submittedAt', 'desc'),
      limit(limitSize)
    );
    
    const snapshot = await getDocs(q);
    const requests = snapshot.docs.map(doc => ({
      id: doc.id,
      ...(doc.data() as { uid: string; submittedAt: any; [key: string]: any })
    }));
    
    // Fetch NGO names for each request
    const requestsWithNames = await Promise.all(
      requests.map(async (req) => {
        if (req.uid) {
          const userDoc = await getDoc(doc(db, 'users', req.uid));
          if (userDoc.exists()) {
            const userData = userDoc.data();
            return {
              ...req,
              ngoName: userData.name || userData.organizationName,
              ngoEmail: userData.email
            };
          }
        }
        return req;
      })
    );
    
    return requestsWithNames;
  } catch (error) {
    console.error('Error getting pending NGO verifications:', error);
    throw error;
  }
}

// Contact form functions
interface ContactFormData {
  name: string;
  email: string;
  subject?: string;
  message: string;
  userType: 'general' | 'donor' | 'ngo';
  createdAt: Date;
}

/**
 * Submit contact form data
 * @param formData Contact form data
 */
export async function submitContactForm(formData: ContactFormData): Promise<void> {
  try {
    const db = getFirestore();
    const contactRef = doc(collection(db, 'contactMessages'));
    
    await setDoc(contactRef, {
      ...formData,
      createdAt: serverTimestamp(),
      status: 'new'
    });
    
    // Send notification to admin
    await createNotification({
      targetUserRole: 'admin',
      type: 'messageReceived',
      title: 'New Contact Message',
      message: `New contact message from ${formData.name}: ${formData.subject || 'No subject'}`,
      isRead: false,
      metadata: {
        contactMessageId: contactRef.id,
        senderName: formData.name,
        senderEmail: formData.email,
        userType: formData.userType
      }
    });
  } catch (error) {
    console.error('Error submitting contact form:', error);
    throw error;
  }
} 