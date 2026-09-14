import { collection, doc, setDoc, addDoc, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';

export async function seedDemoData() {
  const userId = 'demo_user_001';
  const farmId = 'farm_001';
  const zone1Id = 'zone_001';
  const zone2Id = 'zone_002';

  // Create user document
  await setDoc(doc(db, 'users', userId), {
    name: 'Admin User',
    email: 'admin@agriguard.com',
    role: 'admin',
    farmId,
    createdAt: Timestamp.now(),
    lastLoginAt: Timestamp.now(),
  });

  // Create farm
  await setDoc(doc(db, 'farms', farmId), {
    name: 'AgriGuard Demo Farm',
    location: 'Egypt',
    ownerId: userId,
    cropType: 'tomato',
    status: 'active',
    totalZones: 2,
    createdAt: Timestamp.now(),
  });

  // Create zones
  await setDoc(doc(db, 'zones', zone1Id), {
    farmId,
    name: 'Zone 1',
    cropType: 'tomato',
    targetMoisture: 55,
    minimumMoisture: 35,
    maximumMoisture: 70,
    autoIrrigation: true,
    pumpStatus: 'off',
    deviceStatus: 'online',
    createdAt: Timestamp.now(),
  });

  await setDoc(doc(db, 'zones', zone2Id), {
    farmId,
    name: 'Zone 2',
    cropType: 'pepper',
    targetMoisture: 50,
    minimumMoisture: 30,
    maximumMoisture: 65,
    autoIrrigation: false,
    pumpStatus: 'off',
    deviceStatus: 'online',
    createdAt: Timestamp.now(),
  });

  // Create crop profiles
  await setDoc(doc(db, 'cropProfiles', 'tomato'), {
    name: 'Tomato',
    minimumMoisture: 35,
    targetMoisture: 55,
    maximumMoisture: 70,
    minTemperature: 18,
    maxTemperature: 32,
    description: 'Tomato crop profile optimized for greenhouse cultivation',
    createdAt: Timestamp.now(),
  });

  await setDoc(doc(db, 'cropProfiles', 'pepper'), {
    name: 'Pepper',
    minimumMoisture: 30,
    targetMoisture: 50,
    maximumMoisture: 65,
    minTemperature: 20,
    maxTemperature: 35,
    description: 'Pepper crop profile for optimal yield',
    createdAt: Timestamp.now(),
  });

  // Create system config
  await setDoc(doc(db, 'systemConfig', 'main'), {
    selectedModel: 'google/gemma-3-27b-it:free',
    aiEnabled: true,
    temperature: 0.2,
    maxTokens: 1200,
    analysisIntervalMinutes: 10,
    defaultFarmId: farmId,
    maintenanceMode: false,
    updatedAt: Timestamp.now(),
  });

  // Generate sensor readings (last 48 hours)
  const now = new Date();
  const baseMoisture = 63;
  const baseTemp = 29.4;
  const baseHumidity = 56;
  const baseWaterLevel = 74;

  for (let i = 48; i >= 0; i--) {
    const timestamp = new Date(now.getTime() - i * 60 * 60 * 1000);
    
    await addDoc(collection(db, 'sensorReadings'), {
      farmId,
      zoneId: zone1Id,
      soilMoisture: Math.min(100, Math.max(0, baseMoisture + (Math.random() - 0.5) * 10)),
      temperature: Math.min(40, Math.max(15, baseTemp + (Math.random() - 0.5) * 5)),
      humidity: Math.min(100, Math.max(20, baseHumidity + (Math.random() - 0.5) * 15)),
      waterLevel: Math.min(100, Math.max(0, baseWaterLevel - (48 - i) * 0.5)),
      flowRate: Math.max(0, 1.8 + (Math.random() - 0.5) * 0.5),
      lightLevel: Math.min(100, Math.max(0, 78 + (Math.random() - 0.5) * 20)),
      pumpStatus: i % 12 === 0, // Pump on every 12 hours
      deviceStatus: 'online',
      timestamp: Timestamp.fromDate(timestamp),
    });
  }

  // Create AI analysis
  await addDoc(collection(db, 'aiAnalyses'), {
    farmId,
    zoneId: zone1Id,
    model: 'google/gemma-3-27b-it:free',
    healthScore: 87,
    healthStatus: 'healthy',
    waterStress: 'low',
    temperatureStatus: 'normal',
    anomalyDetected: false,
    irrigationRequired: false,
    confidence: 0.91,
    summary: 'The crop is currently healthy and soil moisture is within the recommended range. Temperature and humidity levels are optimal for tomato growth.',
    recommendations: [
      'Continue monitoring soil moisture levels',
      'Monitor afternoon temperature peaks',
      'Consider slight irrigation adjustment if moisture drops below 50%',
    ],
    createdAt: Timestamp.now(),
  });

  // Create irrigation logs
  await addDoc(collection(db, 'irrigationLogs'), {
    farmId,
    zoneId: zone1Id,
    trigger: 'automatic',
    reason: 'Soil moisture below target threshold',
    status: 'completed',
    durationSeconds: 420,
    waterUsedLiters: 12.4,
    startedAt: Timestamp.fromDate(new Date(now.getTime() - 24 * 60 * 60 * 1000)),
    endedAt: Timestamp.fromDate(new Date(now.getTime() - 24 * 60 * 60 * 1000 + 420 * 1000)),
  });

  await addDoc(collection(db, 'irrigationLogs'), {
    farmId,
    zoneId: zone1Id,
    trigger: 'ai_recommendation',
    reason: 'AI detected increasing water stress trend',
    status: 'completed',
    durationSeconds: 360,
    waterUsedLiters: 10.8,
    startedAt: Timestamp.fromDate(new Date(now.getTime() - 48 * 60 * 60 * 1000)),
    endedAt: Timestamp.fromDate(new Date(now.getTime() - 48 * 60 * 60 * 1000 + 360 * 1000)),
  });

  // Create alerts
  await addDoc(collection(db, 'alerts'), {
    farmId,
    zoneId: zone1Id,
    type: 'low_moisture',
    severity: 'warning',
    title: 'Low Soil Moisture',
    message: 'Soil moisture dropped to 38%, below the recommended minimum of 35%.',
    resolved: true,
    createdAt: Timestamp.fromDate(new Date(now.getTime() - 48 * 60 * 60 * 1000)),
    resolvedAt: Timestamp.fromDate(new Date(now.getTime() - 47 * 60 * 60 * 1000)),
  });

  console.log('Demo data seeded successfully!');
}
