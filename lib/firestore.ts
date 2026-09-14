import { 
  collection, 
  doc, 
  getDoc, 
  setDoc, 
  updateDoc, 
  onSnapshot, 
  query, 
  where, 
  orderBy, 
  limit, 
  Timestamp,
  addDoc,
  getDocs,
  serverTimestamp 
} from 'firebase/firestore';
import { db } from './firebase';
import type { 
  User, 
  Farm, 
  Zone, 
  SensorReading, 
  IrrigationLog, 
  Alert, 
  AIAnalysis, 
  CropProfile, 
  SystemConfig 
} from '@/types';

// Users
export const getUser = async (uid: string): Promise<User | null> => {
  try {
    const userDoc = await getDoc(doc(db, 'users', uid));
    if (!userDoc.exists()) return null;
    const data = userDoc.data();
    return {
      uid,
      name: data.name || '',
      email: data.email || '',
      role: data.role || 'user',
      farmId: data.farmId || '',
      createdAt: data.createdAt?.toDate() || new Date(),
      lastLoginAt: data.lastLoginAt?.toDate() || new Date(),
    } as User;
  } catch (error) {
    console.error('Error getting user:', error);
    return null;
  }
};

export const createUser = async (uid: string, userData: Partial<User>): Promise<void> => {
  await setDoc(doc(db, 'users', uid), {
    ...userData,
    createdAt: serverTimestamp(),
    lastLoginAt: serverTimestamp(),
  });
};

// Farms
export const getFarm = async (farmId: string): Promise<Farm | null> => {
  try {
    const farmDoc = await getDoc(doc(db, 'farms', farmId));
    if (!farmDoc.exists()) return null;
    const data = farmDoc.data();
    return {
      id: farmId,
      name: data.name || '',
      location: data.location || '',
      ownerId: data.ownerId || '',
      cropType: data.cropType || '',
      status: data.status || 'active',
      totalZones: data.totalZones || 0,
      createdAt: data.createdAt?.toDate() || new Date(),
    } as Farm;
  } catch (error) {
    console.error('Error getting farm:', error);
    return null;
  }
};

export const getFarmsByOwner = async (ownerId: string): Promise<Farm[]> => {
  try {
    const q = query(collection(db, 'farms'), where('ownerId', '==', ownerId));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
    } as Farm));
  } catch (error) {
    console.error('Error getting farms:', error);
    return [];
  }
};

// Zones
export const getZones = async (farmId: string): Promise<Zone[]> => {
  try {
    const q = query(collection(db, 'zones'), where('farmId', '==', farmId));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
    } as Zone));
  } catch (error) {
    console.error('Error getting zones:', error);
    return [];
  }
};

export const getZone = async (zoneId: string): Promise<Zone | null> => {
  try {
    const zoneDoc = await getDoc(doc(db, 'zones', zoneId));
    if (!zoneDoc.exists()) return null;
    const data = zoneDoc.data();
    return {
      id: zoneId,
      ...data,
      createdAt: data.createdAt?.toDate() || new Date(),
    } as Zone;
  } catch (error) {
    console.error('Error getting zone:', error);
    return null;
  }
};

export const subscribeToZones = (farmId: string, callback: (zones: Zone[]) => void) => {
  const q = query(collection(db, 'zones'), where('farmId', '==', farmId));
  return onSnapshot(q, (snapshot) => {
    const zones = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
    } as Zone));
    callback(zones);
  });
};

// Sensor Readings
export const getLatestSensorReading = async (farmId: string, zoneId?: string): Promise<SensorReading | null> => {
  try {
    let q;
    if (zoneId) {
      q = query(
        collection(db, 'sensorReadings'),
        where('farmId', '==', farmId),
        where('zoneId', '==', zoneId),
        orderBy('timestamp', 'desc'),
        limit(1)
      );
    } else {
      q = query(
        collection(db, 'sensorReadings'),
        where('farmId', '==', farmId),
        orderBy('timestamp', 'desc'),
        limit(1)
      );
    }
    
    const snapshot = await getDocs(q);
    if (snapshot.empty) return null;
    
    const doc = snapshot.docs[0];
    const data = doc.data();
    return {
      id: doc.id,
      farmId: data.farmId,
      zoneId: data.zoneId,
      soilMoisture: data.soilMoisture,
      temperature: data.temperature,
      humidity: data.humidity,
      waterLevel: data.waterLevel,
      flowRate: data.flowRate,
      lightLevel: data.lightLevel,
      pumpStatus: data.pumpStatus,
      deviceStatus: data.deviceStatus,
      timestamp: data.timestamp?.toDate() || new Date(),
    } as SensorReading;
  } catch (error) {
    console.error('Error getting latest sensor reading:', error);
    return null;
  }
};

export const getSensorHistory = async (
  farmId: string, 
  zoneId: string, 
  hours: number = 24
): Promise<SensorReading[]> => {
  try {
    const startTime = new Date(Date.now() - hours * 60 * 60 * 1000);
    const q = query(
      collection(db, 'sensorReadings'),
      where('farmId', '==', farmId),
      where('zoneId', '==', zoneId),
      where('timestamp', '>=', Timestamp.fromDate(startTime)),
      orderBy('timestamp', 'asc')
    );
    
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp?.toDate() || new Date(),
    } as SensorReading));
  } catch (error) {
    console.error('Error getting sensor history:', error);
    return [];
  }
};

export const subscribeToLatestReading = (
  farmId: string, 
  zoneId: string, 
  callback: (reading: SensorReading | null) => void
) => {
  const q = query(
    collection(db, 'sensorReadings'),
    where('farmId', '==', farmId),
    where('zoneId', '==', zoneId),
    orderBy('timestamp', 'desc'),
    limit(1)
  );
  
  return onSnapshot(q, (snapshot) => {
    if (snapshot.empty) {
      callback(null);
      return;
    }
    
    const doc = snapshot.docs[0];
    const data = doc.data();
    callback({
      id: doc.id,
      farmId: data.farmId,
      zoneId: data.zoneId,
      soilMoisture: data.soilMoisture,
      temperature: data.temperature,
      humidity: data.humidity,
      waterLevel: data.waterLevel,
      flowRate: data.flowRate,
      lightLevel: data.lightLevel,
      pumpStatus: data.pumpStatus,
      deviceStatus: data.deviceStatus,
      timestamp: data.timestamp?.toDate() || new Date(),
    } as SensorReading);
  });
};

// AI Analyses
export const getLatestAIAnalysis = async (farmId: string, zoneId?: string): Promise<AIAnalysis | null> => {
  try {
    let q;
    if (zoneId) {
      q = query(
        collection(db, 'aiAnalyses'),
        where('farmId', '==', farmId),
        where('zoneId', '==', zoneId),
        orderBy('createdAt', 'desc'),
        limit(1)
      );
    } else {
      q = query(
        collection(db, 'aiAnalyses'),
        where('farmId', '==', farmId),
        orderBy('createdAt', 'desc'),
        limit(1)
      );
    }
    
    const snapshot = await getDocs(q);
    if (snapshot.empty) return null;
    
    const doc = snapshot.docs[0];
    const data = doc.data();
    return {
      id: doc.id,
      farmId: data.farmId,
      zoneId: data.zoneId,
      model: data.model,
      healthScore: data.healthScore,
      healthStatus: data.healthStatus,
      waterStress: data.waterStress,
      temperatureStatus: data.temperatureStatus,
      anomalyDetected: data.anomalyDetected,
      irrigationRequired: data.irrigationRequired,
      confidence: data.confidence,
      summary: data.summary,
      recommendations: data.recommendations || [],
      createdAt: data.createdAt?.toDate() || new Date(),
    } as AIAnalysis;
  } catch (error) {
    console.error('Error getting latest AI analysis:', error);
    return null;
  }
};

export const getAIAnalysisHistory = async (farmId: string, zoneId: string, limitCount: number = 10): Promise<AIAnalysis[]> => {
  try {
    const q = query(
      collection(db, 'aiAnalyses'),
      where('farmId', '==', farmId),
      where('zoneId', '==', zoneId),
      orderBy('createdAt', 'desc'),
      limit(limitCount)
    );
    
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
    } as AIAnalysis));
  } catch (error) {
    console.error('Error getting AI analysis history:', error);
    return [];
  }
};

export const saveAIAnalysis = async (analysis: Omit<AIAnalysis, 'id' | 'createdAt'>): Promise<string> => {
  const docRef = await addDoc(collection(db, 'aiAnalyses'), {
    ...analysis,
    createdAt: serverTimestamp(),
  });
  return docRef.id;
};

// Alerts
export const getAlerts = async (farmId: string, zoneId?: string): Promise<Alert[]> => {
  try {
    let q;
    if (zoneId) {
      q = query(
        collection(db, 'alerts'),
        where('farmId', '==', farmId),
        where('zoneId', '==', zoneId),
        orderBy('createdAt', 'desc')
      );
    } else {
      q = query(
        collection(db, 'alerts'),
        where('farmId', '==', farmId),
        orderBy('createdAt', 'desc')
      );
    }
    
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      resolvedAt: doc.data().resolvedAt?.toDate() || null,
    } as Alert));
  } catch (error) {
    console.error('Error getting alerts:', error);
    return [];
  }
};

export const resolveAlert = async (alertId: string): Promise<void> => {
  await updateDoc(doc(db, 'alerts', alertId), {
    resolved: true,
    resolvedAt: serverTimestamp(),
  });
};

export const subscribeToAlerts = (farmId: string, callback: (alerts: Alert[]) => void) => {
  const q = query(
    collection(db, 'alerts'),
    where('farmId', '==', farmId),
    orderBy('createdAt', 'desc')
  );
  
  return onSnapshot(q, (snapshot) => {
    const alerts = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
      resolvedAt: doc.data().resolvedAt?.toDate() || null,
    } as Alert));
    callback(alerts);
  });
};

// Irrigation Logs
export const getIrrigationLogs = async (farmId: string, zoneId?: string, limitCount: number = 20): Promise<IrrigationLog[]> => {
  try {
    let q;
    if (zoneId) {
      q = query(
        collection(db, 'irrigationLogs'),
        where('farmId', '==', farmId),
        where('zoneId', '==', zoneId),
        orderBy('startedAt', 'desc'),
        limit(limitCount)
      );
    } else {
      q = query(
        collection(db, 'irrigationLogs'),
        where('farmId', '==', farmId),
        orderBy('startedAt', 'desc'),
        limit(limitCount)
      );
    }
    
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      startedAt: doc.data().startedAt?.toDate() || new Date(),
      endedAt: doc.data().endedAt?.toDate() || null,
    } as IrrigationLog));
  } catch (error) {
    console.error('Error getting irrigation logs:', error);
    return [];
  }
};

// Crop Profiles
export const getCropProfiles = async (): Promise<CropProfile[]> => {
  try {
    const snapshot = await getDocs(collection(db, 'cropProfiles'));
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate() || new Date(),
    } as CropProfile));
  } catch (error) {
    console.error('Error getting crop profiles:', error);
    return [];
  }
};

export const getCropProfile = async (name: string): Promise<CropProfile | null> => {
  try {
    const q = query(collection(db, 'cropProfiles'), where('name', '==', name));
    const snapshot = await getDocs(q);
    if (snapshot.empty) return null;
    
    const doc = snapshot.docs[0];
    const data = doc.data();
    return {
      id: doc.id,
      ...data,
      createdAt: data.createdAt?.toDate() || new Date(),
    } as CropProfile;
  } catch (error) {
    console.error('Error getting crop profile:', error);
    return null;
  }
};

// System Config
export const getSystemConfig = async (): Promise<SystemConfig | null> => {
  try {
    const configDoc = await getDoc(doc(db, 'systemConfig', 'main'));
    if (!configDoc.exists()) return null;
    
    const data = configDoc.data();
    return {
      id: 'main',
      selectedModel: data.selectedModel || '',
      aiEnabled: data.aiEnabled ?? true,
      temperature: data.temperature ?? 0.2,
      maxTokens: data.maxTokens ?? 1200,
      analysisIntervalMinutes: data.analysisIntervalMinutes ?? 10,
      defaultFarmId: data.defaultFarmId || '',
      maintenanceMode: data.maintenanceMode ?? false,
      updatedAt: data.updatedAt?.toDate() || new Date(),
    } as SystemConfig;
  } catch (error) {
    console.error('Error getting system config:', error);
    return null;
  }
};

export const updateSystemConfig = async (config: Partial<SystemConfig>): Promise<void> => {
  await updateDoc(doc(db, 'systemConfig', 'main'), {
    ...config,
    updatedAt: serverTimestamp(),
  });
};

export const initializeSystemConfig = async (): Promise<void> => {
  const configRef = doc(db, 'systemConfig', 'main');
  const configDoc = await getDoc(configRef);
  
  if (!configDoc.exists()) {
    await setDoc(configRef, {
      selectedModel: 'google/gemma-3-27b-it:free',
      aiEnabled: true,
      temperature: 0.2,
      maxTokens: 1200,
      analysisIntervalMinutes: 10,
      defaultFarmId: '',
      maintenanceMode: false,
      updatedAt: serverTimestamp(),
    });
  }
};
