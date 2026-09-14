'use client';

import { useEffect, useState } from 'react';
import { User as FirebaseUser } from 'firebase/auth';
import { subscribeToAuth, signOut } from '@/lib/auth';
import { getUser, type User } from '@/lib/firestore';

export function useAuth() {
  const [user, setUser] = useState<FirebaseUser | null>(null);
  const [userData, setUserData] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = subscribeToAuth(async (firebaseUser) => {
      setUser(firebaseUser);
      
      if (firebaseUser) {
        const userDoc = await getUser(firebaseUser.uid);
        setUserData(userDoc);
      } else {
        setUserData(null);
      }
      
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleSignOut = async () => {
    await signOut();
  };

  return { user, userData, loading, signOut: handleSignOut };
}
