'use client'
import React, { createContext, useState, useEffect, useContext, ReactNode, useCallback } from 'react';
import { 
  User,
  createUserWithEmailAndPassword, 
  signInWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged, 
  sendPasswordResetEmail,
  signInWithPopup,
  updateProfile,
  UserCredential
} from 'firebase/auth';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { auth, db, googleProvider } from '../lib/firebase';
import { useRouter } from 'next/navigation';

// Define user roles
export type UserRole = 'donor' | 'ngo' | 'admin';

// Define user profile structure
export interface UserProfile {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
  role: UserRole;
  phone?: string;
  address?: string;
  verified?: boolean;
  createdAt: number;
}

// Define the auth context type
interface AuthContextType {
  currentUser: User | null;
  userProfile: UserProfile | null;
  loading: boolean;
  signup: (email: string, password: string, role?: UserRole, name?: string) => Promise<UserCredential>;
  login: (email: string, password: string) => Promise<UserCredential>;
  logout: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  googleSignIn: () => Promise<UserCredential>;
  updateUserProfile: (data: Partial<UserProfile>) => Promise<boolean>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  
  // Only initialize router on client side
  const router = typeof window !== 'undefined' ? useRouter() : null;

  // Helper to get user custom claims
  const getUserClaims = async (user: User) => {
    try {
      // Get user token result which contains any custom claims
      const tokenResult = await user.getIdTokenResult(true);
      return tokenResult.claims;
    } catch (error) {
      console.error("Error getting token claims:", error);
      return {};
    }
  };

  // Check if user has a specific role either in custom claims or Firestore profile
  const hasRole = async (user: User, role: string): Promise<boolean> => {
    try {
      // First check custom claims
      const claims = await getUserClaims(user);
      if (claims.role === role) return true;
      
      // Then check Firestore profile
      const userDoc = await getDoc(doc(db, "users", user.uid));
      if (userDoc.exists() && userDoc.data().role === role) return true;
      
      return false;
    } catch (error) {
      console.error("Error checking user role:", error);
      return false;
    }
  };

  // Load user profile from Firestore
  const loadUserProfile = useCallback(async (user: User) => {
    try {
      const docRef = doc(db, "users", user.uid);
      const docSnap = await getDoc(docRef);
      
      if (docSnap.exists()) {
        const profileData = docSnap.data() as UserProfile;
        setUserProfile({
          ...profileData,
          uid: user.uid,
          email: user.email || "",
          displayName: user.displayName || profileData.displayName || "",
          photoURL: user.photoURL || profileData.photoURL || ""
        });
      } else {
        // No profile exists, create a default one
        const defaultRole = "donor"; // Default role for new users
        const newProfile: UserProfile = {
          uid: user.uid,
          email: user.email || "",
          displayName: user.displayName || "",
          photoURL: user.photoURL || "",
          role: defaultRole,
          createdAt: Date.now()
        };
        
        await setDoc(docRef, newProfile);
        setUserProfile(newProfile);
      }
    } catch (error) {
      console.error("Error loading user profile:", error);
    }
  }, []);

  // Initialize auth state
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (authUser) => {
      try {
        if (authUser) {
          setUser(authUser);
          await loadUserProfile(authUser);
          
          // Force token refresh to get latest custom claims
          await authUser.getIdToken(true);
        } else {
          setUser(null);
          setUserProfile(null);
        }
      } catch (error) {
        console.error("Auth state change error:", error);
      } finally {
        setLoading(false);
      }
    });

    return () => unsubscribe();
  }, [loadUserProfile]);

  // Create a new user with email and password
  const signup = async (email: string, password: string, role: UserRole = 'donor', name: string = '') => {
    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const newUser = userCredential.user;
      
      // Create profile in Firestore
      const userProfile: UserProfile = {
        uid: newUser.uid,
        email: newUser.email || email,
        displayName: name || email.split('@')[0],
        photoURL: '',
        role: role,
        createdAt: Date.now()
      };
      
      await setDoc(doc(db, 'users', newUser.uid), userProfile);
      
      return userCredential;
    } catch (error) {
      console.error("Error signing up:", error);
      throw error;
    }
  };

  // Login with email and password
  const login = async (email: string, password: string) => {
    return signInWithEmailAndPassword(auth, email, password);
  };

  // Sign out
  const logout = () => {
    return signOut(auth);
  };

  // Reset password
  const resetPassword = (email: string) => {
    return sendPasswordResetEmail(auth, email);
  };

  // Google sign in function
  const googleSignIn = async () => {
    try {
      const result = await signInWithPopup(auth, googleProvider);
      // User will be automatically loaded by the auth state listener
      return result;
    } catch (error) {
      console.error("Google sign in error:", error);
      throw error;
    }
  };

  // Update user profile
  const updateUserProfile = async (data: Partial<UserProfile>) => {
    if (!user) throw new Error('No authenticated user');
    
    try {
      const userRef = doc(db, 'users', user.uid);
      await setDoc(userRef, data, { merge: true });
      
      // Update local state
      setUserProfile(prev => prev ? { ...prev, ...data } : null);
      
      // If updating display name, also update auth profile
      if (data.displayName) {
        await updateProfile(user, { displayName: data.displayName });
      }
      
      return true;
    } catch (error) {
      console.error("Error updating profile:", error);
      throw error;
    }
  };

  const value = {
    currentUser: user,
    userProfile,
    loading,
    signup,
    login,
    logout,
    resetPassword,
    googleSignIn,
    updateUserProfile,
  };

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
}; 