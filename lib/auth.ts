import { auth } from './firebase';
import { 
  createUserWithEmailAndPassword, 
  signInWithEmailAndPassword, 
  signOut as firebaseSignOut,
  onAuthStateChanged,
  User as FirebaseUser,
  updateProfile
} from 'firebase/auth';

export const signUp = async (email: string, password: string, displayName: string) => {
  try {
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    await updateProfile(userCredential.user, { displayName });
    return { user: userCredential.user, error: null };
  } catch (error: unknown) {
    const err = error as { code?: string; message?: string };
    return { user: null, error: err.message || 'Failed to sign up' };
  }
};

export const signIn = async (email: string, password: string) => {
  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    return { user: userCredential.user, error: null };
  } catch (error: unknown) {
    const err = error as { code?: string; message?: string };
    return { user: null, error: err.message || 'Failed to sign in' };
  }
};

export const signOut = async () => {
  try {
    await firebaseSignOut(auth);
    return { error: null };
  } catch (error: unknown) {
    const err = error as { message?: string };
    return { error: err.message || 'Failed to sign out' };
  }
};

export const subscribeToAuth = (callback: (user: FirebaseUser | null) => void) => {
  return onAuthStateChanged(auth, callback);
};

export const getCurrentUser = (): FirebaseUser | null => {
  return auth.currentUser;
};
